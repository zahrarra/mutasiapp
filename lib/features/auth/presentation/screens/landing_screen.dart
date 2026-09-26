// lib/features/auth/presentation/screens/landing_screen.dart
//
// Landing Page MutasiKu — Baseline: Stitch “MutasiKu — Landing Page (Minimalist Dark Navy)”
// Layar pembuka (intro/splash screen) otomatis:
// - Background: Sleek Dark Petrol Navy (#071520), ambient radial glows.
// - Hero: MutasiKu Vector Emblem dengan dual ribbon exchange icon, Inter typography.
// - Garis progress/loading minimalis (TaskFlow style) dengan glow teal-cyan.
// - Setelah loading selesai, transisi smooth (fade-out) ke Halaman Login.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/router/route_names.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _progressController;
  late final Animation<double> _progressAnimation;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // 1. Controller untuk pengisian garis progress bar (2 detik)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );

    // 2. Controller untuk transisi halus fade-out (250 ms)
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeInOut,
      ),
    );

    // Saat loading penuh → langsung mulai fade-out (tanpa delay tambahan)
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted && !_hasNavigated) {
        _fadeController.forward();
      }
    });

    _fadeController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted && !_hasNavigated) {
        _hasNavigated = true;
        // addPostFrameCallback memastikan GoRouter sudah siap me-mount
        // LoginScreen sebelum LandingScreen benar-benar hilang dari tree.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go(RouteNames.loginPath);
        });
      }
    });

    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: const Color(0xFF071520),
        body: Stack(
          children: [
            // ── Background Ambient Radial Highlights ────────────────────────
            // Top subtle highlight
            Positioned(
              top: -120,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 340,
                  height: 340,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF0F3D56).withValues(alpha: 0.35),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.75],
                    ),
                  ),
                ),
              ),
            ),

            // Center ambient logo glow
            Positioned.fill(
              child: Align(
                alignment: const Alignment(0, -0.22),
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF0F766E).withValues(alpha: 0.28),
                        const Color(0xFF0284C7).withValues(alpha: 0.16),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 0.85],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom subtle depth gradient
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 220,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xFF040C13),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── Main Content Section ────────────────────────────────────────
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 28),
                              child: Column(
                                children: [
                                  const Spacer(flex: 4),

                                  // Brand Emblem Logo Container
                                  _buildBrandEmblem(),

                                  const SizedBox(height: 24),

                                  // App Title
                                  Text(
                                    'MutasiKu',
                                    style: GoogleFonts.inter(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // Brand Subtitle / Tagline
                                  Text(
                                    'Transparan. Terstruktur. Akuntabel.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFFCBD5E1)
                                          .withValues(alpha: 0.85),
                                      letterSpacing: 0.5,
                                    ),
                                  ),

                                  const SizedBox(height: 48),

                                  // Minimal Progress / Loading Indicator (TaskFlow style)
                                  _buildLoadingBar(),

                                  const Spacer(flex: 5),

                                  // iOS Home indicator at bottom
                                  Container(
                                    width: 136,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF475569)
                                          .withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),

                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandEmblem() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Soft Glow Ring behind Logo
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF14B8A6).withValues(alpha: 0.25),
                blurRadius: 36,
                spreadRadius: 8,
              ),
            ],
          ),
        ),

        // MutasiKu Vector Emblem Graphic Container
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F3D56),
                Color(0xFF0F766E),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.20),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F766E).withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const CustomPaint(
            size: Size(96, 96),
            painter: _MutasiKuEmblemRibbonPainter(),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingBar() {
    return Container(
      key: const Key('landing_progress_bar'),
      width: 192,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          return AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              final fillWidth = (totalWidth * _progressAnimation.value)
                  .clamp(0.0, totalWidth);
              return Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: fillWidth,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF2DD4BF),
                        Color(0xFF38BDF8),
                        Color(0xFF0EA5E9),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            const Color(0xFF14B8A6).withValues(alpha: 0.85),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// CustomPainter untuk Dynamic S / Double Exchange Ribbon Icon
/// Berdasarkan SVG path asli Stitch (viewBox: 120x120).
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
    // Top arrow (points right)
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

    // Bottom arrow (points left)
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
