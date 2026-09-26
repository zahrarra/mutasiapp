// lib/features/kadiv/presentation/screens/kadiv_approvals_screen.dart
//
// Screen: Daftar Pengajuan Menunggu Approval & Riwayat Kadiv (KDV-002).
// Sumber: SCREEN-SPEC.md KDV-002, ROLE-FLOW.md §6, DESIGN.md.
// UI: Premium Stitch design — custom top bar, filter panel, styled list cards.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../../core/widgets/custom_floating_nav_bar.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../providers/kadiv_approval_provider.dart';

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

    final title = switch (statusFilter) {
      KadivStatusFilter.waiting => 'Menunggu Otorisasi',
      KadivStatusFilter.approved => 'Disetujui',
      KadivStatusFilter.rejected => 'Ditolak',
      KadivStatusFilter.all => 'Semua Pengajuan',
    };

    return Scaffold(
      backgroundColor: _C.background,
      extendBody: true,
      body: Column(
        children: [
          // ── Custom Top Bar ──────────────────────────────────────────
          _ApprovalsTopBar(
            title: title,
            subtitle: 'Otorisasi Final Tingkat Kepala Divisi',
            onBack: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go(RouteNames.kadivDashboardPath);
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
                  searchKey: const Key('input_search_kadiv_approvals'),
                  controller: _searchController,
                  hintText: 'Cari no. tiket, aset, pemohon, lokasi...',
                  onChanged: (v) {
                    ref.read(kadivSearchQueryProvider.notifier).state = v;
                    setState(() {});
                  },
                  onClear: () {
                    _searchController.clear();
                    ref.read(kadivSearchQueryProvider.notifier).state = '';
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
                          child: DropdownButton<KadivStatusFilter>(
                            key: const Key('dropdown_filter_kadiv_status'),
                            value: statusFilter,
                            isDense: true,
                            isExpanded: true,
                            icon: const Icon(Icons.filter_list_rounded,
                                size: 16, color: _C.teal),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _C.textPrimary),
                            items: KadivStatusFilter.values
                                .map((s) => DropdownMenuItem(
                                    value: s, child: Text(s.displayName)))
                                .toList(),
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
                    const SizedBox(width: 10),
                    _DropdownFilter(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<KadivSortOrder>(
                          key: const Key('dropdown_sort_kadiv'),
                          value: sortOrder,
                          isDense: true,
                          icon: const Icon(Icons.sort_rounded,
                              size: 16, color: _C.textSecondary),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _C.textPrimary),
                          items: KadivSortOrder.values
                              .map((s) => DropdownMenuItem(
                                  value: s, child: Text(s.displayName)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              ref
                                  .read(kadivSortOrderProvider.notifier)
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
                      ref.invalidate(kadivAllMutationsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: mutations.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _KadivApprovalCard(
                      mutation: mutations[i],
                      onTap: () =>
                          context.push('/kadiv/approvals/${mutations[i].id}'),
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
                onRetry: () => ref.invalidate(kadivAllMutationsProvider),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomFloatingNavBar.scaffoldBottomBar(
        items: RoleNavConfig.getNavItemsForRole(UserRole.kadiv),
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
    final subtitle = switch (filter) {
      KadivStatusFilter.waiting =>
        'Seluruh pengajuan mutasi tingkat Kadiv telah selesai diproses.',
      KadivStatusFilter.approved =>
        'Pengajuan yang Anda setujui akan muncul di sini.',
      KadivStatusFilter.rejected =>
        'Pengajuan yang Anda tolak akan muncul di sini.',
      KadivStatusFilter.all =>
        'Tidak ada data yang sesuai kriteria pencarian.',
    };
    return _EmptyState(title: title, subtitle: subtitle);
  }
}

// ── Kadiv Approval Card ──────────────────────────────────────────────────────

class _KadivApprovalCard extends StatelessWidget {
  final Mutation mutation;
  final VoidCallback? onTap;

  const _KadivApprovalCard({required this.mutation, this.onTap});

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = _statusColors(mutation.status.name);

    return GestureDetector(
      key: Key('card_approval_kadiv_${mutation.id}'),
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
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.place_outlined,
                    size: 13, color: _C.textSecondary),
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
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded,
                    size: 13, color: _C.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Pemohon: ${mutation.applicantName}  •  PIC: ${mutation.targetPic}',
                    style: const TextStyle(
                        fontSize: 11, color: _C.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // Kabag approval badge
            if (mutation.approvedBy != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.successLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _C.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded,
                        size: 12, color: _C.success),
                    const SizedBox(width: 4),
                    Text(
                      'Approval Kabag: ${mutation.approvedBy}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _C.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  (Color, Color) _statusColors(String name) {
    switch (name) {
      case 'waitingKadivApproval':
        return (_C.warning, _C.warningLight);
      case 'approved':
      case 'completed':
        return (_C.success, _C.successLight);
      case 'rejected':
        return (_C.error, _C.errorLight);
      default:
        return (_C.info, _C.infoLight);
    }
  }
}

// ── Shared Private Widgets ───────────────────────────────────────────────────

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
          hintStyle:
              const TextStyle(fontSize: 13, color: _C.textSecondary),
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
