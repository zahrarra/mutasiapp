// lib/features/pemohon/presentation/screens/PemohonDashboardScreen.dart
//
// Dashboard Screen untuk Role: Pemohon.
// Sumber: ROLE-FLOW.md §3, SCREEN-SPEC.md REQ-001, WIREFRAME.md §2.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/router/route_names.dart';
import '../../../auth/presentation/widgets/role_dashboard_layout.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';

class PemohonDashboardScreen extends ConsumerStatefulWidget {
  const PemohonDashboardScreen({super.key});

  @override
  ConsumerState<PemohonDashboardScreen> createState() =>
      _PemohonDashboardScreenState();
}

class _PemohonDashboardScreenState
    extends ConsumerState<PemohonDashboardScreen> {
  int _selectedIndex = 0;

  void _onNavDestinationSelected(int index) {
    if (index == 0) {
      // Home — already here
      setState(() => _selectedIndex = 0);
      return;
    }
    if (index == 1) {
      // Mutasi Saya — belum ada route terdaftar, tampilkan snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daftar Mutasi Saya segera tersedia.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    if (index == 2) {
      // Notifikasi
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifikasi segera tersedia.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    if (index == 3) {
      // Profil
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil segera tersedia.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncMutations = ref.watch(mutationListProvider);

    return RoleDashboardLayout(
      title: 'Dashboard Pemohon',
      selectedIndex: _selectedIndex,
      onNavDestinationSelected: _onNavDestinationSelected,
      navItems: const [
        RoleNavItem(label: 'Home', icon: Icons.home_outlined),
        RoleNavItem(label: 'Mutasi Saya', icon: Icons.assignment_outlined),
        RoleNavItem(label: 'Notifikasi', icon: Icons.notifications_outlined),
        RoleNavItem(label: 'Profil', icon: Icons.person_outline),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Summary Stats ───────────────────────────────────────────────
          asyncMutations.when(
            data: (mutations) {
              final diproses = mutations
                  .where((m) =>
                      m.status != MutationStatus.completed &&
                      m.status != MutationStatus.rejected)
                  .length;
              final selesai = mutations
                  .where((m) => m.status == MutationStatus.completed)
                  .length;
              final konfirmasi = mutations
                  .where(
                      (m) => m.status == MutationStatus.pendingConfirmation)
                  .length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ringkasan Pengajuan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          label: 'Diproses',
                          count: diproses,
                          color: AppColors.warning,
                          backgroundColor: AppColors.warningContainer,
                          icon: Icons.hourglass_empty_outlined,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildStatCard(
                          label: 'Selesai',
                          count: selesai,
                          color: AppColors.success,
                          backgroundColor: AppColors.successContainer,
                          icon: Icons.check_circle_outline,
                        ),
                      ),
                      if (konfirmasi > 0) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _buildStatCard(
                            label: 'Perlu Konfirmasi',
                            count: konfirmasi,
                            color: AppColors.error,
                            backgroundColor: AppColors.errorContainer,
                            icon: Icons.pending_actions_outlined,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.md),

          // ─── Action Card — Buat Pengajuan Mutasi ─────────────────────────
          const Text(
            'Layanan Pengajuan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            onTap: () {
              // Navigasi ke pilih aset / create mutation
              // Route pemohonMutasiPath belum terdaftar, tampilkan snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fitur Buat Pengajuan segera tersedia.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.add_to_photos_outlined,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buat Pengajuan Mutasi Baru',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Pilih aset & isi formulir mutasi lokasi/PIC',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward, color: Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ─── Pengajuan Menunggu Konfirmasi ───────────────────────────────
          asyncMutations.when(
            data: (mutations) {
              final pendingList = mutations
                  .where(
                      (m) => m.status == MutationStatus.pendingConfirmation)
                  .toList();

              if (pendingList.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.pending_actions_outlined,
                        size: 16,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Menunggu Konfirmasi (${pendingList.length})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...pendingList.map((mutation) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: InkWell(
                          onTap: () {
                            context.goNamed(
                              RouteNames.pemohonConfirmationName,
                              pathParameters: {'id': mutation.id},
                            );
                          },
                          borderRadius:
                              BorderRadius.circular(AppRadius.card),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.card),
                              border:
                                  Border.all(color: AppColors.errorContainer),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mutation.ticketNumber,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        mutation.asset.name,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.xxs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.errorContainer,
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.pill),
                                  ),
                                  child: const Text(
                                    'Konfirmasi',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // ─── Pengajuan Terbaru ───────────────────────────────────────────
          asyncMutations.when(
            data: (mutations) {
              if (mutations.isEmpty) {
                return Column(
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 48,
                            color: AppColors.textSecondary.withAlpha(100),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          const Text(
                            'Belum ada pengajuan.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              final recent = mutations.take(3).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pengajuan Terbaru',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...recent.map((mutation) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: InkWell(
                          onTap: () {
                            // Navigasi ke detail — route belum terdaftar
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Detail ${mutation.ticketNumber} segera tersedia.'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          borderRadius:
                              BorderRadius.circular(AppRadius.card),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.card),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mutation.ticketNumber,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        mutation.asset.name,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xxs),
                                      Text(
                                        '${mutation.currentLocation} → ${mutation.targetLocation}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.xxs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: mutation.status.backgroundColor,
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.pill),
                                  ),
                                  child: Text(
                                    mutation.status.displayName,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: mutation.status.color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Column(
              children: [
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Ringkasan belum dapat dimuat.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                TextButton.icon(
                  onPressed: () => ref.invalidate(mutationListProvider),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required int count,
    required Color color,
    required Color backgroundColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
