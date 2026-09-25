// test/features/feedback_and_document_preview_test.dart
//
// Pengujian untuk Feedback Global, Document Preview across Roles, dan Total Aset Tanggung Jawab.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/app/theme/app_colors.dart';
import 'package:mutasiku/core/widgets/app_feedback.dart';
import 'package:mutasiku/core/widgets/document_preview_dialog.dart';
import 'package:mutasiku/features/asset/domain/entities/asset.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_category.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_status.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';

void main() {
  const pemohonUser = User(
    id: 'usr_pemohon',
    username: 'pemohon1',
    name: 'Budi Santoso',
    email: 'pemohon@mutasiku.id',
    role: UserRole.pemohon,
  );

  const anotherPemohonUser = User(
    id: 'usr_pemohon_2',
    username: 'pemohon2',
    name: 'Siti Lainnya',
    email: 'siti@mutasiku.id',
    role: UserRole.pemohon,
  );

  const operatorUser = User(
    id: 'usr_operator',
    username: 'operator1',
    name: 'Siti Operator',
    email: 'operator@mutasiku.id',
    role: UserRole.operator,
  );

  const kabagUser = User(
    id: 'usr_kabag',
    username: 'kabag1',
    name: 'Hendra Kabag',
    email: 'kabag@mutasiku.id',
    role: UserRole.kabagAset,
  );

  const kadivUser = User(
    id: 'usr_kadiv',
    username: 'kadiv1',
    name: 'Drs. Ahmad Dahlan',
    email: 'kadiv@mutasiku.id',
    role: UserRole.kadiv,
  );

  const staffUser = User(
    id: 'usr_staff',
    username: 'staff1',
    name: 'Rizky Staff Aset',
    email: 'staff@mutasiku.id',
    role: UserRole.staffAset,
  );

  final testAsset = Asset(
    id: 'ast_test_1',
    assetCode: 'AST-TEST-001',
    name: 'MacBook Pro M2 Max',
    category: const AssetCategory(id: 'cat_it', code: 'IT', name: 'IT Equipment'),
    location: 'Lantai 3',
    pic: 'Budi Santoso',
    status: AssetStatus.available,
    condition: 'Baik',
    acquisitionYear: 2024,
    estimatedValue: 35000000.0,
  );

  final testMutationWithPdf = Mutation(
    id: 'mut_doc_pdf',
    ticketNumber: 'IT-2026-0001',
    asset: testAsset,
    applicantId: 'usr_pemohon',
    applicantName: 'Budi Santoso',
    currentLocation: 'Lantai 3',
    targetLocation: 'Lantai 2',
    currentPic: 'Budi Santoso',
    targetPic: 'Ahmad Supir',
    reason: 'Kebutuhan kerja',
    documentName: 'Surat_Tugas.pdf',
    documentBytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x35]), // %PDF-1.5 header
    status: MutationStatus.submitted,
    createdAt: DateTime.now(),
  );

  final testMutationWithImage = Mutation(
    id: 'mut_doc_img',
    ticketNumber: 'IT-2026-0002',
    asset: testAsset,
    applicantId: 'usr_pemohon',
    applicantName: 'Budi Santoso',
    currentLocation: 'Lantai 3',
    targetLocation: 'Lantai 2',
    currentPic: 'Budi Santoso',
    targetPic: 'Ahmad Supir',
    reason: 'Kebutuhan kerja',
    documentName: 'bukti_fisik.png',
    documentBytes: Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG header
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
      0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
      0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
      0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
      0x42, 0x60, 0x82
    ]),
    status: MutationStatus.submitted,
    createdAt: DateTime.now(),
  );

  final testMutationUnsupported = Mutation(
    id: 'mut_doc_docx',
    ticketNumber: 'IT-2026-0003',
    asset: testAsset,
    applicantId: 'usr_pemohon',
    applicantName: 'Budi Santoso',
    currentLocation: 'Lantai 3',
    targetLocation: 'Lantai 2',
    currentPic: 'Budi Santoso',
    targetPic: 'Ahmad Supir',
    reason: 'Kebutuhan kerja',
    documentName: 'Laporan_Spesifikasi.docx',
    status: MutationStatus.submitted,
    createdAt: DateTime.now(),
  );

  group('Feedback Global (AppFeedback) Tests', () {
    testWidgets('AppFeedback.showSuccess displays green floating snackbar with check icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppFeedback.showSuccess(context, 'Pengajuan berhasil diverifikasi.');
                },
                child: const Text('Trigger'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 500)); // Visible

      expect(find.text('Pengajuan berhasil diverifikasi.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, equals(AppColors.success));
    });

    testWidgets('AppFeedback.showError displays red floating snackbar with error icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppFeedback.showError(context, 'Gagal memverifikasi pengajuan.');
                },
                child: const Text('Trigger'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Gagal memverifikasi pengajuan.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, equals(AppColors.error));
    });

    testWidgets('AppFeedback.showWarning displays amber floating snackbar with warning icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppFeedback.showWarning(context, 'Perhatian: Data perlu dilengkapi.');
                },
                child: const Text('Trigger'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Perhatian: Data perlu dilengkapi.'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, equals(AppColors.warning));
    });
  });

  group('Document Access & Preview across All Roles', () {
    test('Role authorization check: Pemohon can only view own mutation documents', () {
      expect(DocumentPreviewDialog.hasAccess(testMutationWithPdf, pemohonUser), isTrue);
      expect(DocumentPreviewDialog.hasAccess(testMutationWithPdf, anotherPemohonUser), isFalse);
    });

    test('Role authorization check: Operator, Kabag, Kadiv, Staff Aset have legitimate access', () {
      expect(DocumentPreviewDialog.hasAccess(testMutationWithPdf, operatorUser), isTrue);
      expect(DocumentPreviewDialog.hasAccess(testMutationWithPdf, kabagUser), isTrue);
      expect(DocumentPreviewDialog.hasAccess(testMutationWithPdf, kadivUser), isTrue);
      expect(DocumentPreviewDialog.hasAccess(testMutationWithPdf, staffUser), isTrue);
    });

    testWidgets('DocumentPreviewDialog displays Image preview for supported image format', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  DocumentPreviewDialog.show(
                    context,
                    mutation: testMutationWithImage,
                    currentUser: operatorUser,
                  );
                },
                child: const Text('View Doc'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('View Doc'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('bukti_fisik.png'), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('DocumentPreviewDialog displays honest fallback for unsupported formats without fake claim', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  DocumentPreviewDialog.show(
                    context,
                    mutation: testMutationUnsupported,
                    currentUser: kabagUser,
                  );
                },
                child: const Text('View Doc'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('View Doc'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Laporan_Spesifikasi.docx'), findsOneWidget);
      expect(find.text('Pratinjau Tidak Didukung'), findsOneWidget);
      expect(
        find.text('Format file (.docx) tidak mendukung pratinjau langsung di dalam aplikasi.'),
        findsOneWidget,
      );
    });
  });
}
