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
import 'dart:typed_data';

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
    this.onUnauthorized,
    this.tokenGetter,
  }) : _client = httpClient ?? http.Client(),
       isCustomClient = httpClient != null;

  final String baseUrl;
  final http.Client _client;
  final bool isCustomClient;
  http.Client get httpClient => _client;

  /// Callback yang dipanggil saat request terautentikasi menerima response 401 Unauthorized.
  void Function()? onUnauthorized;

  /// Resolver asinkron untuk mengambil token dari persistent storage (misal SecureStorage).
  final Future<String?> Function()? tokenGetter;

  String? _authToken;

  // ─── Auth ─────────────────────────────────────────────────────────────────

  /// Cek apakah client memiliki token autentikasi aktif.
  bool get hasAuthToken => _authToken != null && _authToken!.isNotEmpty;

  /// Getter token aktif (untuk keperluan sinkronisasi internal).
  String? get authToken => _authToken;

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

  Future<Map<String, String>> _resolveHeaders({
    Map<String, String>? extra,
  }) async {
    if ((_authToken == null || _authToken!.isEmpty) && tokenGetter != null) {
      try {
        final token = await tokenGetter!();
        if (token != null && token.isNotEmpty) {
          _authToken = token;
        }
      } catch (_) {}
    }

    return _buildHeaders(extra: extra);
  }

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

  /// Membangun URI lengkap dengan normalisasi prefix dan pencegahan duplikasi /api/v1.
  Uri buildUri(String path, {Map<String, String>? queryParams}) =>
      _buildUri(path, queryParams: queryParams);

  Uri _buildUri(String path, {Map<String, String>? queryParams}) {
    var base = baseUrl.trim();
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }

    var cleanPath = path.trim();
    if (!cleanPath.startsWith('/')) {
      cleanPath = '/$cleanPath';
    }

    // 1. Normalisasi segmen login
    if (cleanPath == '/api/v1/login' || cleanPath == '/login' || cleanPath == '/auth/login') {
      cleanPath = '/api/v1/auth/login';
    } else if (cleanPath.startsWith('/v1/')) {
      cleanPath = '/api$cleanPath';
    } else if (cleanPath.startsWith('/api/') && !cleanPath.startsWith('/api/v1/')) {
      cleanPath = '/api/v1${cleanPath.substring('/api'.length)}';
    } else if (!cleanPath.startsWith('/api/v1/')) {
      cleanPath = '/api/v1$cleanPath';
    }

    // 2. Mencegah duplikasi prefix jika baseUrl sudah mengandung /api/v1 atau /api
    if (base.endsWith('/api/v1')) {
      cleanPath = cleanPath.substring('/api/v1'.length);
      if (!cleanPath.startsWith('/')) {
        cleanPath = '/$cleanPath';
      }
    } else if (base.endsWith('/api')) {
      cleanPath = cleanPath.substring('/api'.length);
      if (!cleanPath.startsWith('/')) {
        cleanPath = '/$cleanPath';
      }
    }

    final fullUrl = '$base$cleanPath';
    final uri = Uri.parse(fullUrl);
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
      final reqHeaders = await _resolveHeaders(extra: headers);
      final response = await _client
          .get(
            _buildUri(path, queryParams: queryParams),
            headers: reqHeaders,
          )
          .timeout(AppConstants.requestTimeout);

      return _handleResponse(response);
    } on SocketException {
      return Result.failure(
        const NetworkFailure(message: 'SocketException: no internet'),
      );
    } on HttpException {
      return Result.failure(const NetworkFailure(message: 'HttpException'));
    } catch (e) {
      return _mapException(e);
    }
  }

  /// GET raw bytes (e.g. streaming dokumen PDF / gambar berautentikasi).
  Future<Result<Uint8List>> getBytes(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    try {
      final reqHeaders = await _resolveHeaders(extra: headers);
      final response = await _client
          .get(
            _buildUri(path, queryParams: queryParams),
            headers: reqHeaders,
          )
          .timeout(AppConstants.requestTimeout);

      final statusCode = response.statusCode;
      if (statusCode >= 200 && statusCode < 300) {
        return Result.success(response.bodyBytes);
      }
      return Result.failure(_failureFromStatusCode(statusCode, response.body));
    } on SocketException {
      return Result.failure(
        const NetworkFailure(message: 'SocketException: no internet'),
      );
    } on HttpException {
      return Result.failure(const NetworkFailure(message: 'HttpException'));
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
      final reqHeaders = await _resolveHeaders(extra: headers);
      final response = await _client
          .post(
            _buildUri(path),
            headers: reqHeaders,
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
      final reqHeaders = await _resolveHeaders(extra: headers);
      final response = await _client
          .put(
            _buildUri(path),
            headers: reqHeaders,
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
      final reqHeaders = await _resolveHeaders(extra: headers);
      final response = await _client
          .patch(
            _buildUri(path),
            headers: reqHeaders,
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

  /// DELETE request.
  Future<Result<Map<String, dynamic>>> delete(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final reqHeaders = await _resolveHeaders(extra: headers);
      final response = await _client
          .delete(
            _buildUri(path),
            headers: reqHeaders,
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

  /// POST multipart request (misal: upload dokumen / berkas form).
  Future<Result<Map<String, dynamic>>> postMultipart(
    String path, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    Map<String, String>? headers,
  }) async {
    try {
      final request = http.MultipartRequest('POST', _buildUri(path));
      final allHeaders = await _resolveHeaders(extra: headers);
      allHeaders.remove('Content-Type');
      request.headers.addAll(allHeaders);

      if (fields != null) {
        request.fields.addAll(fields);
      }
      if (files != null) {
        request.files.addAll(files);
      }

      final streamedResponse = await _client
          .send(request)
          .timeout(AppConstants.requestTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on SocketException {
      return Result.failure(
        const NetworkFailure(message: 'SocketException: no internet'),
      );
    } on HttpException {
      return Result.failure(const NetworkFailure(message: 'HttpException'));
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
        final hadAuthToken = _authToken != null;
        _authToken = null;
        if (hadAuthToken) {
          onUnauthorized?.call();
        }
        return UnauthorizedFailure(
          message: _extractMessage(body) ?? '401 Unauthorized',
        );
      case 403:
        return ForbiddenFailure(
          message: _extractMessage(body) ?? '403 Forbidden',
        );
      case 404:
        return NotFoundFailure(
          message: _extractMessage(body) ?? '404 Not Found',
        );
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
      final msg = decoded?['message'] as String?;
      final errors = decoded?['errors'];
      if (errors is Map<String, dynamic> && errors.isNotEmpty) {
        final firstList = errors.values.first;
        if (firstList is List && firstList.isNotEmpty) {
          final firstMsg = firstList.first.toString();
          if (msg == null ||
              msg.isEmpty ||
              msg == 'Validasi gagal.' ||
              msg == 'The given data was invalid.' ||
              msg == firstMsg) {
            return firstMsg;
          }
          return '$msg: $firstMsg';
        }
      }
      return msg;
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
          (key, value) =>
              MapEntry(key, (value as List).map((e) => e.toString()).toList()),
        );
      }
    } catch (_) {}
    return null;
  }

  Result<T> _mapException<T>(Object e) {
    if (e is TimeoutException || e.toString().contains('TimeoutException')) {
      return const Result.failure(NetworkFailure(message: 'Request timeout'));
    }
    return Result.failure(UnknownFailure(message: 'Unexpected error: $e'));
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
