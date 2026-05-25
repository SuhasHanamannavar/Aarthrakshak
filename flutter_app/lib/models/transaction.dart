class Transaction {
  final String id;
  final double amount;
  final String merchant;
  final String category;
  final DateTime timestamp;
  final bool isFraudulent;
  final double fraudScore;
  final String location;

  const Transaction({
    required this.id,
    required this.amount,
    required this.merchant,
    required this.category,
    required this.timestamp,
    required this.isFraudulent,
    required this.fraudScore,
    required this.location,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      merchant: json['merchant_name'] as String? ?? json['merchant'] as String? ?? '',
      category: json['category'] as String? ?? '',
      timestamp: DateTime.tryParse(
              json['transaction_date'] as String? ??
                  json['timestamp'] as String? ??
                  '') ??
          DateTime.now(),
      isFraudulent: json['is_fraudulent'] as bool? ??
          json['isFraudulent'] as bool? ??
          false,
      fraudScore: ((json['fraud_score'] as num?)?.toDouble() ?? 0.0) / 100,
      location: json['merchant_location'] as String? ??
          json['location'] as String? ??
          '',
    );
  }

  String get formattedAmount => '\u20B9${amount.toStringAsFixed(0)}';

  String get formattedTime {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }
}
