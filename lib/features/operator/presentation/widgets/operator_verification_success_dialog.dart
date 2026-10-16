// lib/features/operator/presentation/widgets/operator_verification_success_dialog.dart
//
// Modal Dialog: Verifikasi Berhasil (Operator)
// SOURCE OF TRUTH: Stitch Screen ID 2cc02f80cf3c404cb3bf174d61e73c50.
// Font: Montserrat. Desain compact, proporsional, dan adaptif di HP.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Menampilkan Modal Dialog Verifikasi Berhasil di atas halaman operator dengan efek blur + dim.
Future<void> showOperatorVerificationSuccessDialog(
  BuildContext context, {
  required VoidCallback onNextTicket,
  required VoidCallback onOpenHistory,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Verifikasi Berhasil',
    barrierColor: const Color(0xFF0F172A)
        .withValues(alpha: 0.50), // bg-slate-900/50
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (dialogCtx, anim1, anim2) => OperatorVerificationSuccessDialog(
      onNextTicket: onNextTicket,
      onOpenHistory: onOpenHistory,
    ),
    transitionBuilder: (dialogCtx, anim1, anim2, child) {
      final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // backdrop-blur-md
        child: FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

class OperatorVerificationSuccessDialog extends StatelessWidget {
  final VoidCallback onNextTicket;
  final VoidCallback onOpenHistory;

  const OperatorVerificationSuccessDialog({
    super.key,
    required this.onNextTicket,
    required this.onOpenHistory,
  });

  TextStyle _m({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = const Color(0xFF00273A),
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
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // Adaptif proporsional untuk layar compact/HP
    final isCompact = screenWidth < 360 || screenHeight < 640;
    final modalWidth = screenWidth < 340 ? (screenWidth - 32) : 310.0;

    final iconSize = isCompact ? 54.0 : 64.0;
    final checkmarkSize = isCompact ? 26.0 : 32.0;
    final titleSize = isCompact ? 17.0 : 18.5;
    final subtitleSize = isCompact ? 11.0 : 12.0;
    final btnHeight = isCompact ? 40.0 : 44.0;
    final btnFontSize = isCompact ? 12.5 : 13.0;
    final cardPadding = isCompact
        ? const EdgeInsets.fromLTRB(16, 20, 16, 16)
        : const EdgeInsets.fromLTRB(20, 24, 20, 20);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(maxWidth: modalWidth),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFF1F5F9), // border-slate-100
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            padding: cardPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── 1. Icon Success (Stitch: emerald circle with SVG checkmark) ──
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5), // bg-emerald-50
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD1FAE5)
                          .withValues(alpha: 0.85), // border-emerald-100/80
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF059669).withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _OperatorEmeraldCheckmark(size: checkmarkSize),
                  ),
                ),

                SizedBox(height: isCompact ? 12 : 16),

                // ── 2. Title & Subtitle (Stitch) ──
                Text(
                  'Verifikasi Berhasil',
                  textAlign: TextAlign.center,
                  style: _m(
                    size: titleSize,
                    weight: FontWeight.w700,
                    color: const Color(0xFF00273A),
                    letterSpacing: -0.2,
                  ),
                ),

                SizedBox(height: isCompact ? 5 : 7),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Tiket telah berhasil diverifikasi dan diteruskan ke pimpinan.',
                    textAlign: TextAlign.center,
                    style: _m(
                      size: subtitleSize,
                      weight: FontWeight.w400,
                      color: const Color(0xFF64748B), // text-slate-500
                      height: 1.4,
                    ),
                  ),
                ),

                SizedBox(height: isCompact ? 16 : 20),

                // ── 3. Action Buttons (Stitch) ──
                // Primary: Periksa Tiket Berikutnya
                SizedBox(
                  width: double.infinity,
                  height: btnHeight,
                  child: ElevatedButton(
                    key: const Key('btn_operator_next_ticket'),
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      onNextTicket();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00273A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      'Periksa Tiket Berikutnya',
                      style: _m(
                        size: btnFontSize,
                        weight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: isCompact ? 7 : 9),

                // Secondary: Buka Riwayat Verifikasi
                SizedBox(
                  width: double.infinity,
                  height: btnHeight,
                  child: ElevatedButton(
                    key: const Key('btn_operator_open_history'),
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      onOpenHistory();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFECF4FF),
                      foregroundColor: const Color(0xFF00273A),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      'Buka Riwayat Verifikasi',
                      style: _m(
                        size: btnFontSize,
                        weight: FontWeight.w600,
                        color: const Color(0xFF00273A),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OperatorEmeraldCheckmark extends StatelessWidget {
  final double size;
  const _OperatorEmeraldCheckmark({this.size = 32});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(
        painter: _OperatorEmeraldCheckmarkPainter(Color(0xFF059669)),
      ),
    );
  }
}

class _OperatorEmeraldCheckmarkPainter extends CustomPainter {
  final Color color;
  const _OperatorEmeraldCheckmarkPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * (size.width / 24.0)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final scaleX = size.width / 24.0;
    final scaleY = size.height / 24.0;

    // SVG: d="M4.5 12.75l6 6 9-13.5"
    final path = Path();
    path.moveTo(4.5 * scaleX, 12.75 * scaleY);
    path.lineTo(10.5 * scaleX, 18.75 * scaleY);
    path.lineTo(19.5 * scaleX, 5.25 * scaleY);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _OperatorEmeraldCheckmarkPainter oldDelegate) =>
      color != oldDelegate.color;
}
