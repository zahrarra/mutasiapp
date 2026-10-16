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
import '../widgets/kadiv_approval_modal.dart';
import '../../../../core/widgets/mutasiku_page_header.dart';

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
      KadivStatusFilter.processing => 'Diproses',
      KadivStatusFilter.allocated => 'Dialokasikan',
      KadivStatusFilter.returned => 'Dikembalikan',
      KadivStatusFilter.completed => 'Selesai',
      KadivStatusFilter.rejected => 'Ditolak',
      KadivStatusFilter.waiting => 'Menunggu Otorisasi',
      KadivStatusFilter.approved => 'Disetujui',
      KadivStatusFilter.all => 'Semua Pengajuan',
    };

    return Scaffold(
      backgroundColor: _C.background,
      extendBody: true,
      body: Column(
        children: [
          // ── Header Baseline ──────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: MutasiKuPageHeader(
              title: 'Approval Kadiv',
              subtitle: title,
              onBack: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go(RouteNames.kadivDashboardPath);
                }
              },
            ),
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
                            icon: const Icon(
                              Icons.filter_list_rounded,
                              size: 16,
                              color: _C.teal,
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _C.textPrimary,
                            ),
                            items:
                                [
                                      KadivStatusFilter.all,
                                      KadivStatusFilter.waiting,
                                      KadivStatusFilter.processing,
                                      KadivStatusFilter.allocated,
                                      KadivStatusFilter.completed,
                                      KadivStatusFilter.rejected,
                                    ]
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s.displayName),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                ref
                                        .read(
                                          kadivStatusFilterProvider.notifier,
                                        )
                                        .state =
                                    val;
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
                          key: const Key('dropdown_filter_kadiv_sort'),
                          value: sortOrder,
                          isDense: true,
                          icon: const Icon(
                            Icons.sort_rounded,
                            size: 16,
                            color: _C.textSecondary,
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _C.textPrimary,
                          ),
                          items: KadivSortOrder.values
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.displayName),
                                ),
                              )
                              .toList(),
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
          const Divider(height: 1, color: _C.border),

          // ── List ────────────────────────────────────────────────────
          Expanded(
            child: asyncApprovals.when(
              data: (mutations) {
                if (mutations.isEmpty) {
                  return _buildEmptyState(statusFilter);
                }
                return RefreshIndicator(
                  color: _C.navy,
                  onRefresh: () async =>
                      ref.invalidate(kadivAllMutationsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: mutations.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _KadivApprovalCard(
                      mutation: mutations[i],
                      onTap: () =>
                          context.push('/kadiv/approvals/${mutations[i].id}'),
                      onQuickApprove: mutations[i].status.isWaitingDivisionApproval
                          ? () async {
                              final approved = await startKadivApprovalFlow(
                                context,
                                mutation: mutations[i],
                              );
                              if (approved == true && mounted) {
                                ref.invalidate(kadivAllMutationsProvider);
                              }
                            }
                          : null,
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: _C.navy),
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
        currentRoute: RouteNames.kadivApprovalsPath,
        onItemTap: (item) => context.go(item.route),
      ),
    );
  }

  Widget _buildEmptyState(KadivStatusFilter filter) {
    final title = switch (filter) {
      KadivStatusFilter.processing => 'Tidak Ada Mutasi Diproses',
      KadivStatusFilter.allocated => 'Tidak Ada Mutasi Dialokasikan',
      KadivStatusFilter.returned => 'Tidak Ada Mutasi Dikembalikan',
      KadivStatusFilter.completed => 'Belum Ada Mutasi Selesai',
      KadivStatusFilter.waiting => 'Tidak Ada Mutasi Menunggu Approval',
      KadivStatusFilter.approved => 'Belum Ada Mutasi Disetujui',
      KadivStatusFilter.rejected => 'Belum Ada Mutasi Ditolak',
      KadivStatusFilter.all => 'Tidak Ada Pengajuan Ditemukan',
    };
    final subtitle = switch (filter) {
      KadivStatusFilter.processing =>
        'Pengajuan yang sedang diproses akan muncul di sini.',
      KadivStatusFilter.allocated =>
        'Pengajuan yang sedang dialokasikan akan muncul di sini.',
      KadivStatusFilter.returned =>
        'Pengajuan yang dikembalikan ke pemohon akan muncul di sini.',
      KadivStatusFilter.completed =>
        'Pengajuan yang telah selesai dikonfirmasi akan muncul di sini.',
      KadivStatusFilter.waiting =>
        'Seluruh pengajuan mutasi tingkat Pemimpin Divisi telah selesai diproses.',
      KadivStatusFilter.approved =>
        'Pengajuan yang Anda setujui akan muncul di sini.',
      KadivStatusFilter.rejected =>
        'Pengajuan yang Anda tolak akan muncul di sini.',
      KadivStatusFilter.all => 'Tidak ada data yang sesuai kriteria pencarian.',
    };
    return _EmptyState(title: title, subtitle: subtitle);
  }
}

// ── Kadiv Approval Card ──────────────────────────────────────────────────────

class _KadivApprovalCard extends StatelessWidget {
  final Mutation mutation;
  final VoidCallback? onTap;
  final VoidCallback? onQuickApprove;

  const _KadivApprovalCard({
    required this.mutation,
    this.onTap,
    this.onQuickApprove,
  });

  @override
  Widget build(BuildContext context) {
    final status = mutation.status;
    final isWaiting = status.isWaitingDivisionApproval;
    final (badgeColor, badgeBg) = _statusColors(status.name);

    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWaiting ? _C.navy.withValues(alpha: 0.25) : _C.border,
          width: isWaiting ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: Key('card_approval_kadiv_${mutation.id}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Row 1: Ticket + Status Badge ─────────────────────────
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Text(
                      mutation.ticketNumber,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _C.navy,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        mutation.status.displayName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Row 2: Asset Name & Category Chip ────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        mutation.asset.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _C.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _C.background,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _C.border),
                      ),
                      child: Text(
                        mutation.asset.category.name,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _C.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // ── Row 3: Pemohon & Lokasi Tujuan ───────────────────────
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 13,
                      color: _C.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        mutation.applicantName,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _C.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 12,
                      color: _C.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        mutation.targetLocation,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _C.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // ── Row 4: Bagian Aset verification badge ────────────────
                if ((mutation.assetVerifiedBy != null &&
                        !RegExp(r'^\d+$').hasMatch(mutation.assetVerifiedBy!.trim())) ||
                    (mutation.approvedBy != null &&
                        !RegExp(r'^\d+$').hasMatch(mutation.approvedBy!.trim())) ||
                    mutation.assetVerifiedAt != null ||
                    mutation.approvedAt != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _C.successLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _C.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          size: 12,
                          color: _C.success,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Verifikasi Bagian Aset: ${() {
                              final name = mutation.assetVerifiedBy ?? mutation.approvedBy;
                              if (name != null && !RegExp(r'^\d+$').hasMatch(name.trim()) && name.trim() != 'null') {
                                return name.trim();
                              }
                              return 'Valid';
                            }()}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _C.success,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 8),
                const Divider(height: 1, color: _C.border),
                const SizedBox(height: 8),

                // ── Row 5: Action Bottom Row ─────────────────────────────
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          mutation.isAssetMovingWithApplicant
                              ? Icons.check_circle_outline
                              : Icons.assignment_late_outlined,
                          size: 13,
                          color: mutation.isAssetMovingWithApplicant
                              ? _C.success
                              : _C.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          mutation.isAssetMovingWithApplicant
                              ? 'Aset dibawa pemohon'
                              : 'Penetapan PIC baru',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: mutation.isAssetMovingWithApplicant
                                ? _C.success
                                : _C.warning,
                          ),
                        ),
                      ],
                    ),
                    if (isWaiting && onQuickApprove != null)
                      ElevatedButton(
                        key: Key('btn_quick_approve_${mutation.id}'),
                        onPressed: onQuickApprove,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.navy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Persetujuan',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(Icons.arrow_forward_rounded, size: 12),
                          ],
                        ),
                      )
                    else
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lihat Detail',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _C.navy,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 14,
                            color: _C.navy,
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
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

class _SearchField extends StatelessWidget {
  final Key? searchKey;
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool showClear;

  const _SearchField({
    this.searchKey,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
    this.showClear = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: _C.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.border),
      ),
      child: TextField(
        key: searchKey,
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13, color: _C.textPrimary),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 12, color: _C.textSecondary),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18,
            color: _C.textSecondary,
          ),
          suffixIcon: controller.text.isNotEmpty || showClear
              ? GestureDetector(
                  onTap: onClear,
                  child: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: _C.textSecondary,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
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
              child: const Icon(
                Icons.task_alt_rounded,
                size: 36,
                color: _C.success,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _C.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _C.textSecondary),
            ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: _C.error,
          ),
          const SizedBox(height: 8),
          Text(
            'Gagal memuat data: $message',
            style: const TextStyle(
              color: _C.textSecondary,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.navy,
              foregroundColor: Colors.white,
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

// ─── Pemimpin Divisi Screen Alias ─────────────────────────────────────────────
typedef PemimpinDivisiApprovalsScreen = KadivApprovalsScreen;
