
class WalletTransaction {
  String type;
  double? amount;
  int? points;
  String description;
  DateTime date;

  WalletTransaction({
    required this.type,
    this.amount,
    this.points,
    required this.description,
    required this.date,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    double? amountValue;
    final amountRaw = json['amount'];
    if (amountRaw != null) {
      if (amountRaw is num) {
        amountValue = amountRaw.toDouble();
      } else if (amountRaw is String) {
        amountValue = double.tryParse(amountRaw);
      }
    }

    int? pointsValue;
    final pointsRaw = json['points'];
    if (pointsRaw != null) {
      if (pointsRaw is int) {
        pointsValue = pointsRaw;
      } else if (pointsRaw is String) {
        pointsValue = int.tryParse(pointsRaw);
      } else if (pointsRaw is double) {
        pointsValue = pointsRaw.toInt();
      }
    }

    return WalletTransaction(
      type: json['type'] ?? '',
      amount: amountValue,
      points: pointsValue,
      description: json['description'] ?? '',
      date: DateTime.parse(json['created_at']),
    );
  }
}