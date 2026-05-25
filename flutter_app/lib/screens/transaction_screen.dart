import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

const Color _bg = Color(0xFF0A0E27);
const Color _cardBg = Color(0xFF141832);
const Color _gold = Color(0xFFFFD700);
const Color _spenderAccent = Color(0xFFFF6B6B);
const Color _textSecondary = Color(0xFF8892B0);

final List<Transaction> _mockTransactions = [
  Transaction(
      id: '1',
      amount: 12499,
      merchant: 'Zomato',
      category: 'Food',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      isFraudulent: false,
      fraudScore: 0.0,
      location: 'Mumbai, India'),
  Transaction(
      id: '2',
      amount: 45000,
      merchant: 'Flipkart',
      category: 'Shopping',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isFraudulent: false,
      fraudScore: 0.0,
      location: 'Delhi, India'),
  Transaction(
      id: '3',
      amount: 890,
      merchant: 'Uber',
      category: 'Travel',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      isFraudulent: false,
      fraudScore: 0.0,
      location: 'Bangalore, India'),
  Transaction(
      id: '4',
      amount: 549,
      merchant: 'Swiggy',
      category: 'Food',
      timestamp: DateTime.now().subtract(const Duration(hours: 6)),
      isFraudulent: false,
      fraudScore: 0.0,
      location: 'Mumbai, India'),
  Transaction(
      id: '5',
      amount: 25000,
      merchant: 'Paytm Wallet',
      category: 'Bills',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isFraudulent: true,
      fraudScore: 0.82,
      location: 'Unknown Location'),
  Transaction(
      id: '6',
      amount: 3299,
      merchant: 'Amazon',
      category: 'Shopping',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      isFraudulent: false,
      fraudScore: 0.0,
      location: 'Gurgaon, India'),
  Transaction(
      id: '7',
      amount: 1450,
      merchant: 'IRCTC',
      category: 'Travel',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      isFraudulent: false,
      fraudScore: 0.0,
      location: 'New Delhi, India'),
  Transaction(
      id: '8',
      amount: 2100,
      merchant: 'BigBasket',
      category: 'Food',
      timestamp: DateTime.now().subtract(const Duration(days: 4)),
      isFraudulent: false,
      fraudScore: 0.0,
      location: 'Pune, India'),
];

IconData _categoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'food':
      return Icons.restaurant;
    case 'shopping':
      return Icons.shopping_bag;
    case 'travel':
      return Icons.flight;
    case 'bills':
      return Icons.receipt;
    default:
      return Icons.receipt_long;
  }
}

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<Transaction> _allTransactions = [];
  String _activeFilter = 'All';
  bool _loading = true;
  bool _wsConnected = false;
  final WebSocketService _wsService = WebSocketService();
  StreamSubscription? _wsSub;

  List<Transaction> get _filteredTransactions {
    if (_activeFilter == 'All') return _allTransactions;
    if (_activeFilter == '\u26A0\uFE0F Fraud Only') {
      return _allTransactions.where((t) => t.isFraudulent).toList();
    }
    return _allTransactions
        .where((t) => t.category == _activeFilter)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _initWebSocket();
  }

  Future<void> _loadTransactions() async {
    try {
      final res = await ApiService.get('/transactions').timeout(
        const Duration(seconds: 5),
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
        _allTransactions = data
            .map((j) => Transaction.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      _allTransactions = List.from(_mockTransactions);
    }
    _allTransactions
        .sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (mounted) setState(() => _loading = false);
  }

  void _initWebSocket() {
    try {
      _wsService.connect();
      _wsSub = _wsService.transactionStream.listen(
        (data) {
          try {
            final t = Transaction.fromJson(
                jsonDecode(data) as Map<String, dynamic>);
            _allTransactions.insert(0, t);
            if (_activeFilter == 'All' ||
                (_activeFilter == '\u26A0\uFE0F Fraud Only' &&
                    t.isFraudulent) ||
                t.category == _activeFilter) {
              _listKey.currentState?.insertItem(0);
            }
            if (t.isFraudulent && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: _spenderAccent,
                  content: Text(
                    '\u26A0\uFE0F Fraud Alert: ${t.merchant} \u2014 ${t.formattedAmount}',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  duration: const Duration(seconds: 4),
                  action: SnackBarAction(
                    label: 'Dekho',
                    textColor: Colors.white,
                    onPressed: () =>
                        Navigator.pushNamed(context, '/fraud-alert'),
                  ),
                ),
              );
            }
          } catch (_) {}
        },
        onError: (_) {},
        onDone: () {},
      );
      _wsConnected = true;
    } catch (_) {
      _wsConnected = false;
    }
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _activeFilter = filter;
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _wsService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: const AlwaysStoppedAnimation<Color>(_gold),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(child: _buildTransactionList()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _bg,
      elevation: 0,
      title: Text('Transactions',
          style: GoogleFonts.poppins(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
      actions: [
        if (_wsConnected)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Colors.green, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('Live',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.green)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChips() {
    const filters = ['All', 'Food', 'Shopping', 'Travel', 'Bills', '\u26A0\uFE0F Fraud Only'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: filters.map((f) {
            final selected = _activeFilter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _onFilterChanged(f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? _gold : _cardBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(f,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: selected ? _bg : _textSecondary,
                        fontWeight: FontWeight.w500,
                      )),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    final filtered = _filteredTransactions;
    if (filtered.isEmpty) {
      return Center(
        child: Text('No transactions found',
            style: GoogleFonts.poppins(color: _textSecondary, fontSize: 16)),
      );
    }
    return RefreshIndicator(
      color: _gold,
      onRefresh: _loadTransactions,
      child: AnimatedList(
        key: _listKey,
        initialItemCount: filtered.length,
        itemBuilder: (context, index, animation) {
          return TransactionTile(
            transaction: filtered[index],
            animation: animation,
            key: ValueKey(filtered[index].id),
          );
        },
      ),
    );
  }
}

class TransactionTile extends StatefulWidget {
  final Transaction transaction;
  final Animation<double> animation;

  const TransactionTile({
    required this.transaction,
    required this.animation,
    super.key,
  });

  @override
  State<TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<TransactionTile>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;

  @override
  void initState() {
    super.initState();
    if (widget.transaction.isFraudulent) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 1),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final tile = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            if (t.isFraudulent)
              AnimatedBuilder(
                animation: _pulseController!,
                builder: (context, child) {
                  final opacity =
                      (_pulseController!.value * 255).round().clamp(0, 255);
                  return Container(
                    width: 5,
                    height: 80,
                    color: _spenderAccent.withAlpha(opacity),
                  );
                },
              ),
            Container(
              padding: const EdgeInsets.all(14),
              child: Icon(_categoryIcon(t.category),
                  color: _gold, size: 24),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t.merchant,
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(t.location,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: _textSecondary)),
                  const SizedBox(height: 2),
                  Text(t.formattedTime,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: _textSecondary)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (t.isFraudulent)
                        const Icon(Icons.report, color: _spenderAccent, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        t.formattedAmount,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: t.isFraudulent ? _spenderAccent : _gold,
                        ),
                      ),
                    ],
                  ),
                  if (t.fraudScore > 0.5) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _spenderAccent.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Risk: ${(t.fraudScore * 100).round()}%',
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: _spenderAccent,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (t.isFraudulent) {
      return SizeTransition(
        sizeFactor: widget.animation,
        child: tile,
      );
    }
    return SizeTransition(
      sizeFactor: widget.animation,
      child: tile,
    );
  }
}
