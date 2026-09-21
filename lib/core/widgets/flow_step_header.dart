// lib/core/widgets/flow_step_header.dart
//
// Widget kecil untuk menunjukkan posisi pengguna di alur bertahap
// (mis. Pilih Aset -> Isi Form -> Selesai), supaya alur "di mana saya
// sekarang & bagaimana caranya kembali" lebih jelas bagi Pemohon.

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

class FlowStepHeader extends StatelessWidget {
  /// Index langkah saat ini (0-based).
  final int currentStep;

  /// Label tiap langkah, mis. ['Pilih Aset', 'Isi Data Mutasi'].
  final List<String> steps;

  const FlowStepHeader({
    super.key,
    required this.currentStep,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.surface,
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            _StepDot(
              index: i + 1,
              label: steps[i],
              isActive: i == currentStep,
              isDone: i < currentStep,
            ),
            if (i != steps.length - 1)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: i < currentStep ? AppColors.primary : AppColors.border,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int index;
  final String label;
  final bool isActive;
  final bool isDone;

  const _StepDot({
    required this.index,
    required this.label,
    required this.isActive,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    final color = (isActive || isDone)
        ? AppColors.primary
        : AppColors.textDisabled;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? AppColors.primary : Colors.transparent,
            border: Border.all(color: color, width: 2),
          ),
          alignment: Alignment.center,
          child: isDone
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : Text(
                  '$index',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
