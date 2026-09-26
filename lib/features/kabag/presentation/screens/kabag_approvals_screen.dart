// lib/features/kabag/presentation/screens/kabag_approvals_screen.dart
//
// Screen: Daftar Pengajuan Menunggu Approval Kabag (KBG-002).
// Sumber: SCREEN-SPEC.md KBG-002, ROLE-FLOW.md §5, WIREFRAME.md §7.
// UI: Premium Stitch design — custom top bar, filter panel, styled list cards.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../../core/widgets/custom_floating_nav_bar.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../providers/kabag_approval_provider.dart';

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
  static const warning = Color(0xFFD97706);
  static const warningLight = Color(0xFFFEF3C7);
  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFEF2F2);
  static const info = Color(0xFF3B82F6);
  static const infoLight = Color(0xFFEFF6FF);
}

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

    final title = switch (statusFilter) {
      KabagStatusFilter.waiting => 'Menunggu Approval',
      KabagStatusFilter.approved => 'Disetujui',
      KabagStatusFilter.rejected => 'Ditolak',
      KabagStatusFilter.all => 'Semua Pengajuan',
    };

    return Scaffold(
      backgroundColor: _C.background,
      extendBody: true,
      body: Column(
        children: [
          // ── Custom Top Bar ──────────────────────────────────────────
          _ApprovalsTopBar(
            title: title,
            subtitle: 'Antrean Approval Kabag Aset',
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(RouteNames.kabagDashboardPath);
              }
            },
          ),

          // ── Search & Filter ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            color: _C.surface,
            child: Column(
              children: [
                // Search
                _SearchField(
                  searchKey: const Key('input_search_approvals'),
                  controller: _searchController,
                  hintText: 'Cari no. tiket, aset, pemohon, lokasi...',
                  onChanged: (v) {
                    ref.read(kabagSearchQueryProvider.notifier).state = v;
                    setState(() {});
                  },
                  onClear: () {
                    _searchController.clear();
                    ref.read(kabagSearchQueryProvider.notifier).state = '';
                    setState(() {});
                  },
                  showClear: _searchController.text.isNotEmpty,
                ),
                const SizedBox(height: 10),

                // Filter row
                Row(
                  children: [
                    Expanded(
                      child: _DropdownFilter(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<KabagStatusFilter>(
                            key: const Key('dropdown_filter_kabag_status'),
                            value: statusFilter,
                            isDense: true,
                            isExpanded: true,
                            icon: const Icon(Icons.filter_list_rounded,
                                size: 16, color: _C.teal),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _C.textPrimary),
                            items: KabagStatusFilter.values
                                .map((s) => DropdownMenuItem(
                                    value: s, child: Text(s.displayName)))
                                .toList(),
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
                    const SizedBox(width: 10),
                    _DropdownFilter(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<KabagSortOrder>(
                          key: const Key('dropdown_sort_kabag'),
                          value: sortOrder,
                          isDense: true,
                          icon: const Icon(Icons.sort_rounded,
                              size: 16, color: _C.textSecondary),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _C.textPrimary),
                          items: KabagSortOrder.values
                              .map((s) => DropdownMenuItem(
                                  value: s, child: Text(s.displayName)))
                              .toList(),
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
          const Divider(height: 1, color: _C.border),

          // ── List ────────────────────────────────────────────────────
          Expanded(
            child: asyncApprovals.when(
              data: (mutations) {
                if (mutations.isEmpty) {
                  return _buildEmptyState(statusFilter);
                }
                return RefreshIndicator(
                  color: _C.teal,
                  onRefresh: () async =>
                      ref.invalidate(kabagAllMutationsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: mutations.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _KabagApprovalCard(
                      mutation: mutations[i],
                      onTap: () =>
                          context.push('/kabag/approvals/${mutations[i].id}'),
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _C.teal),
              ),
              error: (err, _) => _ErrorState(
                message: '$err',
                onRetry: () => ref.invalidate(kabagAllMutationsProvider),
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

  Widget _buildEmptyState(KabagStatusFilter statusFilter) {
    final title = switch (statusFilter) {
      KabagStatusFilter.waiting => 'Tidak Ada Pengajuan Menunggu',
      KabagStatusFilter.approved => 'Belum Ada Pengajuan Disetujui',
      KabagStatusFilter.rejected => 'Belum Ada Pengajuan Ditolak',
      KabagStatusFilter.all => 'Tidak Ada Pengajuan Ditemukan',
    };
    final subtitle = switch (statusFilter) {
      KabagStatusFilter.waiting =>
        'Seluruh permohonan mutasi telah selesai ditinjau.',
      KabagStatusFilter.approved =>
        'Belum ada permohonan mutasi yang disetujui.',
      KabagStatusFilter.rejected =>
        'Belum ada permohonan mutasi yang ditolak.',
      KabagStatusFilter.all =>
        'Tidak ada pengajuan yang sesuai kriteria pencarian.',
    };
    return _EmptyState(title: title, subtitle: subtitle);
  }
}

// ── Shared Private Widgets ───────────────────────────────────────────────────

class _KabagApprovalCard extends StatelessWidget {
  final Mutation mutation;
  final VoidCallback? onTap;

  const _KabagApprovalCard({required this.mutation, this.onTap});

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = _statusColors(mutation.status.name);

    return GestureDetector(
      key: Key('card_approval_${mutation.id}'),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    mutation.status.displayName,
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w600, color: fg),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              mutation.asset.name,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _C.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: _C.border),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded,
                    size: 13, color: _C.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    mutation.applicantName,
                    style: const TextStyle(
                        fontSize: 12, color: _C.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.swap_horiz_rounded,
                    size: 13, color: _C.teal),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${mutation.currentLocation} → ${mutation.targetLocation}',
                    style: const TextStyle(
                        fontSize: 11, color: _C.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  (Color, Color) _statusColors(String name) {
    switch (name) {
      case 'submitted':
      case 'waitingKabagApproval':
        return (_C.warning, _C.warningLight);
      case 'approved':
      case 'waitingKadivApproval':
      case 'completed':
        return (_C.success, _C.successLight);
      case 'rejected':
        return (_C.error, _C.errorLight);
      default:
        return (_C.info, _C.infoLight);
    }
  }
}

// ── Reusable shared widgets for this file ───────────────────────────────────

class _ApprovalsTopBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  const _ApprovalsTopBar({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _C.surface,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: _C.surface,
            border: Border(bottom: BorderSide(color: _C.border, width: 1)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: onBack,
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
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _C.textPrimary)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 11, color: _C.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final Key searchKey;
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool showClear;

  const _SearchField({
    required this.searchKey,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
    required this.showClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
      ),
      child: TextField(
        key: searchKey,
        controller: controller,
        style: const TextStyle(fontSize: 13, color: _C.textPrimary),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 13, color: _C.textSecondary),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 18, color: _C.textSecondary),
          suffixIcon: showClear
              ? GestureDetector(
                  onTap: onClear,
                  child: const Icon(Icons.clear_rounded,
                      size: 16, color: _C.textSecondary),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _DropdownFilter extends StatelessWidget {
  final Widget child;

  const _DropdownFilter({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: _C.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.border),
      ),
      child: child,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
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
              child: const Icon(Icons.task_alt_rounded,
                  size: 36, color: _C.success),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _C.textPrimary)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: _C.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
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
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, color: _C.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
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
    );
  }
}
