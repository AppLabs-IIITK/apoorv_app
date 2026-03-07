import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../constants.dart';
import '../../../providers/app_config_provider.dart';

class ManageShopkeepersScreen extends StatefulWidget {
  static const routeName = '/manage-shopkeepers';

  const ManageShopkeepersScreen({super.key});

  @override
  State<ManageShopkeepersScreen> createState() => _ManageShopkeepersScreenState();
}

class _ManageShopkeepersScreenState extends State<ManageShopkeepersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _shopkeeperSubscription;
  List<QueryDocumentSnapshot> _shopkeeperDocs = [];
  bool _isInitialLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _subscribeShopkeepers();
  }

  @override
  void dispose() {
    _shopkeeperSubscription?.cancel();
    super.dispose();
  }

  void _subscribeShopkeepers() {
    _shopkeeperSubscription?.cancel();
    _shopkeeperSubscription = _firestore
        .collection('users')
        .where('isShopkeeper', isEqualTo: true)
        .snapshots()
        .listen(
      (snapshot) {
        final docs = snapshot.docs.toList();
        docs.sort((a, b) {
          final ad = a.data();
          final bd = b.data();
          final an = (ad['name'] ?? '').toString().toLowerCase();
          final bn = (bd['name'] ?? '').toString().toLowerCase();
          return an.compareTo(bn);
        });
        if (!mounted) return;
        setState(() {
          _shopkeeperDocs = docs;
          _isInitialLoading = false;
          _loadError = null;
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _isInitialLoading = false;
          _loadError = error.toString();
        });
      },
    );
  }

  Future<void> _showAddShopkeeperDialog() async {
    final identifierController = TextEditingController();
    final pointsController = TextEditingController(text: '0');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Constants.blackColor,
        title: const Text('Add shopkeeper',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: identifierController,
              keyboardType: TextInputType.text,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Email or Roll No',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pointsController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Initial shop points',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final identifier = identifierController.text.trim();
    final email = identifier.toLowerCase();
    final rollNo = identifier;
    final points = int.tryParse(pointsController.text.trim()) ?? -1;

    if (identifier.isEmpty || points < 0) {
      _showSnack('Enter email/roll no and non-negative points');
      return;
    }

    try {
      QuerySnapshot query;
      if (identifier.contains('@')) {
        query = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
      } else {
        final rollCandidates = <String>{rollNo, rollNo.toUpperCase()};
        QuerySnapshot? found;
        for (final candidate in rollCandidates) {
          if (candidate.trim().isEmpty) continue;
          final snap = await _firestore
              .collection('users')
              .where('rollNumber', isEqualTo: candidate)
              .limit(1)
              .get();
          if (snap.docs.isNotEmpty) {
            found = snap;
            break;
          }
        }
        query = found ??
            await _firestore
                .collection('users')
                .where('rollNumber', isEqualTo: '__no_match__')
                .limit(1)
                .get();
      }

      if (query.docs.isEmpty) {
        _showSnack('No user found with that email/roll no');
        return;
      }

      await query.docs.first.reference.update({
        'isShopkeeper': true,
        'shopPoints': points,
      });
      _showSnack('Shopkeeper updated');
    } catch (e) {
      _showSnack('Failed to add shopkeeper: $e');
    }
  }

  Future<void> _showEditPointsDialog(QueryDocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final currentPoints = (data['shopPoints'] as int?) ?? 0;
    final controller = TextEditingController(text: currentPoints.toString());

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Constants.blackColor,
        title: const Text('Edit shop points',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Shop points',
            labelStyle: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final points = int.tryParse(controller.text.trim()) ?? -1;
    if (points < 0) {
      _showSnack('Enter non-negative points');
      return;
    }

    try {
      await doc.reference.update({'shopPoints': points});
      _showSnack('Points updated');
    } catch (e) {
      _showSnack('Failed to update points: $e');
    }
  }

  Future<void> _removeShopkeeper(QueryDocumentSnapshot doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Constants.blackColor,
        title: const Text('Remove shopkeeper',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will disable shopkeeper mode and set shop points to 0.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await doc.reference.update({
        'isShopkeeper': false,
        'shopPoints': 0,
      });
      _showSnack('Shopkeeper removed');
    } catch (e) {
      _showSnack('Failed to remove shopkeeper: $e');
    }
  }

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final canManage = context.watch<AppConfigProvider>().canManageContent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Shop Keepers'),
        actions: [
          if (canManage)
            IconButton(
              tooltip: 'Add shopkeeper',
              icon: const Icon(Icons.person_add_alt_1),
              onPressed: _showAddShopkeeperDialog,
            ),
        ],
      ),
      backgroundColor: const Color.fromRGBO(18, 18, 18, 1),
      body: !canManage
          ? const Center(
              child: Text(
                'Not authorized',
                style: TextStyle(color: Colors.white),
              ),
            )
          : _isInitialLoading
              ? const Center(child: CircularProgressIndicator())
              : _loadError != null
                  ? Center(
                      child: Text(
                        'Failed to load shopkeepers: $_loadError',
                        style: const TextStyle(color: Colors.white),
                      ),
                    )
                  : _shopkeeperDocs.isEmpty
                      ? const Center(
                          child: Text(
                            'No shopkeepers found',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _shopkeeperDocs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final doc = _shopkeeperDocs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final name = (data['name'] ?? 'Unknown').toString();
                            final email = (data['email'] ?? '').toString();
                            final points = (data['shopPoints'] as int?) ?? 0;

                            return Container(
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(30, 30, 30, 1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: ListTile(
                                title: Text(name,
                                    style: const TextStyle(color: Colors.white)),
                                subtitle: Text(
                                  '$email\nShop points: $points',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                isThreeLine: true,
                                trailing: Wrap(
                                  spacing: 4,
                                  children: [
                                    IconButton(
                                      tooltip: 'Edit points',
                                      icon: const Icon(Icons.edit,
                                          color: Constants.yellowColor),
                                      onPressed: () => _showEditPointsDialog(doc),
                                    ),
                                    IconButton(
                                      tooltip: 'Remove shopkeeper',
                                      icon: const Icon(Icons.delete,
                                          color: Colors.redAccent),
                                      onPressed: () => _removeShopkeeper(doc),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
    );
  }
}
