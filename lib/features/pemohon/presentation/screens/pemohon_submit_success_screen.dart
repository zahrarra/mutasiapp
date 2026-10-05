import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/mutasiku_page_header.dart';

class PemohonSubmitSuccessScreen extends StatelessWidget {
  final String ticketNumber;
  final String mutationId;

  const PemohonSubmitSuccessScreen({
    super.key,
    required this.ticketNumber,
    required this.mutationId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SafeArea(
            bottom: false,
            child: MutasiKuPageHeader(
              title: 'Pengajuan Terkirim',
              subtitle: 'Tiket berhasil dibuat dan dalam proses',
              onBack: () => context.go(RouteNames.pemohonDashboardPath),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  const Icon(
                    Icons.check_circle,
                    size: 72,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    'Pengajuan Berhasil Dikirim',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Pengajuan mutasi aset Anda telah dikirim untuk diverifikasi Operator.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Card(
                    elevation: 0,
                    color: AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          const Text(
                            'NO. TIKET',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            ticketNumber,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => context.go(
                        RouteNames.pemohonMutasiDetailPath.replaceFirst(
                          ':id',
                          mutationId,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Lihat Detail Mutasi'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => context.go(RouteNames.pemohonMutasiPath),
                      child: const Text('Lihat Mutasi Saya'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
