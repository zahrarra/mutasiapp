import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';

class MutationStatusStepper extends StatelessWidget {
  final MutationStatus status;
  final Mutation? mutation;

  const MutationStatusStepper({
    super.key,
    required this.status,
    this.mutation,
  });

  /// Daftar label sesuai flow mutasi yang dipersyaratkan:
  /// Diajukan -> Verifikasi Operator -> Approval Kabag Aset -> Approval Kadiv -> Update Staf Aset -> Selesai/Konfirmasi
  static const _labels = [
    'Diajukan',
    'Verifikasi Operator',
    'Approval Kabag Aset',
    'Approval Kadiv',
    'Update Staf Aset',
    'Selesai/Konfirmasi',
  ];

  int get _activeIndex {
    switch (status) {
      case MutationStatus.submitted:
      case MutationStatus.returned:
        // Langkah 'Diajukan' telah selesai, saat ini menunggu / proses 'Verifikasi Operator'
        return 1;
      case MutationStatus.verified:
      case MutationStatus.waitingKabagApproval:
        // 'Diajukan' dan 'Verifikasi Operator' telah selesai, saat ini 'Approval Kabag Aset'
        return 2;
      case MutationStatus.waitingKadivApproval:
        // 'Diajukan', 'Verifikasi', dan 'Approval Kabag' selesai, saat ini 'Approval Kadiv'
        return 3;
      case MutationStatus.approved:
        // Seluruh approval selesai, saat ini 'Update Staf Aset'
        return 4;
      case MutationStatus.pendingConfirmation:
        // Update data oleh staf aset selesai, saat ini menunggu 'Selesai/Konfirmasi' oleh Pemohon
        return 5;
      case MutationStatus.completed:
        // Semua tahapan selesai (100% complete)
        return 6;
      case MutationStatus.rejected:
        // Jika penolakan terjadi di Kadiv, posisi di Approval Kadiv; jika di Kabag, posisi di Approval Kabag
        if (mutation?.kadivRejectedAt != null ||
            mutation?.kadivRejectionReason != null) {
          return 3;
        }
        return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeIndex;
    final isAllDone = status == MutationStatus.completed;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(_labels.length, (i) {
        final done = isAllDone || i < active;
        final current = !isAllDone && i == active;
        final circleBorderColor =
            done || current ? AppColors.primary : AppColors.border;

        // Garis kiri menghubungkan step (i-1) ke step i. Aktif bila step i tercapai.
        final leftLineColor =
            (isAllDone || i <= active) ? AppColors.primary : AppColors.border;

        // Garis kanan menghubungkan step i ke step (i+1). Aktif bila step (i+1) tercapai.
        final rightLineColor =
            (isAllDone || i < active) ? AppColors.primary : AppColors.border;

        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: i > 0
                        ? Container(height: 2, color: leftLineColor)
                        : const SizedBox.shrink(),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done
                          ? AppColors.primary
                          : current
                              ? AppColors.surface
                              : AppColors.disabledBackground,
                      border: Border.all(color: circleBorderColor, width: 2),
                    ),
                    child: done
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                  Expanded(
                    child: i < _labels.length - 1
                        ? Container(height: 2, color: rightLineColor)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _labels[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: current ? FontWeight.bold : FontWeight.normal,
                  color: current
                      ? AppColors.primary
                      : done
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
