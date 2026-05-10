import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';

// 1. User Profile Provider
final userProfileProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  return FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().map((snap) => snap.data());
});

// 2. User Sessions Provider
final sessionsProvider = StreamProvider<List<QueryDocumentSnapshot>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return FirebaseFirestore.instance.collection('sessions')
      .where('uid', isEqualTo: user.uid)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snap) => snap.docs);
});

// 3. User Reminders Provider
final remindersProvider = StreamProvider<List<QueryDocumentSnapshot>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return FirebaseFirestore.instance.collection('reminders')
      .where('uid', isEqualTo: user.uid)
      .orderBy('targetDate')
      .snapshots()
      .map((snap) => snap.docs);
});

// 4. --- NEW: Goals Provider ---
final goalsProvider = StreamProvider<List<QueryDocumentSnapshot>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return FirebaseFirestore.instance.collection('goals')
      .where('uid', isEqualTo: user.uid)
      .orderBy('deadline')
      .snapshots()
      .map((snap) => snap.docs);
});

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addCategory(String uid, String newCategory) async {
    await _db.collection('users').doc(uid).set({'categories': FieldValue.arrayUnion([newCategory])}, SetOptions(merge: true));
  }

  Future<void> deleteCategory(String uid, String category) async {
    // 1. Remove category from user's categories array
    await _db.collection('users').doc(uid).set({'categories': FieldValue.arrayRemove([category])}, SetOptions(merge: true));

    // 2. Delete all goals with this category
    final goalsQuery = await _db.collection('goals')
        .where('uid', isEqualTo: uid)
        .where('category', isEqualTo: category)
        .get();
    for (var doc in goalsQuery.docs) {
      await doc.reference.delete();
    }

    // 3. Delete all sessions with this category
    final sessionsQuery = await _db.collection('sessions')
        .where('uid', isEqualTo: uid)
        .where('category', isEqualTo: category)
        .get();
    for (var doc in sessionsQuery.docs) {
      await doc.reference.delete();
    }
  }

  // --- NEW: Add Goal Function ---
  Future<void> addGoal(String uid, String title, String category, double targetHours, DateTime deadline) async {
    await _db.collection('goals').add({
      'uid': uid,
      'title': title,
      'category': category,
      'targetHours': targetHours,
      'currentHours': 0.0,
      'deadline': deadline.toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveSession(String uid, String category, int durationInSeconds) async {
    final double hours = durationInSeconds / 3600.0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final userRef = _db.collection('users').doc(uid);
    final userDoc = await userRef.get();

    int currentStreak = userDoc.data()?['streak'] ?? 0;
    Timestamp? lastSessionTs = userDoc.data()?['lastSessionDate'];

    if (lastSessionTs != null) {
      final lastDate = lastSessionTs.toDate();
      final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
      final difference = today.difference(lastDay).inDays;

      if (difference == 1) {
        currentStreak += 1;
      } else if (difference > 1) {
        currentStreak = 1;
      }
    } else {
      currentStreak = 1;
    }

    // 1. Save Session
    await _db.collection('sessions').add({
      'uid': uid, 'category': category, 'durationSeconds': durationInSeconds, 'timestamp': FieldValue.serverTimestamp(),
    });

    // 2. Update User Stats
    await userRef.set({
      'totalHours': FieldValue.increment(hours),
      'todayHours': FieldValue.increment(hours),
      'totalSessions': FieldValue.increment(1),
      'streak': currentStreak,
      'lastSessionDate': FieldValue.serverTimestamp(),
      'categories': FieldValue.arrayUnion([category])
    }, SetOptions(merge: true));

    // 3. --- NEW: Update Goal Progress automatically ---
    final goalsQuery = await _db.collection('goals')
        .where('uid', isEqualTo: uid)
        .where('category', isEqualTo: category)
        .get();

    for (var doc in goalsQuery.docs) {
      await doc.reference.update({
        'currentHours': FieldValue.increment(hours)
      });
    }
  }

  Future<void> addReminder(String uid, String title, DateTime targetDate, List<int> alertHoursBefore) async {
    await _db.collection('reminders').add({
      'uid': uid, 'title': title, 'targetDate': targetDate.toIso8601String(), 'alerts': alertHoursBefore, 'isCompleted': false, 'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleReminder(String docId, bool isCompleted) async {
    await _db.collection('reminders').doc(docId).update({'isCompleted': isCompleted});
  }
}

final databaseServiceProvider = Provider((ref) => DatabaseService());