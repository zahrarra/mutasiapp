// lib/core/storage/secure_storage.dart
//
// Abstraction untuk penyimpanan credential sensitif.
// Sumber: TECHNICAL-DESIGN.md §16, PROJECT-SETUP.md §19.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

/// Abstraction untuk secure storage credential.
class SecureStorage {
  const SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _options = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  // ─── Write ────────────────────────────────────────────────────────────────

  /// Simpan nilai dengan key.
  Future<void> write(String key, String value) async {
    await _storage.write(
      key: key,
      value: value,
      aOptions: _options,
    );
  }

  // ─── Read ─────────────────────────────────────────────────────────────────

  /// Baca nilai dengan key.
  Future<String?> read(String key) async {
    return _storage.read(key: key, aOptions: _options);
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  /// Hapus satu nilai.
  Future<void> delete(String key) async {
    await _storage.delete(key: key, aOptions: _options);
  }

  /// Hapus semua nilai (digunakan saat logout).
  Future<void> deleteAll() async {
    await _storage.deleteAll(aOptions: _options);
  }

  /// Hapus semua credential (alias deleteAll).
  Future<void> clearAll() async => deleteAll();

  // ─── Check ────────────────────────────────────────────────────────────────

  /// Periksa apakah key ada.
  Future<bool> containsKey(String key) async {
    return _storage.containsKey(key: key, aOptions: _options);
  }

  // ─── Convenience Helpers ──────────────────────────────────────────────────

  Future<void> saveAuthToken(String token) => write(AppConstants.keyAuthToken, token);
  Future<String?> getAuthToken() => read(AppConstants.keyAuthToken);
  Future<bool> hasAuthToken() => containsKey(AppConstants.keyAuthToken);

  Future<void> saveUserId(String userId) => write('user_id', userId);
  Future<String?> getUserId() => read('user_id');
}
