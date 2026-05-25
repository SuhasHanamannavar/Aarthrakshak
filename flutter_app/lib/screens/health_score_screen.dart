import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _bg = Color(0xFF0A0E27);
const Color _cardBg = Color(0xFF141832);
const Color _gold = Color(0xFFFFD700);
const Color _textSecondary = Color(0xFF8892B0);
const Color _green = Color(0xFF00C896);
const Color _amber = Color(0xFFFBBF24);
const Color _red = Color(0xFFFF6B6B);

Color _scoreColor(double score) {
  if (score >= 70) return _green;
  if (score >= 40) return _amber;
  return _red;
}

String _scoreLabel(double score) {
  if (score >= 80) return 'Excellent \uD83C\uDF1F';
  if (score >= 60) return 'Good \uD83D\uDCAA';
  if (score >= 40) return 'Fair \u26A0\uFE0F';
  return 'Needs Attention \uD83D\uDEA8';
}

class _ScoreArcPainter extends CustomPainter {
  final double fraction;
  final Color color;

  _ScoreArcPainter({required this.fraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, fraction * 2 * math.pi, false, fgPaint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final dotAngle = -math.pi / 2 + fraction * 2 * math.pi;
    final dotX = center.dx + radius * math.cos(dotAngle);
    final dotY = center.dy + radius * math.sin(dotAngle);
    canvas.drawCircle(Offset(dotX, dotY), 6, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _ScoreArcPainter old) =>
      old.fraction != fraction || old.color != color;
}

class HealthScoreScreen extends StatefulWidget {
  const HealthScoreScreen({super.key});

  @override
  State<HealthScoreScreen> createState() => _HealthScoreScreenState();
}

class _HealthScoreScreenState extends State<HealthScoreScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  double _animatedScore = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.addListener(() {
      setState(() => _animatedScore = 72 * _animation.value);
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            _buildScoreCircle(),
            const SizedBox(height: 32),
            _buildBreakdownRow(),
            const SizedBox(height: 28),
            _buildTrendChart(),
            const SizedBox(height: 28),
            _buildInsights(),
            const SizedBox(height: 28),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _bg,
      elevation: 0,
      title: Text('Health Score',
          style: GoogleFonts.poppins(
              fontSize: 20, fontWeight: FontWeight.bold, color: _gold)),
    );
  }

  Widget _buildScoreCircle() {
    final color = _scoreColor(_animatedScore);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: CustomPaint(
            painter: _ScoreArcPainter(
              fraction: _animatedScore / 100,
              color: color,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_animatedScore.round()}',
                    style: GoogleFonts.poppins(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    '/ 100',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Financial Health Score',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _scoreLabel(_animatedScore),
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownRow() {
    final categories = [
      _CategoryData('Savings Rate', 78, Icons.savings, _green),
      _CategoryData('Debt Management', 65, Icons.credit_card, _amber),
      _CategoryData('Investment Mix', 80, Icons.trending_up, const Color(0xFF54A0FF)),
      _CategoryData('Emergency Fund', 55, Icons.shield, const Color(0xFFFF9F43)),
      _CategoryData('Spending Control', 68, Icons.pie_chart, const Color(0xFFA78BFA)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text('Score Breakdown',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) => _buildCategoryCard(categories[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(_CategoryData cat) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cat.color.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(cat.icon, color: cat.color, size: 20),
          ),
          const Spacer(),
          Text(
            '${cat.score}/100',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _gold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            cat.label,
            style: GoogleFonts.poppins(fontSize: 11, color: _textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: cat.score / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: cat.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    const scores = [58.0, 62.0, 65.0, 68.0, 70.0, 72.0];
    const months = ['Dec', 'Jan', 'Feb', 'Mar', 'Apr', 'May'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Score Trend (6 Months)',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Colors.white10, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}',
                        style: const TextStyle(color: _textSecondary, fontSize: 11),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(
                        months[v.toInt()],
                        style: const TextStyle(color: _textSecondary, fontSize: 11),
                      ),
                    ),
                  ),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots.map((s) {
                      return LineTooltipItem(
                        '${months[s.x.toInt()]}: ${s.y.toInt()}',
                        TextStyle(
                          color: s.bar.color ?? _gold,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: scores
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    color: _gold,
                    barWidth: 3.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 3,
                        color: _gold,
                        strokeWidth: 0,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _gold.withAlpha(60),
                          _gold.withAlpha(5),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsights() {
    final insights = [
      _InsightData(
        isPositive: true,
        title: 'Strong Savings',
        description: 'You save 28% of income monthly',
        impact: '+12 pts',
      ),
      _InsightData(
        isPositive: true,
        title: 'Diversified Investments',
        description: 'MF + Stocks + Gold mix',
        impact: '+8 pts',
      ),
      _InsightData(
        isPositive: false,
        title: 'High Food Spend',
        description: 'Food is 35% of expenses',
        impact: '-6 pts',
      ),
      _InsightData(
        isPositive: false,
        title: 'No Term Insurance',
        description: 'Risk coverage gap detected',
        impact: '-8 pts',
      ),
      _InsightData(
        isPositive: true,
        title: 'Zero Missed EMIs',
        description: 'Perfect repayment record',
        impact: '+10 pts',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("What's Affecting Your Score",
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 14),
        ...insights.map((i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildInsightCard(i),
            )),
      ],
    );
  }

  Widget _buildInsightCard(_InsightData insight) {
    final impactColor = insight.isPositive ? _green : _red;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: impactColor.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              insight.isPositive ? Icons.check_circle : Icons.warning_amber_rounded,
              color: impactColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                const SizedBox(height: 2),
                Text(insight.description,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: _textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: impactColor.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              insight.impact,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: impactColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/transactions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: const Color(0xFF0A0E27),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
              child: const Text('Improve Score'),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: _cardBg,
                    content: Text(
                      'Full report coming soon',
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: _gold,
                side: const BorderSide(color: _gold, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
              child: const Text('View Full Report'),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryData {
  final String label;
  final int score;
  final IconData icon;
  final Color color;
  const _CategoryData(this.label, this.score, this.icon, this.color);
}

class _InsightData {
  final bool isPositive;
  final String title;
  final String description;
  final String impact;
  const _InsightData({
    required this.isPositive,
    required this.title,
    required this.description,
    required this.impact,
  });
}
