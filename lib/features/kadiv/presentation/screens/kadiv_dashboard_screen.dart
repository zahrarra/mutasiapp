// lib/features/kadiv/presentation/screens/kadiv_dashboard_screen.dart
//
// Dashboard Screen untuk Role: Pemimpin Divisi (Kadiv) — KDV-001.
// UI Baseline Stitch 1:1 Pixel-Accurate
// Screen Reference: 9c9277a747354909891445fde3520f9d (MutasiKu — Dashboard Kadiv).
//
// Ketentuan:
// - Visual/layout pixel-accurate mengikuti Stitch.
// - Menjaga provider, data, state, approval flow, navigation, dan business logic.
// - Search bar glass transparan tanpa background putih solid.
// - Menjaga semua key dan string yang diverifikasi oleh test.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/widgets/custom_floating_nav_bar.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../providers/kadiv_approval_provider.dart';

/// Design tokens persis sesuai Stitch screen 9c9277a747354909891445fde3520f9d
abstract final class _C {
  static const navy = Color(0xFF0F3D56);
  static const teal = Color(0xFF0F766E);
  static const darkNavy = Color(0xFF0B2D40);
  static const bg = Color(0xFFF8F9FA);
  static const textPrimary = Color(0xFF172B4D);
  static const textSecondary = Color(0xFF52606D);
  static const border = Color(0xFFD0D5DD);
  static const borderLight = Color(0xFFE2E8F0);
  static const mintAccent = Color(0xFF9CF2E8);
  static const success = Color(0xFF15803D);
  static const warning = Color(0xFFB45309);
  static const warningLight = Color(0xFFFEF3C7);
  static const error = Color(0xFFB42318);
  static const cardBlue = Color(0xFFECF4FF);
}

class KadivDashboardScreen extends ConsumerStatefulWidget {
  const KadivDashboardScreen({super.key});

  @override
  ConsumerState<KadivDashboardScreen> createState() =>
      _KadivDashboardScreenState();
}

class _KadivDashboardScreenState extends ConsumerState<KadivDashboardScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedCategoryFilter; // null, 'ti', 'umum', 'prioritas', 'cabang'

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

  bool _isITAsset(Mutation m) {
    final catCode = m.asset.category.code.trim().toUpperCase();
    final catName = m.asset.category.name.trim().toLowerCase();
    final name = m.asset.name.toLowerCase();

    if (catCode == 'TI' || catCode == 'IT' || catCode == 'ELK') {
      return true;
    }
    if (catCode == 'FUR' || catCode == 'VEH' || catCode == 'UMUM') {
      return false;
    }

    return catName.contains('it') ||
        catName.contains('ti') ||
        catName.contains('elektronik') ||
        catName.contains('komputer') ||
        catName.contains('hardware') ||
        catName.contains('perangkat') ||
        name.contains('switch') ||
        name.contains('cisco') ||
        name.contains('server') ||
        name.contains('blade') ||
        name.contains('thinkpad') ||
        name.contains('macbook') ||
        name.contains('laptop') ||
        name.contains('pc');
  }

  List<Mutation> _filterMutations(List<Mutation> all) {
    // Antrean Kadiv: hanya yang sedang menunggu otorisasi Kadiv
    var list = all.where(isWaitingKadivApproval);

    // Filter kategori dari 4 Kategori Aset
    if (_selectedCategoryFilter != null) {
      switch (_selectedCategoryFilter) {
        case 'ti':
          list = list.where(_isITAsset);
          break;
        case 'umum':
          list = list.where((m) => !_isITAsset(m));
          break;
        case 'prioritas':
          // Prioritas: semua yang menunggu otorisasi Kadiv
          list = list.where(isWaitingKadivApproval);
          break;
        case 'cabang':
          list = list.where(
            (m) =>
                m.currentLocation.trim().toLowerCase() !=
                m.targetLocation.trim().toLowerCase(),
          );
          break;
      }
    }

    // Filter text search
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((m) {
        final ticket = m.ticketNumber.toLowerCase();
        final asset = m.asset.name.toLowerCase();
        final code = m.asset.assetCode.toLowerCase();
        final sn = m.displaySerialNumber.toLowerCase();
        final name = m.applicantName.toLowerCase();
        final loc =
            '${m.currentLocation} ${m.targetLocation} ${m.asset.location}'
                .toLowerCase();
        return ticket.contains(q) ||
            asset.contains(q) ||
            code.contains(q) ||
            sn.contains(q) ||
            name.contains(q) ||
            loc.contains(q);
      });
    }

    return list.toList();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'KD';
    if (parts.length == 1) {
      return parts.first.length >= 2
          ? parts.first.substring(0, 2).toUpperCase()
          : parts.first.toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agt',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    return '$day $month ${dt.year}';
  }

  void _showProfileMenu(BuildContext context, dynamic user) {
    final userName = user?.name ?? 'Kepala Divisi';
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
                      radius: 22,
                      backgroundColor: _C.navy,
                      child: Text(
                        _initials(userName),
                        style: const TextStyle(
                          color: _C.mintAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
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
                            style: _font(size: 15, weight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pemimpin Divisi (Kadiv)',
                            style: _font(size: 12, color: _C.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.person_outline_rounded,
                    color: _C.navy,
                  ),
                  title: Text(
                    'Profil Akun',
                    style: _font(size: 14, weight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push(RouteNames.profilePath);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.verified_user_outlined,
                    color: _C.navy,
                  ),
                  title: Text(
                    'Antrean Approval Kadiv',
                    style: _font(size: 14, weight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    ref.read(kadivStatusFilterProvider.notifier).state =
                        KadivStatusFilter.waiting;
                    context.push(RouteNames.kadivApprovalsPath);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.notifications_none_rounded,
                    color: _C.navy,
                  ),
                  title: Text(
                    'Notifikasi',
                    style: _font(size: 14, weight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push(RouteNames.kadivNotificationsPath);
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
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final userName = user?.name ?? 'Kepala Divisi';
    final stats = ref.watch(kadivStatsProvider);
    final asyncMutations = ref.watch(kadivAllMutationsProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      backgroundColor: _C.bg,
      body: RefreshIndicator(
        color: _C.teal,
        onRefresh: () async {
          ref.invalidate(kadivAllMutationsProvider);
          await ref.read(kadivAllMutationsProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Curved Deep Navy Header Container (Stitch 1:1) ─────────────
              _buildCurvedHeader(
                user: user,
                userName: userName,
                unreadCount: unreadCount,
              ),

              // ── 2. Body Content ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kategori Aset (Grid 2x2 — Stitch 1:1)
                    _buildCategoryGrid(stats),
                    const SizedBox(height: 24),

                    // Section: Pengajuan Terbaru (Perlu Persetujuan Segera)
                    _buildSectionHeader(),
                    const SizedBox(height: 12),

                    // Ticket Cards List (Stitch 1:1)
                    _buildTicketCardsList(asyncMutations),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomFloatingNavBar.scaffoldBottomBar(
        items: RoleNavConfig.getNavItemsForRole(UserRole.kadiv),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 1. CURVED DEEP NAVY HEADER CONTAINER (Stitch 1:1)
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
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background subtle glows
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.teal.withValues(alpha: 0.15),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding + 10, 20, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Menu Button (kiri) & Actions (Notif + Avatar) (kanan)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Kiri: Hamburger Menu Icon Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showProfileMenu(context, user),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
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

                    // Center: Brand Identitas MUTASIKU
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'MUTASIKU',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),

                    // Kanan: Notifications + Avatar Circle
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Notifikasi Button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () =>
                                context.push(RouteNames.kadivNotificationsPath),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 36,
                              height: 36,
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
                                    size: 19,
                                    color: Colors.white,
                                  ),
                                  if (unreadCount > 0)
                                    Positioned(
                                      top: 7,
                                      right: 7,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: _C.error,
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
                        const SizedBox(width: 8),

                        // Avatar Profile Circle
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showProfileMenu(context, user),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _C.darkNavy,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _C.mintAccent,
                                  width: 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
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
                                    style: const TextStyle(
                                      color: _C.mintAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 9,
                                      height: 9,
                                      decoration: BoxDecoration(
                                        color: _C.success,
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
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Search Bar: Clean transparent glass capsule pill (Stitch 1:1)
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.20),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        size: 20,
                        color: Colors.white.withValues(alpha: 0.70),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            inputDecorationTheme: const InputDecorationTheme(
                              filled: false,
                              fillColor: Colors.transparent,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            cursorColor: Colors.white,
                            style: _font(
                              size: 12.5,
                              color: Colors.white,
                              weight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              filled: false,
                              fillColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              hintText: 'Cari tiket, kode aset, pemohon...',
                              hintStyle: _font(
                                size: 12.5,
                                color: Colors.white.withValues(alpha: 0.70),
                                weight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_query.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Colors.white.withValues(alpha: 0.70),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Hero Banner Card: OTORISASI TIKET CEPAT & TEPAT (Stitch 1:1)
                _buildHeroBannerCard(userName),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HERO BANNER CARD (Stitch 1:1)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildHeroBannerCard(String userName) {
    return Container(
      decoration: BoxDecoration(
        color: _C.darkNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.teal.withValues(alpha: 0.40), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Isometric 3D Graphic (clean geometric polygon - Stitch 1:1)
          Positioned(
            right: -10,
            bottom: -10,
            width: 140,
            height: 140,
            child: IgnorePointer(
              child: CustomPaint(
                painter: const _IsometricGraphicPainter(),
                size: const Size(140, 140),
              ),
            ),
          ),

          // Content Column
          Row(
            children: [
              Expanded(
                flex: 11,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting Tag (Matches test: expect(find.text('Halo, $userName'), findsOneWidget))
                    Text(
                      'Halo, $userName',
                      style: _font(
                        size: 11,
                        weight: FontWeight.w700,
                        color: _C.mintAccent,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),

                    // Title
                    Text(
                      'OTORISASI TIKET CEPAT & TEPAT!',
                      style: _font(
                        size: 15,
                        weight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Subtitle
                    Text(
                      'Pengajuan lolos verifikasi Bagian Aset menunggu otorisasi Anda.',
                      style: _font(
                        size: 11,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Action Button (Primary Key: btn_lihat_approval_kadiv)
                    ElevatedButton.icon(
                      key: const Key('btn_lihat_approval_kadiv'),
                      onPressed: () {
                        ref.read(kadivStatusFilterProvider.notifier).state =
                            KadivStatusFilter.waiting;
                        context.push(RouteNames.kadivApprovalsPath);
                      },
                      icon: const Text(
                        'Tinjau Antrean',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      label: const Icon(Icons.arrow_forward_rounded, size: 15),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _C.navy,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const Expanded(flex: 6, child: SizedBox.shrink()),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // KATEGORI ASET (Grid 2x2 — Stitch 1:1)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildCategoryGrid(KadivApprovalStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategori Aset',
          style: _font(
            size: 14,
            weight: FontWeight.w700,
            color: _C.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCategoryCard(
                title: 'Aset TI',
                subtitle: 'Server, Jaringan',
                icon: Icons.laptop_mac_rounded,
                iconBg: _C.cardBlue,
                iconColor: _C.navy,
                isSelected: _selectedCategoryFilter == 'ti',
                onTap: () {
                  setState(() {
                    _selectedCategoryFilter = _selectedCategoryFilter == 'ti'
                        ? null
                        : 'ti';
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCategoryCard(
                title: 'Aset Umum',
                subtitle: 'Gedung & Mebel',
                icon: Icons.chair_rounded,
                iconBg: _C.cardBlue,
                iconColor: _C.navy,
                isSelected: _selectedCategoryFilter == 'umum',
                onTap: () {
                  setState(() {
                    _selectedCategoryFilter = _selectedCategoryFilter == 'umum'
                        ? null
                        : 'umum';
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCategoryCard(
                title: 'Prioritas Kadiv',
                subtitle: 'Nilai Tinggi (${stats.waitingApprovalCount})',
                icon: Icons.verified_user_rounded,
                iconBg: _C.warningLight,
                iconColor: _C.warning,
                isSelected: _selectedCategoryFilter == 'prioritas',
                onTap: () {
                  setState(() {
                    _selectedCategoryFilter =
                        _selectedCategoryFilter == 'prioritas'
                        ? null
                        : 'prioritas';
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCategoryCard(
                title: 'Pindah Cabang',
                subtitle: 'Antar Wilayah',
                icon: Icons.swap_horiz_rounded,
                iconBg: _C.cardBlue,
                iconColor: _C.navy,
                isSelected: _selectedCategoryFilter == 'cabang',
                onTap: () {
                  setState(() {
                    _selectedCategoryFilter =
                        _selectedCategoryFilter == 'cabang' ? null : 'cabang';
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? _C.teal : _C.border,
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: _font(
                        size: 13,
                        weight: FontWeight.w700,
                        color: _C.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: _font(
                        size: 10.5,
                        weight: FontWeight.w500,
                        color: _C.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: isSelected ? _C.teal : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SECTION HEADER: PENGAJUAN TERBARU (Stitch 1:1)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Pengajuan Terbaru',
          style: _font(
            size: 14,
            weight: FontWeight.w700,
            color: _C.textPrimary,
          ),
        ),
        GestureDetector(
          onTap: () {
            ref.read(kadivStatusFilterProvider.notifier).state =
                KadivStatusFilter.waiting;
            context.push(RouteNames.kadivApprovalsPath);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Lihat Antrean',
                style: _font(size: 12, weight: FontWeight.w600, color: _C.navy),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right_rounded, size: 16, color: _C.navy),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TICKET CARDS LIST (Stitch 1:1)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildTicketCardsList(AsyncValue<List<Mutation>> asyncMutations) {
    return asyncMutations.when(
      data: (allMutations) {
        final filtered = _filterMutations(allMutations);

        if (filtered.isEmpty) {
          return _buildEmptyState();
        }

        // Tampilkan 5 pengajuan terbaru
        final itemsToDisplay = filtered.take(5).toList();

        return Column(
          children: itemsToDisplay.map((m) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTicketCard(m),
            );
          }).toList(),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(strokeWidth: 2, color: _C.teal),
        ),
      ),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Text(
          'Gagal memuat mutasi: $err',
          style: const TextStyle(color: _C.error, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildTicketCard(Mutation m) {
    final isIT = _isITAsset(m);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: No Tiket & Tanggal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'No. Tiket: ${m.ticketNumber}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  color: _C.navy,
                ),
              ),
              Text(
                _formatDate(m.createdAt),
                style: _font(
                  size: 11,
                  color: _C.textSecondary,
                  weight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: _C.border.withValues(alpha: 0.6), height: 1),
          const SizedBox(height: 12),

          // Asset Row: Thumbnail + Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail Box
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.border),
                ),
                child: Icon(
                  isIT ? Icons.laptop_mac_rounded : Icons.inventory_2_outlined,
                  color: _C.navy,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),

              // Detail Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.asset.name,
                      style: _font(
                        size: 13.5,
                        weight: FontWeight.w700,
                        color: _C.textPrimary,
                        height: 1.25,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'SN: ${m.displaySerialNumber} • ${isIT ? 'Valuasi Tinggi' : 'Aset Tetap'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _C.textSecondary,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 14,
                          color: _C.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${m.applicantName} (Pemohon)',
                            style: _font(
                              size: 11,
                              color: _C.textSecondary,
                              weight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Transfer Route Info Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.border.withValues(alpha: 0.70)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.domain_outlined,
                  size: 14,
                  color: _C.textSecondary,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    m.currentLocation,
                    style: _font(
                      size: 11,
                      color: _C.textSecondary,
                      weight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: const Icon(
                    Icons.east_rounded,
                    size: 14,
                    color: _C.teal,
                  ),
                ),
                const Icon(Icons.cell_tower_rounded, size: 14, color: _C.navy),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    m.targetLocation,
                    style: _font(
                      size: 11,
                      color: _C.navy,
                      weight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Review & Setujui CTA Button (Stitch 1:1)
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: () => context.push('/kadiv/approvals/${m.id}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.navy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Review & Setujui',
                    style: _font(
                      size: 13,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
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
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline, size: 44, color: _C.success),
          const SizedBox(height: 12),
          Text(
            'Tidak Ada Antrean Approval',
            style: _font(
              size: 14,
              weight: FontWeight.w700,
              color: _C.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _query.isNotEmpty
                ? 'Tidak ada hasil yang cocok dengan pencarian "$_query".'
                : 'Seluruh mutasi telah diproses oleh Pemimpin Divisi.',
            textAlign: TextAlign.center,
            style: _font(size: 12, color: _C.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// ISOMETRIC 3D GRAPHIC PAINTER (Stitch 1:1)
// ────────────────────────────────────────────────────────────────────────────
class _IsometricGraphicPainter extends CustomPainter {
  const _IsometricGraphicPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 160.0;
    canvas.save();
    canvas.scale(scale, scale);

    // 1. Top base diamond polygon: 80,30 -> 145,65 -> 80,100 -> 15,65
    final pathTopBase = Path()
      ..moveTo(80, 30)
      ..lineTo(145, 65)
      ..lineTo(80, 100)
      ..lineTo(15, 65)
      ..close();
    canvas.drawPath(
      pathTopBase,
      Paint()
        ..color = const Color(0xFF0F766E).withValues(alpha: 0.50)
        ..style = PaintingStyle.fill,
    );

    // 2. Left side: 15,65 -> 80,100 -> 80,118 -> 15,83
    final pathLeft = Path()
      ..moveTo(15, 65)
      ..lineTo(80, 100)
      ..lineTo(80, 118)
      ..lineTo(15, 83)
      ..close();
    canvas.drawPath(
      pathLeft,
      Paint()
        ..color = const Color(0xFF0A2636).withValues(alpha: 0.70)
        ..style = PaintingStyle.fill,
    );

    // 3. Right side: 145,65 -> 80,100 -> 80,118 -> 145,83
    final pathRight = Path()
      ..moveTo(145, 65)
      ..lineTo(80, 100)
      ..lineTo(80, 118)
      ..lineTo(145, 83)
      ..close();
    canvas.drawPath(
      pathRight,
      Paint()
        ..color = const Color(0xFF0F3D56).withValues(alpha: 0.70)
        ..style = PaintingStyle.fill,
    );

    // 4. Dashed border outline: 80,18 -> 142,52 -> 142,110 -> 80,144 -> 18,110 -> 18,52 -> close
    final borderPath = Path()
      ..moveTo(80, 18)
      ..lineTo(142, 52)
      ..lineTo(142, 110)
      ..lineTo(80, 144)
      ..lineTo(18, 110)
      ..lineTo(18, 52)
      ..close();
    canvas.drawPath(
      borderPath,
      Paint()
        ..color = const Color(0xFF0F766E).withValues(alpha: 0.60)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );

    // 5. Inner isometric server box
    // Top face: 80,50 -> 108,66 -> 80,82 -> 52,66
    final innerTop = Path()
      ..moveTo(80, 50)
      ..lineTo(108, 66)
      ..lineTo(80, 82)
      ..lineTo(52, 66)
      ..close();
    canvas.drawPath(
      innerTop,
      Paint()
        ..color = const Color(0xFFF6F8FA)
        ..style = PaintingStyle.fill,
    );

    // Left face: 52,66 -> 80,82 -> 80,118 -> 52,102
    final innerLeft = Path()
      ..moveTo(52, 66)
      ..lineTo(80, 82)
      ..lineTo(80, 118)
      ..lineTo(52, 102)
      ..close();
    canvas.drawPath(
      innerLeft,
      Paint()
        ..color = const Color(0xFF52606D)
        ..style = PaintingStyle.fill,
    );

    // Right face: 108,66 -> 80,82 -> 80,118 -> 108,102
    final innerRight = Path()
      ..moveTo(108, 66)
      ..lineTo(80, 82)
      ..lineTo(80, 118)
      ..lineTo(108, 102)
      ..close();
    canvas.drawPath(
      innerRight,
      Paint()
        ..color = const Color(0xFFD0D5DD)
        ..style = PaintingStyle.fill,
    );

    // Server LEDs: (65,85), (71,88), (65,94), (71,97)
    canvas.drawCircle(
      const Offset(65, 85),
      2.0,
      Paint()..color = const Color(0xFF15803D),
    );
    canvas.drawCircle(
      const Offset(71, 88),
      2.0,
      Paint()..color = const Color(0xFF15803D),
    );
    canvas.drawCircle(
      const Offset(65, 94),
      2.0,
      Paint()..color = const Color(0xFF0F766E),
    );
    canvas.drawCircle(
      const Offset(71, 97),
      2.0,
      Paint()..color = const Color(0xFF15803D),
    );

    // Green circular badge: center (112, 54), radius 14
    canvas.drawCircle(
      const Offset(112, 54),
      14,
      Paint()..color = const Color(0xFF0F766E),
    );

    // White Checkmark: 107,54 -> 110.5,57.5 -> 117,51
    final checkPath = Path()
      ..moveTo(107, 54)
      ..lineTo(110.5, 57.5)
      ..lineTo(117, 51);
    canvas.drawPath(
      checkPath,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Pemimpin Divisi Dashboard Screen Alias ───────────────────────────────────
typedef PemimpinDivisiDashboardScreen = KadivDashboardScreen;
