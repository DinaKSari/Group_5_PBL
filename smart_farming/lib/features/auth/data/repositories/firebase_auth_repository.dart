import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/error_messages.dart';
import '../../../../core/failures.dart';
import '../../../../core/session.dart';
import '../../domain/repositories/auth_repository.dart';

/// Autentikasi riil via Firebase Auth (email & password).
class FirebaseAuthRepository implements AuthRepository {
  const FirebaseAuthRepository();

  String _pesan(FirebaseAuthException e) => switch (e.code) {
    'invalid-email' => 'Format email tidak valid.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'Email atau kata sandi salah.',
    'email-already-in-use' => 'Email sudah terdaftar. Silakan masuk.',
    'weak-password' => 'Kata sandi terlalu lemah (minimal 6 karakter).',
    'user-disabled' => 'Akun ini dinonaktifkan.',
    'too-many-requests' => 'Terlalu banyak percobaan. Coba lagi sebentar.',
    'network-request-failed' => 'Tidak ada koneksi internet.',
    _ => _takTerkenal(e),
  };

  /// Pesan mentah Firebase berbahasa Inggris dan tidak bisa ditindaklanjuti
  /// petani; kodenya masuk log supaya cabang di atas bisa ditambah.
  String _takTerkenal(FirebaseAuthException e) {
    debugPrint('[Auth] kode tidak terpetakan: ${e.code} (${e.message})');
    return ErrorMessages.unexpected;
  }

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
      Session.name = cred.user?.displayName;
      Session.isGuest = false;
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
      Session.name = cred.user?.displayName;
      Session.isGuest = false;
      return (registered: true, failure: null);
    } on FirebaseAuthException catch (e) {
      return (registered: false, failure: AuthFailure(_pesan(e)));
    }
  }

  @override
  Future<void> signOut() async {
    Session.clear();
    await FirebaseAuth.instance.signOut();
  }

  @override
  Future<({bool sent, Failure? failure})> sendPasswordReset(
    String email,
  ) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      return (sent: true, failure: null);
    } on FirebaseAuthException catch (e) {
      return (sent: false, failure: AuthFailure(_pesan(e)));
    }
  }

  @override
  Future<({bool updated, Failure? failure})> updateDisplayName(
    String name,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(name.trim());
        await user.reload();
        Session.name = name.trim();
        return (updated: true, failure: null);
      }
      return (
        updated: false,
        failure: const AuthFailure('Pengguna tidak ditemukan.'),
      );
    } on FirebaseAuthException catch (e) {
      return (updated: false, failure: AuthFailure(_pesan(e)));
    } catch (e) {
      return (
        updated: false,
        failure: AuthFailure('Gagal memperbarui nama: $e'),
      );
    }
  }

  @override
  Future<({bool updated, Failure? failure})> updatePassword(
    String newPassword,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
        return (updated: true, failure: null);
      }
      return (
        updated: false,
        failure: const AuthFailure('Pengguna tidak ditemukan.'),
      );
    } on FirebaseAuthException catch (e) {
      return (updated: false, failure: AuthFailure(_pesan(e)));
    } catch (e) {
      return (
        updated: false,
        failure: AuthFailure('Gagal memperbarui kata sandi: $e'),
      );
    }
  }

  @override
  String? get currentUserId =>
      Session.uid ?? FirebaseAuth.instance.currentUser?.uid;
}
