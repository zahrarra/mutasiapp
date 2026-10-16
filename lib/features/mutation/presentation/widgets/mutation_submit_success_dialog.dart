// lib/features/mutation/presentation/widgets/mutation_submit_success_dialog.dart
//
// Modal Dialog: Pengajuan Berhasil Dikirim
// SOURCE OF TRUTH: HTML Stitch terbaru (pengajuan fix / success modal).
// Tampil di atas Form Pengajuan Mutasi dengan backdrop blur + dim.
// Font: Montserrat. Max-width 340px, compact, responsive 360px–desktop tanpa overflow.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/router/route_names.dart';
import '../providers/mutation_provider.dart';

/// Menampilkan Modal Dialog Pengajuan Berhasil Dikirim di atas halaman Form.
/// Latar belakang form tetap terlihat dengan efek blur + dim sesuai visual HTML Stitch.
Future<void> showMutationSubmitSuccessDialog(
  BuildContext context, {
  required String ticketNumber,
  String? mutationId,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0xFF0F172A)
        .withValues(alpha: 0.40), // bg-slate-900/40
    builder: (dialogCtx) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6), // backdrop-blur-sm
      child: MutationSubmitSuccessDialog(
        ticketNumber: ticketNumber,
        mutationId: mutationId,
      ),
    ),
  );
}

/// Widget dialog modal konfirmasi sukses pengajuan mutasi (Stitch 1:1).
class MutationSubmitSuccessDialog extends ConsumerStatefulWidget {
  final String ticketNumber;
  final String? mutationId;

  const MutationSubmitSuccessDialog({
    super.key,
    required this.ticketNumber,
    this.mutationId,
  });

  @override
  ConsumerState<MutationSubmitSuccessDialog> createState() =>
      _MutationSubmitSuccessDialogState();
}

class _MutationSubmitSuccessDialogState
    extends ConsumerState<MutationSubmitSuccessDialog> {
  bool _copied = false;

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

  Future<void> _copyTicketNumber() async {
    await Clipboard.setData(ClipboardData(text: widget.ticketNumber));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _copied = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFF1F5F9), // border-slate-100
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A)
                      .withValues(alpha: 0.10), // shadow-slate-900/10
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── 1. Icon Success ──
                // w-20 h-20 rounded-full bg-emerald-50 border border-emerald-100/80
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5), // bg-emerald-50
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD1FAE5)
                          .withValues(alpha: 0.80), // border-emerald-100/80
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Center(child: _EmeraldCheckmark(size: 36)),
                ),

                const SizedBox(height: 20),

                // ── 2. Header & Message ──
                Text(
                  'Pengajuan Berhasil Dikirim',
                  textAlign: TextAlign.center,
                  style: _m(
                    size: 20,
                    weight: FontWeight.w700,
                    color: const Color(0xFF00273A),
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Pengajuan perpindahan aset Anda telah berhasil dicatat dan siap diproses.',
                    textAlign: TextAlign.center,
                    style: _m(
                      size: 13,
                      weight: FontWeight.w400,
                      color: const Color(0xFF64748B), // text-slate-500
                      height: 1.45,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── 3. Ticket Number Card ──
                // w-full bg-[#ecf4ff]/70 border border-slate-200/80 rounded-2xl p-3.5
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECF4FF).withValues(alpha: 0.70),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFCBD5E1)
                          .withValues(alpha: 0.80), // border-slate-200/80
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Label & Ticket Number
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NOMOR TIKET',
                              style: _m(
                                size: 10.5,
                                weight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.ticketNumber,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _m(
                                size: 15,
                                weight: FontWeight.w600,
                                color: const Color(0xFF00273A),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Tombol Salin
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: _copyTicketNumber,
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _copied
                                    ? const Color(
                                        0xFF6EE7B7,
                                      ) // border-emerald-300
                                    : const Color(
                                        0xFFE2E8F0,
                                      ), // border-slate-200
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _copied
                                      ? Icons.check_rounded
                                      : Icons.copy_rounded,
                                  size: 13,
                                  color: _copied
                                      ? const Color(
                                          0xFF059669,
                                        ) // text-emerald-600
                                      : const Color(0xFF00273A),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _copied ? 'Tersalin!' : 'Salin',
                                  style: _m(
                                    size: 11.5,
                                    weight: FontWeight.w600,
                                    color: _copied
                                        ? const Color(
                                            0xFF059669,
                                          ) // text-emerald-600
                                        : const Color(0xFF00273A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── 4. Action Buttons ──
                // Primary: Lihat Status Tracking -> membuka halaman Detail Mutasi
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    key: const Key('btn_success_view_tracking'),
                    onPressed: () {
                      ref.invalidate(mutationListProvider);
                      // Pastikan modal ditutup sebelum masuk ke Detail Mutasi
                      Navigator.of(context, rootNavigator: true).pop();
                      final id = widget.mutationId;
                      if (id != null && id.isNotEmpty) {
                        context.go(
                          RouteNames.pemohonMutasiDetailPath.replaceFirst(
                            ':id',
                            id,
                          ),
                        );
                      } else {
                        context.go(RouteNames.pemohonMutasiPath);
                      }
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
                      'Lihat Status Tracking',
                      style: _m(
                        size: 13.5,
                        weight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Secondary: Kembali ke Beranda
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    key: const Key('btn_success_back_home'),
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      context.go(RouteNames.pemohonDashboardPath);
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
                      'Kembali ke Beranda',
                      style: _m(
                        size: 13.5,
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

/// Emerald Checkmark matching SVG d="M5 13l4 4L19 7" from Stitch HTML.
class _EmeraldCheckmark extends StatelessWidget {
  final double size;
  const _EmeraldCheckmark({this.size = 36});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(
        painter: _EmeraldCheckmarkPainter(Color(0xFF059669)),
      ),
    );
  }
}

class _EmeraldCheckmarkPainter extends CustomPainter {
  final Color color;
  const _EmeraldCheckmarkPainter(this.color);

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

    final path = Path();
    path.moveTo(5 * scaleX, 13 * scaleY);
    path.lineTo(9 * scaleX, 17 * scaleY);
    path.lineTo(19 * scaleX, 7 * scaleY);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _EmeraldCheckmarkPainter oldDelegate) =>
      color != oldDelegate.color;
}
