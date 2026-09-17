// lib/core/services/connectivity_service.dart
//
// Abstraction untuk status koneksi internet.
// Sumber: PROJECT-SETUP.md §20, TECHNICAL-DESIGN.md — Offline Architecture.
//
// ATURAN:
// - UI menggunakan ConnectivityService untuk menampilkan OfflineBanner.
// - Business logic offline belum diimplementasikan di foundation.
// - ConnectivityService hanya memberikan sinyal online/offline untuk UX.

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Status koneksi internet.
enum ConnectivityStatus {
  /// Terhubung ke internet.
  online,

  /// Tidak terhubung.
  offline,
}

/// Service untuk memantau koneksi internet.
///
/// Gunakan [isConnected] untuk pemeriksaan satu kali.
/// Gunakan [statusStream] untuk reactive state.
///
/// Contoh:
/// ```dart
/// final status = await connectivityService.checkStatus();
/// if (status == ConnectivityStatus.offline) {
///   // tampilkan OfflineBanner
/// }
/// ```
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  // ─── Status stream ────────────────────────────────────────────────────────

  /// Stream perubahan status koneksi.
  Stream<ConnectivityStatus> get statusStream =>
      _connectivity.onConnectivityChanged.map(_mapConnectivityResult);

  // ─── One-shot check ───────────────────────────────────────────────────────

  /// Periksa status koneksi saat ini.
  Future<ConnectivityStatus> checkStatus() async {
    final results = await _connectivity.checkConnectivity();
    return _mapConnectivityResult(results);
  }

  /// Kembalikan true jika ada koneksi internet.
  Future<bool> get isConnected async {
    final status = await checkStatus();
    return status == ConnectivityStatus.online;
  }

  // ─── Mapping ──────────────────────────────────────────────────────────────

  ConnectivityStatus _mapConnectivityResult(List<ConnectivityResult> results) {
    if (results.isEmpty) return ConnectivityStatus.offline;

    final hasConnection = results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet,
    );

    return hasConnection
        ? ConnectivityStatus.online
        : ConnectivityStatus.offline;
  }
}
