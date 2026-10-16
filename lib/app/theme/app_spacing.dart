// lib/app/theme/app_spacing.dart
//
// Centralized design token: spacing dan border radius.
// Sumber: DESIGN.md §9–11, PROJECT-SETUP.md §6.

/// Konstanta spacing MutasiKu.
///
/// Base unit: 4px.
/// Scale: 4, 8, 12, 16, 20, 24, 32, 40, 48, 64.
abstract final class AppSpacing {
  // ─── Spacing scale ───────────────────────────────────────────────────────

  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 40.0;
  static const double giant = 48.0;
  static const double massive = 64.0;

  // Radius aliases
  static const double radiusSm = AppRadius.small;
  static const double radiusMd = AppRadius.input;
  static const double radiusLg = AppRadius.card;

  // ─── Semantic aliases ────────────────────────────────────────────────────

  /// Padding horizontal screen
  static const double screenHorizontal = lg; // 16

  /// Padding vertikal section
  static const double sectionVertical = xxl; // 24

  /// Jarak antar komponen dalam form
  static const double formFieldGap = lg; // 16

  /// Jarak antar komponen dalam card
  static const double cardContentGap = sm; // 8

  /// Touch target minimum 44px, implementasi target 48px (AGENTS.md §16)
  static const double touchTarget = 48.0;

  /// Button height
  static const double buttonHeight = 48.0;
}

/// Konstanta border radius MutasiKu.
///
/// Sumber: DESIGN.md §11.
abstract final class AppRadius {
  static const double small = 4.0;
  static const double button = 8.0;
  static const double input = 8.0;
  static const double card = 12.0;
  static const double md = 12.0;
  static const double large = 16.0;
  static const double lg = 16.0;
  static const double xlarge = 24.0;
  static const double pill = 999.0;
}
