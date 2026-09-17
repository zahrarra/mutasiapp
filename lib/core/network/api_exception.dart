// lib/core/network/api_exception.dart
//
// Exception internal untuk network layer.
// Tidak dilempar ke UI — dikonversi ke Failure di ApiClient.
// Sumber: TECHNICAL-DESIGN.md §17.

/// Exception internal yang dilempar oleh [ApiClient].
///
/// Jangan menangkap exception ini di widget atau use case.
/// ApiClient mengonversinya menjadi [Failure] sebelum dikembalikan.
sealed class ApiException implements Exception {
  const ApiException({required this.message});

  final String message;

  @override
  String toString() => 'ApiException: $message';
}

/// Gagal terhubung (timeout, no internet).
final class ConnectionException extends ApiException {
  const ConnectionException({required super.message});
}

/// Server mengembalikan response dengan status code error.
final class HttpException extends ApiException {
  const HttpException({
    required super.message,
    required this.statusCode,
    this.body,
  });

  final int statusCode;
  final String? body;

  @override
  String toString() =>
      'HttpException($statusCode): $message';
}

/// Response tidak dapat di-parse / format tidak valid.
final class ParseException extends ApiException {
  const ParseException({required super.message});
}
