import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Satu tempat yang mengubah kegagalan teknis menjadi kalimat yang bisa dibaca
/// petani. Angka status dan nama exception hanya boleh keluar di log — di layar
/// keduanya tidak bisa ditindaklanjuti dan membuat user mengira app-nya rusak.
abstract final class ErrorMessages {
  static const offline =
      'Server sedang mati. Data belum bisa dimuat — coba lagi beberapa menit.';
  static const network =
      'Koneksi internet kalian bermasalah. Periksa kuota atau Wi-Fi, lalu coba lagi.';
  static const sessionExpired = 'Sesi kalian sudah selesai. Masuk kembali ya.';
  static const forbidden = 'Data ini bukan milik akun kalian.';
  static const notFound = 'Data itu tidak ditemukan di server.';
  static const serverBusy =
      'Sedang ada masalah di server. Coba lagi sebentar, data kalian aman.';
  static const tooOften = 'Terlalu sering meminta. Tunggu sebentar ya.';
  static const checkInput = 'Periksa lagi nilai yang kalian isi.';
  static const unexpected =
      'Terjadi kesalahan yang tidak kami duga. Coba lagi, dan kalau tetap gagal laporkan ke pengelola LettuGrow.';

  /// Kalimat untuk respons HTTP bukan-2xx. Pesan `errors` dari 422 Laravel tetap
  /// lebih disukai pemanggilnya karena menyebut kolom mana yang salah.
  static String fromResponse(http.Response response) {
    final status = response.statusCode;
    // Bukan JSON = yang menjawab halaman HTML ngrok/Laragon: agent tunnel mati
    // atau Laravel crash. Dari sudut pandang HP, itu persis "server mati".
    if (!(response.headers['content-type'] ?? '').contains('json')) {
      return status >= 500 ? serverBusy : offline;
    }
    return switch (status) {
      401 => sessionExpired,
      403 => forbidden,
      404 => notFound,
      422 => checkInput,
      429 => tooOften,
      _ when status >= 500 => serverBusy,
      _ => unexpected,
    };
  }

  /// Kalimat untuk exception dari lapisan jaringan. Detail mentahnya masuk log,
  /// bukan layar.
  static String fromException(Object error) {
    debugPrint('[ErrorMessages] $error');
    if (error is TimeoutException) return offline;
    if (error is SocketException) return network;
    return unexpected;
  }
}
