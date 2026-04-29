class AppUser {
  final String id;
  final String role;
  final String fullName;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.role,
    required this.fullName,
    required this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      role: map['role'] as String,
      fullName: map['full_name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role,
      'full_name': fullName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
