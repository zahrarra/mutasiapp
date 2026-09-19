import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../mutation/domain/entities/mutation.dart';

class PemohonMutationCard extends StatelessWidget {
  final Mutation mutation;
  final VoidCallback? onTap;
  final Widget? trailingAction;

  const PemohonMutationCard({
    super.key,
    required this.mutation,
    this.onTap,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    final status = mutation.status;

    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      mutation.ticketNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  StatusBadge(
                    label: status.displayName,
                    backgroundColor: status.backgroundColor,
                    textColor: status.color,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                mutation.asset.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                mutation.asset.assetCode,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${mutation.currentLocation} → ${mutation.targetLocation}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              if (trailingAction != null) ...[
                const SizedBox(height: AppSpacing.md),
                trailingAction!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
