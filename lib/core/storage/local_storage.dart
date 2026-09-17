// lib/core/storage/local_storage.dart
//
// Abstraction untuk penyimpanan preferensi ringan (non-sensitive).
// Sumber: PROJECT-SETUP.md §19.

import 'package:shared_preferences/shared_preferences.dart';

/// Abstraction untuk local storage preferensi ringan.
class LocalStorage {
  const LocalStorage({required this.prefs});

  final SharedPreferences prefs;

  // ─── String ───────────────────────────────────────────────────────────────

  Future<bool> setString(String key, String value) =>
      prefs.setString(key, value);

  String? getString(String key) => prefs.getString(key);

  // ─── Bool ─────────────────────────────────────────────────────────────────

  Future<bool> setBool(String key, {required bool value}) =>
      prefs.setBool(key, value);

  bool? getBool(String key) => prefs.getBool(key);

  // ─── Int ──────────────────────────────────────────────────────────────────

  Future<bool> setInt(String key, int value) => prefs.setInt(key, value);

  int? getInt(String key) => prefs.getInt(key);

  // ─── Remove ───────────────────────────────────────────────────────────────

  Future<bool> remove(String key) => prefs.remove(key);

  Future<bool> clear() => prefs.clear();

  // ─── Contains ─────────────────────────────────────────────────────────────

  bool containsKey(String key) => prefs.containsKey(key);
}
