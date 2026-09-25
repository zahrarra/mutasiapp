// lib/features/kabag/presentation/screens/kabag_approvals_screen.dart
//
// Screen: Daftar Pengajuan Menunggu Approval Kabag (KBG-002).
// Sumber: SCREEN-SPEC.md KBG-002, ROLE-FLOW.md §5, WIREFRAME.md §7.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../../core/widgets/custom_floating_nav_bar.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../providers/kabag_approval_provider.dart';

class KabagApprovalsScreen extends ConsumerStatefulWidget {
  const KabagApprovalsScreen({super.key});

  @override
  ConsumerState<KabagApprovalsScreen> createState() =>
      _KabagApprovalsScreenState();
}

class _KabagApprovalsScreenState extends ConsumerState<KabagApprovalsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncApprovals = ref.watch(filteredKabagApprovalsProvider);
    final sortOrder = ref.watch(kabagSortOrderProvider);
    final statusFilter = ref.watch(kabagStatusFilterProvider);

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(
          statusFilter == KabagStatusFilter.waiting
              ? 'Menunggu Approval'
              : statusFilter == KabagStatusFilter.approved
                  ? 'Riwayat Disetujui'
                  : statusFilter == KabagStatusFilter.rejected
                      ? 'Riwayat Ditolak'
                      : 'Semua Pengajuan',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.kabagDashboardPath);
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.surface,
            child: Column(
              children: [
                // Search Field
                TextField(
                  key: const Key('input_search_approvals'),
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari no. tiket, aset, pemohon, lokasi...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(kabagSearchQueryProvider.notifier).state =
                                  '';
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  onChanged: (value) {
                    ref.read(kabagSearchQueryProvider.notifier).state = value;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),

                // Compact Filter Bar (Status & Sort)
                Row(
                  children: [
                    // Status Filter Dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<KabagStatusFilter>(
                            key: const Key('dropdown_filter_kabag_status'),
                            value: statusFilter,
                            isDense: true,
                            isExpanded: true,
                            icon: const Icon(
                              Icons.filter_list,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            items: KabagStatusFilter.values.map((s) {
                              return DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s.displayName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                ref
                                    .read(kabagStatusFilterProvider.notifier)
                                    .state = val;
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),

                    // Sort Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<KabagSortOrder>(
                          key: const Key('dropdown_filter_kabag_sort'),
                          value: sortOrder,
                          isDense: true,
                          icon: const Icon(
                            Icons.sort,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          items: KabagSortOrder.values.map((order) {
                            return DropdownMenuItem(
                              value: order,
                              child: Text(
                                order.displayName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              ref
                                  .read(kabagSortOrderProvider.notifier)
                                  .state = val;
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.border),

          // Content List
          Expanded(
            child: asyncApprovals.when(
              data: (mutations) {
                if (mutations.isEmpty) {
                  return _buildEmptyState(statusFilter);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(kabagAllMutationsProvider);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      100,
                    ),
                    itemCount: mutations.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final item = mutations[index];
                      return _buildApprovalCard(context, item);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppColors.error),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Gagal memuat daftar approval: $err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(kabagAllMutationsProvider),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomFloatingNavBar.scaffoldBottomBar(
        items: RoleNavConfig.getNavItemsForRole(UserRole.kabagAset),
      ),
    );
  }

  Widget _buildApprovalCard(BuildContext context, Mutation item) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        key: Key('card_approval_${item.id}'),
        onTap: () {
          context.push('/kabag/approvals/${item.id}');
        },
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ticket Number & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.ticketNumber,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

              // Asset Name
              Text(
                item.asset.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: AppSpacing.sm),

              // Pemohon
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Pemohon: ${item.applicantName}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),

              // Lokasi Perpindahan (Asal → Tujuan)
              Row(
                children: [
                  const Icon(Icons.swap_horiz_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      '${item.currentLocation} → ${item.targetLocation}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
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

  Widget _buildEmptyState(KabagStatusFilter statusFilter) {
    final title = switch (statusFilter) {
      KabagStatusFilter.waiting => 'Tidak Ada Pengajuan Menunggu',
      KabagStatusFilter.approved => 'Belum Ada Pengajuan Disetujui',
      KabagStatusFilter.rejected => 'Belum Ada Pengajuan Ditolak',
      KabagStatusFilter.all => 'Tidak Ada Pengajuan Ditemukan',
    };
    final subtitle = switch (statusFilter) {
      KabagStatusFilter.waiting =>
        'Seluruh permohonan mutasi yang masuk telah selesai ditinjau.',
      KabagStatusFilter.approved =>
        'Belum ada permohonan mutasi yang disetujui.',
      KabagStatusFilter.rejected =>
        'Belum ada permohonan mutasi yang ditolak.',
      KabagStatusFilter.all =>
        'Tidak ada pengajuan mutasi yang sesuai dengan kriteria.',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.task_alt, size: 56, color: AppColors.success),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
