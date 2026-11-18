import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/failures.dart';
import '../../../../core/session.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class FirebaseProfileRepository implements ProfileRepository {
  FirebaseProfileRepository({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  UserProfile? get currentProfile {
    final user = _auth.currentUser;
    final email = user?.email ?? Session.email;
    if (user == null && email == null) return null;

    return UserProfile(
      name: user?.displayName ?? Session.name,
      email: email,
      photoUrl: user?.photoURL,
    );
  }

  @override
  Future<({bool cleared, Failure? failure})> clearPhoto() async {
    final user = _auth.currentUser;
    if (user == null) {
      return (
        cleared: false,
        failure: const AuthFailure('Pengguna tidak ditemukan.'),
      );
    }

    try {
      await user.updatePhotoURL(null);
      await user.reload();
      return (cleared: true, failure: null);
    } on FirebaseAuthException catch (error) {
      debugPrint('[Profile] Gagal menghapus photoURL: ${error.code}');
      return (
        cleared: false,
        failure: const AuthFailure('Foto profil gagal dihapus. Coba lagi.'),
      );
    } catch (error) {
      debugPrint('[Profile] Gagal menghapus photoURL: $error');
      return (
        cleared: false,
        failure: const LocalFailure('Foto profil gagal dihapus. Coba lagi.'),
      );
    }
  }
}
