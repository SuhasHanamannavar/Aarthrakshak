import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/archetype.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

const Color _bg = Color(0xFF0A0E27);
const Color _cardBg = Color(0xFF141832);
const Color _gold = Color(0xFFFFD700);
const Color _textSecondary = Color(0xFF8892B0);
const Color _saverAccent = Color(0xFF00C896);
const Color _spenderAccent = Color(0xFFFF6B6B);
const Color _investorAccent = Color(0xFF00E5FF);
const Color _minimalistAccent = Color(0xFFA78BFA);
const Color _adventurerAccent = Color(0xFFFBBF24);

String _formatIndianNumber(dynamic value) {
  final n = value is int ? value : (value as double).round();
  final s = n.toString();
  if (s.length <= 3) return '\u20B9$s';
  final last3 = s.substring(s.length - 3);
  final rest = s.substring(0, s.length - 3);
  final groups = <String>[];
  for (int i = rest.length; i > 0; i -= 2) {
    final start = i > 2 ? i - 2 : 0;
    groups.insert(0, rest.substring(start, i));
  }
  return '\u20B9${groups.join(',')},$last3';
}

Color _accentFor(Archetype a) {
  switch (a) {
    case Archetype.saver: return _saverAccent;
    case Archetype.spender: return _spenderAccent;
    case Archetype.investor: return _investorAccent;
    case Archetype.minimalist: return _minimalistAccent;
    case Archetype.adventurer: return _adventurerAccent;
  }
}

String _archetypeLabel(Archetype a) {
  switch (a) {
    case Archetype.saver: return 'Saver';
    case Archetype.spender: return 'Spender';
    case Archetype.investor: return 'Investor';
    case Archetype.minimalist: return 'Minimalist';
    case Archetype.adventurer: return 'Adventurer';
  }
}

class _RiskOMeter extends StatefulWidget {
  const _RiskOMeter();

  @override
  State<_RiskOMeter> createState() => _RiskOMeterState();
}

class _RiskOMeterState extends State<_RiskOMeter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Risk-O-Meter',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth;
            return SizedBox(
              height: 48,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, _) {
                  final pointerPos = _animation.value * 0.73 * barWidth;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 14,
                        child: Container(
                          height: 20,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.green, Color(0xFFFFEB3B), Colors.red],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Positioned(
                        left: pointerPos.clamp(0, barWidth - 12),
                        top: 6,
                        child: Column(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: _bg, width: 2),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black26, blurRadius: 4),
                                ],
                              ),
                            ),
                            Container(width: 2, height: 8, color: Colors.white),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Your Risk Level: High',
          style: GoogleFonts.poppins(
              fontSize: 14,
              color: _adventurerAccent,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _CircularScoreIndicator extends StatelessWidget {
  final double score;
  final double maxScore;
  final Color color;
  final String label;

  const _CircularScoreIndicator({
    required this.score,
    required this.maxScore,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = score / maxScore;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: CustomPaint(
            painter: _ArcPainter(fraction: fraction, color: color),
            child: Center(
              child: Text(
                '${score.round()}/${maxScore.round()}',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: GoogleFonts.poppins(fontSize: 13, color: _textSecondary)),
      ],
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double fraction;
  final Color color;

  _ArcPainter({required this.fraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2 - 6,
    );
    final bgPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawCircle(rect.center, rect.width / 2, bgPaint);
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, fraction * 2 * math.pi, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) => old.fraction != fraction;
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  double _balance = 0;
  double _monthlySpend = 0;
  double _monthlySavings = 0;
  int _healthScore = 0;
  // ignore: unused_field
  List _transactions = [];
  String _groqTagline = '';
  String _groqTip1 = '';
  String _groqTip2 = '';
  String _groqTip3 = '';
  List<_OpportunityData> _groqOpportunities = [];
  final WebSocketService _wsService = WebSocketService();
  bool _wsConnected = false;
  StreamSubscription? _wsSub;

  String _taglineFor(Archetype a) {
    if (_groqTagline.isNotEmpty) return _groqTagline;
    switch (a) {
      case Archetype.saver: return 'Every rupee counts toward a secure future';
      case Archetype.spender: return 'Live life fully, spend wisely';
      case Archetype.investor: return 'Make your money work for you';
      case Archetype.minimalist: return 'Less is more — financial freedom through simplicity';
      case Archetype.adventurer: return 'Take calculated risks for greater rewards';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _initWebSocket();
  }

  Future<void> _loadDashboard() async {
    try {
      final res = await ApiService.get('/dashboard').timeout(
        const Duration(seconds: 8),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _balance = (data['balance'] as num?)?.toDouble() ?? _balance;
        _monthlySpend = (data['monthlySpend'] as num?)?.toDouble() ?? _monthlySpend;
        _monthlySavings = (data['monthlySavings'] as num?)?.toDouble() ?? _monthlySavings;
        _transactions = (data['transactions'] as List?) ?? [];
        if (mounted) context.read<AppState>().setDashboardData(data);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Using offline cache. Data sync failed: $e')));
      }
    }

    try {
      final res = await ApiService.get('/health-score').timeout(
        const Duration(seconds: 5),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _healthScore = (data['score'] as num?)?.toInt() ?? _healthScore;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _loading = false);
      _loadGroqContent();
    }
  }

  Future<void> _loadGroqContent() async {
    final archetype = context.read<AppState>().currentArchetype;
    if (archetype == null) return;
    
    try {
      // Calling real backend Groq endpoint as specified!
      final res = await ApiService.get('/ai/tips?archetype=${archetype.name}').timeout(
        const Duration(seconds: 8),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final tips = data['tips'] as List<dynamic>? ?? [];
        final opps = data['opportunities'] as List<dynamic>? ?? [];
        
        if (mounted) {
          setState(() {
            _groqTagline = data['tagline'] as String? ?? _groqTagline;
            if (tips.isNotEmpty) _groqTip1 = tips[0] as String;
            if (tips.length > 1) _groqTip2 = tips[1] as String;
            if (tips.length > 2) _groqTip3 = tips[2] as String;
            
            _groqOpportunities = opps.map((e) => _OpportunityData(
              title: e['title'] as String? ?? '',
              subtitle: e['subtitle'] as String? ?? ''
            )).toList();
          });
        }
        return;
      }
    } catch (e) {
      // Fallback behavior if backend fails
      debugPrint("AI Tips API failed, defaulting to local cache.");
    }
  }

  void _initWebSocket() {
    try {
      _wsService.connect(); // Already upgraded to WSS in websocket_service.dart
      _wsSub = _wsService.transactionStream.listen((data) {
         try {
           final decoded = jsonDecode(data);
             if (!mounted) return;
             if (decoded['type'] == 'fraud_alert') {
                // On fraud alert -> show red overlay 
                _showLiveFraudOverlay(decoded);
             } else {
               // Handle live incoming transactions
               context.read<AppState>().addTransaction(decoded);
             }
         } catch (_) {}
      });
      _wsConnected = true;
    } catch (_) {
      _wsConnected = false;
    }
  }

  bool _isFraudAlert = false;

  void _showLiveFraudOverlay(Map<String, dynamic> alert) {
    if (!mounted) return;
    setState(() => _isFraudAlert = true);
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) setState(() => _isFraudAlert = false);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent.shade700,
        duration: const Duration(seconds: 10),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('\u26A0\uFE0F LIVE FRAUD ALERT!', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            Text(alert['explanation'] ?? 'We detected unusually high risk on a recent transaction.', style: GoogleFonts.poppins(color: Colors.white)),
          ],
        ),
      )
    );
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _wsService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final archetype = context.watch<AppState>().currentArchetype;
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
      backgroundColor: _isFraudAlert ? Colors.red.shade900 : _bg,
      appBar: _buildAppBar(archetype),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (archetype != null) _buildGreetingCard(archetype),
            const SizedBox(height: 20),
            _buildStatCards(),
            const SizedBox(height: 16),
            _buildActionButtons(),
            const SizedBox(height: 24),
            if (archetype != null) _buildArchetypeBody(archetype),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/statement-upload'),
            icon: const Icon(Icons.upload_file),
            label: Text('Upload Statement', style: GoogleFonts.poppins(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _cardBg,
              foregroundColor: _gold,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              side: BorderSide(color: _gold.withValues(alpha: 0.3)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/manual-entry'),
            icon: const Icon(Icons.edit_note),
            label: Text('Manual Entry', style: GoogleFonts.poppins(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _cardBg,
              foregroundColor: _gold,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              side: BorderSide(color: _gold.withValues(alpha: 0.3)),
            ),
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(Archetype? archetype) {
    return AppBar(
      backgroundColor: _bg,
      elevation: 0,
      title: Row(
        children: [
          ClipOval(
            child: Image.asset(
              'assets/images/logo.png',
              width: 32,
              height: 32,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.assured_workload, color: _gold, size: 28),
            ),
          ),
          const SizedBox(width: 12),
          Text('Aarthrakshak',
              style: GoogleFonts.poppins(
                  fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: _gold)),
        ],
      ),
      actions: [
        if (_wsConnected)
          Padding(
            padding: const EdgeInsets.only(right: 4),
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
        if (archetype != null)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _gold.withAlpha(80)),
              ),
              child: Text(_archetypeLabel(archetype),
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _gold,
                      fontWeight: FontWeight.w500)),
            ),
          ),
      ],
    );
  }

  Widget _buildGreetingCard(Archetype archetype) {
    final accent = _accentFor(archetype);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconFor(archetype), color: accent, size: 24),
              ),
              const SizedBox(width: 14),
              Text('Welcome, ${_archetypeLabel(archetype)}!',
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ],
          ),
          const SizedBox(height: 10),
          Text(_taglineFor(archetype),
              style: GoogleFonts.poppins(fontSize: 14, color: accent)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.favorite, color: _healthScore > 60 ? Colors.green : _spenderAccent, size: 16),
              const SizedBox(width: 6),
              Text('Health Score: $_healthScore/100',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: _textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconFor(Archetype a) {
    switch (a) {
      case Archetype.saver: return Icons.savings;
      case Archetype.spender: return Icons.shopping_cart;
      case Archetype.investor: return Icons.trending_up;
      case Archetype.minimalist: return Icons.eco;
      case Archetype.adventurer: return Icons.explore;
    }
  }

  Widget _buildStatCards() {
    return Row(
      children: [
        _statCard('Balance', _formatIndianNumber(_balance)),
        const SizedBox(width: 10),
        _statCard('Spend', _formatIndianNumber(_monthlySpend)),
        const SizedBox(width: 10),
        _statCard('Savings', _formatIndianNumber(_monthlySavings)),
      ],
    );
  }

  Widget _statCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _gold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: _textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildArchetypeBody(Archetype archetype) {
    switch (archetype) {
      case Archetype.saver: return _buildSaverBody();
      case Archetype.spender: return _buildSpenderBody();
      case Archetype.investor: return _buildInvestorBody();
      case Archetype.minimalist: return _buildMinimalistBody();
      case Archetype.adventurer: return _buildAdventurerBody();
    }
  }

  Widget _buildSaverBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('FD Maturity Overview'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _saverAccent.withAlpha(60)),
          ),
          child: Row(
            children: [
              Icon(Icons.timer, color: _saverAccent, size: 32),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Next FD Maturity',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: _textSecondary)),
                  Text('28 days remaining',
                      style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _saverAccent)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _sectionHeader('Your Savings Tips'),
        const SizedBox(height: 12),
        _tipCard(_groqTip1.isNotEmpty ? _groqTip1 : 'Follow the 50-30-20 rule for balanced finances', _saverAccent),
        const SizedBox(height: 8),
        _tipCard(_groqTip2.isNotEmpty ? _groqTip2 : 'Save at least 10% of your monthly income', _saverAccent),
        const SizedBox(height: 8),
        _tipCard(_groqTip3.isNotEmpty ? _groqTip3 : 'Build an emergency fund worth 3 months of expenses', _saverAccent),
        const SizedBox(height: 24),
        _sectionHeader('Savings vs Spend - Last 6 Months'),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 20000,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) => Text('${v ~/ 1000}k',
                          style: const TextStyle(
                              color: _textSecondary, fontSize: 10))),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        const labels = [
                          'Jan',
                          'Feb',
                          'Mar',
                          'Apr',
                          'May',
                          'Jun'
                        ];
                        return Text(labels[v.toInt()],
                            style: const TextStyle(
                                color: _textSecondary, fontSize: 10));
                      }),
                ),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 5000,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: Colors.white10, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                _barGroup(0, 8000, 15000),
                _barGroup(1, 10000, 14000),
                _barGroup(2, 12000, 16000),
                _barGroup(3, 9000, 12000),
                _barGroup(4, 11000, 13000),
                _barGroup(5, 12000, 18000),
              ],
            ),
          ),
        ),
      ],
    );
  }

  BarChartGroupData _barGroup(int x, double savings, double spend) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(
          toY: spend,
          color: _gold,
          width: 10,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(4))),
      BarChartRodData(
          toY: savings,
          color: _saverAccent,
          width: 10,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(4))),
    ]);
  }

  Widget _buildSpenderBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_monthlySpend > 15000)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: _spenderAccent.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _spenderAccent.withAlpha(80)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: _spenderAccent, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Your spending is on the rise!',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: _spenderAccent,
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        _sectionHeader('This Month\'s Budget'),
        const SizedBox(height: 12),
        Center(
          child: _CircularScoreIndicator(
            score: _monthlySpend,
            maxScore: 25000,
            color: _spenderAccent,
            label: 'Spend / Budget',
          ),
        ),
        const SizedBox(height: 24),
        _sectionHeader('Category-wise Spend'),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                    value: 8000,
                    color: _spenderAccent,
                    radius: 50,
                    title: 'Food',
                    titleStyle:
                        const TextStyle(fontSize: 11, color: Colors.white)),
                PieChartSectionData(
                    value: 4500,
                    color: const Color(0xFFFF9F43),
                    radius: 50,
                    title: 'Shopping',
                    titleStyle:
                        const TextStyle(fontSize: 11, color: Colors.white)),
                PieChartSectionData(
                    value: 3200,
                    color: const Color(0xFF54A0FF),
                    radius: 50,
                    title: 'Travel',
                    titleStyle:
                        const TextStyle(fontSize: 11, color: Colors.white)),
                PieChartSectionData(
                    value: 2500,
                    color: const Color(0xFF5F27CD),
                    radius: 50,
                    title: 'Bills',
                    titleStyle:
                        const TextStyle(fontSize: 11, color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvestorBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Portfolio Snapshot'),
        const SizedBox(height: 12),
        Row(
          children: [
            _portfolioCard('Mutual Funds', '\u20B945,000', _investorAccent),
            const SizedBox(width: 10),
            _portfolioCard('Stocks', '\u20B932,000', _investorAccent),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _portfolioCard('SIP', '\u20B98,000/mo', _investorAccent),
            const SizedBox(width: 10),
            _portfolioCard('Gold ETF', '\u20B912,000', _investorAccent),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _investorAccent.withAlpha(20),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _investorAccent.withAlpha(80)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_active,
                  color: _investorAccent, size: 18),
              const SizedBox(width: 8),
              Text('Next SIP in 5 days',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: _investorAccent,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _sectionHeader('Portfolio Growth - 12 Months'),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 10000,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: Colors.white10, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, _) => Text('${v ~/ 1000}k',
                          style: const TextStyle(
                              color: _textSecondary, fontSize: 10))),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      getTitlesWidget: (v, _) {
                        const labels = [
                          'Jan',
                          'Mar',
                          'May',
                          'Jul',
                          'Sep',
                          'Nov'
                        ];
                        return Text(labels[v ~/ 2],
                            style: const TextStyle(
                                color: _textSecondary, fontSize: 10));
                      }),
                ),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                      12,
                      (i) => FlSpot(
                          i.toDouble(),
                          [
                            20000, 22000, 25000, 28000, 30000, 35000,
                            38000, 40000, 42000, 45000, 47000, 50000
                          ][i]
                              .toDouble())),
                  isCurved: true,
                  color: _investorAccent,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                      show: true, color: _investorAccent.withAlpha(30)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _portfolioCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: _textSecondary)),
            const SizedBox(height: 6),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalistBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Zero Waste Score'),
        const SizedBox(height: 12),
        Center(
          child: _CircularScoreIndicator(
            score: 78,
            maxScore: 100,
            color: _minimalistAccent,
            label: 'Waste Score',
          ),
        ),
        const SizedBox(height: 24),
        _sectionHeader('This Week\'s Unnecessary Spending'),
        const SizedBox(height: 12),
        _unnecessarySpendCard('Zomato order', '\u20B9450', 'Ordered 3 times this week'),
        const SizedBox(height: 8),
        _unnecessarySpendCard(
            'Amazon impulse buy', '\u20B91,200', 'Did not really need it'),
        const SizedBox(height: 8),
        _unnecessarySpendCard(
            'Cab rides', '\u20B9600', 'Metro would have been cheaper'),
        const SizedBox(height: 24),
        _sectionHeader('Expense Reduction Trend'),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 5000,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: Colors.white10, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) => Text('${v ~/ 1000}k',
                          style: const TextStyle(
                              color: _textSecondary, fontSize: 10))),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        const labels = [
                          'Jan',
                          'Feb',
                          'Mar',
                          'Apr',
                          'May',
                          'Jun'
                        ];
                        return Text(labels[v.toInt()],
                            style: const TextStyle(
                                color: _textSecondary, fontSize: 10));
                      }),
                ),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                      6,
                      (i) => FlSpot(
                          i.toDouble(),
                          [20000, 18000, 16000, 14000, 12000, 10000][i]
                              .toDouble())),
                  isCurved: true,
                  color: _minimalistAccent,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                      show: true, color: _minimalistAccent.withAlpha(30)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _unnecessarySpendCard(
      String title, String amount, String reason) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.remove_circle_outline,
              color: _spenderAccent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500)),
                Text(reason,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: _textSecondary)),
              ],
            ),
          ),
          Text(amount,
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: _spenderAccent,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildAdventurerBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _RiskOMeter(),
        const SizedBox(height: 24),
        _sectionHeader('Your Opportunities'),
        const SizedBox(height: 12),
        if (_groqOpportunities.isNotEmpty)
          ..._groqOpportunities.map((o) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _opportunityCard(o.title, o.subtitle, _adventurerAccent),
          ))
        else ...[
          _opportunityCard(
              'IPO Alert', 'Zomato IPO coming soon!', _adventurerAccent),
          const SizedBox(height: 8),
          _opportunityCard('Crypto SIP',
              'Start \u20B9500/mo Bitcoin SIP', _adventurerAccent),
          const SizedBox(height: 8),
          _opportunityCard(
              'New Fund Offer', 'Motilal Oswal NFO live', _adventurerAccent),
        ],
        const SizedBox(height: 24),
        _sectionHeader('Investment Volatility'),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 10000,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: Colors.white10, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, _) => Text('${v ~/ 1000}k',
                          style: const TextStyle(
                              color: _textSecondary, fontSize: 10))),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      getTitlesWidget: (v, _) {
                        const labels = [
                          'Jan',
                          'Mar',
                          'May',
                          'Jul',
                          'Sep',
                          'Nov'
                        ];
                        return Text(labels[v ~/ 2],
                            style: const TextStyle(
                                color: _textSecondary, fontSize: 10));
                      }),
                ),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                      12,
                      (i) => FlSpot(
                          i.toDouble(),
                          [
                            10000, 15000, 12000, 20000, 16000, 25000,
                            18000, 28000, 22000, 30000, 24000, 35000
                          ][i]
                              .toDouble())),
                  isCurved: true,
                  color: _adventurerAccent,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                      show: true, color: _adventurerAccent.withAlpha(25)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _opportunityCard(String title, String subtitle, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('NEW',
                style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500)),
                Text(subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: _textSecondary)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: color, size: 14),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Text(text,
        style: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white));
  }

  Widget _tipCard(String text, Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10, width: 1)),
      ),
      child: BottomNavigationBar(
        backgroundColor: _cardBg,
        selectedItemColor: _gold,
        unselectedItemColor: _textSecondary,
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        onTap: (i) {
          switch (i) {
            case 1:
              Navigator.pushNamed(context, '/transactions');
            case 2:
              Navigator.pushNamed(context, '/goals');
            case 3:
              Navigator.pushNamed(context, '/health');
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long), label: 'Transactions'),
          BottomNavigationBarItem(
              icon: Icon(Icons.flag), label: 'Goals'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: 'Health'),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      backgroundColor: _spenderAccent,
      onPressed: () => Navigator.pushNamed(context, '/fraud-alert'),
      child: const Icon(Icons.shield, color: Colors.white),
    );
  }
}

class _OpportunityData {
  final String title;
  final String subtitle;
  const _OpportunityData({required this.title, required this.subtitle});
}
