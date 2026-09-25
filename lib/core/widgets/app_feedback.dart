// lib/core/widgets/app_feedback.dart
//
// Standarisasi komponen feedback aksi global:
// - Success: Hijau (#15803D) + Icons.check_circle_rounded
// - Error: Merah (#B42318) + Icons.error_outline_rounded
// - Warning: Kuning/Amber (#B45309) + Icons.warning_amber_rounded
// - Info: Biru (#175CD3) + Icons.info_outline_rounded
//
// Aturan: Hanya dipanggil berdasarkan hasil operasi nyata.

import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

abstract final class AppFeedback {
  /// Menampilkan floating SnackBar dengan icon dan styling terstandarisasi.
  static void _show({
    required BuildContext context,
    required String message,
    String? details,
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 4,
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (details != null && details.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      details,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Menampilkan pesan sukses berwarna hijau dengan icon check_circle.
  /// Contoh: "Pengajuan berhasil diverifikasi."
  static void showSuccess(
    BuildContext context,
    String message, {
    String? details,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context: context,
      message: message,
      details: details,
      backgroundColor: AppColors.success,
      icon: Icons.check_circle_rounded,
      duration: duration,
    );
  }

  /// Menampilkan pesan gagal/error berwarna merah dengan icon error_outline.
  /// Contoh: "Gagal memverifikasi pengajuan."
  static void showError(
    BuildContext context,
    String message, {
    String? details,
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context: context,
      message: message,
      details: details,
      backgroundColor: AppColors.error,
      icon: Icons.error_outline_rounded,
      duration: duration,
    );
  }

  /// Menampilkan pesan peringatan berwarna amber dengan icon warning_amber.
  static void showWarning(
    BuildContext context,
    String message, {
    String? details,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context: context,
      message: message,
      details: details,
      backgroundColor: AppColors.warning,
      icon: Icons.warning_amber_rounded,
      duration: duration,
    );
  }

  /// Menampilkan pesan informasi berwarna biru dengan icon info_outline.
  static void showInfo(
    BuildContext context,
    String message, {
    String? details,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context: context,
      message: message,
      details: details,
      backgroundColor: AppColors.info,
      icon: Icons.info_outline_rounded,
      duration: duration,
    );
  }
}
