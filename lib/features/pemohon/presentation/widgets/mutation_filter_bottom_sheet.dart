// lib/features/pemohon/presentation/widgets/mutation_filter_bottom_sheet.dart
//
// Bottom sheet filter status mutasi untuk Pemohon.
// Sumber: SCREEN-SPEC.md REQ-002, DESIGN.md.

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../mutation/domain/entities/mutation_status.dart';

/// Item pilihan filter status
class FilterStatusItem {
  final MutationStatus? status;
  final String label;

  const FilterStatusItem({required this.status, required this.label});
}

const List<FilterStatusItem> mutationFilterOptions = [
  FilterStatusItem(status: null, label: 'Semua Status'),
  FilterStatusItem(
    status: MutationStatus.submitted,
    label: 'Diajukan',
  ),
  FilterStatusItem(
    status: MutationStatus.returned,
    label: 'Dikembalikan ke Pemohon',
  ),
  FilterStatusItem(
    status: MutationStatus.waitingKabagApproval,
    label: 'Menunggu Approval Kabag',
  ),
  FilterStatusItem(
    status: MutationStatus.approved,
    label: 'Disetujui',
  ),
  FilterStatusItem(
    status: MutationStatus.rejected,
    label: 'Ditolak',
  ),
  FilterStatusItem(
    status: MutationStatus.pendingConfirmation,
    label: 'Menunggu Konfirmasi',
  ),
  FilterStatusItem(
    status: MutationStatus.completed,
    label: 'Selesai',
  ),
];

/// Menampilkan bottom sheet filter status mutasi
Future<MutationStatus?> showMutationFilterBottomSheet({
  required BuildContext context,
  required MutationStatus? currentStatus,
  Map<MutationStatus?, int>? counts,
}) {
  return showModalBottomSheet<MutationStatus?>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.75,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle Bar ─────────────────────────────────────────
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // ── Header ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter Status Mutasi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (currentStatus != null)
                      TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop(null);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),

              // ── Options List ───────────────────────────────────────
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  itemCount: mutationFilterOptions.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, indent: 40),
                  itemBuilder: (context, index) {
                    final item = mutationFilterOptions[index];
                    final isSelected = currentStatus == item.status;
                    final count = counts?[item.status];

                    return InkWell(
                      onTap: () => Navigator.of(ctx).pop(item.status),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: item.status == null
                                    ? AppColors.primary
                                    : item.status!.color,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (count != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withValues(alpha: 0.15)
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 20,
                                color: AppColors.primary,
                              )
                            else
                              const SizedBox(width: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
