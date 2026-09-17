// lib/core/network/api_client.dart
//
// HTTP abstraction terpusat MutasiKu.
// Sumber: TECHNICAL-DESIGN.md §17, PROJECT-SETUP.md §17.
//
// ATURAN:
// - Semua request API melalui ApiClient — feature tidak membuat HTTP client sendiri.
// - Base URL dikonfigurasi melalui environment (tidak hardcode production URL).
// - Auth header diatur dari luar (inject token via setAuthToken).
// - Error dipetakan ke Failure sebelum dikembalikan ke caller.
//
// OPEN QUESTION: Backend authentication mechanism belum final (PRD §13.6).
// ApiClient sudah menyediakan slot untuk auth header — implementasi header
// dapat disesuaikan ketika backend ditentukan.

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';
import '../errors/failures.dart';
import '../errors/result.dart';
import 'api_exception.dart';

/// HTTP client terpusat MutasiKu.
///
/// Satu instance digunakan oleh seluruh repository melalui Riverpod provider.
///
/// Contoh:
/// ```dart
/// final result = await apiClient.get('/mutations');
/// ```
class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _client = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  String? _authToken;

  // ─── Auth ─────────────────────────────────────────────────────────────────

  /// Set token autentikasi.
  ///
  /// Dipanggil setelah login berhasil.
  /// OPEN QUESTION: format token (Bearer JWT, Sanctum, dll.) mengikuti backend.
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Hapus token autentikasi.
  ///
  /// Dipanggil saat logout.
  void clearAuthToken() {
    _authToken = null;
  }

  // ─── Headers ─────────────────────────────────────────────────────────────

  Map<String, String> _buildHeaders({Map<String, String>? extra}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_authToken != null) {
      // OPEN QUESTION: auth header scheme mengikuti backend (Bearer / token / dll.).
      headers['Authorization'] = 'Bearer $_authToken';
    }

    if (extra != null) {
      headers.addAll(extra);
    }

    return headers;
  }

  // ─── URI builder ─────────────────────────────────────────────────────────

  Uri _buildUri(String path, {Map<String, String>? queryParams}) {
    final uri = Uri.parse('$baseUrl$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  // ─── HTTP methods ─────────────────────────────────────────────────────────

  /// GET request.
  Future<Result<Map<String, dynamic>>> get(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client
          .get(
            _buildUri(path, queryParams: queryParams),
            headers: _buildHeaders(extra: headers),
          )
          .timeout(AppConstants.requestTimeout);

      return _handleResponse(response);
    } on SocketException {
      return Result.failure(
        const NetworkFailure(message: 'SocketException: no internet'),
      );
    } on HttpException {
      return Result.failure(
        const NetworkFailure(message: 'HttpException'),
      );
    } catch (e) {
      return _mapException(e);
    }
  }

  /// POST request.
  Future<Result<Map<String, dynamic>>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client
          .post(
            _buildUri(path),
            headers: _buildHeaders(extra: headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(AppConstants.requestTimeout);

      return _handleResponse(response);
    } on SocketException {
      return Result.failure(
        const NetworkFailure(message: 'SocketException: no internet'),
      );
    } catch (e) {
      return _mapException(e);
    }
  }

  /// PUT request.
  Future<Result<Map<String, dynamic>>> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client
          .put(
            _buildUri(path),
            headers: _buildHeaders(extra: headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(AppConstants.requestTimeout);

      return _handleResponse(response);
    } on SocketException {
      return Result.failure(
        const NetworkFailure(message: 'SocketException: no internet'),
      );
    } catch (e) {
      return _mapException(e);
    }
  }

  /// PATCH request.
  Future<Result<Map<String, dynamic>>> patch(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client
          .patch(
            _buildUri(path),
            headers: _buildHeaders(extra: headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(AppConstants.requestTimeout);

      return _handleResponse(response);
    } on SocketException {
      return Result.failure(
        const NetworkFailure(message: 'SocketException: no internet'),
      );
    } catch (e) {
      return _mapException(e);
    }
  }

  // ─── Response handler ─────────────────────────────────────────────────────

  Result<Map<String, dynamic>> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      try {
        if (response.body.isEmpty) {
          return const Result.success({});
        }
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return Result.success(decoded);
        }
        // Jika response bukan object — wrap dalam map
        return Result.success({'data': decoded});
      } catch (e) {
        return Result.failure(
          ParseException(message: 'JSON parse error: $e') as Failure,
        );
      }
    }

    return Result.failure(_failureFromStatusCode(statusCode, response.body));
  }

  Failure _failureFromStatusCode(int statusCode, String body) {
    switch (statusCode) {
      case 401:
        return const UnauthorizedFailure(message: '401 Unauthorized');
      case 403:
        return const ForbiddenFailure(message: '403 Forbidden');
      case 404:
        return const NotFoundFailure(message: '404 Not Found');
      case 409:
        return ConflictFailure(message: _extractMessage(body));
      case 422:
        return ValidationFailure(
          message: _extractMessage(body),
          fieldErrors: _extractFieldErrors(body),
        );
      default:
        if (statusCode >= 500) {
          return ServerFailure(
            message: 'Server error $statusCode',
            statusCode: statusCode,
          );
        }
        return UnknownFailure(message: 'HTTP $statusCode: $body');
    }
  }

  String? _extractMessage(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>?;
      return decoded?['message'] as String?;
    } catch (_) {
      return null;
    }
  }

  Map<String, List<String>>? _extractFieldErrors(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>?;
      final errors = decoded?['errors'];
      if (errors is Map<String, dynamic>) {
        return errors.map(
          (key, value) => MapEntry(
            key,
            (value as List).map((e) => e.toString()).toList(),
          ),
        );
      }
    } catch (_) {}
    return null;
  }

  Result<Map<String, dynamic>> _mapException(Object e) {
    if (e is TimeoutException || e.toString().contains('TimeoutException')) {
      return const Result.failure(
        NetworkFailure(message: 'Request timeout'),
      );
    }
    return Result.failure(
      UnknownFailure(message: 'Unexpected error: $e'),
    );
  }

  /// Tutup HTTP client.
  void dispose() {
    _client.close();
  }
}

// Dummy TimeoutException reference agar compile tanpa dart:async import
class TimeoutException implements Exception {
  const TimeoutException(this.message);
  final String message;
}
