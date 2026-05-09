class UserModel {
  final String id;
  final String email;
  final String name;
  final int totalTrackedSeconds;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.totalTrackedSeconds = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'totalTrackedSeconds': totalTrackedSeconds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      id: documentId,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      totalTrackedSeconds: map['totalTrackedSeconds'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}