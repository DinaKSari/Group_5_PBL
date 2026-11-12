import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/failures.dart';
import '../../../../core/session.dart';
import '../../domain/repositories/auth_repository.dart';

/// Autentikasi riil via Firebase Auth (email & password).
class FirebaseAuthRepository implements AuthRepository {
  const FirebaseAuthRepository();

  String _pesan(FirebaseAuthException e) => switch (e.code) {
        'invalid-email' => 'Format email tidak valid.',
        'user-not-found' || 'wrong-password' || 'invalid-credential' =>
          'Email atau kata sandi salah.',
        'email-already-in-use' => 'Email sudah terdaftar. Silakan masuk.',
        'weak-password' => 'Kata sandi terlalu lemah (minimal 6 karakter).',
        'user-disabled' => 'Akun ini dinonaktifkan.',
        'too-many-requests' => 'Terlalu banyak percobaan. Coba lagi sebentar.',
        'network-request-failed' => 'Tidak ada koneksi internet.',
        _ => 'Autentikasi gagal: ${e.message ?? e.code}',
      };

  @override
  Future<({bool signedIn, Failure? failure})> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      Session.uid = cred.user?.uid;
      Session.email = cred.user?.email;
      return (signedIn: true, failure: null);
    } on FirebaseAuthException catch (e) {
      return (signedIn: false, failure: AuthFailure(_pesan(e)));
    }
  }

  @override
  Future<({bool registered, Failure? failure})> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      Session.uid = cred.user?.uid;
      Session.email = cred.user?.email;
      return (registered: true, failure: null);
    } on FirebaseAuthException catch (e) {
      return (registered: false, failure: AuthFailure(_pesan(e)));
    }
  }

  @override
  Future<void> signOut() async {
    Session.uid = null;
    Session.email = null;
    await FirebaseAuth.instance.signOut();
  }

  @override
  Future<({bool sent, Failure? failure})> sendPasswordReset(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      return (sent: true, failure: null);
    } on FirebaseAuthException catch (e) {
      return (sent: false, failure: AuthFailure(_pesan(e)));
    }
  }

  @override
  String? get currentUserId =>
      Session.uid ?? FirebaseAuth.instance.currentUser?.uid;
}
