import '../../../../core/failures.dart';

/// Kontrak autentikasi. Presentation tidak boleh tahu apakah
/// login divalidasi ke API, offline, atau mode demo.
abstract class AuthRepository {
  Future<({bool signedIn, Failure? failure})> signIn({
    required String email,
    required String password,
  });

  Future<({bool registered, Failure? failure})> signUp({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<({bool sent, Failure? failure})> sendPasswordReset(String email);

  String? get currentUserId;
}
