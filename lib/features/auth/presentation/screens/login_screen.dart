// lib/features/auth/presentation/screens/login_screen.dart
//
// Screen: Halaman Login (Responsive Desktop & Mobile).
// Baseline: Stitch "MutasiKu — Portal Login & Tata Kelola Aset (Executive Redesign)"
// Screen ID: 658aa4d233d54aa78204fa309fcdca96
//
// UI Architecture:
// - Desktop / Laptop (>= 960px):
//   * Two-column split layout matching the reference design image.
//   * Left (45%): Dark navy hero panel (navy-850/800/900 gradient, ambient radial glows,
//     glowing brand emblem, headline, value proposition, 3 feature glass cards, SSL compliance seal).
//   * Right (55%): Executive form canvas (#FFFFFF / #F8FAFC) with layered ambient circular curves,
//     top action bar (back button + status pill), Hello Again! header, form inputs,
//     Remember me & Forgot Password?, elevated #13384D Login button, Security notice card,
//     helpdesk support link, and micro-copy footer.
// - Mobile / Tablet (< 960px):
//   * Responsive single-column layout preserving the exact visual styling.
//   * Clean, fluid, touch-friendly inputs, zero overflow, no horizontal scrolling.
// - 100% preservation of auth logic, state management, validation, routing, and test keys.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/validators/form_validators.dart';
import '../providers/auth_provider.dart';

/// Design tokens sesuai baseline Stitch Halaman Login (Executive Redesign)
abstract final class _LoginTheme {
  // Brand & Navy Palette
  static const Color navy900 = Color(0xFF001A27);
  static const Color navy850 = Color(0xFF00273A);
  static const Color navy800 = Color(0xFF06344D);
  static const Color brandNavy = Color(0xFF13384D); // Primary CTA Button

  // Teal & Cyan Palette
  static const Color teal = Color(0xFF0F766E);
  static const Color teal400 = Color(0xFF2DD4BF);
  static const Color teal500 = Color(0xFF14B8A6);
  static const Color teal600 = Color(0xFF0D9488);

  // Surfaces & Backgrounds
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);

  // Typography
  static const Color textHeading = Color(0xFF0F172A);
  static const Color textBody = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textPlaceholder = Color(0xFF94A3B8);

  // States & Badges
  static const Color error = Color(0xFFB42318);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color successGreen = Color(0xFF047857);
  static const Color successGreenBg = Color(0xFFECFDF5);
  static const Color successGreenBorder = Color(0xFFD1FAE5);

  static const Color trustGreen = Color(0xFF059669);
  static const Color trustGreenBorder = Color(0xFFA7F3D0);
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _remember = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(authStateProvider.notifier)
        .login(_usernameController.text.trim(), _passwordController.text);
  }

  void _showHelpdeskDialog() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCCFBF1)),
                    ),
                    child: const Icon(
                      Icons.help_outline_rounded,
                      color: _LoginTheme.teal,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bantuan Akses MutasiKu',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _LoginTheme.textHeading,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Akun MutasiKu terintegrasi dengan kredensial Single Sign-On (SSO) pegawai internal.\n\nJika mengalami kendala masuk, pembaruan kata sandi, atau mutasi divisi tugas, silakan hubungi Helpdesk TI di ext. 1404 atau melalui portal dukungan internal.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  height: 1.5,
                  color: _LoginTheme.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _LoginTheme.brandNavy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Mengerti',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final loading = auth.isLoading;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Breakpoint: Mobile / Tablet portrait (< 960px)
        // Desktop / Laptop (>= 960px): Stitch two-column split layout
        final isMobile = constraints.maxWidth < 960;
        if (isMobile) {
          return _buildMobileLayout(loading, auth, constraints);
        } else {
          return _buildDesktopLayout(loading, auth, constraints);
        }
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // MOBILE LAYOUT (< 960px): RESPONSIVE SINGLE-COLUMN FORM CANVAS
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildMobileLayout(
    bool loading,
    dynamic auth,
    BoxConstraints constraints,
  ) {
    final horizontalPadding = math
        .max(20.0, math.min(28.0, constraints.maxWidth * 0.06))
        .toDouble();

    return Scaffold(
      backgroundColor: _LoginTheme.backgroundLight,
      body: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Ambient background curves (exact circular layers from reference image)
          Positioned(
            top: -160,
            right: -160,
            child: IgnorePointer(
              child: Container(
                width: 480,
                height: 480,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE8F1F7).withValues(alpha: 0.65),
                ),
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -80,
            child: IgnorePointer(
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFDFEBF4).withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
          Positioned(
            top: 60,
            right: 10,
            child: IgnorePointer(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD6E5F1).withValues(alpha: 0.40),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    16,
                    horizontalPadding,
                    24,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Bar: Back Button & MutasiKu Internal Badge
                        _buildTopHeader(),

                        const SizedBox(height: 32),

                        // Heading Section: Hello Again!
                        _buildHeadingSection(),

                        const SizedBox(height: 24),

                        // Error Alert Banner (if auth failed)
                        if (auth.failure != null) ...[
                          _buildErrorBanner(auth.failure!.userMessage),
                          const SizedBox(height: 16),
                        ],

                        // Input 1: Email Address / NIP Input Card
                        _buildUsernameField(),

                        const SizedBox(height: 14),

                        // Input 2: Password Input Card
                        _buildPasswordField(),

                        const SizedBox(height: 14),

                        // Utility Row: Remember Me & Forgot Password
                        _buildUtilityRow(),

                        const SizedBox(height: 18),

                        // Primary CTA: Elevated Login Button
                        _buildSubmitButton(loading),

                        const SizedBox(height: 20),

                        // Enterprise Trust & Security Card
                        _buildEnterpriseTrustCard(),

                        const SizedBox(height: 18),

                        // Helpdesk Link
                        _buildHelpdeskLink(),

                        const SizedBox(height: 36),

                        // Bottom Footer
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DESKTOP LAYOUT (>= 960px): TWO-COLUMN STITCH REFERENCE IMAGE REDESIGN
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildDesktopLayout(
    bool loading,
    dynamic auth,
    BoxConstraints constraints,
  ) {
    return Scaffold(
      backgroundColor: _LoginTheme.backgroundLight,
      body: Row(
        children: [
          // ── Left Column: Brand Hero Panel (Reference Image Specs) ──────────
          Expanded(
            flex: 9,
            child: _buildDesktopHeroPanel(),
          ),

          // ── Right Column: Login Form Canvas (Reference Image Specs) ────────
          Expanded(
            flex: 11,
            child: Container(
              color: _LoginTheme.backgroundLight,
              height: double.infinity,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // Subtle ambient circular curves behind form (Reference Image Specs)
                  Positioned(
                    top: -180,
                    right: -180,
                    child: IgnorePointer(
                      child: Container(
                        width: 720,
                        height: 720,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE8F1F7).withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -100,
                    right: -100,
                    child: IgnorePointer(
                      child: Container(
                        width: 540,
                        height: 540,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFDFEBF4).withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 60,
                    right: 20,
                    child: IgnorePointer(
                      child: Container(
                        width: 340,
                        height: 340,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFD6E5F1).withValues(alpha: 0.40),
                        ),
                      ),
                    ),
                  ),

                  // Center Form Container
                  SafeArea(
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, viewportConstraints) {
                          return SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 24,
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: math.max(0, viewportConstraints.maxHeight - 48),
                                maxWidth: 440,
                              ),
                              child: IntrinsicHeight(
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Top Action Bar: Back Button & Status Badge
                                      _buildTopHeader(),

                                      const Spacer(),

                                      // Heading Section: Hello Again!
                                      _buildHeadingSection(),

                                      const SizedBox(height: 24),

                                      // Error Alert Banner (if auth failed)
                                      if (auth.failure != null) ...[
                                        _buildErrorBanner(auth.failure!.userMessage),
                                        const SizedBox(height: 16),
                                      ],

                                      // Input 1: Email Address / NIP Input Card
                                      _buildUsernameField(),

                                      const SizedBox(height: 14),

                                      // Input 2: Password Input Card
                                      _buildPasswordField(),

                                      const SizedBox(height: 14),

                                      // Utility Row: Remember Me & Forgot Password
                                      _buildUtilityRow(),

                                      const SizedBox(height: 18),

                                      // Primary CTA: Elevated Login Button
                                      _buildSubmitButton(loading),

                                      const SizedBox(height: 20),

                                      // Enterprise Trust & Security Card
                                      _buildEnterpriseTrustCard(),

                                      const SizedBox(height: 18),

                                      // Helpdesk Link
                                      _buildHelpdeskLink(),

                                      const Spacer(),

                                      // Bottom Footer
                                      _buildFooter(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DESKTOP HERO PANEL (Left Column Visual Showcase - Reference Image Specs)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildDesktopHeroPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _LoginTheme.navy850,
            _LoginTheme.navy800,
            _LoginTheme.navy900,
          ],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Background ambient glows (Reference image specs)
          Positioned(
            top: -96,
            right: -96,
            child: IgnorePointer(
              child: Container(
                width: 384,
                height: 384,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _LoginTheme.teal500.withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: IgnorePointer(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _LoginTheme.teal600.withValues(alpha: 0.16),
                ),
              ),
            ),
          ),

          // Content Showcase
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Section: Logo, Headline, Value Proposition & 3 Feature Cards
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Brand Header: Logo Emblem + Name + Subtitle
                          Row(
                            children: [
                              _buildBrandEmblem(size: 48, radius: 12),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Mutasi',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        Text(
                                          'Ku',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            color: _LoginTheme.teal400,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Enterprise Asset Portal',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF64748B),
                                        letterSpacing: 0.2,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 40),

                          // Hero Headline (Constrained to naturally break on 3 lines like reference image)
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: Text(
                              'Tata Kelola Mutasi Aset\nCepat, Transparan & Akuntabel.',
                              style: GoogleFonts.montserrat(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.25,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: Text(
                              'Sistem terintegrasi untuk permohonan, verifikasi kelengkapan, penentuan PIC baru, hingga otorisasi final Pemimpin Divisi secara real-time.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: const Color(0xFF94A3B8),
                                height: 1.5,
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // 3 Feature Glass Cards (Reference image specs)
                          _buildDesktopFeatureItem(
                            icon: Icons.verified_user_rounded,
                            title: 'Otorisasi & Alur Berjenjang',
                            desc:
                                'Alur transisi status resmi: Pemohon → Operator → Bagian Aset → Kadiv → Selesai.',
                          ),
                          const SizedBox(height: 14),
                          _buildDesktopFeatureItem(
                            icon: Icons.show_chart_rounded,
                            title: 'Pelacakan Status Real-Time',
                            desc:
                                'Pantau riwayat pergerakan dan perpindahan lokasi fisik aset secara transparan dan akurat.',
                          ),
                          const SizedBox(height: 14),
                          _buildDesktopFeatureItem(
                            icon: Icons.assignment_turned_in_rounded,
                            title: 'Audit Trail Otomatis SIPA',
                            desc:
                                'Validasi ketat Serial Number & Kode Aset master data dengan enkripsi sistem SIPA.',
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Compliance & Security Seal Footer (Reference Image Specs)
                  Container(
                    padding: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.lock_rounded,
                              size: 14,
                              color: _LoginTheme.teal400,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Koneksi Terenkripsi 256-bit SSL',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          'Single Sign-On (SSO) Terintegrasi',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandEmblem({required double size, required double radius}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF002233),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: _LoginTheme.teal400.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _LoginTheme.teal400.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.72, size * 0.72),
          painter: const _MutasiKuEmblemRibbonPainter(),
        ),
      ),
    );
  }

  Widget _buildDesktopFeatureItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _LoginTheme.teal500.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _LoginTheme.teal500.withValues(alpha: 0.25),
              ),
            ),
            child: Icon(icon, color: _LoginTheme.teal400, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF94A3B8),
                    height: 1.4,
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
  // SHARED FORM COMPONENTS
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back Button
        InkWell(
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.landingPath);
            }
          },
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: _LoginTheme.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Color(0xFF334155),
              size: 20,
            ),
          ),
        ),

        // Status Indicator Pill: Logo Emblem + MutasiKu + Internal
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _LoginTheme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBrandEmblem(size: 22, radius: 6),
              const SizedBox(width: 8),
              Text(
                'MutasiKu',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _LoginTheme.successGreenBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _LoginTheme.successGreenBorder),
                ),
                child: Text(
                  'Internal',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _LoginTheme.successGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeadingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello Again!',
          style: GoogleFonts.montserrat(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: _LoginTheme.textHeading,
            letterSpacing: -0.6,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Welcome back you've\nbeen missed.",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: _LoginTheme.textMuted,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _LoginTheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _LoginTheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: _LoginTheme.error,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                color: _LoginTheme.error,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsernameField() {
    return Container(
      decoration: BoxDecoration(
        color: _LoginTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _LoginTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextFormField(
        key: const Key('login_username_field'),
        controller: _usernameController,
        textInputAction: TextInputAction.next,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          color: _LoginTheme.textBody,
        ),
        decoration: InputDecoration(
          hintText: 'Email',
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14.5,
            color: _LoginTheme.textPlaceholder,
          ),
          prefixIcon: const Icon(
            Icons.person_outline_rounded,
            size: 19,
            color: _LoginTheme.textPlaceholder,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        validator: FormValidators.email,
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: _LoginTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _LoginTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextFormField(
        key: const Key('login_password_field'),
        controller: _passwordController,
        obscureText: _obscure,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _login(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          color: _LoginTheme.textBody,
        ),
        decoration: InputDecoration(
          hintText: 'Password',
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14.5,
            color: _LoginTheme.textPlaceholder,
          ),
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            size: 19,
            color: _LoginTheme.textPlaceholder,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 19,
              color: _LoginTheme.textPlaceholder,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        validator: (v) =>
            (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
      ),
    );
  }

  Widget _buildUtilityRow() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        // Remember Me
        InkWell(
          onTap: () => setState(() => _remember = !_remember),
          borderRadius: BorderRadius.circular(6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: Checkbox(
                  value: _remember,
                  activeColor: _LoginTheme.brandNavy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                  onChanged: (v) => setState(() => _remember = v ?? false),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Remember me',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: _LoginTheme.textMuted,
                ),
              ),
            ],
          ),
        ),

        // Forgot Password
        GestureDetector(
          onTap: _showHelpdeskDialog,
          child: Text(
            'Forgot Password?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool loading) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        key: const Key('login_submit_button'),
        onPressed: loading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: _LoginTheme.brandNavy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _LoginTheme.brandNavy.withValues(alpha: 0.7),
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Login',
                style: GoogleFonts.montserrat(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }

  Widget _buildEnterpriseTrustCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCECF5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _LoginTheme.successGreenBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _LoginTheme.trustGreenBorder),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: _LoginTheme.trustGreen,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sistem Terotentikasi & Terproteksi',
                  style: GoogleFonts.montserrat(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Akses hanya diperuntukkan bagi pegawai resmi. Setiap aktivitas pencatatan mutasi aset diawasi oleh audit log SIPA.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: _LoginTheme.textMuted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpdeskLink() {
    return Center(
      child: InkWell(
        onTap: _showHelpdeskDialog,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.help_outline_rounded,
                size: 15,
                color: _LoginTheme.textPlaceholder,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Butuh bantuan akses? ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: _LoginTheme.textMuted,
                        ),
                      ),
                      TextSpan(
                        text: 'Hubungi Helpdesk TI',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_rounded,
              size: 12,
              color: _LoginTheme.textPlaceholder,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Sistem Pengelolaan Mutasi & Inventaris Aset',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: _LoginTheme.textMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'MutasiKu v2.4.0 • Divisi Operasional TI',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: _LoginTheme.textPlaceholder,
          ),
        ),
      ],
    );
  }
}

/// CustomPainter untuk Dynamic S / Double Exchange Ribbon Icon
class _MutasiKuEmblemRibbonPainter extends CustomPainter {
  const _MutasiKuEmblemRibbonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 120.0;
    canvas.save();
    canvas.scale(scale, scale);

    // 1. Top capsule / ribbon going right (White)
    final topPath = Path()
      ..moveTo(38, 42)
      ..cubicTo(38, 35.37, 43.37, 30, 50, 30)
      ..lineTo(70, 30)
      ..cubicTo(76.63, 30, 82, 35.37, 82, 42)
      ..cubicTo(82, 48.63, 76.63, 54, 70, 54)
      ..lineTo(54, 54)
      ..cubicTo(47.37, 54, 42, 59.37, 42, 66);

    final topPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(topPath, topPaint);

    // 2. Bottom capsule / ribbon going left (Accent Gradient: Cyan to Teal)
    final bottomPath = Path()
      ..moveTo(82, 54)
      ..cubicTo(82, 60.63, 76.63, 66, 70, 66)
      ..lineTo(50, 66)
      ..cubicTo(43.37, 66, 38, 71.37, 38, 78)
      ..cubicTo(38, 84.63, 43.37, 90, 50, 90)
      ..lineTo(70, 90)
      ..cubicTo(76.63, 90, 82, 84.63, 82, 78);

    final bottomPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Color(0xFF0284C7),
          Color(0xFF14B8A6),
        ],
      ).createShader(const Rect.fromLTWH(38, 54, 44, 36))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(bottomPath, bottomPaint);

    // 3. Directional arrow accent markers on transfer flow
    final topArrow = Path()
      ..moveTo(76, 26)
      ..lineTo(84, 30)
      ..lineTo(76, 34)
      ..close();
    canvas.drawPath(
      topArrow,
      Paint()
        ..color = const Color(0xFF38BDF8)
        ..style = PaintingStyle.fill,
    );

    final bottomArrow = Path()
      ..moveTo(44, 86)
      ..lineTo(36, 90)
      ..lineTo(44, 94)
      ..close();
    canvas.drawPath(
      bottomArrow,
      Paint()
        ..color = const Color(0xFF2DD4BF)
        ..style = PaintingStyle.fill,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
