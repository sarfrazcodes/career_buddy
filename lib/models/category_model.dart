class CategoryModel {
  final String id;
  final String userId; // Links the category to the specific user
  final String name;   // e.g., "Embedded Systems", "Flutter Dev", "Gym"
  final String colorHex; // To give custom colors to the Analytics charts
  final bool isDefault; // To track if it's a system default or user-created

  CategoryModel({
    required this.id,
    required this.userId,
    required this.name,
    this.colorHex = '#6366F1', // Defaults to AppTheme.primaryAccent
    this.isDefault = false,
  });

  // Convert to Map for Firebase Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'colorHex': colorHex,
      'isDefault': isDefault,
    };
  }

  // Create from Firebase Firestore Map
  factory CategoryModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CategoryModel(
      id: documentId,
      userId: map['userId'] ?? '',
      name: map['name'] ?? 'Unnamed Category',
      colorHex: map['colorHex'] ?? '#6366F1',
      isDefault: map['isDefault'] ?? false,
    );
  }
}