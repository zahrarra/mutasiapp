// lib/app/theme/app_typography.dart
//
// Centralized design token: typography.
// Sumber: DESIGN.md §6–8, PROJECT-SETUP.md §6.
// Font: Inter (DESIGN.md §6).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// TextStyle factory untuk type scale MutasiKu.
///
/// Selalu gunakan kelas ini — jangan buat TextStyle ad-hoc di widget.
///
/// Type scale (DESIGN.md §7):
/// | Name       | Size | Weight |
/// |------------|-----:|-------:|
/// | Display    |  32  |  700   |
/// | H1         |  24  |  700   |
/// | H2         |  20  |  700   |
/// | H3         |  18  |  600   |
/// | Body Large |  16  |  400   |
/// | Body       |  14  |  400   |
/// | Caption    |  12  |  400   |
/// | Button     |  14  |  600   |
/// | Ticket     |  14  |  600   |
abstract final class AppTypography {
  // ─── Display ─────────────────────────────────────────────────────────────

  static TextStyle get display => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  // ─── Headings ─────────────────────────────────────────────────────────────

  static TextStyle get h1 => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get h2 => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get h3 => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  // ─── Body ─────────────────────────────────────────────────────────────────

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodySecondary => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  // ─── Caption ─────────────────────────────────────────────────────────────

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  static TextStyle get captionPrimary => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  // ─── Button ──────────────────────────────────────────────────────────────

  static TextStyle get button => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.surface,
        height: 1.0,
      );

  static TextStyle get buttonSecondary => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        height: 1.0,
      );

  // ─── Ticket ──────────────────────────────────────────────────────────────

  /// Style khusus untuk ticket number (DESIGN.md §8).
  /// Ticket harus mudah ditemukan dan tidak menggunakan typography dekoratif.
  static TextStyle get ticket => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        height: 1.0,
        letterSpacing: 0.5,
      );

  // ─── Helper: TextTheme untuk MaterialApp ─────────────────────────────────

  /// Menghasilkan [TextTheme] untuk digunakan di [ThemeData].
  static TextTheme get textTheme => GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          titleSmall: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.surface,
          ),
        ),
      );
}
