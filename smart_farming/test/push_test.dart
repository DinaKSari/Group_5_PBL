import 'package:flutter_test/flutter_test.dart';
import 'package:smart_farming/routes.dart';
import 'package:smart_farming/features/notification/domain/usecases/notification_route_resolver.dart';

void main() {
  group('routeFromMessage tests', () {
    test('Kasus 1: data kosong atau null mengembalikan rute default (riwayat)', () {
      expect(routeFromMessage(null), equals(AppRoutes.riwayat));
      expect(routeFromMessage({}), equals(AppRoutes.riwayat));
      expect(routeFromMessage({'route': ''}), equals(AppRoutes.riwayat));
      expect(routeFromMessage({'route': '   '}), equals(AppRoutes.riwayat));
      expect(routeFromMessage({'other_key': '123'}), equals(AppRoutes.riwayat));
    });

    test('Kasus 2: data tanpa slash otomatis ditambahkan prefix slash', () {
      expect(routeFromMessage({'route': 'riwayat'}), equals('/riwayat'));
      expect(routeFromMessage({'route': 'prediksi'}), equals('/prediksi'));
      expect(routeFromMessage({'route': 'home'}), equals('/home'));
    });

    test('Kasus 3: data dengan slash tetap valid dan utuh', () {
      expect(routeFromMessage({'route': '/riwayat'}), equals('/riwayat'));
      expect(routeFromMessage({'route': '/prediksi'}), equals('/prediksi'));
      expect(routeFromMessage({'route': '/home'}), equals('/home'));
      expect(routeFromMessage({'route': '  /home  '}), equals('/home'));
    });
  });

  group('maskToken tests', () {
    test('Token null atau kosong tidak crash', () {
      expect(maskToken(null), equals('(kosong)'));
      expect(maskToken(''), equals('(kosong)'));
    });

    test('Token panjang disamarkan menjadi 12 karakter pertama + ellipsis', () {
      const longToken = 'fcm_token_panjang_sekali_1234567890';
      final masked = maskToken(longToken);
      expect(masked.length, equals(15)); // 12 + 3 (...)
      expect(masked, equals('fcm_token_pa...'));
      expect(masked.contains('1234567890'), isFalse);
    });
  });
}
