// lib/features/dashboard/presentation/screens/dashboard_screen.dart
//
// Skeleton Screen: Dashboard Foundation.
// Sumber: SKILLS.md §3, PROJECT-SETUP.md §11.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Foundation Screen untuk Dashboard.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final connectivityAsync = ref.watch(connectivityStatusProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard MutasiKu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              ref.read(authStateProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connectivity Status Banner
            connectivityAsync.when(
              data: (status) {
                if (status == ConnectivityStatus.offline) {
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.wifi_off, color: AppColors.warning, size: 18),
                        SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            'Anda sedang offline. Sinyal koneksi terputus.',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (error, stackTrace) => const SizedBox.shrink(),
            ),

            // User Info Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          user?.name ?? 'Pengguna MutasiKu',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (user != null)
                          StatusBadge.info(user.role.label),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      user?.email ?? '-',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (user?.department != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Departemen: ${user!.department}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textDisabled,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            const Text(
              'MutasiKu Foundation Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Flutter Foundation siap. Seluruh arsitektur core, token desain, routing, auth skeleton, dan error handling telah berhasil diinisialisasi.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            CustomButton(
              label: 'Keluar (Logout)',
              variant: ButtonVariant.outline,
              onPressed: () {
                ref.read(authStateProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}
