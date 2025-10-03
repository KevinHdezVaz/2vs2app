
class PriceDetail {
  final String store;
  final double price;
  final String currency;

  PriceDetail({
    required this.store,
    required this.price,
    required this.currency,
  });

  factory PriceDetail.fromJson(Map<String, dynamic> json) {
    return PriceDetail(
      store: json['store'] as String? ?? 'Tienda Desconocida',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'store': store,
      'price': price,
      'currency': currency,
    };
  }
}