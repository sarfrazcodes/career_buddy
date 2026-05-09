import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';



class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;



  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;



  Future<UserCredential?> signUp(String email, String password) async {

    try {

      return await _auth.createUserWithEmailAndPassword(

        email: email,

        password: password,

      );

    } catch (e) {

      throw Exception(_handleFirebaseAuthError(e));

    }

  }



  Future<UserCredential?> signIn(String email, String password) async {

    try {

      return await _auth.signInWithEmailAndPassword(

        email: email,

        password: password,

      );

    } catch (e) {

      throw Exception(_handleFirebaseAuthError(e));

    }

  }



  Future<void> signOut() async {

    await _auth.signOut();

  }



  String _handleFirebaseAuthError(dynamic e) {

    if (e is FirebaseAuthException) {

      switch (e.code) {

        case 'user-not-found': return 'No user found for that email.';

        case 'wrong-password': return 'Wrong password provided.';

        case 'email-already-in-use': return 'An account already exists for that email.';

        case 'invalid-email': return 'The email address is badly formatted.';

        case 'weak-password': return 'The password provided is too weak.';

        default: return e.message ?? 'An unknown error occurred.';

      }

    }

    return e.toString();

  }

}



final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) => ref.watch(authServiceProvider).authStateChanges);