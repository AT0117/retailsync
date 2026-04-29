class Customer {
  final String id;
  final String mobileNumber;
  final String fullName;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.mobileNumber,
    required this.fullName,
    required this.createdAt,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      mobileNumber: map['mobile_number'] as String,
      fullName: map['full_name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mobile_number': mobileNumber,
      'full_name': fullName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
