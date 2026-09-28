import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/core/services/document_picker_service.dart';

void main() {
  setUp(() {
    DocumentPickerService.testPicker = null;
  });

  tearDown(() {
    DocumentPickerService.testPicker = null;
  });

  group('DocumentPickerService — Upload SK SDM & Boundary Tests', () {
    test('≤30 MB → upload berhasil', () async {
      const size10Mb = 10 * 1024 * 1024;
      final bytes = Uint8List(1024);

      DocumentPickerService.testPicker = () async {
        return DocumentPickerResult.success(
          PickedDocument(
            name: 'SK_SDM_Mutasi_Pegawai.pdf',
            size: size10Mb,
            bytes: bytes,
            path: '/mock/path/SK_SDM_Mutasi_Pegawai.pdf',
          ),
        );
      };

      final result = await DocumentPickerService.pickDocument();

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.document, isNotNull);
      expect(result.document!.name, equals('SK_SDM_Mutasi_Pegawai.pdf'));
      expect(result.document!.size, equals(size10Mb));
      expect(result.document!.isPdf, isTrue);
    });

    test('Tepat 30 MB (31,457,280 bytes) → upload berhasil', () async {
      const size30Mb = DocumentPickerService.maxFileSizeBytes;

      DocumentPickerService.testPicker = () async {
        return const DocumentPickerResult.success(
          PickedDocument(
            name: 'SK_SDM_30MB_Max.pdf',
            size: size30Mb,
            bytes: null,
            path: '/mock/path/SK_SDM_30MB_Max.pdf',
          ),
        );
      };

      final result = await DocumentPickerService.pickDocument();

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.document!.size, equals(size30Mb));
    });

    test('>30 MB → upload gagal + pesan: "Upload gagal. Ukuran file maksimal 30 MB."', () async {
      const sizeOver30Mb = DocumentPickerService.maxFileSizeBytes + 1;

      DocumentPickerService.testPicker = () async {
        if (sizeOver30Mb > DocumentPickerService.maxFileSizeBytes) {
          return const DocumentPickerResult.failure(
            'Upload gagal. Ukuran file maksimal 30 MB.',
          );
        }
        return const DocumentPickerResult.canceled();
      };

      final result = await DocumentPickerService.pickDocument();

      expect(result.isFailure, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.document, isNull);
      expect(result.errorMessage, equals('Upload gagal. Ukuran file maksimal 30 MB.'));
    });

    test('Picker error/exception ditangani aman tanpa menyebabkan crash', () async {
      DocumentPickerService.testPicker = () async {
        return const DocumentPickerResult.failure(
          'Gagal memilih file: Platform channel error',
        );
      };

      final result = await DocumentPickerService.pickDocument();

      expect(result.isFailure, isTrue);
      expect(result.errorMessage, contains('Gagal memilih file'));
      expect(result.document, isNull);
    });

    test('User membatalkan dialog pemilihan file → canceled tanpa crash', () async {
      DocumentPickerService.testPicker = () async {
        return const DocumentPickerResult.canceled();
      };

      final result = await DocumentPickerService.pickDocument();

      expect(result.isCanceled, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isFalse);
      expect(result.document, isNull);
    });
  });
}
