class TransactionRecord {
  final String id;
  final String customerId;
  final String processedBy;
  final double cartValue;
  final String categories;
  final DateTime createdAt;

  TransactionRecord({
    required this.id,
    required this.customerId,
    required this.processedBy,
    required this.cartValue,
    required this.categories,
    required this.createdAt,
  });

  factory TransactionRecord.fromMap(Map<String, dynamic> map) {
    return TransactionRecord(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      processedBy: map['processed_by'] as String,
      cartValue: (map['cart_value'] as num).toDouble(),
      categories: map['categories'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'processed_by': processedBy,
      'cart_value': cartValue,
      'categories': categories,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
