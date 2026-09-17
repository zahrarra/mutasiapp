// lib/app/theme/app_theme.dart
//
// ThemeData terpusat MutasiKu.
// Sumber: DESIGN.md, PROJECT-SETUP.md §6–7.
//
// ATURAN:
// - Gunakan Theme.of(context).colorScheme atau AppColors di widget.
// - Jangan hardcode Colors.blue / Colors.red di widget.

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// ThemeData untuk MutasiKu.
///
/// Gunakan [AppTheme.light] sebagai [MaterialApp.theme].
abstract final class AppTheme {
  /// Light theme alias untuk MaterialApp integration.
  static ThemeData get lightTheme => light;

  /// Light theme — satu-satunya theme yang digunakan MVP.
  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,

      // Primary
      primary: AppColors.primary,
      onPrimary: AppColors.surface,
      primaryContainer: AppColors.infoContainer,
      onPrimaryContainer: AppColors.primary,

      // Secondary
      secondary: AppColors.secondary,
      onSecondary: AppColors.surface,
      secondaryContainer: AppColors.infoContainer,
      onSecondaryContainer: AppColors.secondary,

      // Tertiary (unused, set to secondary for completeness)
      tertiary: AppColors.secondary,
      onTertiary: AppColors.surface,

      // Error
      error: AppColors.error,
      onError: AppColors.surface,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.error,

      // Background / Surface
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.background,
      onSurfaceVariant: AppColors.textSecondary,

      // Outline
      outline: AppColors.border,
      outlineVariant: AppColors.border,

      // Inverse
      inversePrimary: AppColors.background,
      inverseSurface: AppColors.primary,
      onInverseSurface: AppColors.surface,

      // Shadow / scrim
      shadow: Colors.black12,
      scrim: Colors.black26,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      // Typography
      textTheme: AppTypography.textTheme,

      // Scaffold
      scaffoldBackgroundColor: AppColors.background,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: AppTypography.h2,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      // ElevatedButton (AppButton.primary)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          disabledBackgroundColor: AppColors.disabledBackground,
          disabledForegroundColor: AppColors.disabled,
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          elevation: 0,
          textStyle: AppTypography.button,
        ),
      ),

      // OutlinedButton (AppButton.secondary)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.disabled,
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.md,
          ),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: AppTypography.buttonSecondary,
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.button.copyWith(color: AppColors.primary),
        ),
      ),

      // InputDecoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        labelStyle: AppTypography.body.copyWith(color: AppColors.textSecondary),
        hintStyle:
            AppTypography.body.copyWith(color: AppColors.textDisabled),
        errorStyle: AppTypography.caption.copyWith(color: AppColors.error),
      ),

      // Card
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 0,
      ),

      // ListTile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        tileColor: AppColors.surface,
        titleTextStyle: AppTypography.body,
        subtitleTextStyle: AppTypography.caption,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle:
            AppTypography.body.copyWith(color: AppColors.surface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // FloatingActionButton — minimal shadow sesuai DESIGN.md §12
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        elevation: 2,
      ),

      // ProgressIndicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
    );
  }
}
