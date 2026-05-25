class Insight {
  final String title;
  final String description;
  final String impact;
  final bool isPositive;

  const Insight({
    required this.title,
    required this.description,
    required this.impact,
    required this.isPositive,
  });

  factory Insight.fromJson(Map<String, dynamic> json) {
    return Insight(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      impact: json['impact'] as String? ?? '',
      isPositive: json['isPositive'] as bool? ?? true,
    );
  }

  static List<Insight> defaultInsights() {
    return [
      const Insight(
          title: 'Strong Savings',
          description: 'You save 28% of income monthly',
          impact: '+12 pts',
          isPositive: true),
      const Insight(
          title: 'Diversified Investments',
          description: 'MF + Stocks + Gold mix',
          impact: '+8 pts',
          isPositive: true),
      const Insight(
          title: 'High Food Spend',
          description: 'Food is 35% of expenses',
          impact: '-6 pts',
          isPositive: false),
      const Insight(
          title: 'No Term Insurance',
          description: 'Risk coverage gap detected',
          impact: '-8 pts',
          isPositive: false),
      const Insight(
          title: 'Zero Missed EMIs',
          description: 'Perfect repayment record',
          impact: '+10 pts',
          isPositive: true),
    ];
  }
}
