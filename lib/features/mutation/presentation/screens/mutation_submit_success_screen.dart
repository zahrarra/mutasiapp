// lib/features/mutation/presentation/screens/mutation_submit_success_screen.dart
//
// Screen: Konfirmasi Sukses Pengajuan Mutasi (REQ-006).
// Sumber: SCREEN-SPEC.md REQ-006, ROLE-FLOW.md §3.
//
// Langkah terakhir dari alur Pengajuan Mutasi: menampilkan nomor tiket
// hasil generate server dan navigasi kembali ke Mutasi Saya / Dashboard.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/custom_button.dart';

/// Screen konfirmasi sukses setelah pengajuan mutasi berhasil dikirim.
class MutationSubmitSuccessScreen extends StatelessWidget {
  final String? ticketNumber;

  const MutationSubmitSuccessScreen({super.key, this.ticketNumber});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    color: AppColors.successContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 56,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                const Text(
                  'Pengajuan Berhasil Dikirim!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Pengajuan mutasi Anda telah diterima dan akan diverifikasi oleh Operator.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: AppSpacing.xxl),
                if (ticketNumber != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Nomor Tiket',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          ticketNumber!,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.xxxl),
                CustomButton(
                  label: 'Lihat Mutasi Saya',
                  width: double.infinity,
                  onPressed: () => context.go(RouteNames.pemohonMutasiPath),
                ),
                const SizedBox(height: AppSpacing.sm),
                CustomButton(
                  label: 'Kembali ke Dashboard',
                  variant: ButtonVariant.text,
                  width: double.infinity,
                  onPressed: () => context.go(RouteNames.pemohonDashboardPath),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
