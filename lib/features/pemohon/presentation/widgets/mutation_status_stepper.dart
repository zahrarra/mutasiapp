import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../mutation/domain/entities/mutation_status.dart';

class MutationStatusStepper extends StatelessWidget {
  final MutationStatus status;

  const MutationStatusStepper({super.key, required this.status});

  int get _activeIndex {
    switch (status) {
      case MutationStatus.submitted:
        return 0;
      case MutationStatus.returned:
        return 0;
      case MutationStatus.verified:
      case MutationStatus.waitingKabagApproval:
      case MutationStatus.waitingKadivApproval:
        return 1;
      case MutationStatus.approved:
        return 2;
      case MutationStatus.pendingConfirmation:
        return 3;
      case MutationStatus.completed:
        return 4;
      case MutationStatus.rejected:
        return 1;
    }
  }

  static const _labels = [
    'Diajukan',
    'Verifikasi',
    'Approval',
    'Update',
    'Selesai',
  ];

  @override
  Widget build(BuildContext context) {
    final active = _activeIndex;

    return Row(
      children: List.generate(_labels.length, (i) {
        final done = i < active;
        final current = i == active;
        final color = done || current ? AppColors.primary : AppColors.border;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (i > 0)
                    Expanded(child: Container(height: 2, color: color)),
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
                      border: Border.all(color: color, width: 2),
                    ),
                    child: done
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                  if (i < _labels.length - 1)
                    Expanded(child: Container(height: 2, color: color)),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _labels[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: current ? FontWeight.bold : FontWeight.normal,
                  color: current ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
