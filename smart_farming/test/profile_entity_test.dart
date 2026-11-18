import 'package:flutter_test/flutter_test.dart';
import 'package:smart_farming/features/profile/domain/entities/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('memilih nama tampilan dan email yang sudah dinormalisasi', () {
      const profile = UserProfile(
        name: '  Siti  ',
        email: '  siti@example.com  ',
      );

      expect(profile.displayName, 'Siti');
      expect(profile.displayEmail, 'siti@example.com');
    });

    test('menggunakan prefix email saat nama Firebase belum diatur', () {
      const profile = UserProfile(email: 'petani.selada@example.com');

      expect(profile.displayName, 'Petani.selada');
    });

    test('memberikan fallback aman untuk profil kosong', () {
      const profile = UserProfile();

      expect(profile.displayName, 'Petani Selada');
      expect(profile.displayEmail, 'petani@smartfarming.com');
    });
  });
}
