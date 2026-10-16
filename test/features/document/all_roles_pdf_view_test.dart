// test/features/document/all_roles_pdf_view_test.dart
//
// Widget & Unit test untuk verifikasi:
// 1. Hak akses melihat dokumen PDF untuk 5 Role:
//    - Admin, Operator, Bagian Aset, Kadiv (seluruh mutasi yang terkait)
//    - Pemohon (hanya mutasi miliknya sendiri)
// 2. Integrasi streaming PDF melalui ApiClient:
//    - Menampilkan indikator loading saat mengunduh dokumen
//    - Menampilkan PdfPreview setelah bytes berhasil diunduh
//    - Menampilkan pesan error ramah saat server merespons gagal / 404 / 403
// 3. Akses diblokir jika Pemohon lain mencoba melihat dokumen mutasi orang lain

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mutasiku/core/network/api_client.dart';
import 'package:mutasiku/core/providers/core_providers.dart';
import 'package:mutasiku/core/widgets/document_preview_dialog.dart';
import 'package:mutasiku/features/asset/domain/entities/asset.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_category.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_status.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:printing/printing.dart';

void main() {
  final validPdfBytes = Uint8List.fromList(
    utf8.encode(
      '%PDF-1.4\n1 0 obj<< /Title (Dokumen SK Mutasi) >>endobj\ntrailer<<>>\n%%EOF',
    ),
  );

  const testAsset = Asset(
    id: 'ast_01',
    assetCode: 'AST-001',
    name: 'MacBook Pro M3',
    category: AssetCategory(id: 'cat_it', code: 'IT', name: 'Teknologi Informasi'),
    location: 'Lantai 2 IT',
    pic: 'Budi Santoso',
    condition: 'Baik',
    status: AssetStatus.available,
    acquisitionYear: 2024,
  );

  final sampleMutation = Mutation(
    id: 'mut_100',
    ticketNumber: 'MUT-2026-00100',
    asset: testAsset,
    applicantId: 'usr_pemohon_01',
    applicantName: 'Budi Santoso',
    currentLocation: 'Lantai 2 IT',
    targetLocation: 'Lantai 3 Finance',
    currentPic: 'Budi Santoso',
    targetPic: 'Diana Sari',
    reason: 'Pindah penugasan divisi',
    documentName: 'SK_Mutasi_2026.pdf',
    documentBytes: null, // Bytes akan diunduh dari API
    status: MutationStatus.submitted,
    createdAt: DateTime.now(),
  );

  final pemohonUser = const User(
    id: 'usr_pemohon_01',
    name: 'Budi Santoso',
    username: 'pemohon_budi',
    role: UserRole.pemohon,
  );

  final otherPemohonUser = const User(
    id: 'usr_pemohon_99',
    name: 'Joko Anwar',
    username: 'pemohon_joko',
    role: UserRole.pemohon,
  );

  final operatorUser = const User(
    id: 'usr_operator_01',
    name: 'Siti Aminah',
    username: 'operator_siti',
    role: UserRole.operator,
  );

  final bagianAsetUser = const User(
    id: 'usr_aset_01',
    name: 'Hendro Gunawan',
    username: 'aset_hendro',
    role: UserRole.bagianAset,
  );

  final kadivUser = const User(
    id: 'usr_kadiv_01',
    name: 'Dr. Surya Wijaya',
    username: 'kadiv_surya',
    role: UserRole.kadiv,
  );

  final adminUser = const User(
    id: 'usr_admin_01',
    name: 'Administrator TI',
    username: 'admin_ti',
    role: UserRole.admin,
  );

  group('Hak Akses Dokumen PDF untuk Semua Role', () {
    test('Admin, Operator, Bagian Aset, Kadiv, dan Pemohon pemilik memiliki izin akses', () {
      expect(DocumentPreviewDialog.hasAccess(sampleMutation, adminUser), isTrue);
      expect(DocumentPreviewDialog.hasAccess(sampleMutation, operatorUser), isTrue);
      expect(DocumentPreviewDialog.hasAccess(sampleMutation, bagianAsetUser), isTrue);
      expect(DocumentPreviewDialog.hasAccess(sampleMutation, kadivUser), isTrue);
      expect(DocumentPreviewDialog.hasAccess(sampleMutation, pemohonUser), isTrue);
    });

    test('Pemohon lain tidak diizinkan mengakses dokumen mutasi yang bukan miliknya', () {
      expect(DocumentPreviewDialog.hasAccess(sampleMutation, otherPemohonUser), isFalse);
    });
  });

  group('Tampilan & Streaming Dokumen PDF via ApiClient untuk Seluruh Role', () {
    final mockHttpClient = MockClient((request) async {
      if (request.url.path.endsWith('/api/v1/mutations/100/document')) {
        return http.Response.bytes(
          validPdfBytes,
          200,
          headers: {'content-type': 'application/pdf'},
        );
      }
      return http.Response('Not Found', 404);
    });

    final apiClient = ApiClient(
      baseUrl: 'http://localhost:8000',
      httpClient: mockHttpClient,
    );

    final rolesToTest = [
      adminUser,
      operatorUser,
      bagianAsetUser,
      kadivUser,
      pemohonUser,
    ];

    for (final user in rolesToTest) {
      testWidgets('Role ${user.role.name} dapat membuka dialog dan melihat PdfPreview saat PDF berhasil diunduh', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              apiClientProvider.overrideWithValue(apiClient),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (ctx) => ElevatedButton(
                    onPressed: () => DocumentPreviewDialog.show(
                      ctx,
                      mutation: sampleMutation,
                      currentUser: user,
                      apiClient: apiClient,
                    ),
                    child: const Text('Buka Dokumen'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Buka Dokumen'));
        await tester.pump();
        expect(find.byType(Dialog), findsOneWidget);
        expect(find.text('SK_Mutasi_2026.pdf'), findsOneWidget);

        // Tunggu hingga request streaming selesai dan UI ter-render
        await tester.pump(const Duration(milliseconds: 200));

        // PdfPreview harus tampil untuk role ini
        expect(find.byType(PdfPreview), findsOneWidget);
      });
    }

    testWidgets('Menampilkan error card yang jelas saat server gagal mengembalikan file (404)', (tester) async {
      final notFoundClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'File dokumen fisik tidak ditemukan di server.',
          }),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final notFoundApiClient = ApiClient(
        baseUrl: 'http://localhost:8000',
        httpClient: notFoundClient,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(notFoundApiClient),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => DocumentPreviewDialog.show(
                    ctx,
                    mutation: sampleMutation,
                    currentUser: operatorUser,
                    apiClient: notFoundApiClient,
                  ),
                  child: const Text('Buka Dokumen'),
                ),
              ),
            ),
          ),
        ),
      );

        await tester.tap(find.text('Buka Dokumen'));
        await tester.pumpAndSettle();

        expect(find.byType(Dialog), findsOneWidget);
        expect(find.text('Gagal Memuat Dokumen'), findsOneWidget);
        expect(find.text('File dokumen fisik tidak ditemukan di server.'), findsOneWidget);
      });
  });
}
