// lib/features/kabag/presentation/screens/kabag_dashboard_screen.dart
//
// Dashboard Screen untuk Role: Kabag Aset (KBG-001).
// Sumber: ROLE-FLOW.md §5, SCREEN-SPEC.md KBG-001, WIREFRAME.md §7.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/role_dashboard_layout.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../providers/kabag_approval_provider.dart';

class KabagDashboardScreen extends ConsumerWidget {
  const KabagDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userName = authState.user?.name ?? 'Kabag Aset';
    final stats = ref.watch(kabagStatsProvider);
    final asyncMutations = ref.watch(kabagAllMutationsProvider);

    return RoleDashboardLayout(
      title: 'Dashboard Kabag Aset',
      selectedIndex: 0,
      onNavDestinationSelected: (index) {
        switch (index) {
          case 1:
            context.push(RouteNames.kabagApprovalsPath);
            break;
          case 2:
            context.push(RouteNames.kabagNotificationsPath);
            break;
          case 3:
            context.push(RouteNames.profilePath);
            break;
        }
      },
      navItems: const [
        RoleNavItem(label: 'Home', icon: Icons.home_outlined),
        RoleNavItem(label: 'Approval', icon: Icons.how_to_reg_outlined),
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
            'Tinjau dan berikan persetujuan atas pengajuan mutasi aset.',
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
                  onTap: () => context.push(RouteNames.kabagApprovalsPath),
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
                  onTap: () => context.push(RouteNames.kabagApprovalsPath),
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
                  onTap: () => context.push(RouteNames.kabagApprovalsPath),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Primary Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('btn_lihat_approval'),
              onPressed: () => context.push(RouteNames.kabagApprovalsPath),
              icon: const Icon(Icons.how_to_reg_outlined),
              label: const Text(
                'Lihat Daftar Approval',
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
                onPressed: () => context.push(RouteNames.kabagApprovalsPath),
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          asyncMutations.when(
            data: (mutations) {
              if (mutations.isEmpty) {
                return _buildEmptyState();
              }

              final recentMutations = mutations.take(3).toList();
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentMutations.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final item = recentMutations[index];
                  return _buildRecentCard(context, item);
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Center(
              child: Text(
                'Gagal memuat pengajuan: $err',
                style: const TextStyle(color: AppColors.error),
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
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: bgColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 20),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCard(BuildContext context, Mutation item) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        title: Text(
          item.ticketNumber,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              item.asset.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Pemohon: ${item.applicantName}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
        onTap: () {
          context.push('/kabag/approvals/${item.id}');
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_outlined, size: 40, color: AppColors.textSecondary),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Belum ada pengajuan',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
