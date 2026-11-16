/// State sesi app.
///
/// `uid`/`email`/`name` hanya untuk tampilan; **tidak** pernah dikirim ke
/// backend sebagai identitas. Server mengambil uid dari klaim ID token yang
/// diverifikasi (lihat `docs/PLAN.md` §6 M1.1–M1.4).
abstract final class Session {
  static String? uid;
  static String? email;
  static String? name;

  /// Mode Tamu = read-only (keputusan RUNBOOK R1). Dipasang oleh tombol
  /// "Masuk Langsung sebagai Tamu", dilepas oleh login/register/logout.
  static bool isGuest = false;

  static void clear() {
    uid = null;
    email = null;
    name = null;
    isGuest = false;
  }

  static bool get hasAccount => !isGuest && uid != null;
}
