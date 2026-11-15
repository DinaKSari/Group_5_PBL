import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_farming/config/api_config.dart';
import 'package:smart_farming/config/app_version.dart';
import 'package:smart_farming/core/remote_settings.dart';
import 'package:smart_farming/features/home/presentation/pages/home_page.dart';

void main() {
  tearDown(RemoteSettings.reset);

  group('RemoteSettings.apply', () {
    test('mengisi holder sinkron dan membuang spasi/slash akhir', () {
      RemoteSettings.apply({
        RemoteKeys.apiBaseUrl: '  https://craftily-handcraft-outboard.ngrok-free.dev/api/ ',
        RemoteKeys.minimumSupportedVersion: ' 1.2.0 ',
      });

      expect(RemoteSettings.apiBaseUrl,
          'https://craftily-handcraft-outboard.ngrok-free.dev/api');
      expect(RemoteSettings.minimumSupportedVersion, '1.2.0');
    });

    test('null dan string kosong berarti tidak diatur', () {
      RemoteSettings.apply({
        RemoteKeys.apiBaseUrl: '',
        RemoteKeys.minimumSupportedVersion: '   ',
      });

      expect(RemoteSettings.apiBaseUrl, isNull);
      expect(RemoteSettings.minimumSupportedVersion, isNull);
    });

    test('key yang tidak ada di peta tidak mengubah apa pun', () {
      RemoteSettings.apply({RemoteKeys.apiBaseUrl: 'https://a.test/api'});
      RemoteSettings.apply({RemoteKeys.minimumSupportedVersion: '2.0.0'});

      expect(RemoteSettings.apiBaseUrl, 'https://a.test/api');
      expect(RemoteSettings.minimumSupportedVersion, '2.0.0');
    });
  });

  group('compareVersions & isOutdated', () {
    test('membandingkan per segmen, bukan sebagai teks', () {
      expect(RemoteSettings.compareVersions('1.10.0', '1.9.0'), greaterThan(0));
      expect(RemoteSettings.compareVersions('1.9.0', '1.10.0'), lessThan(0));
      expect(RemoteSettings.compareVersions('1.2', '1.2.0'), isZero);
      expect(RemoteSettings.compareVersions('1.2.0', '1.2.0+7'), isZero);
      expect(RemoteSettings.compareVersions('2.0.0', '1.99.99'), greaterThan(0));
    });

    test('nilai sampah dianggap 0, tidak melempar', () {
      expect(RemoteSettings.compareVersions('v1', '0'), isZero);
      expect(RemoteSettings.compareVersions('1.x', '1.0'), isZero);
    });

    test('tanpa minimum_supported_version = tidak pernah dianggap tertinggal', () {
      expect(RemoteSettings.isOutdated('1.0.0'), isFalse);

      RemoteSettings.apply({RemoteKeys.minimumSupportedVersion: '1.0.0'});
      expect(RemoteSettings.isOutdated('1.0.0'), isFalse);

      RemoteSettings.apply({RemoteKeys.minimumSupportedVersion: '1.1.0'});
      expect(RemoteSettings.isOutdated('1.0.0'), isTrue);
    });
  });

  group('ApiConfig', () {
    test('tanpa Remote Config memakai nilai build default', () {
      expect(ApiConfig.resolve(remoteValue: null), ApiConfig.buildDefault);
    });

    test('Remote Config dipakai begitu tersedia', () {
      RemoteSettings.apply(
          {RemoteKeys.apiBaseUrl: 'https://tunnel.test.ngrok-free.dev/api'});

      expect(ApiConfig.baseUrl, 'https://tunnel.test.ngrok-free.dev/api');
    });

    test('override eksplisit menang atas Remote Config (jalur dart-define)', () {
      RemoteSettings.apply({RemoteKeys.apiBaseUrl: 'https://rc.test/api'});

      expect(ApiConfig.resolve(remoteValue: 'http://10.0.2.2:8000/api'),
          'http://10.0.2.2:8000/api');
    });

    test('slash akhir tidak mengubah hasil', () {
      expect(ApiConfig.resolve(remoteValue: 'https://rc.test/api//'),
          ApiConfig.resolve(remoteValue: 'https://rc.test/api'));
    });
  });

  group('loadRemoteSettings', () {
    test('menulis hasil fetch ke holder', () async {
      await loadRemoteSettings(fetch: () async => {
            RemoteKeys.apiBaseUrl: 'https://dari-console.test/api',
            RemoteKeys.minimumSupportedVersion: '1.4.0',
          });

      expect(RemoteSettings.apiBaseUrl, 'https://dari-console.test/api');
      expect(RemoteSettings.isOutdated('1.0.0'), isTrue);
    });

    test('fetch yang gagal tidak melempar dan tidak menghapus nilai lama', () async {
      await loadRemoteSettings(
          fetch: () async => {RemoteKeys.apiBaseUrl: 'https://lama.test/api'});

      await loadRemoteSettings(fetch: () async => throw StateError('offline'));

      expect(RemoteSettings.apiBaseUrl, 'https://lama.test/api');
    });

    test('fetch yang menggantung dipotong timeout, start app tidak tertahan',
        () async {
      final started = DateTime.now();
      await loadRemoteSettings(
        timeout: const Duration(milliseconds: 50),
        fetch: () => Completer<Map<String, String?>>().future,
      );

      expect(DateTime.now().difference(started), lessThan(const Duration(seconds: 2)));
      expect(RemoteSettings.apiBaseUrl, isNull);
      expect(ApiConfig.baseUrl, ApiConfig.buildDefault);
    });
  });

  group('VersionNoticeBanner', () {
    Future<void> pump(WidgetTester tester) => tester.pumpWidget(
          MaterialApp(home: Scaffold(body: const VersionNoticeBanner())),
        );

    testWidgets('tidak tampil selama versi APK memenuhi minimum', (tester) async {
      RemoteSettings.apply({RemoteKeys.minimumSupportedVersion: appVersion});
      await pump(tester);

      expect(find.textContaining('lebih lama dari versi minimum'), findsNothing);
    });

    testWidgets('tampil dan menyebut kedua angka versi saat tertinggal', (tester) async {
      RemoteSettings.apply({RemoteKeys.minimumSupportedVersion: '99.0.0'});
      await pump(tester);

      expect(find.textContaining('lebih lama dari versi minimum 99.0.0'), findsOneWidget);
      // Non-dismissible: tidak ada tombol tutup di banner.
      expect(find.bySubtype<IconButton>(), findsNothing);
    });
  });
}
