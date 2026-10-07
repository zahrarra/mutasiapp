// lib/features/bagian_aset/presentation/screens/bagian_aset_verifications_screen.dart
//
// Screen: Daftar Pengajuan Antrean Verifikasi Bagian Aset.
// Sumber: PRD V1.1 §5, §6.4.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/widgets/custom_floating_nav_bar.dart';
import '../../../../core/widgets/mutasiku_page_header.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../providers/bagian_aset_verification_provider.dart';

class _C {
  static const navy = Color(0xFF0F3D56);
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
}

class BagianAsetVerificationsScreen extends ConsumerStatefulWidget {
  const BagianAsetVerificationsScreen({super.key});

  @override
  ConsumerState<BagianAsetVerificationsScreen> createState() =>
      _BagianAsetVerificationsScreenState();
}

class _BagianAsetVerificationsScreenState
    extends ConsumerState<BagianAsetVerificationsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncVerifications =
        ref.watch(filteredBagianAsetVerificationsProvider);
    final sortOrder = ref.watch(bagianAsetSortOrderProvider);
    final statusFilter = ref.watch(bagianAsetStatusFilterProvider);
    final role = ref.watch(authStateProvider).user?.role ?? UserRole.bagianAset;

    final title = switch (statusFilter) {
      BagianAsetStatusFilter.waiting => 'Menunggu Verifikasi',
      BagianAsetStatusFilter.verified ||
      BagianAsetStatusFilter.approved =>
        'Lolos Verifikasi',
      BagianAsetStatusFilter.returned ||
      BagianAsetStatusFilter.rejected =>
        'Dikembalikan',
      BagianAsetStatusFilter.all => 'Semua Pengajuan',
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
              title: title,
              subtitle: 'Antrean Verifikasi Data Aset & Validitas Mutasi',
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(RouteNames.bagianAsetDashboardPath);
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
                // Search Field
                _SearchField(
                  searchKey: const Key('input_search_approvals'),
                  controller: _searchController,
                  hintText: 'Cari no. tiket, aset, pemohon, lokasi...',
                  onChanged: (v) {
                    ref.read(bagianAsetSearchQueryProvider.notifier).state = v;
                    setState(() {});
                  },
                  onClear: () {
                    _searchController.clear();
                    ref.read(bagianAsetSearchQueryProvider.notifier).state = '';
                    setState(() {});
                  },
                ),
                const SizedBox(height: 10),

                // Filter row
                Row(
                  children: [
                    Expanded(
                      child: _DropdownFilter(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<BagianAsetStatusFilter>(
                            key: const Key('dropdown_filter_bagian_aset_status'),
                            value: statusFilter,
                            isDense: true,
                            isExpanded: true,
                            icon: const Icon(Icons.filter_list_rounded,
                                size: 16, color: _C.success),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _C.textPrimary),
                            items: [
                              BagianAsetStatusFilter.waiting,
                              BagianAsetStatusFilter.verified,
                              BagianAsetStatusFilter.returned,
                              BagianAsetStatusFilter.all,
                            ]
                                .map((s) => DropdownMenuItem(
                                    value: s, child: Text(s.displayName)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                ref
                                    .read(bagianAsetStatusFilterProvider.notifier)
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
                        child: DropdownButton<BagianAsetSortOrder>(
                          key: const Key('dropdown_filter_bagian_aset_sort'),
                          value: sortOrder,
                          isDense: true,
                          icon: const Icon(Icons.sort_rounded,
                              size: 16, color: _C.textSecondary),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _C.textPrimary),
                          items: BagianAsetSortOrder.values
                              .map((s) => DropdownMenuItem(
                                  value: s, child: Text(s.displayName)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              ref
                                  .read(bagianAsetSortOrderProvider.notifier)
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

          // ── Content List ─────────────────────────────────────────────
          Expanded(
            child: asyncVerifications.when(
              data: (list) {
                if (list.isEmpty) {
                  return _EmptyState(
                    statusFilter: statusFilter,
                    hasQuery: _searchController.text.isNotEmpty,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    return _VerificationCard(
                      key: Key('approval_card_${list[i].id}'),
                      mutation: list[i],
                      onTap: () {
                        context.push(
                          RouteNames.bagianAsetVerificationDetailPath
                              .replaceFirst(':id', list[i].id),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: _C.navy),
              ),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 40, color: _C.error),
                    const SizedBox(height: 8),
                    Text(
                      'Gagal memuat data: $err',
                      style: const TextStyle(color: _C.textSecondary, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(bagianAsetAllMutationsProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.navy,
                        foregroundColor: Colors.white,
                      ),
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
        items: RoleNavConfig.getNavItemsForRole(role),
        currentRoute: RouteNames.bagianAsetVerificationsPath,
        onItemTap: (item) => context.go(item.route),
      ),
    );
  }
}

// ── Search Field ─────────────────────────────────────────────────────────────
class _SearchField extends StatelessWidget {
  final Key? searchKey;
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    this.searchKey,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
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
          prefixIcon:
              const Icon(Icons.search_rounded, size: 18, color: _C.textSecondary),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: onClear,
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: _C.textSecondary),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

// ── Verification Card ─────────────────────────────────────────────────────────
class _VerificationCard extends StatelessWidget {
  final Mutation mutation;
  final VoidCallback onTap;

  const _VerificationCard({
    super.key,
    required this.mutation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = mutation.status;
    final isWaiting = status.isWaitingAssetVerification;

    final badgeColor = isWaiting
        ? _C.warning
        : status == MutationStatus.returned || status == MutationStatus.rejected
            ? _C.error
            : _C.success;

    final badgeBg = isWaiting
        ? _C.warningLight
        : status == MutationStatus.returned || status == MutationStatus.rejected
            ? _C.errorLight
            : _C.successLight;

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
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Nomor Tiket & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status.displayName,
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

                // Row 2: Nama Aset & Kategori
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        mutation.asset.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _C.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
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

                // Row 3: Pemohon & Lokasi
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded,
                        size: 13, color: _C.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      mutation.applicantName,
                      style: const TextStyle(
                          fontSize: 11, color: _C.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 12, color: _C.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        mutation.targetLocation,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _C.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: _C.border),
                const SizedBox(height: 8),

                // Row 4: Aset Ikut Pemohon & Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
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
                    Row(
                      children: [
                        Text(
                          isWaiting ? 'Verifikasi' : 'Lihat Detail',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _C.navy,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.chevron_right_rounded,
                            size: 14, color: _C.navy),
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
}

// ── Dropdown Filter Container ───────────────────────────────────────────────
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

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final BagianAsetStatusFilter statusFilter;
  final bool hasQuery;

  const _EmptyState({
    required this.statusFilter,
    required this.hasQuery,
  });

  @override
  Widget build(BuildContext context) {
    final title = switch (statusFilter) {
      BagianAsetStatusFilter.waiting => 'Tidak Ada Pengajuan Menunggu',
      BagianAsetStatusFilter.verified ||
      BagianAsetStatusFilter.approved =>
        'Belum Ada Pengajuan Diverifikasi',
      BagianAsetStatusFilter.returned ||
      BagianAsetStatusFilter.rejected =>
        'Belum Ada Pengajuan Dikembalikan',
      BagianAsetStatusFilter.all => 'Tidak Ada Pengajuan Ditemukan',
    };

    final subtitle = hasQuery
        ? 'Tidak ada data yang sesuai kriteria pencarian.'
        : switch (statusFilter) {
            BagianAsetStatusFilter.waiting =>
              'Seluruh pengajuan mutasi telah selesai diverifikasi.',
            BagianAsetStatusFilter.verified ||
            BagianAsetStatusFilter.approved =>
              'Pengajuan yang lolos verifikasi akan muncul di sini.',
            BagianAsetStatusFilter.returned ||
            BagianAsetStatusFilter.rejected =>
              'Pengajuan yang dikembalikan akan muncul di sini.',
            BagianAsetStatusFilter.all =>
              'Tidak ada data yang sesuai kriteria pencarian.',
          };

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
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: _C.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

