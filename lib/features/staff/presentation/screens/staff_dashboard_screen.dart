// lib/features/staff/presentation/screens/staff_dashboard_screen.dart
//
// Dashboard Screen untuk Role: Staff Aset (STF-001).
// Sumber: ROLE-FLOW.md §7, WIREFRAME.md §2, SCREEN-SPEC.md STF-001.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/role_dashboard_layout.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../providers/staff_mutation_provider.dart';

class StaffAsetDashboardScreen extends ConsumerWidget {
  const StaffAsetDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userName = authState.user?.name ?? 'Staff Aset';
    final stats = ref.watch(staffStatsProvider);
    final asyncMutations = ref.watch(filteredStaffMutationsProvider);

    return RoleDashboardLayout(
      title: 'Dashboard Staff Aset',
      selectedIndex: 0,
      onNavDestinationSelected: (index) {
        switch (index) {
          case 1:
            context.push(RouteNames.staffMutationsPath);
            break;
          case 2:
            context.push(RouteNames.staffNotificationsPath);
            break;
          case 3:
            context.push(RouteNames.profilePath);
            break;
        }
      },
      navItems: const [
        RoleNavItem(label: 'Home', icon: Icons.home_outlined),
        RoleNavItem(label: 'Update Aset', icon: Icons.edit_location_alt_outlined),
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
            'Lakukan perpindahan fisik aset dan perbarui data lokasi & PIC.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Stat Card: Antrian Pembaruan Aset
          InkWell(
            key: const Key('card_stat_waiting_update'),
            onTap: () => context.push(RouteNames.staffMutationsPath),
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.successContainer,
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                      child: const Icon(
                        Icons.published_with_changes_outlined,
                        color: AppColors.success,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Menunggu Pembaruan Aset',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Pengajuan yang telah disetujui & siap di-update',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.infoContainer,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '${stats.waitingUpdateCount}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Section Header: Antrian Terkini
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Antrian Pembaruan Terkini',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (stats.waitingUpdateCount > 0)
                TextButton(
                  onPressed: () => context.push(RouteNames.staffMutationsPath),
                  child: const Text('Lihat Semua'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // List of mutations waiting for update
          asyncMutations.when(
            data: (mutations) {
              if (mutations.isEmpty) {
                return _buildEmptyState();
              }

              // Show top 3
              final displayList = mutations.take(3).toList();
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayList.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final item = displayList[index];
                  return _buildMutationCard(context, item);
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Gagal memuat antrian: $err',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.border),
      ),
      child: const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 44,
                color: AppColors.success,
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                'Tidak Ada Antrian Update',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Semua mutasi yang disetujui telah selesai diperbarui lokasinya.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMutationCard(BuildContext context, Mutation item) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        key: Key('card_staff_mutation_${item.id}'),
        onTap: () {
          context.push('/staff-aset/mutations/${item.id}');
        },
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      vertical: 3,
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
              const SizedBox(height: AppSpacing.xs),
              Text(
                item.asset.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${item.asset.assetCode} • ${item.asset.category.name}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const Divider(height: AppSpacing.md),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Tujuan: ${item.targetLocation}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'PIC Baru: ${item.targetPic}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
