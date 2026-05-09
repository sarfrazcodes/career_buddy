import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Save the extra user details (Name, Mobile)
  Future<void> createUserProfile(String uid, String name, String mobile) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'mobile': mobile,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

final firestoreServiceProvider = Provider((ref) => FirestoreService());