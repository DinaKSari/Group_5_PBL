/// Kegagalan eksplisit lintas layer domain/data.
/// Layer data tidak boleh melempar exception mentah ke presentation;
/// ia mengonversinya menjadi salah satu subtype Failure.
sealed class Failure {
  const Failure(this.message);
  final String message;

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Tidak terhubung ke server']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Terjadi kesalahan pada server']);
}

class LocalFailure extends Failure {
  const LocalFailure([super.message = 'Terjadi kesalahan di perangkat']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Autentikasi gagal']);
}
