import 'package:flutter_test/flutter_test.dart';
import 'package:smart_farming/core/failures.dart';
import 'package:smart_farming/features/notification/domain/repositories/notification_repository.dart';
import 'package:smart_farming/features/notification/domain/usecases/notification_route_resolver.dart';

/// Repository palsu untuk menguji kontrak domain tanpa Firebase/jaringan.
class FakeNotificationRepository implements NotificationRepository {
  FakeNotificationRepository({this.backendDown = false});

  final bool backendDown;
  final List<String> openedRoutes = [];
  String? lastRegisteredToken;

  @override
  Future<({String? token, Failure? failure})> initialize({
    required void Function(String route) onNotificationOpened,
  }) async {
    final route = routeFromMessage({'route': 'prediksi'});
    onNotificationOpened(route);
    return (token: 'fake-token-1234567890', failure: null);
  }

  @override
  Future<({bool granted, Failure? failure})> requestPermissionAndSubscribe() async {
    return (granted: true, failure: null);
  }

  @override
  Future<({bool registered, Failure? failure})> registerDevice(String fcmToken) async {
    lastRegisteredToken = fcmToken;
    if (backendDown) {
      return (registered: false, failure: NetworkFailure());
    }
    return (registered: true, failure: null);
  }

  @override
  Future<({String? token, Failure? failure})> currentOrFreshToken() async {
    return (token: lastRegisteredToken ?? 'fake-token-1234567890', failure: null);
  }
}

void main() {
  group('NotificationRepository contract (fake repo, tanpa Firebase)', () {
    test('initialize memanggil callback dengan rute ternormalisasi', () async {
      final repo = FakeNotificationRepository();
      final outcome = await repo.initialize(
        onNotificationOpened: repo.openedRoutes.add,
      );
      expect(outcome.token, isNotNull);
      expect(repo.openedRoutes, ['/prediksi']);
    });

    test('registerDevice saat backend mati mengembalikan NetworkFailure, bukan exception', () async {
      final repo = FakeNotificationRepository(backendDown: true);
      final outcome = await repo.registerDevice('token-x');
      expect(outcome.registered, isFalse);
      expect(outcome.failure, isA<NetworkFailure>());
    });

    test('maskToken tidak pernah membocorkan token penuh', () {
      expect(maskToken('fake-token-1234567890'), 'fake-token-1...');
    });
  });
}
