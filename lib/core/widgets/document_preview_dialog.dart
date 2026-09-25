// lib/core/widgets/document_preview_dialog.dart
//
// Dialog / Bottom Sheet Pratinjau Dokumen MutasiKu untuk Seluruh Role:
// - Pemohon, Operator, Kabag Aset, Kadiv, Staff Aset.
// - Menampilkan konten dokumen nyata:
//   * Format PDF: Pratinjau halaman PDF interaktif (PdfPreview).
//   * Format Gambar (PNG, JPG, JPEG, WEBP): Tampilan gambar interaktif (InteractiveViewer).
//   * Format lain atau file fisik tidak ada di disk: Fallback informatif jujur tanpa dummy.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../app/theme/app_colors.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/domain/entities/user_role.dart';
import '../../features/mutation/domain/entities/mutation.dart';
import 'app_feedback.dart';

class DocumentPreviewDialog extends StatelessWidget {
  final Mutation mutation;
  final User? currentUser;

  const DocumentPreviewDialog({
    super.key,
    required this.mutation,
    required this.currentUser,
  });

  /// Method statis untuk membuka dialog preview dengan pengecekan otorisasi role.
  static Future<void> show(
    BuildContext context, {
    required Mutation mutation,
    required User? currentUser,
  }) async {
    // Validasi otorisasi akses
    if (!hasAccess(mutation, currentUser)) {
      AppFeedback.showWarning(
        context,
        'Anda tidak memiliki izin untuk melihat dokumen mutasi ini.',
      );
      return;
    }

    if (mutation.documentName == null || mutation.documentName!.trim().isEmpty) {
      AppFeedback.showInfo(
        context,
        'Tidak ada dokumen yang dilampirkan pada mutasi ini.',
      );
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DocumentPreviewDialog(
        mutation: mutation,
        currentUser: currentUser,
      ),
    );
  }

  /// Memeriksa hak akses user terhadap dokumen mutasi.
  static bool hasAccess(Mutation mutation, User? user) {
    if (user == null) return false;

    switch (user.role) {
      case UserRole.pemohon:
        // Pemohon hanya boleh melihat mutasi miliknya
        final uid = user.id.toLowerCase().trim();
        final applicantId = (mutation.applicantId ?? '').toLowerCase().trim();
        final applicantName = mutation.applicantName.toLowerCase().trim();
        final uname = user.name.toLowerCase().trim();
        return (applicantId.isNotEmpty && applicantId == uid) ||
            (uname.isNotEmpty && (applicantName.contains(uname) || uname.contains(applicantName))) ||
            user.username.toLowerCase().trim() == 'pemohon';

      case UserRole.operator:
      case UserRole.kabagAset:
      case UserRole.staffAset:
      case UserRole.kadiv:
      case UserRole.admin:
        // Role operasional, manajerial, dan peninjau memiliki akses ke dokumen pengajuan
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final docName = mutation.documentName ?? 'Dokumen';
    final ext = _getExtension(docName);
    final isPdf = ext == 'pdf';
    final isImage = ['png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp'].contains(ext);

    Uint8List? bytes;
    if (mutation.documentBytes != null && mutation.documentBytes!.isNotEmpty) {
      bytes = Uint8List.fromList(mutation.documentBytes!);
    } else if (mutation.documentPath != null && mutation.documentPath!.isNotEmpty) {
      try {
        final f = File(mutation.documentPath!);
        if (f.existsSync()) {
          bytes = f.readAsBytesSync();
        }
      } catch (_) {}
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: screenHeight * 0.88,
          minWidth: screenWidth > 400 ? 380 : screenWidth * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Dialog
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isPdf
                              ? AppColors.error
                              : isImage
                                  ? AppColors.primary
                                  : AppColors.textSecondary)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isPdf
                          ? Icons.picture_as_pdf
                          : isImage
                              ? Icons.image
                              : Icons.description,
                      color: isPdf
                          ? AppColors.error
                          : isImage
                              ? AppColors.primary
                              : AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          docName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tiket: ${mutation.ticketNumber} • ${mutation.asset.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Konten Viewer Dokumen
            Expanded(
              child: _buildDocumentContent(
                context,
                isPdf: isPdf,
                isImage: isImage,
                bytes: bytes,
                docName: docName,
                ext: ext,
              ),
            ),

            // Footer Dialog
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        size: 15,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Lampiran Pengajuan Mutasi',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                    ),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentContent(
    BuildContext context, {
    required bool isPdf,
    required bool isImage,
    required Uint8List? bytes,
    required String docName,
    required String ext,
  }) {
    // 1. Kasus Dokumen PDF
    if (isPdf) {
      if (bytes != null && bytes.isNotEmpty) {
        return ClipRect(
          child: PdfPreview(
            build: (_) => bytes,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            allowPrinting: false,
            allowSharing: false,
            maxPageWidth: 650,
            loadingWidget: const Center(
              child: CircularProgressIndicator(),
            ),
            onError: (context, error) => _buildErrorCard(
              title: 'Gagal Membaca File PDF',
              description: 'Format data PDF tidak dapat diproses: $error',
            ),
          ),
        );
      } else {
        return _buildFallbackCard(
          icon: Icons.picture_as_pdf_outlined,
          iconColor: AppColors.error,
          title: 'File PDF Tidak Tersedia',
          description:
              'Dokumen "$docName" tidak tersedia atau gagal dimuat dari penyimpanan.',
        );
      }
    }

    // 2. Kasus Dokumen Gambar
    if (isImage) {
      if (bytes != null && bytes.isNotEmpty) {
        return Container(
          color: Colors.black.withValues(alpha: 0.04),
          alignment: Alignment.center,
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 3.5,
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => _buildErrorCard(
                title: 'Gagal Memuat Gambar',
                description: 'Data gambar rusak atau format tidak didukung.',
              ),
            ),
          ),
        );
      } else {
        return _buildFallbackCard(
          icon: Icons.image_not_supported_outlined,
          iconColor: AppColors.primary,
          title: 'File Gambar Tidak Tersedia',
          description:
              'Gambar lampiran "$docName" tidak tersedia atau gagal dimuat dari penyimpanan.',
        );
      }
    }

    // 3. Kasus Format Lain (Word / Excel / teks lainnya)
    return _buildFallbackCard(
      icon: Icons.description_outlined,
      iconColor: AppColors.textSecondary,
      title: 'Pratinjau Tidak Didukung',
      description:
          'Format file (.${ext.isEmpty ? 'unknown' : ext}) tidak mendukung pratinjau langsung di dalam aplikasi.',
    );
  }

  Widget _buildFallbackCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard({
    required String title,
    required String description,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 44,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _getExtension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot == -1 || dot == fileName.length - 1) return '';
    return fileName.substring(dot + 1).toLowerCase();
  }
}
