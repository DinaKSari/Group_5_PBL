import '../../../../core/failures.dart';
import '../../../../core/session.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implementasi mode demo/offline: kredensial apa pun diterima setelah jeda
/// simulasi. Provider utama memakai FirebaseAuthRepository; kelas ini dipakai
/// ulang oleh test dan mode tanpa-Firebase.
class DemoAuthRepository implements AuthRepository {
  const DemoAuthRepository();

  @override
  Future<({bool signedIn, Failure? failure})> signIn({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (email.trim().isEmpty || password.isEmpty) {
      return (signedIn: false, failure: AuthFailure('Email atau kata sandi kosong'));
    }
    Session.uid = 'demo-${email.trim()}';
    Session.email = email.trim();
    return (signedIn: true, failure: null);
  }

  @override
  Future<({bool registered, Failure? failure})> signUp({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (email.trim().isEmpty || password.length < 6) {
      return (registered: false, failure: AuthFailure('Email kosong atau sandi kurang dari 6 karakter'));
    }
    Session.uid = 'demo-${email.trim()}';
    Session.email = email.trim();
    return (registered: true, failure: null);
  }

  @override
  Future<void> signOut() async {
    Session.uid = null;
    Session.email = null;
  }

  @override
  Future<({bool sent, Failure? failure})> sendPasswordReset(String email) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return (sent: email.trim().isNotEmpty, failure: null);
  }

  @override
  String? get currentUserId => Session.uid;
}
