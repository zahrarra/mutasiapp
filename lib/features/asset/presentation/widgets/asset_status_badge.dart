// lib/features/asset/presentation/widgets/asset_status_badge.dart
//
// Widget Badge Status Aset.
// Sumber: DESIGN.md.
// DESIGN.md §3: Radius badge = 999px (pill).
// DESIGN.md §2: Status badge = Icon + Text + Color.

import 'package:flutter/material.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/asset_status.dart';

class AssetStatusBadge extends StatelessWidget {
  final AssetStatus status;
  final bool isLocked;

  const AssetStatusBadge({
    super.key,
    required this.status,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + AppSpacing.xxs, // 10px
        vertical: AppSpacing.xs,                    // 4px
      ),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLocked) ...[
            Icon(Icons.lock_clock, size: 12, color: status.color),
            const SizedBox(width: 4),
          ],
          Text(
            status.displayName,
            style: TextStyle(
              color: status.color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
