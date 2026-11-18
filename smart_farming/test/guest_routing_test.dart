import 'package:flutter_test/flutter_test.dart';
import 'package:smart_farming/core/session.dart';
import 'package:smart_farming/routes.dart';

void main() {
  tearDown(Session.clear);

  group('redirectLocationFor', () {
    test(
      'mode tamu boleh masuk tiga tab, tapi tidak halaman catat parameter',
      () {
        Session.isGuest = true;
        expect(redirectLocationFor(AppRoutes.home), isNull);
        expect(redirectLocationFor(AppRoutes.prediksi), isNull);
        expect(redirectLocationFor(AppRoutes.riwayat), isNull);
        expect(redirectLocationFor(AppRoutes.sensor), AppRoutes.splash);
      },
    );

    test(
      'tanpa akun dan tanpa mode tamu, semua halaman privat dilempar ke splash',
      () {
        for (final location in [
          AppRoutes.home,
          AppRoutes.prediksi,
          AppRoutes.riwayat,
          AppRoutes.sensor,
        ]) {
          expect(
            redirectLocationFor(location),
            AppRoutes.splash,
            reason: location,
          );
        }
      },
    );

    test('akun login boleh masuk ke semuanya', () {
      Session.uid = 'uid-1';
      expect(redirectLocationFor(AppRoutes.sensor), isNull);
      expect(redirectLocationFor(AppRoutes.home), isNull);
    });

    test('halaman publik tetap bisa dibuka tanpa akun', () {
      expect(redirectLocationFor(AppRoutes.splash), isNull);
      expect(redirectLocationFor(AppRoutes.login), isNull);
      expect(redirectLocationFor(AppRoutes.register), isNull);
    });

    test(
      'akun Firebase yang dipulihkan langsung ke beranda, bukan onboarding',
      () {
        Session.uid = 'uid-restored';
        expect(redirectLocationFor(AppRoutes.splash), AppRoutes.home);
        expect(redirectLocationFor(AppRoutes.login), AppRoutes.home);
        expect(redirectLocationFor(AppRoutes.register), AppRoutes.home);
      },
    );
  });
}
