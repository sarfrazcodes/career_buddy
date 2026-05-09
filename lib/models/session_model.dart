class SessionModel {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime endTime;
  final int durationInSeconds;
  final String category;
  final String notes;

  SessionModel({
    required this.id,
    required this.userId,
    required this.startTime,
    required this.endTime,
    required this.durationInSeconds,
    required this.category,
    this.notes = '',
  });

  // Convert to Map for Firebase Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationInSeconds': durationInSeconds,
      'category': category,
      'notes': notes,
    };
  }

  // Create from Firebase Firestore Map
  factory SessionModel.fromMap(Map<String, dynamic> map, String documentId) {
    return SessionModel(
      id: documentId,
      userId: map['userId'] ?? '',
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      durationInSeconds: map['durationInSeconds'] ?? 0,
      category: map['category'] ?? 'General',
      notes: map['notes'] ?? '',
    );
  }
}