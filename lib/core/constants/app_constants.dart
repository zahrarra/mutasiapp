// lib/core/constants/app_constants.dart
//
// Konstanta global MutasiKu.
// Jangan menaruh business rule di sini.

import 'package:flutter/foundation.dart';

/// Konstanta aplikasi MutasiKu.
abstract final class AppConstants {
  /// Nama aplikasi
  static const String appName = 'MutasiKu';

  /// Versi aplikasi
  static const String appVersion = '1.0.0';

  // ─── API ─────────────────────────────────────────────────────────────────

  /// Default request timeout
  static const Duration requestTimeout = Duration(seconds: 30);

  /// Default connection timeout
  static const Duration connectionTimeout = Duration(seconds: 15);

  // ─── Storage keys ─────────────────────────────────────────────────────────
  // Kunci untuk SecureStorage dan LocalStorage.
  // Jangan gunakan string literal di tempat lain — selalu referensikan konstanta ini.

  /// Kunci token autentikasi (SecureStorage)
  static const String keyAuthToken = 'auth_token';

  /// Kunci refresh token (SecureStorage)
  static const String keyRefreshToken = 'refresh_token';

  /// Kunci data user yang disimpan (LocalStorage)
  static const String keyCurrentUser = 'current_user';

  // ─── Environment ─────────────────────────────────────────────────────────
  // Nilai default; nilai sesungguhnya dikonfigurasi via environment.
  // Lihat .env.example.

  /// Base URL default (override via environment API_BASE_URL).
  /// Otomatis menggunakan 10.0.2.2:8000 pada platform Android Emulator
  /// dan 127.0.0.1:8000 pada Web / Desktop Localhost.
  static String get defaultBaseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }
}
