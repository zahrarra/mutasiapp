// lib/app/theme/app_colors.dart
//
// Centralized design token: warna.
// Sumber: DESIGN.md §4, PROJECT-SETUP.md §6, AGENTS.md §17.
//
// ATURAN: Jangan hardcode warna langsung di widget.
// Gunakan AppColors atau Theme.of(context).colorScheme.

import 'package:flutter/material.dart';

/// Semua konstanta warna MutasiKu.
///
/// Jangan menambahkan warna baru tanpa konfirmasi design system.
abstract final class AppColors {
  // ─── Brand ───────────────────────────────────────────────────────────────

  /// Primary — #0F3D56
  /// Digunakan: primary button, active nav, heading, brand element.
  static const Color primary = Color(0xFF0F3D56);

  /// Primary container (light tinted background for brand element)
  static const Color primaryContainer = Color(0xFFE0F2FE);

  /// Secondary — #0F766E
  /// Digunakan: secondary emphasis, supporting interactive elements.
  static const Color secondary = Color(0xFF0F766E);

  // ─── Background / Surface ────────────────────────────────────────────────

  /// Screen background — #F6F8FA
  static const Color background = Color(0xFFF6F8FA);

  /// Card / form surface — #FFFFFF
  static const Color surface = Color(0xFFFFFFFF);

  // ─── Text ────────────────────────────────────────────────────────────────

  /// Text primary — #172B4D
  static const Color textPrimary = Color(0xFF172B4D);

  /// Text secondary — #52606D
  static const Color textSecondary = Color(0xFF52606D);

  /// Text disabled — #98A2B3
  static const Color textDisabled = Color(0xFF98A2B3);

  // ─── Border / Divider ────────────────────────────────────────────────────

  /// Border / divider — #D0D5DD
  static const Color border = Color(0xFFD0D5DD);

  // ─── Semantic ────────────────────────────────────────────────────────────

  /// Success — #15803D
  /// Status: Selesai, Disetujui.
  static const Color success = Color(0xFF15803D);

  /// Success container (background for badge)
  static const Color successContainer = Color(0xFFDCFCE7);

  /// Warning — #B45309
  /// Status: Menunggu, Dikembalikan.
  static const Color warning = Color(0xFFB45309);

  /// Warning container
  static const Color warningContainer = Color(0xFFFEF3C7);

  /// Error — #B42318
  /// Status: Ditolak, Error, Destructive action.
  static const Color error = Color(0xFFB42318);

  /// Error container
  static const Color errorContainer = Color(0xFFFEE2E2);

  /// Info — #175CD3
  /// Status: Diajukan, Informasi sistem.
  static const Color info = Color(0xFF175CD3);

  /// Info container
  static const Color infoContainer = Color(0xFFDBEAFE);

  // ─── Interaction ─────────────────────────────────────────────────────────

  /// Warna disabled untuk komponen interaktif
  static const Color disabled = Color(0xFF98A2B3);

  /// Background disabled
  static const Color disabledBackground = Color(0xFFF2F4F7);

  // ─── Offline indicator ───────────────────────────────────────────────────

  /// Banner offline — menggunakan warning
  static const Color offlineBanner = Color(0xFFFEF3C7);

  /// Teks banner offline
  static const Color offlineBannerText = Color(0xFF92400E);

  // Aliases for convenience
  static const Color successLight = successContainer;
  static const Color warningLight = warningContainer;
  static const Color errorLight = errorContainer;
  static const Color infoLight = infoContainer;
}
