sealed class Failure {
  const Failure({this.message});

  final String? message;

  String get userMessage {
    if (this is NetworkFailure) {
      final msg = message?.toLowerCase() ?? '';
      if (msg.contains('timeout')) {
        return 'Waktu permintaan habis. Silakan periksa koneksi Anda dan coba lagi.';
      }
      return 'Koneksi ke server tidak tersedia. Periksa koneksi Anda, lalu coba lagi.';
    }

    if (this is UnauthorizedFailure) {
      return message ?? 'Sesi Anda telah berakhir. Silakan login kembali.';
    }

    if (this is ForbiddenFailure) {
      final raw = message?.trim();
      if (raw != null &&
          raw.isNotEmpty &&
          !raw.contains('403') &&
          !raw.toLowerCase().contains('forbidden')) {
        return raw;
      }
      return 'Akun Anda telah dinonaktifkan atau Anda tidak memiliki izin.';
    }

    if (this is ValidationFailure) {
      return message ?? 'Periksa kembali data yang Anda masukkan.';
    }

    if (this is NotFoundFailure) {
      return message ?? 'Data yang dicari tidak ditemukan.';
    }

    if (this is ConflictFailure) {
      return message ?? 'Aset sedang memiliki proses mutasi lain.';
    }

    if (this is ServerFailure) {
      return 'Terjadi kesalahan pada server. Silakan coba lagi.';
    }

    return 'Terjadi kesalahan pada server. Silakan coba lagi.';
  }
}

final class NetworkFailure extends Failure {
  const NetworkFailure({super.message});
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.message});
}

final class ForbiddenFailure extends Failure {
  const ForbiddenFailure({super.message});
}

final class ValidationFailure extends Failure {
  const ValidationFailure({super.message, this.fieldErrors});

  final Map<String, List<String>>? fieldErrors;

  @override
  String get userMessage =>
      message ?? 'Periksa kembali data yang Anda masukkan.';
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure({super.message});

  @override
  String get userMessage => message ?? 'Data yang dicari tidak ditemukan.';
}

final class ConflictFailure extends Failure {
  const ConflictFailure({super.message});

  @override
  String get userMessage =>
      message ?? 'Aset sedang memiliki proses mutasi lain.';
}

final class ServerFailure extends Failure {
  const ServerFailure({super.message, this.statusCode});

  final int? statusCode;
}

final class UnknownFailure extends Failure {
  const UnknownFailure({super.message});
}
