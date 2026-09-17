// lib/core/providers/core_providers.dart
//
// Centralized Riverpod providers untuk Core Services & Storage.
// Sumber: TECHNICAL-DESIGN.md §2, PROJECT-SETUP.md §1.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../network/api_client.dart';
import '../services/connectivity_service.dart';
import '../storage/local_storage.dart';
import '../storage/secure_storage.dart';

/// Provider untuk [SharedPreferences] yang di-override di main.dart saat bootstrap.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main()');
});

/// Provider untuk [http.Client] dasar.
final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(() => client.close());
  return client;
});

/// Provider untuk [ApiClient] HTTP wrapper.
final apiClientProvider = Provider<ApiClient>((ref) {
  final httpClient = ref.watch(httpClientProvider);
  return ApiClient(
    httpClient: httpClient,
    baseUrl: AppConstants.defaultBaseUrl,
  );
});

/// Provider untuk [SecureStorage] token storage.
final secureStorageProvider = Provider<SecureStorage>((ref) {
  return const SecureStorage();
});

/// Provider untuk [LocalStorage] non-sensitive preferences storage.
final localStorageProvider = Provider<LocalStorage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStorage(prefs: prefs);
});

/// Provider untuk [ConnectivityService] status jaringan.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

/// Stream provider status koneksi online/offline.
final connectivityStatusProvider = StreamProvider<ConnectivityStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.statusStream;
});
