// lib/features/asset/presentation/widgets/asset_card.dart
//
// Widget: AssetCard (Kartu informasi aset).
// Sumber: SCREEN-SPEC.md, DESIGN.md.

import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/asset.dart';
import 'asset_status_badge.dart';

/// Widget Kartu Aset standar MutasiKu dengan indikator Asset Lock.
class AssetCard extends StatelessWidget {
  final Asset asset;
  final VoidCallback? onTap;

  const AssetCard({
    super.key,
    required this.asset,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(
          color: asset.isLocked ? AppColors.warning : AppColors.border,
          width: asset.isLocked ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Asset Code & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      asset.assetCode,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  AssetStatusBadge(status: asset.status, isLocked: asset.isLocked),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),

              // Asset Name
              Text(
                asset.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // Category & Location
              Row(
                children: [
                  const Icon(Icons.category_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    asset.category.name,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.xxs),
                  Expanded(
                    child: Text(
                      asset.location,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),

              // PIC
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: AppColors.textDisabled),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    'PIC: ${asset.pic}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textDisabled),
                  ),
                ],
              ),

              // Asset Lock Alert Banner
              if (asset.isLocked) ...[
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warningContainer,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock, size: 12, color: AppColors.warning),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        'Aset Terkunci (${asset.activeMutationTicket ?? "Mutasi Aktif"})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
