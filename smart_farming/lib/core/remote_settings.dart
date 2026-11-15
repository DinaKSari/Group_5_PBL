import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Nama parameter yang dibaca dari Firebase Remote Config (Console → Remote Config).
abstract final class RemoteKeys {
  static const apiBaseUrl = 'api_base_url';
  static const minimumSupportedVersion = 'minimum_supported_version';
}

/// Nilai yang bisa diganti dari Console tanpa build ulang APK.
///
/// Diisi SEKALI saat start (lihat [loadRemoteSettings]) lalu dibaca sinkron.
/// Sengaja bukan Future/Provider: `ApiClient` tidak boleh menunggu jaringan
/// untuk setiap request, dan Remote Config yang lambat tidak boleh menahan UI.
abstract final class RemoteSettings {
  static String? _apiBaseUrl;
  static String? _minimumSupportedVersion;

  static String? get apiBaseUrl => _apiBaseUrl;
  static String? get minimumSupportedVersion => _minimumSupportedVersion;

  /// Dipakai loader Firebase DAN tes unit. Key yang tidak ada di peta dibiarkan
  /// seperti adanya (Console baru mengisi sebagian parameter), key dengan nilai
  /// null/kosong berarti "tidak diatur" dan menghapus nilai lama.
  static void apply(Map<String, String?> values) {
    if (values.containsKey(RemoteKeys.apiBaseUrl)) {
      final url = values[RemoteKeys.apiBaseUrl]?.trim();
      _apiBaseUrl = (url == null || url.isEmpty) ? null : _trimSlash(url);
    }

    if (values.containsKey(RemoteKeys.minimumSupportedVersion)) {
      final minimum = values[RemoteKeys.minimumSupportedVersion]?.trim();
      _minimumSupportedVersion = (minimum == null || minimum.isEmpty) ? null : minimum;
    }
  }

  static void reset() {
    _apiBaseUrl = null;
    _minimumSupportedVersion = null;
  }

  /// true kalau Remote Config meminta versi minimum lebih baru daripada APK ini.
  static bool isOutdated(String currentVersion) {
    final minimum = _minimumSupportedVersion;
    if (minimum == null) return false;
    return compareVersions(minimum, currentVersion) > 0;
  }

  /// Menerima '1.2', '1.2.0', '1.2.0+7'; segmen non-angka dianggap 0.
  static int compareVersions(String left, String right) {
    final a = _segments(left), b = _segments(right);
    final length = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < length; i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x.compareTo(y);
    }
    return 0;
  }

  static List<int> _segments(String version) => version
      .split('+')
      .first // build metadata (1.2.0+7) tidak memengaruhi urutan, ikut aturan semver
      .split(RegExp(r'[.-]'))
      .map((part) => int.tryParse(part.trim()) ?? 0)
      .toList(growable: false);

  static String _trimSlash(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;
}

/// Ambil nilai Remote Config. Tidak pernah melempar dan tidak pernah menahan
/// start aplikasi lebih dari [timeout] — Remote Config yang belum di-set (R4 belum
/// dikerjakan), jaringan mati, atau project baru semuanya jatuh ke nilai build-time.
Future<void> loadRemoteSettings({
  Duration timeout = const Duration(seconds: 3),
  Future<Map<String, String?>> Function()? fetch,
}) async {
  try {
    RemoteSettings.apply(await (fetch ?? _fetchFromFirebase).call().timeout(timeout));
  } catch (error) {
    debugPrint('Remote Config dilewati, pakai nilai build: $error');
  }
}

Future<Map<String, String?>> _fetchFromFirebase() async {
  final remote = FirebaseRemoteConfig.instance;
  await remote.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(seconds: 3),
    // 12 jam: pindah ngrok -> hosting lain tetap butuh 1x buka app berikutnya,
    // tapi tidak menambah request ke Firebase tiap kali aplikasi dibuka.
    minimumFetchInterval: const Duration(hours: 12),
  ));
  await remote.fetchAndActivate();

  final values = <String, String?>{};
  for (final key in const [
    RemoteKeys.apiBaseUrl,
    RemoteKeys.minimumSupportedVersion,
  ]) {
    final entry = remote.getValue(key);
    // Parameter yang belum pernah dibuat/di-fetch di Console (source static atau
    // default): jangan timpa nilai build dengan string kosong.
    if (entry.source != ValueSource.valueRemote) continue;
    final text = entry.asString().trim();
    values[key] = text.isEmpty ? null : text;
  }
  return values;
}
