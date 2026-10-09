import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';
import 'platform_check.dart';

/// Abstraction untuk secure storage credential.
class SecureStorage {
  SecureStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _androidOptions = AndroidOptions();
  static const _iosOptions = IOSOptions();
  static const _webOptions = WebOptions(
    dbName: 'mutasiku_secure_storage',
    publicKey: 'mutasiku_vault',
  );

  static final Map<String, String> _memoryFallback = {};

  static bool get isTestEnvironment => isFlutterTest;
  static bool get _isTest => isTestEnvironment;

  // ─── Write ────────────────────────────────────────────────────────────────

  /// Simpan nilai dengan key.
  Future<void> write(String key, String value) async {
    if (_isTest) {
      _memoryFallback[key] = value;
      return;
    }
    await _storage.write(
      key: key,
      value: value,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
      webOptions: _webOptions,
    );
  }

  // ─── Read ─────────────────────────────────────────────────────────────────

  /// Baca nilai dengan key.
  Future<String?> read(String key) async {
    if (_isTest) return _memoryFallback[key];
    return _storage.read(
      key: key,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
      webOptions: _webOptions,
    );
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  /// Hapus satu nilai.
  Future<void> delete(String key) async {
    if (_isTest) {
      _memoryFallback.remove(key);
      return;
    }
    await _storage.delete(
      key: key,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
      webOptions: _webOptions,
    );
  }

  /// Hapus semua nilai (digunakan saat logout).
  Future<void> deleteAll() async {
    if (_isTest) {
      _memoryFallback.clear();
      return;
    }
    await _storage.deleteAll(
      aOptions: _androidOptions,
      iOptions: _iosOptions,
      webOptions: _webOptions,
    );
  }

  /// Hapus semua credential (alias deleteAll).
  Future<void> clearAll() async => deleteAll();

  // ─── Check ────────────────────────────────────────────────────────────────

  /// Periksa apakah key ada.
  Future<bool> containsKey(String key) async {
    if (_isTest) return _memoryFallback.containsKey(key);
    return _storage.containsKey(
      key: key,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
      webOptions: _webOptions,
    );
  }

  // ─── Convenience Helpers ──────────────────────────────────────────────────

  Future<void> saveAuthToken(String token) =>
      write(AppConstants.keyAuthToken, token);
  Future<String?> getAuthToken() => read(AppConstants.keyAuthToken);
  Future<bool> hasAuthToken() => containsKey(AppConstants.keyAuthToken);

  Future<void> saveUserId(String userId) => write('user_id', userId);
  Future<String?> getUserId() => read('user_id');
}
