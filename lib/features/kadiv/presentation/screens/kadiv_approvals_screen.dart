// lib/features/kadiv/presentation/screens/kadiv_approvals_screen.dart
//
// Screen: Daftar Pengajuan Menunggu Approval & Riwayat Kadiv (KDV-002).
// Sumber: SCREEN-SPEC.md KDV-002, ROLE-FLOW.md §6, DESIGN.md.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../providers/kadiv_approval_provider.dart';

class KadivApprovalsScreen extends ConsumerStatefulWidget {
  const KadivApprovalsScreen({super.key});

  @override
  ConsumerState<KadivApprovalsScreen> createState() =>
      _KadivApprovalsScreenState();
}

class _KadivApprovalsScreenState extends ConsumerState<KadivApprovalsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncApprovals = ref.watch(filteredKadivApprovalsProvider);
    final statusFilter = ref.watch(kadivStatusFilterProvider);
    final sortOrder = ref.watch(kadivSortOrderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Approval Kadiv'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go(RouteNames.kadivDashboardPath);
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Field
                TextField(
                  key: const Key('input_search_kadiv_approvals'),
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari no. tiket, aset, pemohon, lokasi...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(kadivSearchQueryProvider.notifier).state =
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
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  onChanged: (value) {
                    ref.read(kadivSearchQueryProvider.notifier).state = value;
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
                          child: DropdownButton<KadivStatusFilter>(
                            key: const Key('dropdown_filter_kadiv_status'),
                            value: statusFilter,
                            isDense: true,
                            isExpanded: true,
                            icon: const Icon(
                              Icons.filter_list,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            items: KadivStatusFilter.values.map((s) {
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
                                    .read(kadivStatusFilterProvider.notifier)
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
                        child: DropdownButton<KadivSortOrder>(
                          key: const Key('dropdown_filter_kadiv_sort'),
                          value: sortOrder,
                          isDense: true,
                          icon: const Icon(
                            Icons.sort,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          items: KadivSortOrder.values.map((order) {
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
                              ref.read(kadivSortOrderProvider.notifier).state =
                                  val;
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
                    ref.invalidate(kadivAllMutationsProvider);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
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
                      'Gagal memuat daftar approval Kadiv: $err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(kadivAllMutationsProvider),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
        key: Key('card_approval_kadiv_${item.id}'),
        onTap: () {
          context.push('/kadiv/approvals/${item.id}');
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
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
              const SizedBox(height: 6),

              // Asset Name
              Text(
                item.asset.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),

              // Transition Location
              Row(
                children: [
                  const Icon(Icons.place_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
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
              const SizedBox(height: 2),

              // Applicant & Target PIC
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Pemohon: ${item.applicantName} • PIC: ${item.targetPic}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),

              // Highlight Approval Kabag (KDV-003 & PRD §6.5)
              if (item.approvedBy != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified,
                          size: 14, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        'Approval Kabag: ${item.approvedBy}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(KadivStatusFilter filter) {
    final title = switch (filter) {
      KadivStatusFilter.waiting => 'Tidak Ada Mutasi Menunggu Approval',
      KadivStatusFilter.approved => 'Belum Ada Mutasi Disetujui',
      KadivStatusFilter.rejected => 'Belum Ada Mutasi Ditolak',
      KadivStatusFilter.all => 'Tidak Ada Pengajuan Ditemukan',
    };

    final message = switch (filter) {
      KadivStatusFilter.waiting =>
        'Seluruh pengajuan mutasi tingkat Kadiv telah selesai diproses.',
      KadivStatusFilter.approved =>
        'Pengajuan yang Anda setujui akan muncul di sini sebagai riwayat.',
      KadivStatusFilter.rejected =>
        'Pengajuan yang Anda tolak akan muncul di sini sebagai riwayat.',
      KadivStatusFilter.all =>
        'Tidak ada data pengajuan yang sesuai dengan kriteria pencarian.',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 56,
              color: AppColors.disabled,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
