// lib/features/kadiv/presentation/screens/kadiv_dashboard_screen.dart
//
// Dashboard Screen untuk Role: Kadiv (KDV-001).
// Sumber: ROLE-FLOW.md §6, SCREEN-SPEC.md KDV-001, DESIGN.md.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/role_dashboard_layout.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../providers/kadiv_approval_provider.dart';

class KadivDashboardScreen extends ConsumerWidget {
  const KadivDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userName = authState.user?.name ?? 'Kepala Divisi';
    final stats = ref.watch(kadivStatsProvider);
    final asyncMutations = ref.watch(kadivAllMutationsProvider);

    return RoleDashboardLayout(
      title: 'Dashboard Kadiv',
      selectedIndex: 0,
      onNavDestinationSelected: (index) {
        switch (index) {
          case 1:
            context.push(RouteNames.kadivApprovalsPath);
            break;
          case 2:
            context.push(RouteNames.kadivNotificationsPath);
            break;
          case 3:
            context.push(RouteNames.profilePath);
            break;
        }
      },
      navItems: const [
        RoleNavItem(label: 'Home', icon: Icons.home_outlined),
        RoleNavItem(label: 'Approval', icon: Icons.verified_user_outlined),
        RoleNavItem(label: 'Notifikasi', icon: Icons.notifications_outlined),
        RoleNavItem(label: 'Profil', icon: Icons.person_outline),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting Header
          Text(
            'Halo, $userName',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Tinjau dan putuskan pengajuan mutasi aset dengan kriteria khusus tingkat Kepala Divisi.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Stat Cards (Menunggu Approval, Disetujui, Ditolak)
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Menunggu Approval',
                  count: stats.waitingApprovalCount,
                  icon: Icons.pending_actions_rounded,
                  color: AppColors.warning,
                  bgColor: AppColors.warningContainer,
                  onTap: () {
                    ref.read(kadivStatusFilterProvider.notifier).state =
                        KadivStatusFilter.waiting;
                    context.push(RouteNames.kadivApprovalsPath);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildStatCard(
                  title: 'Disetujui',
                  count: stats.approvedCount,
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                  bgColor: AppColors.successContainer,
                  onTap: () {
                    ref.read(kadivStatusFilterProvider.notifier).state =
                        KadivStatusFilter.approved;
                    context.push(RouteNames.kadivApprovalsPath);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildStatCard(
                  title: 'Ditolak',
                  count: stats.rejectedCount,
                  icon: Icons.cancel_outlined,
                  color: AppColors.error,
                  bgColor: AppColors.errorContainer,
                  onTap: () {
                    ref.read(kadivStatusFilterProvider.notifier).state =
                        KadivStatusFilter.rejected;
                    context.push(RouteNames.kadivApprovalsPath);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Primary Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('btn_lihat_approval_kadiv'),
              onPressed: () {
                ref.read(kadivStatusFilterProvider.notifier).state =
                    KadivStatusFilter.waiting;
                context.push(RouteNames.kadivApprovalsPath);
              },
              icon: const Icon(Icons.verified_user_outlined),
              label: const Text(
                'Lihat Antrean Approval Kadiv',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Section Pengajuan Terbaru
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pengajuan Terbaru',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(kadivStatusFilterProvider.notifier).state =
                      KadivStatusFilter.all;
                  context.push(RouteNames.kadivApprovalsPath);
                },
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          asyncMutations.when(
            data: (mutations) {
              // Filter yang relevan untuk Kadiv: pengajuan yang menunggu keputusan Kadiv
              final relevant = mutations
                  .where((m) => m.status == MutationStatus.waitingKadivApproval)
                  .take(5)
                  .toList();

              if (relevant.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 44,
                        color: AppColors.success,
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        'Tidak Ada Antrean Approval',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        'Seluruh mutasi yang memerlukan keputusan Kadiv telah selesai diproses.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: relevant.map((mutation) {
                  return _buildRecentCard(context, mutation);
                }).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.error),
              ),
              child: Text(
                'Gagal memuat mutasi: $err',
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCard(BuildContext context, Mutation item) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        key: Key('card_recent_kadiv_${item.id}'),
        onTap: () {
          context.push('/kadiv/approvals/${item.id}');
        },
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ticket & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.ticketNumber,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: item.status.backgroundColor,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      item.status.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: item.status.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Asset Name
              Text(
                item.asset.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),

              // Target Location & Applicant
              Text(
                'Tujuan: ${item.targetLocation} • Pemohon: ${item.applicantName}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),

              // Info Approval Kabag jika ada
              if (item.approvedBy != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 14,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Disetujui Kabag: ${item.approvedBy}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
