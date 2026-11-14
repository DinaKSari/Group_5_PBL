/// Penyimpan uid user aktif (Firebase) agar layer data lain bisa mengirim
/// identitas ke backend tanpa mengenal FirebaseAuth.
abstract final class Session {
  static String? uid;
  static String? email;
}
