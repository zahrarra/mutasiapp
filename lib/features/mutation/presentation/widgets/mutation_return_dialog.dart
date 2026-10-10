// lib/features/mutation/presentation/widgets/mutation_return_dialog.dart
//
// Modal Dialog: Kembalikan Pengajuan Mutasi (Operator & Bagian Aset)
// SOURCE OF TRUTH: Stitch Screen ID 04_modal_kembalikan_pengajuan_operator.
// Font: Montserrat. Desain compact, responsif, dan adaptif di HP.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../mutation/domain/entities/mutation.dart';

/// Menampilkan Modal "Kembalikan Pengajuan" di atas halaman Detail Pengajuan
/// dengan efek background dim + blur.
Future<void> showMutationReturnDialog({
  required BuildContext context,
  required Mutation mutation,
  required Future<bool> Function(String reason) onConfirm,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Kembalikan Pengajuan',
    barrierColor: const Color(0xFF0F172A)
        .withValues(alpha: 0.50), // bg-slate-900/50
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (dialogCtx, anim1, anim2) =>
        MutationReturnDialog(mutation: mutation, onConfirm: onConfirm),
    transitionBuilder: (dialogCtx, anim1, anim2, child) {
      final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // backdrop-blur-md
        child: FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

class MutationReturnDialog extends StatefulWidget {
  final Mutation mutation;
  final Future<bool> Function(String reason) onConfirm;

  const MutationReturnDialog({
    super.key,
    required this.mutation,
    required this.onConfirm,
  });

  @override
  State<MutationReturnDialog> createState() => _MutationReturnDialogState();
}

class _MutationReturnDialogState extends State<MutationReturnDialog> {
  final _reasonController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  TextStyle _m({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = const Color(0xFF0F172A),
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
    final isCompact = screenWidth < 360 || screenHeight < 640;

    final modalWidth = screenWidth < 440 ? (screenWidth - 32) : 420.0;

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
                color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.14),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header (Stitch 04) ───────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isCompact ? 16 : 20,
                    isCompact ? 16 : 20,
                    isCompact ? 14 : 16,
                    0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: isCompact ? 36 : 40,
                        height: isCompact ? 36 : 40,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFFEE2E2,
                          ), // bg-error-container/50
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.assignment_return_rounded,
                          size: 20,
                          color: Color(0xFFB42318), // text-error
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kembalikan Pengajuan',
                              style: _m(
                                size: isCompact ? 16 : 17.5,
                                weight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tuliskan catatan perbaikan berkas untuk pemohon.',
                              style: _m(
                                size: isCompact ? 11.5 : 12.5,
                                color: const Color(0xFF52606D),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Body ─────────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isCompact ? 16 : 20,
                    14,
                    isCompact ? 16 : 20,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Context Card (Ticket & Asset Info)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFECF4FF,
                          ), // surface-container-low
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD5E4F4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nomor Tiket',
                                    style: _m(
                                      size: 10.5,
                                      weight: FontWeight.w500,
                                      color: const Color(0xFF52606D),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.mutation.ticketNumber,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.robotoMono(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF172B4D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Aset & Pemohon',
                                    style: _m(
                                      size: 10.5,
                                      weight: FontWeight.w500,
                                      color: const Color(0xFF52606D),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.mutation.asset.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _m(
                                      size: 12,
                                      weight: FontWeight.w600,
                                      color: const Color(0xFF172B4D),
                                    ),
                                  ),
                                  Text(
                                    widget.mutation.applicantName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _m(
                                      size: 10.5,
                                      color: const Color(0xFF52606D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Label Alasan Pengembalian
                      Row(
                        children: [
                          Text(
                            'Alasan Pengembalian',
                            style: _m(
                              size: 12.5,
                              weight: FontWeight.w600,
                              color: const Color(0xFF172B4D),
                            ),
                          ),
                          const Text(
                            ' *',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB42318),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Textarea
                      TextField(
                        controller: _reasonController,
                        enabled: !_isLoading,
                        maxLines: isCompact ? 3 : 4,
                        minLines: 3,
                        style: _m(
                          size: 13,
                          color: const Color(0xFF172B4D),
                          height: 1.45,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Tuliskan alasan pengembalian untuk pemohon...',
                          hintStyle: _m(
                            size: 12.5,
                            color: const Color(0xFF98A2B3),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFD0D5DD),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _errorText != null
                                  ? const Color(0xFFB42318)
                                  : const Color(0xFFD0D5DD),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF0F3D56),
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged: (val) {
                          if (_errorText != null && val.trim().isNotEmpty) {
                            setState(() => _errorText = null);
                          }
                        },
                      ),

                      if (_errorText != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 14,
                              color: Color(0xFFB42318),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _errorText!,
                              style: _m(
                                size: 11.5,
                                color: const Color(0xFFB42318),
                                weight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Footer Actions ───────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isCompact ? 16 : 20,
                    16,
                    isCompact ? 16 : 20,
                    isCompact ? 16 : 20,
                  ),
                  child: Row(
                    children: [
                      // Button Batal
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF172B4D),
                            side: const BorderSide(color: Color(0xFFD0D5DD)),
                            minimumSize: Size(0, isCompact ? 40 : 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Batal',
                            style: _m(
                              size: 13,
                              weight: FontWeight.w500,
                              color: const Color(0xFF172B4D),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Button Kembalikan
                      Expanded(
                        child: ElevatedButton.icon(
                          key: const Key('btn_submit_kembalikan'),
                          onPressed: _isLoading ? null : _handleConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB42318),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size(0, isCompact ? 40 : 44),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.assignment_return_rounded,
                                  size: 16,
                                ),
                          label: Text(
                            _isLoading ? 'Memproses...' : 'Kembalikan',
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: _m(
                              size: 13,
                              weight: FontWeight.w600,
                              color: Colors.white,
                            ),
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
      ),
    );
  }

  Future<void> _handleConfirm() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() {
        _errorText = 'Alasan pengembalian wajib diisi.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final success = await widget.onConfirm(reason);

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
