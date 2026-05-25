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
import '../services/groq_service.dart';

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

String _abbreviateAmount(double value) {
  if (value >= 10000000) {
    return '\u20B9${(value / 10000000).toStringAsFixed(1)}Cr';
  } else if (value >= 100000) {
    return '\u20B9${(value / 100000).toStringAsFixed(1)}L';
  } else if (value >= 1000) {
    return '\u20B9${(value / 1000).toStringAsFixed(0)}K';
  }
  return '\u20B9${value.toInt()}';
}

String _staticTip(Archetype a, double savings) {
  switch (a) {
    case Archetype.saver:
      return 'Invest in Fixed Deposits for a guaranteed ~7% return';
    case Archetype.spender:
      return 'Reduce expenses by 10% to save an extra ${_formatIndianNumber(savings * 0.1)} each month';
    case Archetype.investor:
      return 'Combine SIP with ELSS for an expected 15% long-term return';
    case Archetype.minimalist:
      return 'Index funds offer low-cost, steady growth over time';
    case Archetype.adventurer:
      return 'Small-cap SIPs offer high risk with potential for high reward';
  }
}

Color _archetypeAccent(Archetype a) {
  switch (a) {
    case Archetype.saver: return _saverAccent;
    case Archetype.spender: return _spenderAccent;
    case Archetype.investor: return _investorAccent;
    case Archetype.minimalist: return _minimalistAccent;
    case Archetype.adventurer: return _adventurerAccent;
  }
}

class SavingsSimulatorScreen extends StatefulWidget {
  const SavingsSimulatorScreen({super.key});

  @override
  State<SavingsSimulatorScreen> createState() =>
      _SavingsSimulatorScreenState();
}

class _SavingsSimulatorScreenState extends State<SavingsSimulatorScreen> {
  double _monthlyContribution = 5000;
  double _annualReturnRate = 12.0;
  double _goalAmount = 500000;
  int _timelineMonths = 24;

  List<double> _projectedSavings = [];
  int _monthsToGoal = 0;
  double _totalInterestEarned = 0;
  bool _achievable = false;

  double _currentMonthlySavings = 8000;
  double _monthlyIncome = 50000;
  double _monthlyExpenses = 32000;
  double _currentSavingsRate = 16.0;

  String _archetypeTipText = '';
  bool _loading = true;
  bool _simulating = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  Future<void> _loadCurrentData() async {
    try {
      final res = await ApiService.get('/savings/current').timeout(
        const Duration(seconds: 5),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _currentMonthlySavings =
            (data['monthlySavings'] as num?)?.toDouble() ?? 8000;
        _monthlyIncome =
            (data['monthlyIncome'] as num?)?.toDouble() ?? 50000;
        _monthlyExpenses =
            (data['monthlyExpenses'] as num?)?.toDouble() ?? 32000;
        _currentSavingsRate =
            (data['currentSavingsRate'] as num?)?.toDouble() ?? 16.0;
      }
    } catch (_) {
      // use mock defaults
    }
    if (mounted) {
      setState(() => _loading = false);
      _runSimulation();
      _loadTip();
    }
  }

  Future<String> _loadArchetypeTip(Archetype a) async {
    final groq = await GroqService.complete(
      prompt: 'I am a $a in personal finance. Monthly savings: $_currentMonthlySavings, income: $_monthlyIncome, expenses: $_monthlyExpenses. Give ONE personalized financial tip in professional English (1-2 sentences).',
      systemPrompt: 'You are a professional financial advisor. Use clear, professional English.',
      model: 'llama3-8b-8192',
      temperature: 0.7,
      maxTokens: 150,
    );
    return groq ?? _staticTip(a, _currentMonthlySavings);
  }

  Future<void> _loadTip() async {
    final archetype = context.read<AppState>().currentArchetype;
    if (archetype == null) return;
    final tip = await _loadArchetypeTip(archetype);
    if (mounted) setState(() => _archetypeTipText = tip);
  }

  void _runSimulation() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      setState(() => _simulating = true);
      try {
        final res = await ApiService.post('/savings/simulate', {
          'monthlyContribution': _monthlyContribution,
          'annualReturnRate': _annualReturnRate,
          'goalAmount': _goalAmount,
          'timelineMonths': _timelineMonths,
        }).timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          _projectedSavings = (data['projectedSavings'] as List<dynamic>)
              .map((v) => (v as num).toDouble())
              .toList();
          _monthsToGoal = (data['monthsToGoal'] as num?)?.toInt() ?? 0;
          _totalInterestEarned =
              (data['totalInterestEarned'] as num?)?.toDouble() ?? 0;
          _achievable = data['achievable'] as bool? ?? false;
          if (mounted) setState(() => _simulating = false);
          return;
        }
      } catch (_) {
        // local calculation fallback
      }
      _calculateLocally();
      if (mounted) setState(() => _simulating = false);
    });
  }

  void _calculateLocally() {
    final r = _annualReturnRate / 100.0;
    final monthlyRate = r / 12;
    final n = _timelineMonths;
    final m = _monthlyContribution;

    _projectedSavings = List.generate(n, (i) {
      if (monthlyRate == 0) return m * (i + 1);
      return m * (math.pow(1 + monthlyRate, i + 1) - 1) / monthlyRate;
    });

    final totalContributions = m * n;
    _totalInterestEarned =
        _projectedSavings.isNotEmpty ? _projectedSavings.last - totalContributions : 0;

    _monthsToGoal = _projectedSavings.indexWhere((s) => s >= _goalAmount) + 1;
    _achievable = _monthsToGoal > 0 && _monthsToGoal <= n;
  }

  double _minimumContribution() {
    final r = _annualReturnRate / 100.0;
    final monthlyRate = r / 12;
    final n = _timelineMonths;
    if (monthlyRate == 0) return _goalAmount / n;
    return _goalAmount / ((math.pow(1 + monthlyRate, n) - 1) / monthlyRate);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _bg,
        body: const Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_gold)),
        ),
      );
    }
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentSummary(),
            const SizedBox(height: 24),
            _buildSliderSection(),
            const SizedBox(height: 24),
            _buildChart(),
            const SizedBox(height: 24),
            if (_projectedSavings.isNotEmpty)
              _simulating
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(_gold)),
                      ),
                    )
                  : _buildResultCard(),
            const SizedBox(height: 24),
            _buildArchetypeTip(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _bg,
      elevation: 0,
      title: Text('Savings Simulator',
          style: GoogleFonts.poppins(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Icon(Icons.calculate, color: _gold),
        ),
      ],
    );
  }

  Widget _buildCurrentSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _gold.withAlpha(60)),
      ),
      child: Row(
        children: [
          _summaryItem('Income', _formatIndianNumber(_monthlyIncome)),
          _summaryDivider(),
          _summaryItem('Expenses', _formatIndianNumber(_monthlyExpenses)),
          _summaryDivider(),
          _summaryItem('Savings Rate', '${_currentSavingsRate.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.bold, color: _gold),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(label,
              style:
                  GoogleFonts.poppins(fontSize: 10, color: _textSecondary)),
        ],
      ),
    );
  }

  Widget _summaryDivider() {
    return Container(width: 1, height: 40, color: Colors.white12);
  }

  Widget _buildSliderSection() {
    return Column(
      children: [
        _buildSlider(
          label: 'Monthly Contribution',
          value: _monthlyContribution,
          min: 1000,
          max: 50000,
          divisions: 490,
          display: _formatIndianNumber(_monthlyContribution),
          onChanged: (v) => setState(() {
            _monthlyContribution = v;
            _runSimulation();
          }),
        ),
        const SizedBox(height: 20),
        _buildSlider(
          label: 'Expected Return Rate',
          value: _annualReturnRate,
          min: 1.0,
          max: 30.0,
          divisions: 290,
          display: '${_annualReturnRate.toStringAsFixed(1)}%',
          helperText:
              '<8% Conservative  |  8-15% Moderate  |  >15% Aggressive',
          onChanged: (v) => setState(() {
            _annualReturnRate = v;
            _runSimulation();
          }),
        ),
        const SizedBox(height: 20),
        _buildSlider(
          label: 'Goal Amount',
          value: _goalAmount,
          min: 10000,
          max: 5000000,
          divisions: 499,
          display: _goalAmount >= 100000
              ? '\u20B9${(_goalAmount / 100000).toStringAsFixed(1)}L'
              : _formatIndianNumber(_goalAmount),
          onChanged: (v) => setState(() {
            _goalAmount = v;
            _runSimulation();
          }),
        ),
        const SizedBox(height: 20),
        _buildSlider(
          label: 'Timeline',
          value: _timelineMonths.toDouble(),
          min: 6,
          max: 120,
          divisions: 114,
          display: '$_timelineMonths months',
          helperText: '= ${_timelineMonths ~/ 12} years ${_timelineMonths % 12} months',
          onChanged: (v) => setState(() {
            _timelineMonths = v.round();
            _runSimulation();
          }),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String display,
    required ValueChanged<double> onChanged,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500)),
            Text(display,
                style: GoogleFonts.poppins(
                    fontSize: 14, color: _gold, fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: _gold,
            inactiveTrackColor: _cardBg,
            thumbColor: _gold,
            overlayColor: _gold.withAlpha(30),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(helperText,
                style: GoogleFonts.poppins(fontSize: 11, color: _textSecondary)),
          ),
      ],
    );
  }

  Widget _buildChart() {
    if (_projectedSavings.isEmpty) return const SizedBox.shrink();

    final simpleSavings =
        List.generate(_timelineMonths, (i) => _monthlyContribution * (i + 1));
    final maxY = [
      ..._projectedSavings,
      _goalAmount,
      ...simpleSavings,
    ].reduce(math.max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Growth Projection',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 16),
          SizedBox(
            height: 260,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: LineChart(
                key: ValueKey('chart_${_projectedSavings.length}_$_timelineMonths'),
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: _projectedSavings
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      color: _gold,
                      barWidth: 3,
                      isCurved: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                          show: true, color: _gold.withAlpha(20)),
                    ),
                    LineChartBarData(
                      spots: simpleSavings
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      color: _textSecondary,
                      barWidth: 2,
                      dashArray: const [8, 4],
                      isCurved: false,
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: [
                        FlSpot(0, _goalAmount),
                        FlSpot((_timelineMonths - 1).toDouble(), _goalAmount),
                      ],
                      color: _spenderAccent,
                      barWidth: 2,
                      dashArray: const [6, 4],
                      isCurved: false,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                  minY: 0,
                  maxY: maxY * 1.1,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 5,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: Colors.white10, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (v, _) => Text(
                          _abbreviateAmount(v),
                          style: const TextStyle(
                              color: _textSecondary, fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: math.max(1, _timelineMonths / 6).ceilToDouble(),
                        getTitlesWidget: (v, _) => Text(
                          '${v.toInt()}m',
                          style: const TextStyle(
                              color: _textSecondary, fontSize: 10),
                        ),
                      ),
                    ),
                    topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      bottom: BorderSide(color: _cardBg),
                      left: BorderSide(color: _cardBg),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((s) {
                        return LineTooltipItem(
                          'Month ${s.x.toInt() + 1}: ${_abbreviateAmount(s.y)}',
                          TextStyle(
                              color: s.bar.color ?? _gold,
                              fontWeight: FontWeight.w500,
                              fontSize: 12),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(_gold, 'With Interest'),
              const SizedBox(width: 16),
              _legendDot(_textSecondary, 'Without Interest'),
              const SizedBox(width: 16),
              _legendDot(_spenderAccent, 'Goal'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: _textSecondary)),
      ],
    );
  }

  Widget _buildResultCard() {
    final years = _monthsToGoal ~/ 12;
    final remainingMonths = _monthsToGoal % 12;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _achievable
            ? const Color(0xFF1A2A1A)
            : const Color(0xFF2A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _achievable
              ? _saverAccent.withAlpha(120)
              : _spenderAccent.withAlpha(120),
        ),
      ),
      child: _achievable ? _buildAchievableResult(years, remainingMonths) : _buildNotAchievableResult(),
    );
  }

  Widget _buildAchievableResult(int years, int remainingMonths) {
    return Column(
      children: [
        const Icon(Icons.check_circle, color: _saverAccent, size: 40),
        const SizedBox(height: 8),
        Text('Lakshya haasil hoga! \uD83C\uDF89',
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _saverAccent)),
        const SizedBox(height: 8),
        Text(
          '${_formatIndianNumber(_goalAmount)} in $_monthsToGoal months ($years years $remainingMonths months)',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.savings, color: _gold, size: 18),
              const SizedBox(width: 8),
              Text('Total Interest: ${_formatIndianNumber(_totalInterestEarned)}',
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600, color: _gold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotAchievableResult() {
    final minContrib = _minimumContribution();
    return Column(
      children: [
        const Icon(Icons.warning_amber_rounded, color: _spenderAccent, size: 40),
        const SizedBox(height: 8),
        Text('Is timeline mein lakshya mushkil hai',
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _spenderAccent)),
        const SizedBox(height: 8),
        Text('Suggestion: contribution badhao ya timeline extend karo',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFBBF24).withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Minimum required: ${_formatIndianNumber(minContrib)}/month',
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFBBF24)),
          ),
        ),
      ],
    );
  }

  Widget _buildArchetypeTip() {
    final archetype = context.watch<AppState>().currentArchetype;
    if (archetype == null) return const SizedBox.shrink();
    final accent = _archetypeAccent(archetype);
    final tip = _archetypeTipText.isNotEmpty ? _archetypeTipText : _staticTip(archetype, _currentMonthlySavings);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: accent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(tip,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
