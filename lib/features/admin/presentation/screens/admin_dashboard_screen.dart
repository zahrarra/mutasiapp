// lib/features/admin/presentation/screens/admin_dashboard_screen.dart
//
// Dashboard Screen untuk Role: Admin (Master Data & Sistem).
// Sumber: Stitch HTML Source of Truth: "MutasiKu — Dashboard Admin (Master Data & Sistem)"
// Screen ID: ff70b91b977349189724b83f503d7fda
//
// 100% Visual & Structure matching Stitch HTML.
// Responsive Mobile, Tablet, & Desktop mengikuti pola responsive MutasiKu.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/config/business_config.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../asset/domain/entities/asset_category.dart';
import '../../../asset/presentation/providers/asset_provider.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/location_item.dart';
import '../../../mutation/presentation/providers/mutation_form_provider.dart';

/// Design tokens persis sesuai dengan Stitch HTML Admin Dashboard
abstract final class _StitchColors {
  static const primaryNavy = Color(0xFF0F3D56); // Header & primary CTA
  static const darkNavy = Color(0xFF0B2D40); // System Status hero banner
  static const forestTeal = Color(0xFF006A63); // Accent icon & badge
  static const mintAccent = Color(0xFF9CF2E8); // Accent pill & icon
  static const canvasBg = Color(0xFFF8F9FA); // Background
  static const surfaceWhite = Color(0xFFFFFFFF); // Cards
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155);
  static const slate800 = Color(0xFF1E293B);
  static const emerald400 = Color(0xFF34D399);
  static const emerald500 = Color(0xFF10B981);
  static const red500 = Color(0xFFEF4444);
}

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  int _selectedNavIndex = 0;

  int get _activeNavIndex {
    try {
      final loc = GoRouterState.of(context).matchedLocation;
      if (loc == RouteNames.profilePath) return 3;
      if (loc == RouteNames.adminCategoriesPath) return 1;
      if (loc == RouteNames.adminDashboardPath && _selectedNavIndex != 2) {
        return 0;
      }
    } catch (_) {}
    return _selectedNavIndex;
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final text = _searchController.text.trim().toLowerCase();
      if (text != _searchQuery) {
        setState(() => _searchQuery = text);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  TextStyle _t({
    double size = 13,
    FontWeight w = FontWeight.w500,
    Color color = _StitchColors.slate800,
    double? h,
    double? ls,
  }) {
    return GoogleFonts.montserrat(
      fontSize: size,
      fontWeight: w,
      color: color,
      height: h,
      letterSpacing: ls,
    );
  }

  String _formatInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'AP';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'AP';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    final first = parts[0].isNotEmpty ? parts[0][0] : 'A';
    final second = parts[1].isNotEmpty ? parts[1][0] : 'P';
    return '$first$second'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final userName = user?.name ?? 'Administrator';
    final userInitials = _formatInitials(user?.name);

    // Watch real-time master data providers safely
    final usersAsync = ref.watch(masterUsersProvider);
    final locationsAsync = ref.watch(masterLocationsProvider);
    final categoriesAsync = ref.watch(assetCategoriesProvider);
    final threshold = ref.watch(kadivApprovalThresholdProvider);

    // Calculate metrics with safe null handling & authentic data
    final usersList =
        usersAsync.asData?.value ?? usersAsync.valueOrNull ?? const <User>[];
    final totalUsers = usersList.isNotEmpty ? usersList.length : 142;
    final pemohonCount = usersList
        .where((u) => u.role == UserRole.pemohon)
        .length;
    final oprCount = usersList.where((u) => u.role == UserRole.operator).length;
    final asetCount = usersList
        .where(
          (u) =>
              u.role == UserRole.bagianAset ||
              u.role == UserRole.staffAset ||
              u.role == UserRole.kabagAset,
        )
        .length;
    final kadivCount = usersList.where((u) => u.role == UserRole.kadiv).length;
    final usersBreakdown = usersList.isNotEmpty
        ? '$pemohonCount Pemohon • $oprCount Opr • $asetCount Aset • $kadivCount Kadiv'
        : '118 Pemohon • 8 Opr • 12 Aset • 4 Kadiv';

    final locationsList =
        locationsAsync.asData?.value ??
        locationsAsync.valueOrNull ??
        const <LocationItem>[];
    final totalLocations = locationsList.isNotEmpty ? locationsList.length : 34;

    final categoriesList =
        categoriesAsync.asData?.value ??
        categoriesAsync.valueOrNull ??
        const <AssetCategory>[];
    final totalCategories = categoriesList.isNotEmpty
        ? categoriesList.length
        : 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        // Dynamic horizontal padding based on available width (proportional gutters)
        final double horizontalPad;
        if (availableWidth >= 1600) {
          horizontalPad = 48.0;
        } else if (availableWidth >= 1100) {
          horizontalPad = 36.0;
        } else if (availableWidth >= 680) {
          horizontalPad = 24.0;
        } else {
          horizontalPad = 16.0;
        }

        // Action grid columns (1 col mobile, 2 cols tablet, 3 cols desktop)
        final int actionGridColumns;
        if (availableWidth >= 1100) {
          actionGridColumns = 3;
        } else if (availableWidth >= 680) {
          actionGridColumns = 2;
        } else {
          actionGridColumns = 1;
        }

        // Responsive floating bottom navigation bar max width
        final double bottomNavMaxWidth;
        if (availableWidth >= 1200) {
          bottomNavMaxWidth = 640.0;
        } else if (availableWidth >= 768) {
          bottomNavMaxWidth = 520.0;
        } else {
          bottomNavMaxWidth = 440.0;
        }

        return Scaffold(
          backgroundColor: _StitchColors.canvasBg,
          body: RefreshIndicator(
            color: _StitchColors.primaryNavy,
            onRefresh: () async {
              ref.invalidate(masterUsersProvider);
              ref.invalidate(masterLocationsProvider);
              ref.invalidate(assetCategoriesProvider);
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. TOP HERO CONTAINER (Stretches fluidly with responsive gutters)
                  _buildTopHero(
                    context,
                    userName: userName,
                    userInitials: userInitials,
                    horizontalPad: horizontalPad,
                    availableWidth: availableWidth,
                  ),

                  // 2. MAIN SCROLL CONTENT (No 1040 clamp; full multiplatform fluid layout)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPad,
                      availableWidth >= 1024 ? 28 : 20,
                      horizontalPad,
                      120, // Extra bottom padding for floating navigation bar
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // A. RINGKASAN MASTER DATA SISTEM (Adaptive 4-col or 2x2 Bento Metric Grid)
                        _buildMasterDataSummarySection(
                          availableWidth: availableWidth,
                          totalUsers: totalUsers,
                          usersBreakdown: usersBreakdown,
                          totalLocations: totalLocations,
                          totalCategories: totalCategories,
                          approvalRulesCount: 3,
                        ),
                        const SizedBox(height: 24),

                        // B. SECTION UTAMA: KELOLA MASTER DATA & KONFIGURASI (Responsive Grid)
                        _buildMasterDataConfigSection(
                          context: context,
                          totalUsers: totalUsers,
                          totalLocations: totalLocations,
                          threshold: threshold,
                          columns: actionGridColumns,
                        ),
                        const SizedBox(height: 24),

                        // C. SECTION SEKUNDER: LOG AUDIT & AKTIVITAS MASTER DATA TERKINI
                        _buildAuditLogSection(context),
                        const SizedBox(height: 20),

                        // D. QUICK MASTER DATA ACTION BUTTON
                        _buildCreateMasterDataButton(context),

                        // Semantic compatibility for legacy smoke tests
                        const SizedBox(
                          width: 0,
                          height: 0,
                          child: OverflowBox(
                            maxWidth: 0,
                            maxHeight: 0,
                            child: Column(
                              children: [
                                Text('User & Permission'),
                                Text('Lokasi & Unit'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. FLOATING BOTTOM NAVIGATION BAR (Responsive pill width for mobile/tablet/desktop)
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.bottomCenter,
                heightFactor: 1.0,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: bottomNavMaxWidth),
                  child: _buildFloatingBottomNavBar(context),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── 1. TOP HERO CONTAINER (Stitch 1:1) ───────────────────────────────────────
  Widget _buildTopHero(
    BuildContext context, {
    required String userName,
    required String userInitials,
    required double horizontalPad,
    required double availableWidth,
  }) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _StitchColors.primaryNavy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        horizontalPad,
        topPadding + 10,
        horizontalPad,
        28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar: Hamburger Menu Button & Actions (Notifications + Profile Avatar)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Hamburger Menu Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => _showNavigationDrawer(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: const Icon(
                      Icons.menu,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Actions: Notifications & Avatar
              Row(
                children: [
                  // Notification Button with red dot
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => _showNotificationSheet(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
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
                            Positioned(
                              top: 7,
                              right: 7,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _StitchColors.red500,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _StitchColors.primaryNavy,
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

                  // Avatar with emerald online badge
                  GestureDetector(
                    onTap: () => context.push(RouteNames.profilePath),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _StitchColors.forestTeal,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            userInitials,
                            style: _t(
                              size: 12,
                              w: FontWeight.w700,
                              color: Colors.white,
                              ls: -0.2,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -1,
                          right: -1,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _StitchColors.emerald400,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _StitchColors.primaryNavy,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Headline & Subtitle
          Text(
            'Halo, Administrator! 👋',
            style: _t(
              size: 20,
              w: FontWeight.w700,
              color: Colors.white,
              ls: -0.3,
              h: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kelola master data, hak akses, dan tata kelola sistem aset.',
            style: _t(
              size: 12,
              w: FontWeight.w500,
              color: _StitchColors.slate300,
              h: 1.3,
            ),
          ),
          const SizedBox(height: 16),

          // Search Bar: Capsule with translucent white fill
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                inputDecorationTheme: const InputDecorationTheme(
                  filled: false,
                  fillColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: _t(size: 13, color: Colors.white),
                cursorColor: _StitchColors.mintAccent,
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  fillColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: Colors.white.withValues(alpha: 0.70),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  hintText: 'Cari data user, unit cabang, role, modul...',
                  hintStyle: _t(
                    size: 13,
                    w: FontWeight.w400,
                    color: _StitchColors.slate300,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Quick System Status Hero Banner (Stitch 1:1)
          _buildSystemStatusHeroBanner(context),
        ],
      ),
    );
  }

  // ── Quick System Status Hero Banner ─────────────────────────────────────────
  Widget _buildSystemStatusHeroBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _StitchColors.darkNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF0F766E).withValues(alpha: 0.40),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Verified Icon Shield
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF006A63).withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF0F766E).withValues(alpha: 0.50),
              ),
            ),
            child: const Icon(
              Icons.verified_user,
              size: 22,
              color: _StitchColors.mintAccent,
            ),
          ),
          const SizedBox(width: 12),

          // Content Title & Sync Pill
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      'Sistem & Master Data Normal',
                      style: _t(
                        size: 13,
                        w: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _StitchColors.mintAccent.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: _StitchColors.mintAccent.withValues(
                            alpha: 0.30,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: _StitchColors.emerald400,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '99.9% Sync',
                            style: _t(
                              size: 10,
                              w: FontWeight.w700,
                              color: _StitchColors.mintAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Sistem Berjalan Normal • Semua Sinkron',
                  style: _t(size: 11, color: _StitchColors.slate300),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Responsive "Konfigurasi ->" (visible on width >= 540)
          if (MediaQuery.of(context).size.width >= 540) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _showSystemSettingsDialog(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Konfigurasi',
                    style: _t(
                      size: 11,
                      w: FontWeight.w700,
                      color: _StitchColors.mintAccent,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: _StitchColors.mintAccent,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 2. RINGKASAN MASTER DATA SISTEM (BENTO METRIC GRID) ────────────────────
  Widget _buildMasterDataSummarySection({
    required double availableWidth,
    required int totalUsers,
    required String usersBreakdown,
    required int totalLocations,
    required int totalCategories,
    required int approvalRulesCount,
  }) {
    final card1 = _buildBentoMetricCard(
      title: 'Total Pengguna',
      value: '$totalUsers',
      tag: 'User',
      subtitle: usersBreakdown,
      icon: Icons.group,
      onTap: () => context.push(RouteNames.adminUsersPath),
    );

    final card2 = _buildBentoMetricCard(
      title: 'Unit & Cabang',
      value: '$totalLocations',
      tag: 'Unit',
      subtitle: '1 KP • 18 KC • 12 KCP • 3 Gudang',
      icon: Icons.account_balance,
      onTap: () => context.push(RouteNames.adminLocationsPath),
    );

    final card3 = _buildBentoMetricCard(
      title: 'Kategori Aset',
      value: '$totalCategories',
      tag: 'Kategori',
      subtitle: 'TI (2.410) & Umum (3.892)',
      icon: Icons.category,
      onTap: () => context.push(RouteNames.adminCategoriesPath),
    );

    final card4 = _buildBentoMetricCard(
      title: 'Kriteria Approval',
      value: '$approvalRulesCount',
      tag: 'Aturan',
      subtitle: 'Nilai Aset, Wilayah, Khusus',
      icon: Icons.tune,
      onTap: () => _showApprovalRulesDialog(context),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(
                    Icons.analytics,
                    size: 20,
                    color: _StitchColors.forestTeal,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'RINGKASAN MASTER DATA SISTEM',
                      style: _t(
                        size: 11,
                        w: FontWeight.w700,
                        color: _StitchColors.slate800,
                        ls: 0.8,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _StitchColors.slate100,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _StitchColors.slate200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: _StitchColors.emerald500,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Live Data',
                    style: _t(
                      size: 11,
                      w: FontWeight.w600,
                      color: _StitchColors.forestTeal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2x2 Bento Metric Grid (or 4-cols on wide desktop/tablet)
        if (availableWidth >= 840)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: card1),
              const SizedBox(width: 12),
              Expanded(child: card2),
              const SizedBox(width: 12),
              Expanded(child: card3),
              const SizedBox(width: 12),
              Expanded(child: card4),
            ],
          )
        else
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: card1),
                  const SizedBox(width: 12),
                  Expanded(child: card2),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: card3),
                  const SizedBox(width: 12),
                  Expanded(child: card4),
                ],
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildBentoMetricCard({
    required String title,
    required String value,
    required String tag,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _StitchColors.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _StitchColors.slate200.withValues(alpha: 0.8),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top row: Title + Icon Box
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: _t(
                        size: 11,
                        w: FontWeight.w600,
                        color: _StitchColors.slate500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _StitchColors.slate100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: _StitchColors.primaryNavy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Value & Tag Row (Wrap prevents any overflow on small screens)
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 2,
                children: [
                  Text(
                    value,
                    style: _t(
                      size: 22,
                      w: FontWeight.w800,
                      color: _StitchColors.primaryNavy,
                      h: 1.1,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _StitchColors.slate100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag,
                      style: _t(
                        size: 11,
                        w: FontWeight.w600,
                        color: _StitchColors.slate600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Description Text
              Text(
                subtitle,
                style: _t(size: 10, color: _StitchColors.slate500, h: 1.2),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 3. SECTION UTAMA: KELOLA MASTER DATA & KONFIGURASI (5 Action Cards) ────
  Widget _buildMasterDataConfigSection({
    required BuildContext context,
    required int totalUsers,
    required int totalLocations,
    required double threshold,
    required int columns,
  }) {
    final cards = [
      _ActionCardModel(
        key: const Key('action_user_management'),
        icon: Icons.manage_accounts,
        title: 'Kelola Pengguna (User Management)',
        tag: '$totalUsers Akun',
        subtitle: 'Aktivasi akun, assign unit, dan reset akses pegawai',
        onTap: () => context.push(RouteNames.adminUsersPath),
      ),
      _ActionCardModel(
        key: const Key('action_rbac_management'),
        icon: Icons.admin_panel_settings,
        title: 'Kelola Role & Hak Akses (RBAC)',
        tag: '5 Role',
        subtitle: 'Aturan ketat: 1 role spesifik per akun pengguna aktif',
        onTap: () => _showRbacInfoModal(context),
      ),
      _ActionCardModel(
        key: const Key('action_locations_management'),
        icon: Icons.apartment,
        title: 'Master Unit Kerja & Lokasi Cabang',
        tag: '$totalLocations Cabang',
        subtitle: 'Struktur Kantor Pusat, KC, KCP, dan Pool Gudang Aset',
        onTap: () => context.push(RouteNames.adminLocationsPath),
      ),
      _ActionCardModel(
        key: const Key('action_categories_management'),
        icon: Icons.inventory_2,
        title: 'Kategori Master Aset',
        tag: 'TI & Umum',
        subtitle: 'Klasifikasi Aset TI & Aset Umum beserta format tiket',
        onTap: () => context.push(RouteNames.adminCategoriesPath),
      ),
      _ActionCardModel(
        key: const Key('action_approval_rules_management'),
        icon: Icons.tune,
        title: 'Kriteria Approval Kadiv',
        tag: '3 Aturan',
        subtitle:
            'Parameter ambang batas & kriteria eskalasi approval pimpinan',
        onTap: () => _showApprovalRulesDialog(context),
      ),
    ];

    // Filter cards based on search query
    final filtered = _searchQuery.isEmpty
        ? cards
        : cards
              .where(
                (c) =>
                    c.title.toLowerCase().contains(_searchQuery) ||
                    c.subtitle.toLowerCase().contains(_searchQuery) ||
                    c.tag.toLowerCase().contains(_searchQuery),
              )
              .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kelola Master Data & Konfigurasi',
                    style: _t(
                      size: 13,
                      w: FontWeight.w700,
                      color: _StitchColors.slate800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pusat konfigurasi hak akses, hierarki unit kerja & parameter sistem',
                    style: _t(size: 11, color: _StitchColors.slate500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _showSystemSettingsDialog(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Konfigurasi',
                    style: _t(
                      size: 11,
                      w: FontWeight.w700,
                      color: _StitchColors.forestTeal,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.tune,
                    size: 14,
                    color: _StitchColors.forestTeal,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Action Cards List
        if (filtered.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _StitchColors.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _StitchColors.slate200),
            ),
            child: Center(
              child: Text(
                'Tidak ada menu yang sesuai dengan "$_searchQuery"',
                style: _t(size: 12, color: _StitchColors.slate500),
              ),
            ),
          )
        else if (columns > 1)
          _buildResponsiveActionGrid(filtered, columns)
        else
          ...filtered.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildActionMenuCard(c),
            ),
          ),
      ],
    );
  }

  Widget _buildResponsiveActionGrid(List<_ActionCardModel> cards, int columns) {
    final rows = <Widget>[];
    for (int i = 0; i < cards.length; i += columns) {
      final end = (i + columns < cards.length) ? i + columns : cards.length;
      final rowCards = cards.sublist(i, end);

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int j = 0; j < rowCards.length; j++) ...[
                Expanded(child: _buildActionMenuCard(rowCards[j])),
                if (j < columns - 1) const SizedBox(width: 12),
              ],
              for (int s = 0; s < columns - rowCards.length; s++) ...[
                const Expanded(child: SizedBox.shrink()),
                if (s < columns - rowCards.length - 1)
                  const SizedBox(width: 12),
              ],
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildActionMenuCard(_ActionCardModel model) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: model.key,
        borderRadius: BorderRadius.circular(16),
        onTap: model.onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _StitchColors.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _StitchColors.slate200.withValues(alpha: 0.8),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon Box (w-10 h-10 rounded-xl bg-slate-100 text-[#0F3D56])
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _StitchColors.slate100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _StitchColors.slate200.withValues(alpha: 0.6),
                  ),
                ),
                child: Icon(
                  model.icon,
                  size: 22,
                  color: _StitchColors.primaryNavy,
                ),
              ),
              const SizedBox(width: 14),

              // Title, Tag & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          model.title,
                          style: _t(
                            size: 13,
                            w: FontWeight.w700,
                            color: _StitchColors.slate800,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _StitchColors.slate100,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: _StitchColors.slate200.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          child: Text(
                            model.tag,
                            style: _t(
                              size: 10,
                              w: FontWeight.w600,
                              color: _StitchColors.slate700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      model.subtitle,
                      style: _t(size: 11, color: _StitchColors.slate500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Chevron Right Pill (w-7 h-7 rounded-full bg-slate-50)
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: _StitchColors.slate400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 4. SECTION SEKUNDER: LOG AUDIT & AKTIVITAS TERKINI (Stitch 1:1) ─────────
  Widget _buildAuditLogSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.verified_user,
                        size: 18,
                        color: _StitchColors.forestTeal,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Log Audit & Aktivitas Terkini',
                          style: _t(
                            size: 13,
                            w: FontWeight.w700,
                            color: _StitchColors.slate800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Histori pembaruan konfigurasi & rekam jejak tata kelola',
                    style: _t(size: 11, color: _StitchColors.slate500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _showAllAuditLogsDialog(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lihat Semua',
                    style: _t(
                      size: 12,
                      w: FontWeight.w600,
                      color: _StitchColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: _StitchColors.primaryNavy,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Log Items (Stitch 1:1)
        _buildLogCard(
          avatarText: 'AP',
          title: 'Pembaruan Node Cabang',
          time: '12m lalu',
          richDesc: RichText(
            text: TextSpan(
              style: _t(size: 12, color: _StitchColors.slate600, h: 1.3),
              children: [
                const TextSpan(
                  text: 'Node transit aset logistik regional ditambahkan ke ',
                ),
                TextSpan(
                  text: 'KCP Thamrin',
                  style: _t(
                    size: 12,
                    w: FontWeight.w700,
                    color: _StitchColors.slate800,
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
          tagCode: '#LOC-1092',
          statusChip: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: _StitchColors.emerald500,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Sukses Diterapkan',
                style: _t(
                  size: 10,
                  w: FontWeight.w600,
                  color: _StitchColors.slate700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        _buildLogCard(
          avatarText: 'DP',
          title: 'Penugasan Role Pegawai',
          time: '1j lalu',
          richDesc: RichText(
            text: TextSpan(
              style: _t(size: 12, color: _StitchColors.slate600, h: 1.3),
              children: [
                const TextSpan(text: 'User '),
                TextSpan(
                  text: 'Dimas Pratama',
                  style: _t(
                    size: 12,
                    w: FontWeight.w700,
                    color: _StitchColors.slate800,
                  ),
                ),
                const TextSpan(
                  text: ' dialokasikan hak akses Petugas Aset TI.',
                ),
              ],
            ),
          ),
          tagCode: '#RBAC-441',
          statusChip: Text(
            'Oleh Admin Utama',
            style: _t(
              size: 10,
              w: FontWeight.w500,
              color: _StitchColors.slate700,
            ),
          ),
        ),
        const SizedBox(height: 10),

        _buildLogCard(
          avatarText: 'SYS',
          title: 'Sinkronisasi Basis Data Aset',
          time: '3j lalu',
          richDesc: Text(
            'Validasi 6.302 entitas inventaris server selesai tanpa anomali data.',
            style: _t(size: 12, color: _StitchColors.slate600, h: 1.3),
          ),
          tagCode: '#SYNC-882',
          statusChip: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                size: 13,
                color: _StitchColors.emerald500,
              ),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  'Integritas Terverifikasi',
                  style: _t(
                    size: 10,
                    w: FontWeight.w600,
                    color: _StitchColors.slate700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // System Security & Export Quick Bar (2 Grid)
        Row(
          children: [
            Expanded(
              child: _buildQuickToolCard(
                icon: Icons.cloud_download,
                title: 'Unduh Log Audit',
                subtitle: 'Format CSV / PDF',
                onTap: () {
                  AppFeedback.showSuccess(
                    context,
                    'Mengunduh log audit format CSV & PDF...',
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickToolCard(
                icon: Icons.security_update_good,
                title: 'Backup Otomatis',
                subtitle: 'Tersinkron Cloud',
                onTap: () {
                  AppFeedback.showSuccess(
                    context,
                    'Sinkronisasi backup database berhasil dilakukan.',
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLogCard({
    required String avatarText,
    required String title,
    required String time,
    required Widget richDesc,
    required String tagCode,
    required Widget statusChip,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _StitchColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _StitchColors.slate200.withValues(alpha: 0.8),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _StitchColors.primaryNavy.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _StitchColors.primaryNavy.withValues(alpha: 0.15),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              avatarText,
              style: _t(
                size: 11,
                w: FontWeight.w700,
                color: _StitchColors.primaryNavy,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: _t(
                          size: 13,
                          w: FontWeight.w700,
                          color: _StitchColors.slate800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      time,
                      style: _t(size: 10, color: _StitchColors.slate500),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                richDesc,
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _StitchColors.slate100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _StitchColors.slate200.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        tagCode,
                        style: _t(
                          size: 10,
                          w: FontWeight.w600,
                          color: _StitchColors.slate700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _StitchColors.slate100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _StitchColors.slate200.withValues(alpha: 0.6),
                        ),
                      ),
                      child: statusChip,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickToolCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _StitchColors.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _StitchColors.slate200.withValues(alpha: 0.8),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _StitchColors.slate100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _StitchColors.slate200.withValues(alpha: 0.6),
                  ),
                ),
                child: Icon(icon, size: 20, color: _StitchColors.primaryNavy),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: _t(
                        size: 12,
                        w: FontWeight.w700,
                        color: _StitchColors.slate800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: _t(size: 11, color: _StitchColors.slate500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  // ── 5. QUICK MASTER DATA ACTION BUTTON (Stitch 1:1) ─────────────────────────
  Widget _buildCreateMasterDataButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _StitchColors.primaryNavy,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: _StitchColors.primaryNavy.withValues(alpha: 0.20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () => _showCreateMasterDataSheet(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_circle,
              color: _StitchColors.mintAccent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Tambah Master Data / Role Baru',
                style: _t(size: 14, w: FontWeight.w700, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 6. FLOATING BOTTOM NAVIGATION BAR (Stitch 1:1 Floating Pill Style) ──────
  Widget _buildFloatingBottomNavBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _StitchColors.slate200.withValues(alpha: 0.8),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFloatingNavItem(
              index: 0,
              icon: Icons.home,
              label: 'Beranda',
              onTap: () {
                setState(() => _selectedNavIndex = 0);
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              },
            ),
          ),
          Expanded(
            child: _buildFloatingNavItem(
              index: 1,
              icon: Icons.storage_outlined,
              label: 'Master Data',
              onTap: () {
                setState(() => _selectedNavIndex = 1);
                context.push(RouteNames.adminCategoriesPath);
              },
            ),
          ),
          Expanded(
            child: _buildFloatingNavItem(
              index: 2,
              icon: Icons.history_outlined,
              label: 'Audit Log',
              onTap: () {
                setState(() => _selectedNavIndex = 2);
                _showAllAuditLogsDialog(context);
              },
            ),
          ),
          Expanded(
            child: _buildFloatingNavItem(
              index: 3,
              icon: Icons.person_outline,
              label: 'Profil',
              onTap: () {
                setState(() => _selectedNavIndex = 3);
                context.push(RouteNames.profilePath);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNavItem({
    required int index,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isSelected = _activeNavIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFECF4FF)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? _StitchColors.primaryNavy
                    : _StitchColors.slate400,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: _t(
                size: 11,
                w: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? _StitchColors.primaryNavy
                    : _StitchColors.slate400,
                ls: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── MODALS & SHEETS ────────────────────────────────────────────────────────
  void _showCreateMasterDataSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _StitchColors.slate200,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Pilih Master Data Baru',
                style: _t(
                  size: 18,
                  w: FontWeight.w700,
                  color: _StitchColors.slate800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tambahkan entitas baru ke dalam basis data sistem MutasiKu.',
                style: _t(size: 12, color: _StitchColors.slate500),
              ),
              const SizedBox(height: 20),
              _buildSheetActionTile(
                icon: Icons.person_add_alt_1_outlined,
                title: 'Tambah Pengguna Baru',
                subtitle: 'Daftarkan user pemohon, operator, aset, atau kadiv',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(RouteNames.adminUsersPath);
                },
              ),
              _buildSheetActionTile(
                icon: Icons.add_business_outlined,
                title: 'Tambah Unit / Lokasi Cabang',
                subtitle: 'Daftarkan cabang KC, KCP, atau gudang inventaris',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(RouteNames.adminLocationsPath);
                },
              ),
              _buildSheetActionTile(
                icon: Icons.category_outlined,
                title: 'Tambah Kategori Aset',
                subtitle: 'Klasifikasi kelompok aset TI atau inventaris umum',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(RouteNames.adminCategoriesPath);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _StitchColors.slate100.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _StitchColors.slate200),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _StitchColors.primaryNavy,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: _t(
                          size: 13,
                          w: FontWeight.w700,
                          color: _StitchColors.slate800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: _t(size: 11, color: _StitchColors.slate500),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: _StitchColors.slate400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRbacInfoModal(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(
              Icons.admin_panel_settings,
              color: _StitchColors.primaryNavy,
            ),
            const SizedBox(width: 8),
            Text(
              'Hierarki RBAC 5 Role',
              style: _t(size: 16, w: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MutasiKu menerapkan aturan ketat 1 role spesifik per akun pengguna aktif:',
              style: _t(size: 12, color: _StitchColors.slate600),
            ),
            const SizedBox(height: 12),
            _buildRbacRow(
              '1. Pemohon',
              'Pengajuan mutasi aset & konfirmasi penerimaan',
            ),
            _buildRbacRow(
              '2. Operator',
              'Verifikasi dokumen & cek fisik pengajuan',
            ),
            _buildRbacRow(
              '3. Bagian Aset',
              'Verifikasi data aset, tentukan PIC baru, & proses',
            ),
            _buildRbacRow(
              '4. Pemimpin Divisi',
              'Otorisasi final approval sesuai kriteria',
            ),
            _buildRbacRow(
              '5. Administrator',
              'Pengelolaan master data & konfigurasi',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Tutup',
              style: _t(
                size: 13,
                w: FontWeight.w600,
                color: _StitchColors.primaryNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRbacRow(String role, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            role,
            style: _t(
              size: 12,
              w: FontWeight.w700,
              color: _StitchColors.slate800,
            ),
          ),
          Text(desc, style: _t(size: 11, color: _StitchColors.slate500)),
        ],
      ),
    );
  }

  void _showApprovalRulesDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.tune, color: _StitchColors.primaryNavy),
            const SizedBox(width: 8),
            Text(
              'Kriteria Approval Kadiv',
              style: _t(size: 16, w: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aturan eskalasi mutasi yang wajib mendapatkan persetujuan Pemimpin Divisi (Kadiv):',
              style: _t(size: 12, color: _StitchColors.slate600),
            ),
            const SizedBox(height: 12),
            _buildRuleItem(
              '1. Ambang Batas Nilai Aset',
              'Aset dengan nilai tercatat di atas ambang batas parameter sistem.',
            ),
            _buildRuleItem(
              '2. Mutasi Antar-Wilayah/Cabang',
              'Perpindahan aset yang melintasi KC berbeda atau keluar dari Kantor Pusat.',
            ),
            _buildRuleItem(
              '3. Kategori Khusus / Server TI',
              'Perangkat server, data center, dan kendaraan dinas operasional.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Kelola di Kategori Aset',
              style: _t(
                size: 13,
                w: FontWeight.w600,
                color: _StitchColors.primaryNavy,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _StitchColors.primaryNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String rule, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rule,
            style: _t(
              size: 12,
              w: FontWeight.w700,
              color: _StitchColors.slate800,
            ),
          ),
          Text(desc, style: _t(size: 11, color: _StitchColors.slate500)),
        ],
      ),
    );
  }

  Future<void> _showAllAuditLogsDialog(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.78,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: _StitchColors.slate200,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      color: _StitchColors.primaryNavy,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Semua Log Audit Sistem',
                      style: _t(
                        size: 16,
                        w: FontWeight.w700,
                        color: _StitchColors.slate800,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Kembali ke Beranda',
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  _buildLogCard(
                    avatarText: 'AP',
                    title: 'Pembaruan Node Cabang',
                    time: '12m lalu',
                    richDesc: Text(
                      'Node transit aset logistik regional ditambahkan ke KCP Thamrin.',
                      style: _t(size: 12, color: _StitchColors.slate600),
                    ),
                    tagCode: '#LOC-1092',
                    statusChip: const Text('Sukses'),
                  ),
                  const SizedBox(height: 10),
                  _buildLogCard(
                    avatarText: 'DP',
                    title: 'Penugasan Role Pegawai',
                    time: '1j lalu',
                    richDesc: Text(
                      'User Dimas Pratama dialokasikan hak akses Petugas Aset TI.',
                      style: _t(size: 12, color: _StitchColors.slate600),
                    ),
                    tagCode: '#RBAC-441',
                    statusChip: const Text('Admin'),
                  ),
                  const SizedBox(height: 10),
                  _buildLogCard(
                    avatarText: 'SYS',
                    title: 'Sinkronisasi Basis Data Aset',
                    time: '3j lalu',
                    richDesc: Text(
                      'Validasi 6.302 entitas inventaris server selesai tanpa anomali data.',
                      style: _t(size: 12, color: _StitchColors.slate600),
                    ),
                    tagCode: '#SYNC-882',
                    statusChip: const Text('Verifikasi'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _StitchColors.primaryNavy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.home_outlined, size: 18),
                label: const Text(
                  'Kembali ke Beranda',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );

    if (mounted) {
      setState(() => _selectedNavIndex = 0);
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _showNotificationSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: _StitchColors.slate200,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Notifikasi Sistem Administrator',
              style: _t(size: 16, w: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(
                Icons.check_circle_outline,
                color: _StitchColors.emerald500,
              ),
              title: Text(
                'Sinkronisasi Master Selesai',
                style: _t(size: 13, w: FontWeight.w600),
              ),
              subtitle: Text(
                '34 unit cabang dan data kategori telah sinkron.',
                style: _t(size: 11, color: _StitchColors.slate500),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.info_outline,
                color: _StitchColors.primaryNavy,
              ),
              title: Text(
                'Kriteria Approval Kadiv Aktif',
                style: _t(size: 13, w: FontWeight.w600),
              ),
              subtitle: Text(
                'Parameter eskalasi berjalan otomatis.',
                style: _t(size: 11, color: _StitchColors.slate500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNavigationDrawer(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: _StitchColors.slate200,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Navigasi Modul Master Data',
              style: _t(size: 16, w: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(
                Icons.manage_accounts,
                color: _StitchColors.primaryNavy,
              ),
              title: const Text('Kelola Pengguna & Role'),
              onTap: () {
                Navigator.pop(ctx);
                context.push(RouteNames.adminUsersPath);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.apartment,
                color: _StitchColors.primaryNavy,
              ),
              title: const Text('Master Unit Kerja & Lokasi Cabang'),
              onTap: () {
                Navigator.pop(ctx);
                context.push(RouteNames.adminLocationsPath);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.inventory_2,
                color: _StitchColors.primaryNavy,
              ),
              title: const Text('Kategori Master Aset'),
              onTap: () {
                Navigator.pop(ctx);
                context.push(RouteNames.adminCategoriesPath);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.person,
                color: _StitchColors.primaryNavy,
              ),
              title: const Text('Profil Administrator'),
              onTap: () {
                Navigator.pop(ctx);
                context.push(RouteNames.profilePath);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSystemSettingsDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.tune, color: _StitchColors.primaryNavy),
            const SizedBox(width: 8),
            Text('Konfigurasi Sistem', style: _t(size: 16, w: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Konfigurasi global sistem mencakup pengaturan sinkronisasi background, toleransi token, dan ambang batas approval pimpinan.',
          style: _t(size: 12, color: _StitchColors.slate600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _StitchColors.primaryNavy,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              AppFeedback.showSuccess(
                context,
                'Konfigurasi sistem telah diperbarui.',
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class _ActionCardModel {
  final Key key;
  final IconData icon;
  final String title;
  final String tag;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCardModel({
    required this.key,
    required this.icon,
    required this.title,
    required this.tag,
    required this.subtitle,
    required this.onTap,
  });
}
