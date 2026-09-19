// lib/features/auth/presentation/screens/landing_screen.dart
//
// Landing page MutasiKu — disesuaikan dari mockup (navy + network + CTA Mulai).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';

/// Warna mengikuti mockup HTML.
class _LandingColors {
  static const navy = Color(0xFF0F3D56);
  static const teal = Color(0xFF0F766E);
  static const tealSoft = Color(0xFF99EFE5);
}

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _LandingColors.navy,
      body: Stack(
        children: [
          // Pola geometri (mirip SVG di mockup)
          Positioned.fill(
            child: CustomPaint(painter: _NetworkBackgroundPainter()),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Badge brand
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _LandingColors.navy,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.swap_horiz_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'MutasiKu',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: _LandingColors.teal,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ENTERPRISE',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),

                // Konten tengah
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Pill status
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _LandingColors.teal.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: _LandingColors.teal.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: _LandingColors.tealSoft,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Sistem Alur Mutasi Aktif',
                                style: TextStyle(
                                  color: _LandingColors.tealSoft,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          'Mutasi Aset,\nLebih Teratur.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            height: 1.12,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          'Ajukan dan pantau mutasi aset dalam satu alur terpusat.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.80),
                            fontSize: 16,
                            height: 1.45,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // CTA bawah
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            context.go(RouteNames.loginPath);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _LandingColors.navy,
                            elevation: 8,
                            shadowColor: Colors.black.withValues(alpha: 0.25),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Mulai',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Aplikasi Internal Pengelolaan Mutasi Aset',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.60),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Latar lingkaran + jalur (sederhana, mirip mockup).
class _NetworkBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.44);

    void circle(double r, Color c, double stroke, {List<double>? dash}) {
      final paint = Paint()
        ..color = c
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke;
      canvas.drawCircle(center, r, paint);
    }

    circle(
      size.width * 0.72,
      const Color(0xFF0F766E).withValues(alpha: 0.35),
      1,
    );
    circle(size.width * 0.50, Colors.white.withValues(alpha: 0.08), 1);
    circle(
      size.width * 0.30,
      const Color(0xFF0F766E).withValues(alpha: 0.20),
      1.5,
    );

    final pathPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final p1 = Path()
      ..moveTo(40, size.height * 0.26)
      ..lineTo(110, size.height * 0.33)
      ..lineTo(size.width - 110, size.height * 0.33)
      ..lineTo(size.width - 40, size.height * 0.26);
    canvas.drawPath(p1, pathPaint);

    final p2Paint = Paint()
      ..color = const Color(0xFF0F766E).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final p2 = Path()
      ..moveTo(50, size.height * 0.58)
      ..lineTo(130, size.height * 0.53)
      ..lineTo(size.width - 130, size.height * 0.53)
      ..lineTo(size.width - 50, size.height * 0.58);
    canvas.drawPath(p2, p2Paint);

    final nodePaint = Paint()..color = const Color(0xFF0F766E);
    canvas.drawCircle(Offset(110, size.height * 0.33), 4, nodePaint);
    canvas.drawCircle(
      Offset(size.width - 110, size.height * 0.33),
      4,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
    canvas.drawCircle(Offset(130, size.height * 0.53), 4, nodePaint);
    canvas.drawCircle(
      Offset(size.width - 130, size.height * 0.53),
      4,
      nodePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
