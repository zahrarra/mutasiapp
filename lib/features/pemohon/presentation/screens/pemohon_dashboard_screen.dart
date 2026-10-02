// lib/features/pemohon/presentation/screens/pemohon_dashboard_screen.dart
//
// Dashboard Pemohon — Baseline UI Stitch (Screen: 304565ac29f447dd985bde4075809822).
// Menggunakan Curved Deep Navy Header, Search Bar transparan 1:1 Stitch,
// Metric Row (Dalam Proses, Perlu Tindakan, Selesai), Action Banner,
// Stepper Timeline 6 Langkah, dan List Pengajuan Terbaru.
// Tetap mempertahankan 100% business logic, provider, navigation, dan flow MutasiKu.

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
import '../../../mutation/presentation/providers/mutation_provider.dart';
import '../../../notification/presentation/providers/notification_provider.dart';

/// Design tokens sesuai DESIGN.md dan Stitch baseline UI
abstract final class _C {
  static const navy = Color(0xFF0F3D56);
  static const darkNavy = Color(0xFF072435);
  static const teal = Color(0xFF0F766E);
  static const tealAccent = Color(0xFF006A63);
  static const bg = Color(0xFFF6F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF172B4D);
  static const textSecondary = Color(0xFF52606D);
  static const borderLight = Color(0xFFE2E8F0);

  // Status colors
  static const success = Color(0xFF15803D);
  static const successBg = Color(0xFFECFDF5);

  static const info = Color(0xFF175CD3);
  static const infoBg = Color(0xFFEFF6FF);

  static const warning = Color(0xFFB45309);
  static const warningBg = Color(0xFFFFFBEB);
  static const warningBorder = Color(0xFFFDE68A);

  static const error = Color(0xFFB42318);
  static const errorBg = Color(0xFFFEF2F2);
}

class PemohonDashboardScreen extends ConsumerStatefulWidget {
  const PemohonDashboardScreen({super.key});

  @override
  ConsumerState<PemohonDashboardScreen> createState() =>
      _PemohonDashboardScreenState();
}

class _PemohonDashboardScreenState
    extends ConsumerState<PemohonDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
    if (val != _searchQuery) {
      setState(() => _searchQuery = val);
    }
  }

  String _detailPath(String id) =>
      RouteNames.pemohonMutasiDetailPath.replaceFirst(':id', id);

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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final mutationsAsync = ref.watch(mutationListProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      backgroundColor: _C.bg,
      body: RefreshIndicator(
        color: _C.navy,
        onRefresh: () async {
          ref.invalidate(mutationListProvider);
          await ref.read(mutationListProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // ── 1. Curved Deep Navy Header Container ─────────────────────────
            SliverToBoxAdapter(
              child: _buildCurvedHeader(
                user: user,
                unreadCount: unreadCount,
              ),
            ),

            // ── 2. Body Content ──────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Quick Action Banner: "Butuh Mutasi / Relokasi Aset?"
                  _buildQuickActionBanner(),
                  const SizedBox(height: 14),

                  // 3 Metric Cards: Dalam Proses, Perlu Tindakan, Selesai
                  _buildMetricGrid(mutationsAsync),
                  const SizedBox(height: 16),

                  // Section: Mutasi Dalam Proses
                  _buildActiveSection(mutationsAsync),
                  const SizedBox(height: 20),

                  // Section: Pengajuan Terbaru
                  _buildRecentSection(mutationsAsync),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomFloatingNavBar.scaffoldBottomBar(
        items: RoleNavConfig.getNavItemsForRole(UserRole.pemohon),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HEADER SECTION (Curved Deep Navy #0F3D56, Search Bar Transparan 1:1 Stitch)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildCurvedHeader({
    required dynamic user,
    required int unreadCount,
  }) {
    final userName = user?.name ?? 'Pemohon';
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
            padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Menu Button (Kiri) & Notifikasi + Avatar (Kanan) — Stitch 1:1
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Menu Hamburger Button (Stitch: w-10 h-10 rounded-full bg-white/10 border-white/10)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showMenu(context, user),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 40,
                          height: 40,
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
                        // Notifikasi Button (Stitch: w-10 h-10 rounded-full bg-white/10 border-white/15)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => context.go(RouteNames.pemohonNotificationsPath),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 40,
                              height: 40,
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
                            onTap: () => context.go(RouteNames.pemohonProfilePath),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF006A63),
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
                        'Halo, $userName!',
                        style: _font(
                          size: 22,
                          weight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pengajuan & Pelacakan Mutasi Aset Kantor',
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
                    color: Colors.white.withValues(alpha: 0.10),
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
                          padding: const EdgeInsets.only(left: 16, right: 12),
                          child: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: Colors.white.withValues(alpha: 0.70),
                          ),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
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
                        hintText: 'Cari nomor tiket, kode aset, status...',
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
  // QUICK ACTION BANNER ("Butuh Mutasi / Relokasi Aset?")
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildQuickActionBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_C.navy, _C.darkNavy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.teal.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: _C.navy.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _C.tealAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.add_to_photos_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Butuh Mutasi / Relokasi Aset?',
                  style: _font(
                    size: 13,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ajukan perpindahan barang inventaris dinas dengan cepat & terlacak.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _font(
                    size: 11,
                    weight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.75),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: _C.tealAccent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => context.go(RouteNames.pemohonMutasiCreatePath),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Ajukan Mutasi',
                      style: _font(
                        size: 11,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
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

  // ──────────────────────────────────────────────────────────────────────────
  // 3 METRIC CARDS ROW (Dalam Proses, Perlu Tindakan, Selesai)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildMetricGrid(AsyncValue<List<Mutation>> mutationsAsync) {
    final list = mutationsAsync.valueOrNull ?? const <Mutation>[];

    // 1. Dalam Proses: Mutasi Saya yang sedang dalam proses berjalan
    final inProcessCount = list.where(_isInProcess).length;

    // 2. Perlu Tindakan: Hanya mutasi yang butuh tindakan Pemohon (konfirmasi / revisi)
    final actionCount = list.where(_needsAction).length;

    // 3. Selesai: Mutasi yang sudah benar-benar Selesai dari data Mutasi Saya
    final completedCount =
        list.where((m) => m.status == MutationStatus.completed).length;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.sync_rounded,
            iconColor: _C.info,
            iconBg: _C.infoBg,
            title: 'Dalam Proses',
            value: '$inProcessCount Tiket',
            onTap: () => context.go(
              '${RouteNames.pemohonMutasiPath}?filter=progress',
              extra: 'progress',
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.assignment_turned_in_rounded,
            iconColor: _C.warning,
            iconBg: _C.warningBg,
            borderColor: actionCount > 0 ? _C.warningBorder : null,
            title: 'Perlu Tindakan',
            value: '$actionCount Tiket',
            onTap: () => context.go(
              '${RouteNames.pemohonMutasiPath}?filter=action',
              extra: 'action',
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.verified_rounded,
            iconColor: _C.success,
            iconBg: _C.successBg,
            title: 'Selesai',
            value: '$completedCount Tiket',
            onTap: () => context.go(
              '${RouteNames.pemohonMutasiPath}?filter=done',
              extra: 'done',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String value,
    Color? borderColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _C.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor ?? _C.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: _font(
                  size: 13,
                  weight: FontWeight.w800,
                  color: iconColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: _font(
                  size: 11,
                  weight: FontWeight.w600,
                  color: _C.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SECTION: MUTASI DALAM PROSES (WITH 6-STEP STEPPER, TANPA "LIHAT SEMUA")
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildActiveSection(AsyncValue<List<Mutation>> mutationsAsync) {
    final list = mutationsAsync.valueOrNull ?? const <Mutation>[];
    final active =
        list
            .where(_isActive)
            .where(_matchesSearch)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: _C.info,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Mutasi Dalam Proses',
              style: _font(
                size: 14,
                weight: FontWeight.w700,
                color: _C.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _C.infoBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${active.length} Berjalan',
                style: _font(
                  size: 10,
                  weight: FontWeight.w700,
                  color: _C.info,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (active.isEmpty)
          _buildEmptyActiveCard()
        else
          _buildMutationProcessCard(active.first),
      ],
    );
  }

  Widget _buildEmptyActiveCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.borderLight),
      ),
      child: Column(
        children: [
          Text(
            'Belum ada mutasi aktif',
            style: _font(size: 13, weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Pengajuan yang sedang berjalan akan tampil di sini.',
            textAlign: TextAlign.center,
            style: _font(size: 11, color: _C.textSecondary),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go(RouteNames.pemohonMutasiCreatePath),
            child: Text(
              'Ajukan Mutasi',
              style: _font(
                size: 12,
                weight: FontWeight.w700,
                color: _C.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMutationProcessCard(Mutation m) {
    final step = _stitchStepIndex(m);
    const labels = [
      'Diajukan',
      'Verifikasi',
      'Disetujui',
      'Update Aset',
      'Konfirmasi',
      'Selesai',
    ];

    return Material(
      color: _C.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.go(_detailPath(m.id)),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Ticket number & status pill
              Row(
                children: [
                  Expanded(
                    child: Text(
                      m.ticketNumber.isNotEmpty
                          ? m.ticketNumber
                          : m.displayAssetCode,
                      style: _font(
                        size: 12,
                        weight: FontWeight.w700,
                        color: _C.navy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _statusPill(m.status),
                ],
              ),
              const SizedBox(height: 8),

              // Asset info
              Text(
                m.displayAssetName,
                style: _font(
                  size: 14,
                  weight: FontWeight.w700,
                  color: _C.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'SN: ${m.displaySerialNumber}',
                style: _font(size: 11, color: _C.textSecondary),
              ),
              const SizedBox(height: 10),

              // Route box
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _C.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.borderLight),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.apartment_rounded,
                      size: 15,
                      color: _C.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        m.currentLocation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _font(
                          size: 11,
                          weight: FontWeight.w500,
                          color: _C.textPrimary,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 15,
                        color: _C.teal,
                      ),
                    ),
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
                      Icons.domain_rounded,
                      size: 15,
                      color: _C.navy,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 6-Step Stepper Timeline
              SizedBox(
                height: 52,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final stepWidth = constraints.maxWidth / labels.length;
                    final progress =
                        (step.clamp(0, labels.length - 1)) /
                        (labels.length - 1);

                    return Stack(
                      children: [
                        // Background line
                        Positioned(
                          top: 10,
                          left: stepWidth / 2,
                          right: stepWidth / 2,
                          child: Container(
                            height: 2,
                            color: _C.borderLight,
                          ),
                        ),
                        // Active progress line
                        Positioned(
                          top: 10,
                          left: stepWidth / 2,
                          width: (constraints.maxWidth - stepWidth) * progress,
                          child: Container(
                            height: 2,
                            color: _C.success,
                          ),
                        ),
                        // Dots & Labels
                        Row(
                          children: [
                            for (var i = 0; i < labels.length; i++)
                              SizedBox(
                                width: stepWidth,
                                child: Column(
                                  children: [
                                    _buildStepDot(i, step),
                                    const SizedBox(height: 4),
                                    Text(
                                      labels[i],
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: _font(
                                        size: 9,
                                        weight: i == step
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: i < step
                                            ? _C.success
                                            : i == step
                                                ? _C.info
                                                : _C.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              const Divider(height: 1, color: _C.borderLight),
              const SizedBox(height: 10),

              // Bottom CTA
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lihat Detail Pelacakan',
                    style: _font(
                      size: 12,
                      weight: FontWeight.w700,
                      color: _C.navy,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: _C.navy,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepDot(int i, int active) {
    if (i < active) {
      return Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: _C.success,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 12,
          color: Colors.white,
        ),
      );
    }
    if (i == active) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: _C.info,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _C.info.withValues(alpha: 0.25),
              blurRadius: 0,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: _C.surface,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
      ),
    );
  }

  int _stitchStepIndex(Mutation m) {
    switch (m.status) {
      case MutationStatus.submitted:
      case MutationStatus.returned:
        return 0;
      case MutationStatus.waitingAssetVerification:
      case MutationStatus.verified:
        return 1;
      case MutationStatus.waitingDivisionHeadApproval:
      case MutationStatus.waitingKabagApproval:
      case MutationStatus.waitingKadivApproval:
        return 2;
      case MutationStatus.approved:
        return 3;
      case MutationStatus.waitingConfirmation:
      case MutationStatus.pendingConfirmation:
        return 4;
      case MutationStatus.completed:
        return 5;
      case MutationStatus.rejected:
      case MutationStatus.waitingSync:
        return 0;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SECTION: PENGAJUAN TERBARU
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildRecentSection(AsyncValue<List<Mutation>> mutationsAsync) {
    final list = mutationsAsync.valueOrNull ?? const <Mutation>[];
    final recent = list.where(_matchesSearch).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final items = recent.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Pengajuan Terbaru',
              style: _font(
                size: 14,
                weight: FontWeight.w700,
                color: _C.textPrimary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.go(RouteNames.pemohonMutasiPath),
              child: Row(
                children: [
                  Text(
                    'Lihat Semua',
                    style: _font(
                      size: 11,
                      weight: FontWeight.w600,
                      color: _C.navy,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 15,
                    color: _C.navy,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.borderLight),
            ),
            child: Text(
              'Belum ada pengajuan mutasi.',
              textAlign: TextAlign.center,
              style: _font(size: 12, color: _C.textSecondary),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      indent: 14,
                      endIndent: 14,
                      color: _C.borderLight,
                    ),
                  _buildRecentItem(items[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRecentItem(Mutation m) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(_detailPath(m.id)),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _C.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.borderLight),
                ),
                child: Icon(
                  _categoryIcon(m.displayAssetName, m.displayAssetCode),
                  size: 20,
                  color: _C.navy,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.ticketNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _font(
                        size: 11,
                        weight: FontWeight.w700,
                        color: _C.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      m.displayAssetName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _font(
                        size: 13,
                        weight: FontWeight.w700,
                        color: _C.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${m.targetLocation}  •  ${_fmtDate(m.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _font(size: 10, color: _C.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _statusPill(m.status),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STATUS PILL & HELPERS
  // ──────────────────────────────────────────────────────────────────────────
  Widget _statusPill(MutationStatus status) {
    final bg = _pillBg(status);
    final fg = _pillFg(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          Text(
            _shortStatus(status),
            style: _font(size: 10, weight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String name, String code) {
    final lower = '$name $code'.toLowerCase();
    if (lower.contains('laptop') ||
        lower.contains('macbook') ||
        lower.contains('thinkpad') ||
        lower.contains('dell') ||
        lower.contains('pc') ||
        lower.contains('server') ||
        lower.contains('switch')) {
      return Icons.laptop_mac_rounded;
    }
    if (lower.contains('kursi') ||
        lower.contains('meja') ||
        lower.contains('lemari') ||
        lower.contains('furnitur')) {
      return Icons.chair_rounded;
    }
    return Icons.devices_other_rounded;
  }

  void _showMenu(BuildContext context, [dynamic user]) {
    final userName = user?.name ?? 'Pemohon';
    final roleName = user?.role?.displayName ?? 'Pemohon';
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
                    color: _C.borderLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF006A63),
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
                              roleName,
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
                  leading: const Icon(Icons.sync_alt_rounded),
                  title: Text('Mutasi Saya', style: _font(size: 14)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.go(RouteNames.pemohonMutasiPath);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_none_rounded),
                  title: Text('Notifikasi', style: _font(size: 14)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.go(RouteNames.pemohonNotificationsPath);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded),
                  title: Text('Profil Pengguna', style: _font(size: 14)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.go(RouteNames.pemohonProfilePath);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isActive(Mutation m) =>
      m.status != MutationStatus.completed &&
      m.status != MutationStatus.rejected;

  bool _isInProcess(Mutation m) {
    return m.status == MutationStatus.submitted ||
        m.status == MutationStatus.waitingAssetVerification ||
        m.status == MutationStatus.verified ||
        m.status == MutationStatus.waitingKabagApproval ||
        m.status == MutationStatus.waitingKadivApproval ||
        m.status == MutationStatus.waitingDivisionHeadApproval ||
        m.status == MutationStatus.approved ||
        m.status == MutationStatus.waitingSync;
  }

  bool _needsAction(Mutation m) {
    return m.status == MutationStatus.waitingConfirmation ||
        m.status == MutationStatus.pendingConfirmation ||
        m.status == MutationStatus.returned;
  }

  bool _matchesSearch(Mutation m) {
    if (_searchQuery.isEmpty) return true;
    final values = [
      m.ticketNumber,
      m.displayAssetName,
      m.displayAssetCode,
      m.displaySerialNumber,
      m.currentLocation,
      m.targetLocation,
    ];
    return values.any((v) => v.toLowerCase().contains(_searchQuery));
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'P';
    if (parts.length == 1) {
      return parts.first.length >= 2
          ? parts.first.substring(0, 2).toUpperCase()
          : parts.first.toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Color _pillBg(MutationStatus s) {
    switch (s) {
      case MutationStatus.waitingConfirmation:
      case MutationStatus.pendingConfirmation:
        return _C.warningBg;
      case MutationStatus.returned:
      case MutationStatus.waitingSync:
        return const Color(0xFFEDF2F7);
      case MutationStatus.approved:
      case MutationStatus.completed:
      case MutationStatus.submitted:
      case MutationStatus.verified:
        return _C.infoBg;
      case MutationStatus.waitingAssetVerification:
      case MutationStatus.waitingDivisionHeadApproval:
      case MutationStatus.waitingKabagApproval:
      case MutationStatus.waitingKadivApproval:
        return _C.warningBg;
      case MutationStatus.rejected:
        return _C.errorBg;
    }
  }

  Color _pillFg(MutationStatus s) {
    switch (s) {
      case MutationStatus.waitingConfirmation:
      case MutationStatus.pendingConfirmation:
        return _C.warning;
      case MutationStatus.returned:
      case MutationStatus.waitingSync:
        return const Color(0xFF4A5568);
      case MutationStatus.approved:
      case MutationStatus.completed:
      case MutationStatus.submitted:
      case MutationStatus.verified:
        return _C.info;
      case MutationStatus.waitingAssetVerification:
      case MutationStatus.waitingDivisionHeadApproval:
      case MutationStatus.waitingKabagApproval:
      case MutationStatus.waitingKadivApproval:
        return _C.warning;
      case MutationStatus.rejected:
        return _C.error;
    }
  }

  String _shortStatus(MutationStatus s) {
    switch (s) {
      case MutationStatus.submitted:
        return 'Diajukan';
      case MutationStatus.returned:
        return 'Perlu Perbaikan';
      case MutationStatus.waitingAssetVerification:
        return 'Verifikasi Aset';
      case MutationStatus.waitingKabagApproval:
        return 'Menunggu Kabag';
      case MutationStatus.waitingDivisionHeadApproval:
      case MutationStatus.waitingKadivApproval:
        return 'Menunggu Kadiv';
      case MutationStatus.verified:
        return 'Terverifikasi';
      case MutationStatus.approved:
        return 'Disetujui';
      case MutationStatus.waitingConfirmation:
      case MutationStatus.pendingConfirmation:
        return 'Konfirmasi';
      case MutationStatus.completed:
        return 'Selesai';
      case MutationStatus.waitingSync:
        return 'Offline';
      case MutationStatus.rejected:
        return 'Ditolak';
    }
  }
}
