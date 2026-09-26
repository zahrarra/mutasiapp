// lib/features/staff/presentation/screens/staff_mutation_list_screen.dart
//
// Screen: Daftar Pengajuan Menunggu Pembaruan Aset oleh Staff Aset (STF-002).
// Sumber: ROLE-FLOW.md §7, SCREEN-SPEC.md STF-002, WIREFRAME.md §2.
// UI: Premium Stitch design — custom top bar, filter panel, styled list cards.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../../core/widgets/custom_floating_nav_bar.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../providers/staff_mutation_provider.dart';

class _C {
  static const navy = Color(0xFF0F3D56);
  static const teal = Color(0xFF0F766E);
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF6F8FA);
  static const textPrimary = Color(0xFF172B4D);
  static const textSecondary = Color(0xFF52606D);
  static const border = Color(0xFFE2E8F0);
  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFFECFDF5);
  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFEF2F2);
  static const info = Color(0xFF3B82F6);
  static const infoLight = Color(0xFFEFF6FF);
}

class StaffMutationListScreen extends ConsumerStatefulWidget {
  const StaffMutationListScreen({super.key});

  @override
  ConsumerState<StaffMutationListScreen> createState() =>
      _StaffMutationListScreenState();
}

class _StaffMutationListScreenState
    extends ConsumerState<StaffMutationListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncMutations = ref.watch(filteredStaffMutationsProvider);
    final statusFilter = ref.watch(staffStatusFilterProvider);
    final sortOrder = ref.watch(staffSortOrderProvider);

    return Scaffold(
      backgroundColor: _C.background,
      extendBody: true,
      body: Column(
        children: [
          // ── Custom Top Bar ──────────────────────────────────────────
          Container(
            color: _C.surface,
            child: SafeArea(
              bottom: false,
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: _C.surface,
                  border: Border(
                      bottom: BorderSide(color: _C.border, width: 1)),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _safePop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _C.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _C.border),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            size: 18, color: _C.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Antrian Pembaruan Aset',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _C.textPrimary,
                            ),
                          ),
                          Text(
                            'Mutasi disetujui, siap diperbarui',
                            style: TextStyle(
                                fontSize: 11, color: _C.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Search & Filter ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            color: _C.surface,
            child: Column(
              children: [
                // Search Field
                Container(
                  decoration: BoxDecoration(
                    color: _C.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.border),
                  ),
                  child: TextField(
                    key: const Key('input_search_staff_mutations'),
                    controller: _searchController,
                    style:
                        const TextStyle(fontSize: 13, color: _C.textPrimary),
                    decoration: InputDecoration(
                      hintText:
                          'Cari tiket, aset, pemohon, lokasi, PIC...',
                      hintStyle: const TextStyle(
                          fontSize: 13, color: _C.textSecondary),
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 18, color: _C.textSecondary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                ref
                                    .read(
                                        staffSearchQueryProvider.notifier)
                                    .state = '';
                                setState(() {});
                              },
                              child: const Icon(Icons.clear_rounded,
                                  size: 16, color: _C.textSecondary),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onChanged: (v) {
                      ref.read(staffSearchQueryProvider.notifier).state =
                          v;
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Filter row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: _C.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _C.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<StaffStatusFilter>(
                            key: const Key(
                                'dropdown_filter_staff_status'),
                            value: statusFilter,
                            isDense: true,
                            isExpanded: true,
                            icon: const Icon(Icons.filter_list_rounded,
                                size: 16, color: _C.teal),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _C.textPrimary),
                            items: StaffStatusFilter.values
                                .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s.displayName)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                ref
                                    .read(staffStatusFilterProvider
                                        .notifier)
                                    .state = val;
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: _C.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _C.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<StaffSortOrder>(
                          key: const Key('dropdown_sort_staff'),
                          value: sortOrder,
                          isDense: true,
                          icon: const Icon(Icons.sort_rounded,
                              size: 16, color: _C.textSecondary),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _C.textPrimary),
                          items: StaffSortOrder.values
                              .map((s) => DropdownMenuItem(
                                  value: s, child: Text(s.displayName)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              ref
                                  .read(staffSortOrderProvider.notifier)
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
          const Divider(height: 1, color: _C.border),

          // ── List ────────────────────────────────────────────────────
          Expanded(
            child: asyncMutations.when(
              data: (mutations) {
                if (mutations.isEmpty) {
                  return _buildEmptyState();
                }
                return RefreshIndicator(
                  color: _C.teal,
                  onRefresh: () async =>
                      ref.invalidate(staffAllMutationsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: mutations.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = mutations[index];
                      return _StaffMutationCard(
                        mutation: item,
                        onTap: () => context
                            .push('/staff-aset/mutations/${item.id}'),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _C.teal),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: _C.errorLight,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.error_outline_rounded,
                            size: 32, color: _C.error),
                      ),
                      const SizedBox(height: 16),
                      const Text('Gagal Memuat Data',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _C.textPrimary)),
                      const SizedBox(height: 6),
                      Text('$err',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12, color: _C.textSecondary)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () =>
                            ref.invalidate(staffAllMutationsProvider),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Coba Lagi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomFloatingNavBar.scaffoldBottomBar(
        items: RoleNavConfig.getNavItemsForRole(UserRole.staffAset),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _C.successLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  size: 36, color: _C.success),
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Tidak ada hasil untuk\n"${_searchController.text}"'
                  : 'Tidak Ada Antrian Update',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _C.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Semua mutasi yang disetujui telah\nselesai diproses.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _C.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  void _safePop(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      try {
        context.go(RouteNames.staffDashboardPath);
      } catch (_) {}
    }
  }
}

/// Card item mutasi untuk antrian update Staff Aset.
class _StaffMutationCard extends StatelessWidget {
  final Mutation mutation;
  final VoidCallback? onTap;

  const _StaffMutationCard({required this.mutation, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key('card_staff_item_${mutation.id}'),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ticket + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  mutation.ticketNumber,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    color: _C.navy,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _C.infoLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    mutation.status.displayName,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _C.info,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Asset name + code
            Text(
              mutation.asset.name,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _C.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${mutation.asset.assetCode} • ${mutation.asset.category.name}',
              style: const TextStyle(
                  fontSize: 11, color: _C.textSecondary),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: _C.border),
            const SizedBox(height: 8),

            // Location transfer row
            Row(
              children: [
                const Icon(Icons.swap_horiz_rounded,
                    size: 14, color: _C.teal),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${mutation.currentLocation} → ${mutation.targetLocation}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _C.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded,
                    size: 14, color: _C.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'PIC: ${mutation.currentPic} → ${mutation.targetPic}',
                    style: const TextStyle(
                        fontSize: 11, color: _C.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pemohon: ${mutation.applicantName}',
                  style: const TextStyle(
                      fontSize: 11, color: _C.textSecondary),
                ),
                Text(
                  '${mutation.createdAt.day.toString().padLeft(2, '0')}/'
                  '${mutation.createdAt.month.toString().padLeft(2, '0')}/'
                  '${mutation.createdAt.year}',
                  style: const TextStyle(
                      fontSize: 11, color: _C.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
