import 'package:apoorv_app/api.dart';
import 'package:apoorv_app/widgets/points-widget/transactions.dart';
import 'package:apoorv_app/widgets/transaction_details_modal.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../constants.dart';

class AllTransactions extends StatefulWidget {
  static const routeName = '/all-transactions';
  const AllTransactions({super.key});

  @override
  State<AllTransactions> createState() => _AllTransactionsState();
}

class _AllTransactionsState extends State<AllTransactions> {
  final _scrollController = ScrollController();

  bool _globalMode = false;
  bool _loading = false;
  bool _hasMore = true;

  List<Map<String, dynamic>> _txns = [];
  dynamic _lastDocument; // DocumentSnapshot<Map<String, dynamic>>

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _refresh();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loading) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _txns = [];
      _lastDocument = null;
      _hasMore = true;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
    });

    try {
      final api = APICalls();
      final page = _globalMode
          ? await api.getGlobalTransactions(
              lastDocument: _lastDocument,
              limit: 25,
            )
          : await api.getUserTransactionsPage(
              lastDocument: _lastDocument,
              limit: 25,
            );

      if (page['success'] != true) {
        throw Exception(page['error'] ?? 'Failed to load transactions');
      }

      final List<dynamic> raw = (page['transactions'] as List?) ?? [];
      final items = raw
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();

      setState(() {
        _txns.addAll(items);
        _lastDocument = page['lastDocument'];
        _hasMore = page['hasMore'] == true;
      });
    } catch (_) {
      // For testing UI, just stop pagination on failure.
      setState(() {
        _hasMore = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  DateTime _asLocalDateTime(dynamic ts) {
    if (ts == null) return DateTime.now();
    if (ts is DateTime) return ts.toLocal();
    // Timestamp
    if (ts.runtimeType.toString() == 'Timestamp') {
      try {
        // ignore: avoid_dynamic_calls
        return (ts.toDate() as DateTime).toLocal();
      } catch (_) {}
    }
    if (ts is String) {
      return (DateTime.tryParse(ts) ?? DateTime.now()).toLocal();
    }
    return DateTime.now();
  }

  void _showTransactionDetails(Map<String, dynamic> txn) {
    final fromUid = txn['from']?.toString() ?? '';
    final toUid = txn['to']?.toString() ?? '';
    final fromName = txn['fromName']?.toString() ?? 'Unknown';
    final toName = txn['toName']?.toString() ?? 'Unknown';
    final fromEmail = txn['fromEmail']?.toString() ?? '';
    final toEmail = txn['toEmail']?.toString() ?? '';
    final points = (txn['transactionValue'] is int)
        ? txn['transactionValue'] as int
        : int.tryParse(txn['transactionValue']?.toString() ?? '') ?? 0;
    final updatedAt = _asLocalDateTime(txn['updatedAt']);
    final formattedTime =
        DateFormat("MMMM d, yyyy 'at' h:mm a").format(updatedAt);

    final myUid = FirebaseAuth.instance.currentUser?.uid;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromRGBO(18, 18, 18, 1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TransactionDetailsModal(
        fromUid: fromUid,
        toUid: toUid,
        fromName: fromName,
        toName: toName,
        fromEmail: fromEmail,
        toEmail: toEmail,
        points: points,
        formattedTime: formattedTime,
        myUid: myUid,
      ),
    );
  }

  Widget _buildMyTxn(Map<String, dynamic> txn) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final fromUid = txn['from']?.toString();
    // final toUid = txn['to']?.toString();

    final updatedAt = _asLocalDateTime(txn['updatedAt']);
    final formattedTime =
        DateFormat("MMMM d, yyyy 'at' h:mm a").format(updatedAt);

    final myEmail = FirebaseAuth.instance.currentUser?.email?.trim().toLowerCase();

    final fromEmail = (txn['fromEmail'] ?? '').toString().trim().toLowerCase();

    final isDebit = (myUid != null && fromUid == myUid) || (myEmail != null && myEmail.isNotEmpty && fromEmail == myEmail);

    final name = isDebit ? (txn['toName'] ?? '') : (txn['fromName'] ?? '');
    final points = (txn['transactionValue'] is int)
        ? txn['transactionValue'] as int
        : int.tryParse(txn['transactionValue']?.toString() ?? '') ?? 0;
    final isShop =
        (txn['type'] ?? 'user').toString().toLowerCase() == 'shop';

    return TransactionsWidget(
      name: name.toString().isEmpty ? 'Unknown' : name.toString(),
      date: formattedTime,
      type: isDebit ? 'debit' : 'credit',
      points: points,
      isShop: isShop,
      fromUid: txn['from']?.toString(),
      toUid: txn['to']?.toString(),
      fromEmail: txn['fromEmail']?.toString(),
      toEmail: txn['toEmail']?.toString(),
      onTap: () => _showTransactionDetails(txn),
    );
  }

  Widget _buildGlobalTxn(Map<String, dynamic> txn) {
    final updatedAt = _asLocalDateTime(txn['updatedAt']);
    final formattedTime =
        DateFormat("MMMM d, yyyy 'at' h:mm a").format(updatedAt);
    final fromName = (txn['fromName'] ?? 'Unknown').toString();
    final toName = (txn['toName'] ?? 'Unknown').toString();
    final points = (txn['transactionValue'] is int)
        ? txn['transactionValue'] as int
        : int.tryParse(txn['transactionValue']?.toString() ?? '') ?? 0;
    final isShop =
        (txn['type'] ?? 'user').toString().toLowerCase() == 'shop';

    return InkWell(
      onTap: () => _showTransactionDetails(txn),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Container(
          decoration: BoxDecoration(
            color: Constants.silverColor,
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$fromName -> $toName',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color.fromRGBO(18, 18, 18, 1),
                            ),
                          ),
                        ),
                        if (isShop)
                          const Text(
                            'shop',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color.fromRGBO(18, 18, 18, 0.6),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      formattedTime,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color.fromRGBO(18, 18, 18, 1),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    points.toString(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Constants.blackColor,
                    ),
                  ),
                  const Text(
                    'Points',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color.fromRGBO(18, 18, 18, 1),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modeIndex = _globalMode ? 1 : 0;
    return Scaffold(
      backgroundColor: const Color.fromRGBO(18, 18, 18, 1),
      body: CustomMaterialIndicator(
        indicatorBuilder: (context, controller) =>
            Image.asset('assets/images/phoenix_74.png'),
        onRefresh: _refresh,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      Constants.gradientHigh,
                      Constants.gradientMid,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: const EdgeInsets.all(20.0),
                width: MediaQuery.of(context).size.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      child: const Icon(
                        Icons.arrow_back_outlined,
                        size: 30,
                        color: Colors.black,
                      ),
                      onTap: () => Navigator.pop(context),
                    ),
                    const Text(
                      'All Transactions',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Constants.gap,
                    const Text(
                      'Pull down to refresh. Scroll to load more.',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.03,
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: ToggleButtons(
                          isSelected: [modeIndex == 0, modeIndex == 1],
                          onPressed: (i) {
                            final newGlobal = i == 1;
                            if (newGlobal == _globalMode) return;
                            setState(() {
                              _globalMode = newGlobal;
                            });
                            _refresh();
                          },
                          borderRadius: BorderRadius.circular(12),
                          constraints: const BoxConstraints(minHeight: 44),
                          fillColor: Constants.yellowColor,
                          selectedColor: Constants.blackColor,
                          color: Colors.white,
                          borderColor: const Color(0xff2a2a2a),
                          selectedBorderColor: const Color.fromRGBO(42, 42, 42, 1),
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14),
                              child: Text(
                                'My Transactions',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14),
                              child: Text(
                                'Global Transactions',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                ),
                  ),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.03,
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _txns.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= _txns.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final txn = _txns[i];
                      return _globalMode ? _buildGlobalTxn(txn) : _buildMyTxn(txn);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
