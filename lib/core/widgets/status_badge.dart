// lib/core/widgets/status_badge.dart
//
// Shared widget: StatusBadge.
// Sumber: PROJECT-SETUP.md §21, DESIGN.md.
// DESIGN.md §3: Radius badge = 999px (pill).
// DESIGN.md §2: Status badge = Icon + Text + Color.

import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

/// Badge status umum aplikasi MutasiKu.
///
/// Menggunakan pill radius (999px) sesuai DESIGN.md §3.
/// Optional [icon] untuk mendukung "Icon + Text + Color" sesuai DESIGN.md §2.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory StatusBadge.success(String label, {IconData? icon}) => StatusBadge(
        label: label,
        backgroundColor: AppColors.successContainer,
        textColor: AppColors.success,
        icon: icon,
      );

  factory StatusBadge.warning(String label, {IconData? icon}) => StatusBadge(
        label: label,
        backgroundColor: AppColors.warningContainer,
        textColor: AppColors.warning,
        icon: icon,
      );

  factory StatusBadge.error(String label, {IconData? icon}) => StatusBadge(
        label: label,
        backgroundColor: AppColors.errorContainer,
        textColor: AppColors.error,
        icon: icon,
      );

  factory StatusBadge.info(String label, {IconData? icon}) => StatusBadge(
        label: label,
        backgroundColor: AppColors.infoContainer,
        textColor: AppColors.info,
        icon: icon,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + AppSpacing.xxs, // 10px
        vertical: AppSpacing.xs,                    // 4px
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
