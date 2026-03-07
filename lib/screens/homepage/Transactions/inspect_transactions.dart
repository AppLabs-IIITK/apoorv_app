import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../constants.dart';
import '../../../widgets/spinning_apoorv.dart';

class InspectTransactionsScreen extends StatefulWidget {
  static const routeName = '/inspect-transactions';

  final String uid;
  final String name;
  final String email;

  const InspectTransactionsScreen({
    super.key,
    required this.uid,
    required this.name,
    required this.email,
  });

  @override
  State<InspectTransactionsScreen> createState() =>
      _InspectTransactionsScreenState();
}

enum TxnFilter {
  all,
  sent,
  received,
  shopSent,
  shopReceived,
  transferSent,
}

enum TxnSort { dateDesc, amountDesc }

class _InspectTransactionsScreenState extends State<InspectTransactionsScreen> {
  bool _loading = true;
  String? _error;
  int _currentPoints = 0;
  List<Map<String, dynamic>> _txns = [];

  TxnFilter _filter = TxnFilter.all;
  TxnSort _sort = TxnSort.dateDesc;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();
      _currentPoints = (userSnap.data()?['points'] as int?) ?? 0;

      final email = widget.email.trim().toLowerCase();
      final txSnap = await FirebaseFirestore.instance
          .collection('transactions')
          .where('involvedPartiesEmails', arrayContains: email)
          .orderBy('updatedAt', descending: true)
          .limit(500)
          .get();

      _txns = txSnap.docs
          .map((d) => <String, dynamic>{'id': d.id, ...d.data()})
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  bool _isSent(Map<String, dynamic> txn) {
    final fromUid = txn['from']?.toString() ?? '';
    final fromEmail = (txn['fromEmail'] ?? '').toString().trim().toLowerCase();
    return fromUid == widget.uid ||
        (fromEmail.isNotEmpty && fromEmail == widget.email.toLowerCase());
  }

  bool _isReceived(Map<String, dynamic> txn) {
    final toUid = txn['to']?.toString() ?? '';
    final toEmail = (txn['toEmail'] ?? '').toString().trim().toLowerCase();
    return toUid == widget.uid ||
        (toEmail.isNotEmpty && toEmail == widget.email.toLowerCase());
  }

  String _txnType(Map<String, dynamic> txn) {
    return (txn['type'] ?? 'user').toString().toLowerCase() == 'shop'
        ? 'shop'
        : 'user';
  }

  int _txnAmount(Map<String, dynamic> txn) {
    final raw = txn['transactionValue'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  DateTime _txnTime(Map<String, dynamic> txn) {
    final raw = txn['updatedAt'];
    if (raw is Timestamp) return raw.toDate().toLocal();
    if (raw is DateTime) return raw.toLocal();
    return DateTime.tryParse(raw?.toString() ?? '')?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  List<Map<String, dynamic>> _filteredTxns() {
    Iterable<Map<String, dynamic>> items = _txns;
    switch (_filter) {
      case TxnFilter.sent:
        items = items.where(_isSent);
        break;
      case TxnFilter.received:
        items = items.where(_isReceived);
        break;
      case TxnFilter.shopSent:
        items = items.where((t) => _isSent(t) && _txnType(t) == 'shop');
        break;
      case TxnFilter.shopReceived:
        items = items.where((t) => _isReceived(t) && _txnType(t) == 'shop');
        break;
      case TxnFilter.transferSent:
        items = items.where((t) => _isSent(t) && _txnType(t) == 'user');
        break;
      case TxnFilter.all:
        break;
    }

    final list = items.toList();
    switch (_sort) {
      case TxnSort.amountDesc:
        list.sort((a, b) => _txnAmount(b).compareTo(_txnAmount(a)));
        break;
      case TxnSort.dateDesc:
        list.sort((a, b) => _txnTime(b).compareTo(_txnTime(a)));
        break;
    }
    return list;
  }

  Map<String, int> _computeTotals() {
    int sent = 0;
    int received = 0;
    int shopSent = 0;
    int shopReceived = 0;
    int transferSent = 0;

    for (final txn in _txns) {
      final amt = _txnAmount(txn);
      final type = _txnType(txn);
      if (_isSent(txn)) {
        sent += amt;
        if (type == 'shop') {
          shopSent += amt;
        } else {
          transferSent += amt;
        }
      }
      if (_isReceived(txn)) {
        received += amt;
        if (type == 'shop') {
          shopReceived += amt;
        }
      }
    }

    final net = received - transferSent;
    final unaccounted = _currentPoints - net;
    return {
      'sent': sent,
      'received': received,
      'net': net,
      'current': _currentPoints,
      'unaccounted': unaccounted,
      'shopSent': shopSent,
      'shopReceived': shopReceived,
      'transferSent': transferSent,
    };
  }

  Widget _statTile(String label, int value, {Color? color}) {
    final accent = color ?? Constants.yellowColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(30, 30, 30, 1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accent,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: accent.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: SpinningApoorv()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error!)),
      );
    }

    final totals = _computeTotals();
    final filtered = _filteredTxns();

    return Scaffold(
      backgroundColor: const Color.fromRGBO(18, 18, 18, 1),
      appBar: AppBar(
        title: Text('Inspect ${widget.name}'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _statTile('Transfer Sent', totals['transferSent']!),
                  _statTile('Total Received', totals['received']!),
                  _statTile('Net', totals['net']!),
                  _statTile('Total Points', totals['current']!),
                  _statTile('Unaccounted', totals['unaccounted']!),
                  _statTile('Shop Sent', totals['shopSent']!),
                  _statTile('Shop Received', totals['shopReceived']!),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  DropdownButton<TxnSort>(
                    value: _sort,
                    dropdownColor: const Color.fromRGBO(18, 18, 18, 1),
                    style: const TextStyle(color: Colors.white),
                    underline: Container(
                      height: 2,
                      color: Colors.white54,
                    ),
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() => _sort = val);
                    },
                    items: const [
                      DropdownMenuItem(
                        value: TxnSort.dateDesc,
                        child: Text('Sort: Date'),
                      ),
                      DropdownMenuItem(
                        value: TxnSort.amountDesc,
                        child: Text('Sort: Amount'),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip('All', TxnFilter.all),
                          _filterChip('Sent', TxnFilter.sent),
                          _filterChip('Received', TxnFilter.received),
                          _filterChip('Transfer Sent', TxnFilter.transferSent),
                          _filterChip('Shop Sent', TxnFilter.shopSent),
                          _filterChip('Shop Received', TxnFilter.shopReceived),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final txn = filtered[index];
                    final isSent = _isSent(txn);
                    final type = _txnType(txn);
                    final amount = _txnAmount(txn);
                    final time = _txnTime(txn);
                    final name = isSent ? txn['toName'] : txn['fromName'];

                    final isShop = type == 'shop';
                    final accent = isShop
                        ? Constants.yellowColor
                        : (isSent ? Constants.redColorAlt : Constants.greenColor);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(30, 30, 30, 1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accent.withOpacity(0.7),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      (name ?? 'Unknown').toString(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (isShop) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Constants.yellowColor,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Text(
                                          'SHOP',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${time.toLocal()}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white60,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isShop
                                      ? (isSent
                                          ? 'Shopkeeper sent'
                                          : 'Received from shopkeeper')
                                      : (isSent
                                          ? 'Transfer sent'
                                          : 'Transfer received'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            (isSent ? '- ' : '+ ') + amount.toString(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label, TxnFilter filter) {
    final selected = _filter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = filter),
        selectedColor: Constants.yellowColor,
        backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
        checkmarkColor: Colors.black, // Make checkmark visible on yellow background
        labelStyle: TextStyle(
          color: selected ? Colors.black : Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? Constants.yellowColor : Colors.white54,
          ),
        ),
      ),
    );
  }
}
