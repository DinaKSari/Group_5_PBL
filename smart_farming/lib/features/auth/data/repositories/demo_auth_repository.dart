import '../../../../core/failures.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implementasi mode demo PBL: kredensial apa pun diterima setelah jeda
/// simulasi. TODO(API): ganti ke endpoint /auth backend bila tersedia.
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
    return (signedIn: true, failure: null);
  }
}
