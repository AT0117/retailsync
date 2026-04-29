class LoyaltyRecord {
  final String id;
  final String customerId;
  final int pointsAdded;
  final int pointsRedeemed;
  final String transactionId;
  final DateTime createdAt;

  LoyaltyRecord({
    required this.id,
    required this.customerId,
    required this.pointsAdded,
    required this.pointsRedeemed,
    required this.transactionId,
    required this.createdAt,
  });

  factory LoyaltyRecord.fromMap(Map<String, dynamic> map) {
    return LoyaltyRecord(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      pointsAdded: (map['points_added'] as num).toInt(),
      pointsRedeemed: (map['points_redeemed'] as num).toInt(),
      transactionId: map['transaction_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'points_added': pointsAdded,
      'points_redeemed': pointsRedeemed,
      'transaction_id': transactionId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
