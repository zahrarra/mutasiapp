import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../../../mutation/presentation/models/mutation_tracking_step.dart';

/// Stepper horizontal alur mutasi yang merefleksikan status mutasi riil.
/// Sumber kebenaran tunggal: [MutationStatus] dan [Mutation.requiresKadivApproval].
class MutationStatusStepper extends StatelessWidget {
  final MutationStatus status;
  final Mutation? mutation;

  const MutationStatusStepper({
    super.key,
    required this.status,
    this.mutation,
  });

  @override
  Widget build(BuildContext context) {
    final steps = MutationTrackingHelper.getStepsForMutation(
      status,
      mutation: mutation,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (i) {
        final step = steps[i];
        final done = step.isCompleted;
        final current = step.isCurrent;
        final alert = step.isAlert;

        // Lingkaran step
        Color circleBg;
        Color circleBorder;
        Widget? iconChild;

        if (alert) {
          circleBg = AppColors.error;
          circleBorder = AppColors.error;
          iconChild = const Icon(Icons.close, size: 12, color: Colors.white);
        } else if (done) {
          circleBg = AppColors.primary;
          circleBorder = AppColors.primary;
          iconChild = const Icon(Icons.check, size: 12, color: Colors.white);
        } else if (current) {
          circleBg = AppColors.surface;
          circleBorder = AppColors.primary;
          iconChild = Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
          );
        } else {
          circleBg = AppColors.disabledBackground;
          circleBorder = AppColors.border;
          iconChild = null;
        }

        // Garis penghubung
        final leftLineActive = i > 0 &&
            (step.isCompleted || step.isCurrent || step.isAlert);
        final rightLineActive = i < steps.length - 1 &&
            (steps[i + 1].isCompleted ||
                steps[i + 1].isCurrent ||
                steps[i + 1].isAlert);

        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: i > 0
                        ? Container(
                            height: 2,
                            color: leftLineActive
                                ? AppColors.primary
                                : AppColors.border,
                          )
                        : const SizedBox.shrink(),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: circleBg,
                      border: Border.all(color: circleBorder, width: 2),
                    ),
                    child: Center(child: iconChild),
                  ),
                  Expanded(
                    child: i < steps.length - 1
                        ? Container(
                            height: 2,
                            color: rightLineActive
                                ? AppColors.primary
                                : AppColors.border,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                step.shortLabel,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: current || alert
                      ? FontWeight.bold
                      : done
                          ? FontWeight.w600
                          : FontWeight.normal,
                  color: alert
                      ? AppColors.error
                      : current
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
