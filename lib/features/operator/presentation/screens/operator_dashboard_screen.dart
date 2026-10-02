// lib/features/operator/presentation/screens/operator_dashboard_screen.dart
//
// Dashboard Operator — UI Baseline Stitch (Screen: 8635da188ee14001bb4d2e31da291d20).
// Menggunakan Curved Deep Navy Header, Search Bar Kapsul Transparan 1:1 Stitch,
// Hero Action Banner (Tugas Operator SLA 18M), Kategori & Status Prioritas 2x2 Grid,
// dan Antrean Perlu Pemeriksaan dengan checklist badge & CTA Periksa & Teruskan Tiket.
// Mempertahankan 100% business logic, provider, navigation, dan flow Operator.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/widgets/custom_floating_nav_bar.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../providers/operator_verification_provider.dart';

/// Design tokens sesuai DESIGN.md dan Stitch baseline UI
abstract final class _C {
  static const navy = Color(0xFF0F3D56);
  static const teal = Color(0xFF0F766E);
  static const tealAccent = Color(0xFF006A63);
  static const bg = Color(0xFFF6F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF172B4D);
  static const textSecondary = Color(0xFF52606D);
  static const border = Color(0xFFE2E8F0);
}

class OperatorDashboardScreen extends ConsumerStatefulWidget {
  const OperatorDashboardScreen({super.key});

  @override
  ConsumerState<OperatorDashboardScreen> createState() =>
      _OperatorDashboardScreenState();
}

class _OperatorDashboardScreenState
    extends ConsumerState<OperatorDashboardScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final val = _searchController.text.trim().toLowerCase();
    if (val != _query) {
      setState(() => _query = val);
    }
  }

  TextStyle _font({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = _C.textPrimary,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.montserrat(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  List<Mutation> _filter(List<Mutation> list) {
    final q = _query.trim().toLowerCase();
    var result = list.where((m) => m.status == MutationStatus.submitted);
    if (q.isEmpty) return result.toList();
    return result.where((m) {
      final ticket = m.ticketNumber.toLowerCase();
      final asset = m.asset.name.toLowerCase();
      final code = m.asset.assetCode.toLowerCase();
      final name = m.applicantName.toLowerCase();
      return ticket.contains(q) ||
          asset.contains(q) ||
          code.contains(q) ||
          name.contains(q);
    }).toList();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.length >= 2
          ? parts.first.substring(0, 2).toUpperCase()
          : parts.first.toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  void _showMenu(BuildContext context, dynamic user) {
    final userName = user?.name ?? 'Operator';
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _C.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _C.tealAccent,
                      child: Text(
                        _initials(userName),
                        style: _font(
                          size: 13,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: _font(
                              size: 15,
                              weight: FontWeight.w700,
                              color: _C.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _C.teal.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Operator',
                              style: _font(
                                size: 11,
                                weight: FontWeight.w700,
                                color: _C.teal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.fact_check_outlined, color: _C.navy),
                  title: Text('Pengajuan Masuk', style: _font(size: 14)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push(RouteNames.operatorMutationsPath);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_none_rounded, color: _C.navy),
                  title: Text('Notifikasi', style: _font(size: 14)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push(RouteNames.operatorNotificationsPath);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded, color: _C.navy),
                  title: Text('Profil Pengguna', style: _font(size: 14)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push(RouteNames.profilePath);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.red),
                  title: Text(
                    'Keluar',
                    style: _font(size: 14, color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    ref.read(authStateProvider.notifier).logout();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final userName = user?.name ?? 'Operator';
    final stats = ref.watch(verificationStatsProvider);
    final asyncMutations = ref.watch(operatorAllMutationsProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      backgroundColor: _C.bg,
      body: RefreshIndicator(
        color: _C.teal,
        onRefresh: () async {
          ref.invalidate(operatorAllMutationsProvider);
          await ref.read(operatorAllMutationsProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // ── 1. Curved Deep Navy Header Container (Stitch 1:1) ─────────────
            SliverToBoxAdapter(
              child: _buildCurvedHeader(
                user: user,
                userName: userName,
                unreadCount: unreadCount,
              ),
            ),

            // ── 2. Body Content ──────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Hero Banner Card: Operator Pemeriksaan Kelengkapan Tiket
                  _buildHeroActionBanner(stats),
                  const SizedBox(height: 16),

                  // Kategori & Status Prioritas (2x2 Grid)
                  _buildPriorityCategoryGrid(stats),
                  const SizedBox(height: 20),

                  // Antrean Perlu Pemeriksaan
                  _buildQueueSection(asyncMutations),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomFloatingNavBar.scaffoldBottomBar(
        items: RoleNavConfig.getNavItemsForRole(UserRole.operator),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HEADER SECTION (Curved Deep Navy #0F3D56, Search Bar Transparan 1:1 Stitch)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildCurvedHeader({
    required dynamic user,
    required String userName,
    required int unreadCount,
  }) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _C.navy,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative glow (Stitch 1:1)
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 192,
              height: 192,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.teal.withValues(alpha: 0.20),
              ),
            ),
          ),
          Positioned(
            left: -16,
            bottom: -16,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.tealAccent.withValues(alpha: 0.15),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Menu Button (Kiri) & Notifikasi + Avatar (Kanan) — Stitch 1:1
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Menu Hamburger Button (Stitch: w-9 h-9 rounded-full bg-white/10 border-white/10)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showMenu(context, user),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.10),
                              width: 1.0,
                            ),
                          ),
                          child: const Icon(
                            Icons.menu_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // Right: Notifications Button & Avatar Profile Circle
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Notifikasi Button (Stitch: w-9 h-9 rounded-full bg-white/10 border-white/15)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => context.push(RouteNames.operatorNotificationsPath),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.10),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 1.0,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Icon(
                                    Icons.notifications_none_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  if (unreadCount > 0)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEF4444),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: _C.navy,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Avatar Profile Circle (Stitch: w-9 h-9 bg-[#006a63] border-2 border-white/30)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => context.push(RouteNames.profilePath),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _C.tealAccent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.30),
                                  width: 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.10),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Text(
                                    _initials(userName),
                                    style: _font(
                                      size: 12,
                                      weight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  Positioned(
                                    right: -1,
                                    bottom: -1,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF34D399),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _C.navy,
                                          width: 2.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Greeting & Subtext — Stitch 1:1
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, $userName',
                        style: _font(
                          size: 22,
                          weight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Verifikasi & Periksa Mutasi Aset',
                        style: _font(
                          size: 12,
                          weight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.70),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Search Bar Kapsul Transparan Persis Stitch Terbaru (1:1 Reference)
                Container(
                  width: double.infinity,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.20),
                      width: 1.0,
                    ),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      inputDecorationTheme: const InputDecorationTheme(
                        filled: false,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      cursorColor: Colors.white,
                      style: _font(
                        size: 13,
                        weight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: false,
                        fillColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 14, right: 10),
                          child: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: Colors.white.withValues(alpha: 0.70),
                          ),
                        ),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: Colors.white.withValues(alpha: 0.70),
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                        hintText: 'Cari nomor tiket, kode aset, pemohon...',
                        hintStyle: _font(
                          size: 13,
                          weight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.60),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HERO BANNER CARD (Pemeriksaan Kelengkapan Tiket — Stitch 1:1)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildHeroActionBanner(VerificationStats stats) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _C.navy,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _C.navy.withValues(alpha: 0.20),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background soft blur glow
          Positioned(
            right: -24,
            bottom: -24,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pill: Tugas Operator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.assignment_late_outlined,
                              size: 13,
                              color: Color(0xFF99F6E4),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Tugas Operator',
                              style: _font(
                                size: 10,
                                weight: FontWeight.w700,
                                color: const Color(0xFFCCFBF1),
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Title
                      Text(
                        'PEMERIKSAAN KELENGKAPAN TIKET',
                        style: _font(
                          size: 14,
                          weight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.2,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Subtitle
                      Text(
                        'Periksa kelengkapan berkas & SK SDM sebelum diteruskan ke Bagian Aset.',
                        style: _font(
                          size: 12,
                          weight: FontWeight.w400,
                          color: const Color(0xFFCCFBF1),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Action CTA + Status indicator
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ElevatedButton(
                            key: const Key('btn_lihat_pengajuan'),
                            onPressed: () => context.push(RouteNames.operatorMutationsPath),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: _C.navy,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Periksa Antrean',
                                  style: _font(
                                    size: 12,
                                    weight: FontWeight.w700,
                                    color: _C.navy,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 15,
                                  color: _C.navy,
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF99F6E4),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${stats.pendingCount} Tiket Menunggu',
                                style: _font(
                                  size: 11,
                                  weight: FontWeight.w600,
                                  color: const Color(0xFF99F6E4),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Right SLA Box (Stitch: w-16 h-16 rounded-2xl bg-white/10)
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.fact_check_outlined,
                        size: 28,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'SLA 18M',
                        style: _font(
                          size: 9,
                          weight: FontWeight.w800,
                          color: const Color(0xFFCCFBF1),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PRIORITY & CATEGORY CARDS (2x2 Grid — Stitch 1:1)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildPriorityCategoryGrid(VerificationStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'KATEGORI & STATUS PRIORITAS',
          style: _font(
            size: 11,
            weight: FontWeight.w700,
            color: _C.textPrimary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),

        // Row 1: Menunggu Verifikasi & Pengajuan Dikembalikan
        Row(
          children: [
            Expanded(
              child: _buildCategoryCard(
                icon: Icons.inbox_outlined,
                iconColor: const Color(0xFF1D4ED8),
                iconBg: const Color(0xFFEFF6FF),
                title: 'Menunggu Verifikasi',
                subtitle: '${stats.pendingCount} Tiket Baru',
                onTap: () => context.push(
                  '${RouteNames.operatorMutationsPath}?filter=submitted',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCategoryCard(
                icon: Icons.assignment_return_outlined,
                iconColor: const Color(0xFFD97706),
                iconBg: const Color(0xFFFFFBEB),
                title: 'Pengajuan Dikembalikan',
                subtitle: '${stats.returnedCount} Berkas Cek',
                onTap: () => context.push(
                  '${RouteNames.operatorMutationsPath}?filter=returned',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Row 2: Aset TI & Aset Umum
        Row(
          children: [
            Expanded(
              child: _buildCategoryCard(
                icon: Icons.laptop_mac_outlined,
                iconColor: _C.teal,
                iconBg: const Color(0xFFF0FDFA),
                title: stats.tiCount > 0
                    ? 'Aset TI (${stats.tiCount})'
                    : 'Aset TI',
                subtitle: 'Laptop, PC, dsb',
                onTap: () => context.push(
                  '${RouteNames.operatorMutationsPath}?filter=ti',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCategoryCard(
                icon: Icons.chair_outlined,
                iconColor: const Color(0xFF7E22CE),
                iconBg: const Color(0xFFFAF5FF),
                title: stats.umumCount > 0
                    ? 'Aset Umum (${stats.umumCount})'
                    : 'Aset Umum',
                subtitle: 'Furnitur, Armada',
                onTap: () => context.push(
                  '${RouteNames.operatorMutationsPath}?filter=umum',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _C.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.border),
            boxShadow: [
              BoxShadow(
                color: _C.navy.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _font(
                        size: 11,
                        weight: FontWeight.w700,
                        color: _C.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _font(
                        size: 10,
                        weight: FontWeight.w500,
                        color: _C.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: _C.textSecondary.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ANTREAN PERLU PEMERIKSAAN SECTION (Stitch 1:1)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildQueueSection(AsyncValue<List<Mutation>> asyncMutations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Antrean Perlu Pemeriksaan',
                  style: _font(
                    size: 13,
                    weight: FontWeight.w800,
                    color: _C.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Verifikasi kelengkapan berkas fisik & SK',
                  style: _font(
                    size: 11,
                    weight: FontWeight.w400,
                    color: _C.textSecondary,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => context.push('${RouteNames.operatorMutationsPath}?filter=all'),
              child: Row(
                children: [
                  Text(
                    'Lihat Semua',
                    style: _font(
                      size: 12,
                      weight: FontWeight.w600,
                      color: _C.navy,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: _C.navy,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        asyncMutations.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _C.teal,
              ),
            ),
          ),
          error: (e, _) => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Text(
              'Gagal memuat antrean: $e',
              style: _font(size: 12, color: const Color(0xFFB42318)),
            ),
          ),
          data: (all) {
            final list = _filter(all).take(10).toList();
            if (list.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36),
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _C.border),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.inbox_outlined,
                      size: 40,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tidak ada pengajuan menunggu',
                      style: _font(
                        size: 13,
                        weight: FontWeight.w600,
                        color: _C.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: list.map((m) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildQueueCard(m),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TICKET CARD ITEM (Stitch 1:1)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildQueueCard(Mutation m) {
    final initials = _initials(m.applicantName);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: _C.navy.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Ticket Number Monospace + Status Badge / Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No. Tiket: ',
                    style: _font(
                      size: 11,
                      weight: FontWeight.w500,
                      color: _C.textSecondary,
                    ),
                  ),
                  Text(
                    '#${m.ticketNumber}',
                    style: GoogleFonts.robotoMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _C.navy,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.circle,
                      size: 6,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      m.status.displayName,
                      style: _font(
                        size: 10,
                        weight: FontWeight.w600,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Applicant & Asset Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFF0FDFA),
                child: Text(
                  initials,
                  style: _font(
                    size: 12,
                    weight: FontWeight.w700,
                    color: _C.teal,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            m.applicantName,
                            style: _font(
                              size: 12,
                              weight: FontWeight.w700,
                              color: _C.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          'Pemohon',
                          style: _font(
                            size: 10,
                            weight: FontWeight.w500,
                            color: _C.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      m.asset.name,
                      style: _font(
                        size: 12,
                        weight: FontWeight.w700,
                        color: _C.navy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'SN: ${m.displaySerialNumber}',
                      style: GoogleFonts.robotoMono(
                        fontSize: 10,
                        color: _C.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Route Transfer Box (Stitch: bg-slate-50 rounded-xl)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.apartment_rounded,
                        size: 14,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          m.currentLocation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _font(
                            size: 11,
                            weight: FontWeight.w500,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: _C.teal,
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          m.targetLocation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: _font(
                            size: 11,
                            weight: FontWeight.w700,
                            color: _C.navy,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: _C.navy,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Document Checklist Badges (Stitch 1:1)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildDocumentBadge(
                label: 'SK SDM Terlampir',
                isAttached: m.documentName != null && m.documentName!.isNotEmpty,
              ),
              _buildDocumentBadge(
                label: 'Form Mutasi Terlampir',
                isAttached: true,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Button: Periksa & Teruskan Tiket
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.push(
                  RouteNames.operatorVerificationDetailPath
                      .replaceFirst(':id', m.id),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Periksa & Teruskan Tiket',
                    style: _font(
                      size: 13,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentBadge({
    required String label,
    required bool isAttached,
  }) {
    final fg = isAttached ? const Color(0xFF047857) : const Color(0xFF64748B);
    final bg = isAttached ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9);
    final border = isAttached ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAttached ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            size: 12,
            color: fg,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: _font(
              size: 10,
              weight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
