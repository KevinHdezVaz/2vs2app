class Transaction {
  final String type;
  final String description;
  final DateTime date;
  final double? amount;
  final int? points;

  Transaction({
    required this.type,
    required this.description,
    required this.date,
    this.amount,
    this.points,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      type: json['type'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      amount: json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      points: json['points'] as int?,
    );
  }
}