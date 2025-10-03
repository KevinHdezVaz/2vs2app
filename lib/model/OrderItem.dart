 
class OrderItem {
  final String title;
  final int quantity;
  final double unitPrice;

  OrderItem({
    required this.title,
    required this.quantity,
    required this.unitPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'quantity': quantity,
      'unit_price': unitPrice,
    };
  }
}