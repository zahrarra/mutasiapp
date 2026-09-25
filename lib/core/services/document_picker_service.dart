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

  const DocumentPickerResult.canceled()
      : document = null,
        errorMessage = null;

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
  static Future<DocumentPickerResult> pickDocument() async {
    // 1. Jika dalam mode pengujian, gunakan testPicker hook
    if (testPicker != null) {
      return await testPicker!();
    }

    try {
      FilePickerResult? result;

      if (kIsWeb) {
        // Coba FilePicker platform terlebih dahulu di Web
        try {
          result = await FilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: allowedExtensions,
            withData: true,
          );
        } on MissingPluginException {
          // Fallback ke browser native HTML file input
          return await _pickViaWebHtml();
        } catch (_) {
          return await _pickViaWebHtml();
        }
      } else {
        // Desktop / Mobile
        try {
          result = await FilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: allowedExtensions,
            withData: true,
          );
        } on MissingPluginException {
          return const DocumentPickerResult.failure(
            'Plugin pemilihan file tidak tersedia di perangkat ini.',
          );
        }
      }

      if (result == null || result.files.isEmpty) {
        return const DocumentPickerResult.canceled();
      }

      final file = result.files.first;

      // 2. Validasi Ekstensi
      final ext = _getExtension(file.name);
      if (!allowedExtensions.contains(ext)) {
        return DocumentPickerResult.failure(
          'Format file .$ext tidak didukung. Format yang diizinkan: PDF, JPG, JPEG, PNG, WEBP.',
        );
      }

      // 3. Validasi Ukuran (Maksimal 30 MB)
      if (file.size > maxFileSizeBytes) {
        final sizeMb = (file.size / (1024 * 1024)).toStringAsFixed(1);
        return DocumentPickerResult.failure(
          'Ukuran file melebihi batas maksimal 30 MB (ukuran: $sizeMb MB).',
        );
      }

      // 4. Ekstraksi Bytes secara nyata (bukan hanya nama file)
      Uint8List? bytes = file.bytes;
      if ((bytes == null || bytes.isEmpty) &&
          file.path != null &&
          file.path!.isNotEmpty) {
        try {
          final f = File(file.path!);
          if (await f.exists()) {
            bytes = await f.readAsBytes();
          }
        } catch (_) {}
      }

      if (bytes == null || bytes.isEmpty) {
        return const DocumentPickerResult.failure(
          'Gagal membaca isi dokumen: file kosong atau tidak dapat diakses.',
        );
      }

      return DocumentPickerResult.success(
        PickedDocument(
          name: file.name,
          size: file.size,
          bytes: bytes,
          path: file.path,
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

  static Future<DocumentPickerResult> _pickViaWebHtml() async {
    try {
      final webResult = await WebDocumentPicker.pickFileWeb(
        allowedExtensions: allowedExtensions,
      );

      if (webResult == null) {
        return const DocumentPickerResult.canceled();
      }

      final name = webResult['name'] as String? ?? 'document.pdf';
      final size = webResult['size'] as int? ?? 0;
      final bytes = webResult['bytes'] as Uint8List?;

      final ext = _getExtension(name);
      if (!allowedExtensions.contains(ext)) {
        return DocumentPickerResult.failure(
          'Format file .$ext tidak didukung. Format yang diizinkan: PDF, JPG, JPEG, PNG, WEBP.',
        );
      }

      if (size > maxFileSizeBytes) {
        final sizeMb = (size / (1024 * 1024)).toStringAsFixed(1);
        return DocumentPickerResult.failure(
          'Ukuran file melebihi batas maksimal 30 MB (ukuran: $sizeMb MB).',
        );
      }

      if (bytes == null || bytes.isEmpty) {
        return const DocumentPickerResult.failure(
          'Gagal membaca isi dokumen: file kosong atau tidak dapat diakses.',
        );
      }

      return DocumentPickerResult.success(
        PickedDocument(
          name: name,
          size: size,
          bytes: bytes,
          path: null,
        ),
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
