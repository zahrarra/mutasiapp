// lib/core/errors/failures.dart
//
// Centralized failure model.
// Sumber: TECHNICAL-DESIGN.md §25, AGENTS.md §21, PROJECT-SETUP.md §16.
//
// ATURAN:
// - Jangan menampilkan raw exception ke user.
// - Semua failure memiliki user-facing message.
// - UI memetakan Failure → pesan yang dapat dipahami user.

/// Base class untuk semua failure di MutasiKu.
///
/// Gunakan sealed class agar pattern matching dapat exhaustive di Dart.
sealed class Failure {
  const Failure({this.message});

  /// Pesan teknis (untuk logging, bukan untuk ditampilkan langsung ke user).
  final String? message;

  /// Pesan user-facing yang dapat ditampilkan di UI.
  ///
  /// Override di subclass jika pesan perlu disesuaikan.
  String get userMessage => _defaultUserMessage;

  String get _defaultUserMessage => switch (this) {
        NetworkFailure() =>
          'Koneksi internet tidak tersedia. Periksa koneksi Anda.',
        UnauthorizedFailure() =>
          'Sesi Anda telah berakhir. Silakan login kembali.',
        ForbiddenFailure() =>
          'Anda tidak memiliki izin untuk melakukan tindakan ini.',
        ValidationFailure(:final message) =>
          message ?? 'Periksa kembali data yang Anda masukkan.',
        NotFoundFailure() => 'Data yang dicari tidak ditemukan.',
        ConflictFailure(:final message) =>
          message ?? 'Aset sedang memiliki proses mutasi lain.',
        ServerFailure() =>
          'Terjadi kesalahan pada server. Coba lagi beberapa saat.',
        UnknownFailure() => 'Terjadi kesalahan. Coba lagi.',
      };
}

/// Failure akibat masalah koneksi / timeout.
final class NetworkFailure extends Failure {
  const NetworkFailure({super.message});
}

/// Failure akibat autentikasi gagal (401).
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.message});
}

/// Failure akibat tidak memiliki izin (403).
final class ForbiddenFailure extends Failure {
  const ForbiddenFailure({super.message});
}

/// Failure akibat validasi gagal (client atau server 422).
final class ValidationFailure extends Failure {
  const ValidationFailure({super.message, this.fieldErrors});

  /// Error per field jika tersedia dari server.
  final Map<String, List<String>>? fieldErrors;

  @override
  String get userMessage => message ?? 'Periksa kembali data yang Anda masukkan.';
}

/// Failure akibat data tidak ditemukan (404).
final class NotFoundFailure extends Failure {
  const NotFoundFailure({super.message});
}

/// Failure akibat konflik data, misalnya aset sudah memiliki mutasi aktif (409).
final class ConflictFailure extends Failure {
  const ConflictFailure({super.message});

  @override
  String get userMessage =>
      message ?? 'Aset sedang memiliki proses mutasi lain.';
}

/// Failure akibat error server (5xx).
final class ServerFailure extends Failure {
  const ServerFailure({super.message, this.statusCode});

  final int? statusCode;
}

/// Failure untuk kondisi yang tidak terduga.
final class UnknownFailure extends Failure {
  const UnknownFailure({super.message});
}
