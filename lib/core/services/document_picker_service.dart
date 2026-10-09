// lib/core/services/document_picker_service.dart
//
// Layanan pemilihan dokumen terpusat untuk MutasiKu:
// - Batas ukuran maksimal: 30 MB (31.457.280 bytes)
// - Format didukung: PDF, PNG, JPG, JPEG, WEBP
// - Menangani MissingPluginException secara tangguh dengan fallback Web HTML
// - Menyimpan file reference dan bytes nyata
// - Menyediakan hook pengujian (testPicker) untuk widget/unit test tanpa flakiness

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'document_picker_web_stub.dart'
    if (dart.library.html) 'document_picker_web.dart';

class PickedDocument {
  final String name;
  final int size;
  final Uint8List? bytes;
  final String? path;

  const PickedDocument({
    required this.name,
    required this.size,
    this.bytes,
    this.path,
  });

  bool get isPdf => name.toLowerCase().endsWith('.pdf');
  bool get isImage {
    final lower = name.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp');
  }
}

class DocumentPickerResult {
  final PickedDocument? document;
  final String? errorMessage;

  const DocumentPickerResult.success(PickedDocument this.document)
    : errorMessage = null;

  const DocumentPickerResult.failure(this.errorMessage) : document = null;

  const DocumentPickerResult.canceled() : document = null, errorMessage = null;

  bool get isSuccess => document != null;
  bool get isFailure => errorMessage != null;
  bool get isCanceled => document == null && errorMessage == null;
}

class DocumentPickerService {
  /// Batas maksimal ukuran dokumen pengajuan: 30 MB (31.457.280 bytes).
  static const int maxFileSizeBytes = 30 * 1024 * 1024;

  /// Ekstensi file yang diizinkan: PDF dan Gambar.
  static const List<String> allowedExtensions = [
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];

  /// Hook override untuk pengujian otomatis (unit / widget test).
  @visibleForTesting
  static Future<DocumentPickerResult> Function()? testPicker;

  /// Memilih dokumen dari sistem operasi / browser.
  static Future<DocumentPickerResult> pickDocument({
    List<String>? allowedExtensions,
  }) async {
    // 1. Jika dalam mode pengujian, gunakan testPicker hook
    if (testPicker != null) {
      return await testPicker!();
    }

    final effectiveExtensions =
        allowedExtensions ?? DocumentPickerService.allowedExtensions;

    try {
      dynamic rawResult;

      if (kIsWeb) {
        // Coba FilePicker platform terlebih dahulu di Web
        try {
          rawResult = await FilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: effectiveExtensions,
          );
        } on MissingPluginException {
          // Fallback ke browser native HTML file input
          return await _pickViaWebHtml(allowedExtensions: effectiveExtensions);
        } catch (_) {
          return await _pickViaWebHtml(allowedExtensions: effectiveExtensions);
        }
      } else {
        // Desktop / Mobile
        try {
          rawResult = await FilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: effectiveExtensions,
          );
        } on MissingPluginException {
          return const DocumentPickerResult.failure(
            'Plugin pemilihan file tidak tersedia di perangkat ini.',
          );
        }
      }

      // 2. Ekstraksi files secara tangguh (mendukung List<PlatformFile>, JSArray<PlatformFile>, legacy FilePickerResult)
      List<PlatformFile> platformFiles = const [];
      if (rawResult is List<PlatformFile>) {
        platformFiles = rawResult;
      } else if (rawResult is List) {
        platformFiles = rawResult.whereType<PlatformFile>().toList();
      } else if (rawResult != null) {
        try {
          final dynamic filesProp = (rawResult as dynamic).files;
          if (filesProp is List<PlatformFile>) {
            platformFiles = filesProp;
          } else if (filesProp is List) {
            platformFiles = filesProp.whereType<PlatformFile>().toList();
          } else {
            platformFiles = const [];
          }
        } catch (_) {
          platformFiles = const [];
        }
      }

      if (platformFiles.isEmpty) {
        return const DocumentPickerResult.canceled();
      }

      final file = platformFiles.first;

      // 3. Validasi Ekstensi
      final fileName = file.name.trim().isNotEmpty ? file.name : 'dokumen.pdf';
      final ext =
          (file.extension?.trim().isNotEmpty == true
                  ? file.extension!
                  : _getExtension(fileName))
              .toLowerCase();

      if (allowedExtensions != null && !allowedExtensions.contains(ext)) {
        return DocumentPickerResult.failure(
          'Format file .$ext tidak didukung. Format yang diizinkan: PDF, JPG, JPEG, PNG, WEBP.',
        );
      }

      // 4. Validasi Ukuran (Maksimal 30 MB)
      int fileSize = 0;
      final syncLength = file.lengthSync();
      if (syncLength != null && syncLength > 0) {
        fileSize = syncLength;
      } else {
        try {
          fileSize = await file.length();
        } catch (_) {
          try {
            fileSize = (file as dynamic).size as int? ?? 0;
          } catch (_) {}
        }
      }

      if (fileSize > maxFileSizeBytes) {
        return const DocumentPickerResult.failure(
          'Upload gagal. Ukuran file maksimal 30 MB.',
        );
      }

      // 5. Ekstraksi Bytes secara nyata (bukan hanya nama file)
      Uint8List? bytes;
      try {
        bytes = await file.readAsBytes();
      } catch (_) {
        try {
          final dynamic legacyBytes = (file as dynamic).bytes;
          if (legacyBytes is Uint8List) {
            bytes = legacyBytes;
          }
        } catch (_) {}

        if ((bytes == null || bytes.isEmpty) &&
            !kIsWeb &&
            file.path != null &&
            file.path!.isNotEmpty) {
          try {
            final f = File(file.path!);
            if (await f.exists()) {
              bytes = await f.readAsBytes();
            }
          } catch (_) {}
        }
      }

      if (bytes != null && bytes.isNotEmpty) {
        if (fileSize <= 0) {
          fileSize = bytes.length;
        }
      }

      // Validasi kembali ukuran jika sebelumnya belum terdeteksi dari metadata
      if (fileSize > maxFileSizeBytes) {
        return const DocumentPickerResult.failure(
          'Upload gagal. Ukuran file maksimal 30 MB.',
        );
      }

      if (bytes == null || bytes.isEmpty) {
        return const DocumentPickerResult.failure(
          'Gagal membaca isi dokumen: file kosong atau tidak dapat diakses.',
        );
      }

      String? filePath;
      try {
        filePath = file.path;
      } catch (_) {}

      return DocumentPickerResult.success(
        PickedDocument(
          name: fileName,
          size: fileSize,
          bytes: bytes,
          path: filePath,
        ),
      );
    } on MissingPluginException {
      if (kIsWeb) {
        return await _pickViaWebHtml();
      }
      return const DocumentPickerResult.failure(
        'Plugin pemilihan file belum terpasang atau tidak didukung di perangkat ini.',
      );
    } catch (e) {
      return DocumentPickerResult.failure('Gagal memilih file: $e');
    }
  }

  static Future<DocumentPickerResult> _pickViaWebHtml({
    List<String>? allowedExtensions,
  }) async {
    final effectiveExtensions =
        allowedExtensions ?? DocumentPickerService.allowedExtensions;
    try {
      final webResult = await WebDocumentPicker.pickFileWeb(
        allowedExtensions: effectiveExtensions,
      );

      if (webResult == null) {
        return const DocumentPickerResult.canceled();
      }

      final name = webResult['name'] as String? ?? 'document.pdf';
      final size = webResult['size'] as int? ?? 0;
      final bytes = webResult['bytes'] as Uint8List?;

      final ext = _getExtension(name);
      if (allowedExtensions != null && !allowedExtensions.contains(ext)) {
        return DocumentPickerResult.failure(
          'Format file .$ext tidak didukung. Format yang diizinkan: PDF, JPG, JPEG, PNG, WEBP.',
        );
      }

      if (size > maxFileSizeBytes) {
        return const DocumentPickerResult.failure(
          'Upload gagal. Ukuran file maksimal 30 MB.',
        );
      }

      if (bytes == null || bytes.isEmpty) {
        return const DocumentPickerResult.failure(
          'Gagal membaca isi dokumen: file kosong atau tidak dapat diakses.',
        );
      }

      return DocumentPickerResult.success(
        PickedDocument(name: name, size: size, bytes: bytes, path: null),
      );
    } catch (e) {
      return DocumentPickerResult.failure('Gagal memilih file di browser: $e');
    }
  }

  static String _getExtension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot == -1 || dot == fileName.length - 1) return '';
    return fileName.substring(dot + 1).toLowerCase();
  }
}
