// lib/features/operator/presentation/screens/operator_mutations_screen.dart
//
// Screen: Pengajuan Masuk — Antrean Verifikasi Operator (OPR-002).
// Sumber: SCREEN-SPEC.md OPR-002, ROLE-FLOW.md §4, WIREFRAME.md §2.
// UI: Stitch design baseline — filter tab-pills, avatar initials, asset info box.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../../core/widgets/custom_floating_nav_bar.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../providers/operator_verification_provider.dart';

// ─── Design tokens (Stitch baseline) ─────────────────────────────────────────
class _C {
  static const navy    = Color(0xFF0F3D56);
  static const teal    = Color(0xFF0F766E);
  static const surface = Color(0xFFFFFFFF);
  static const bg      = Color(0xFFF6F8FA);
  static const textPrimary   = Color(0xFF172B4D);
  static const textSecondary = Color(0xFF52606D);
  static const border  = Color(0xFFD0D5DD);
  static const success = Color(0xFF10B981);
  static const successBg = Color(0xFFECFDF5);
  static const error   = Color(0xFFEF4444);
  static const errorBg = Color(0xFFFEF2F2);
  static const info    = Color(0xFF3B82F6);
  static const infoBg  = Color(0xFFEFF6FF);
}

// ─── Filter tab enum ──────────────────────────────────────────────────────────
enum _Tab { all, submitted, returned }

extension _TabExt on _Tab {
  String label(int count) => switch (this) {
        _Tab.all       => 'Semua ($count)',
        _Tab.submitted => 'Menunggu',
        _Tab.returned  => 'Dikembalikan',
      };
  OperatorStatusFilter get statusFilter => switch (this) {
        _Tab.all       => OperatorStatusFilter.all,
        _Tab.submitted => OperatorStatusFilter.submitted,
        _Tab.returned  => OperatorStatusFilter.returned,
      };
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class OperatorMutationsScreen extends ConsumerStatefulWidget {
  const OperatorMutationsScreen({super.key});

  @override
  ConsumerState<OperatorMutationsScreen> createState() =>
      _OperatorMutationsScreenState();
}

class _OperatorMutationsScreenState
    extends ConsumerState<OperatorMutationsScreen> {
  final _searchController = TextEditingController();
  _Tab _activeTab = _Tab.submitted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(operatorAllMutationsProvider);
        // Sync provider filter ke tab awal
        ref.read(operatorStatusFilterProvider.notifier).state =
            _activeTab.statusFilter;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _switchTab(_Tab tab) {
    setState(() => _activeTab = tab);
    ref.read(operatorStatusFilterProvider.notifier).state = tab.statusFilter;
  }

  @override
  Widget build(BuildContext context) {
    final asyncIncoming = ref.watch(filteredIncomingMutationsProvider);
    final asyncAll      = ref.watch(operatorAllMutationsProvider);

    // Hitung badge jumlah (dari data mentah)
    final totalCount = asyncAll.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: _C.bg,
      extendBody: true,
      body: Column(
        children: [
          // ── App bar ───────────────────────────────────────────────────
          _buildTopBar(context, totalCount),

          // ── Search ────────────────────────────────────────────────────
          _buildSearchBar(),

          // ── Filter tab-pills ──────────────────────────────────────────
          _buildFilterTabs(asyncAll),

          const Divider(height: 1, color: _C.border),

          // ── List ──────────────────────────────────────────────────────
          Expanded(
            child: asyncIncoming.when(
              data:    (list) => _buildList(list),
              loading: () => const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _C.teal,
                ),
              ),
              error: (err, _) => _buildError(err),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomFloatingNavBar.scaffoldBottomBar(
        items: RoleNavConfig.getNavItemsForRole(UserRole.operator),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, int count) {
    return Container(
      color: _C.surface,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: const BoxDecoration(
            color: _C.surface,
            border: Border(
              bottom: BorderSide(color: _C.border, width: 1),
            ),
          ),
          child: Row(
            children: [
              // Back
              GestureDetector(
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(RouteNames.operatorDashboardPath);
                  }
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _C.bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _C.border),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 18,
                    color: _C.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Title
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Pengajuan Masuk',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _C.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Antrean berkas mutasi menunggu verifikasi',
                      style: TextStyle(
                        fontSize: 11,
                        color: _C.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Count badge (amber pulse)
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _C.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _C.border.withValues(alpha: 0.8)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$count Tiket',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _C.navy,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      color: _C.surface,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: _C.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
        ),
        child: TextField(
          key: const Key('input_search_mutations'),
          controller: _searchController,
          style: const TextStyle(
            fontSize: 13,
            color: _C.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Cari no. tiket, aset, pemohon...',
            hintStyle: TextStyle(
              fontSize: 13,
              color: _C.textSecondary.withValues(alpha: 0.6),
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 14, right: 8),
              child: Icon(
                Icons.search_rounded,
                size: 20,
                color: _C.textSecondary,
              ),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: _searchController.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      ref.read(operatorSearchQueryProvider.notifier).state = '';
                      setState(() {});
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: _C.textSecondary,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          onChanged: (value) {
            ref.read(operatorSearchQueryProvider.notifier).state = value;
            setState(() {});
          },
        ),
      ),
    );
  }

  // ── Filter tab-pills (scrollable) ─────────────────────────────────────────
  Widget _buildFilterTabs(AsyncValue<List<Mutation>> asyncAll) {
    final allList = asyncAll.valueOrNull ?? [];
    final totalAll = allList.length;
    final totalSubmitted =
        allList.where((m) => m.status == MutationStatus.submitted).length;
    final totalReturned =
        allList.where((m) => m.status == MutationStatus.returned).length;

    final counts = {
      _Tab.all: totalAll,
      _Tab.submitted: totalSubmitted,
      _Tab.returned: totalReturned,
    };

    return Container(
      color: _C.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 0, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _Tab.values.map((tab) {
            final active = _activeTab == tab;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _switchTab(tab),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: active ? _C.navy : _C.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: active
                          ? _C.navy
                          : _C.border.withValues(alpha: 0.8),
                    ),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: _C.navy.withValues(alpha: 0.18),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    tab.label(counts[tab] ?? 0),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w500,
                      color: active
                          ? Colors.white
                          : _C.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── List ──────────────────────────────────────────────────────────────────
  Widget _buildList(List<Mutation> mutations) {
    if (mutations.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      color: _C.teal,
      onRefresh: () async => ref.invalidate(operatorAllMutationsProvider),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        itemCount: mutations.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = mutations[index];
          return _MutationCard(
            mutation: item,
            onTap: () => context.push('/operator/mutations/${item.id}'),
          );
        },
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    final isSearch =
        ref.watch(operatorSearchQueryProvider).trim().isNotEmpty;

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
                color: isSearch ? _C.infoBg : _C.successBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isSearch
                    ? Icons.search_off_rounded
                    : Icons.check_circle_outline_rounded,
                size: 36,
                color: isSearch ? _C.info : _C.success,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearch
                  ? 'Tidak Ditemukan'
                  : 'Tidak Ada Pengajuan Masuk',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _C.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSearch
                  ? 'Coba kata kunci lain atau ubah filter.'
                  : 'Semua pengajuan telah diproses.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: _C.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error state ───────────────────────────────────────────────────────────
  Widget _buildError(Object err) {
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
                color: _C.errorBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: _C.error,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gagal Memuat Data',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _C.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$err',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: _C.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => ref.invalidate(operatorAllMutationsProvider),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _C.teal,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Coba Lagi',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Mutation Card (Stitch-style) ─────────────────────────────────────────────
class _MutationCard extends StatelessWidget {
  final Mutation mutation;
  final VoidCallback? onTap;

  const _MutationCard({required this.mutation, this.onTap});

  // ── Date helper ─────────────────────────────────────────────────────────
  static String _relativeDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  // ── Initials ─────────────────────────────────────────────────────────────
  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  // ── Avatar color from name ────────────────────────────────────────────────
  static Color _avatarBg(String name) {
    final hash = name.codeUnits.fold(0, (p, e) => p + e);
    const palette = [
      Color(0xFFECFDF5), // green
      Color(0xFFEFF6FF), // blue
      Color(0xFFF5F3FF), // purple
      Color(0xFFFFF7ED), // orange
      Color(0xFFFCE7F3), // pink
    ];
    return palette[hash % palette.length];
  }

  static Color _avatarFg(String name) {
    final hash = name.codeUnits.fold(0, (p, e) => p + e);
    const palette = [
      Color(0xFF059669),
      Color(0xFF1D4ED8),
      Color(0xFF7C3AED),
      Color(0xFFEA580C),
      Color(0xFFDB2777),
    ];
    return palette[hash % palette.length];
  }

  // ── Status badge ─────────────────────────────────────────────────────────
  ({Color fg, Color bg, String label}) _statusInfo(MutationStatus s) =>
      switch (s) {
        MutationStatus.submitted => (
          fg: const Color(0xFFB45309),
          bg: const Color(0xFFFEF3C7),
          label: 'Menunggu Verifikasi',
        ),
        MutationStatus.returned => (
          fg: const Color(0xFFB45309),
          bg: const Color(0xFFFFF7ED),
          label: 'Dikembalikan',
        ),
        MutationStatus.waitingKabagApproval => (
          fg: const Color(0xFF1D4ED8),
          bg: const Color(0xFFEFF6FF),
          label: 'Menunggu Kabag',
        ),
        MutationStatus.approved => (
          fg: const Color(0xFF059669),
          bg: const Color(0xFFECFDF5),
          label: 'Disetujui',
        ),
        MutationStatus.rejected => (
          fg: const Color(0xFFDC2626),
          bg: const Color(0xFFFEF2F2),
          label: 'Ditolak',
        ),
        _ => (
          fg: const Color(0xFF52606D),
          bg: const Color(0xFFF6F8FA),
          label: s.displayName,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final m   = mutation;
    final si  = _statusInfo(m.status);
    final ini = _initials(m.applicantName);
    final bg  = _avatarBg(m.applicantName);
    final fg  = _avatarFg(m.applicantName);

    return GestureDetector(
      key: Key('card_mutation_${m.id}'),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF2F4F7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: Ticket + Status ──────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    m.ticketNumber,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                      color: _C.navy,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                // Status badge with dot
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: si.bg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: si.fg.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: si.fg,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        si.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: si.fg,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Row 2: Avatar + Pemohon + Waktu ────────────────────────
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: bg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: fg.withValues(alpha: 0.18),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    ini,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.applicantName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _C.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _relativeDate(m.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: _C.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Asset info box (Stitch-style) ───────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _C.bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF2F4F7)),
              ),
              child: Column(
                children: [
                  // Asset name + code
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _C.navy.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          size: 18,
                          color: _C.navy,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.displayAssetName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _C.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              m.displayAssetCode,
                              style: const TextStyle(
                                fontSize: 10,
                                color: _C.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Container(
                      height: 1,
                      color: const Color(0xFFE5E7EB),
                    ),
                  ),
                  // Lokasi: asal → tujuan
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: _C.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          m.currentLocation,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _C.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: _C.textSecondary.withValues(alpha: 0.6),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          m.targetLocation,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _C.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Row 4: Doc info + CTA button ────────────────────────────
            Row(
              children: [
                // Doc chip
                if (m.documentName != null && m.documentName!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _C.bg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _C.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.attach_file_rounded,
                          size: 12,
                          color: _C.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '1 Lampiran',
                          style: const TextStyle(
                            fontSize: 10,
                            color: _C.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ] else
                  const Spacer(),

                // Periksa Pengajuan button
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: _C.navy,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: _C.navy.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Periksa Pengajuan',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
