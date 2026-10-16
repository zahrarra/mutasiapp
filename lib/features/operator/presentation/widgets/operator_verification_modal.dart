// lib/features/operator/presentation/widgets/operator_verification_modal.dart
//
// Modal Dialog Verifikasi Pengajuan oleh Operator:
// - Header dengan judul "Verifikasi Pengajuan"
// - Ringkasan pengajuan & aset
// - Form catatan "Catatan Hasil Pemeriksaan (Opsional)"
// - Tombol Batal & Teruskan ke Bagian Aset
// - Catatan bersifat opsional dan diteruskan bersama pengajuan
// - Operator hanya bertugas memeriksa kelengkapan & meneruskan (tidak ada pilihan Tolak/Terima)

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';
import '../../../notification/domain/entities/notification_item.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../providers/operator_verification_provider.dart';

/// Menampilkan Dialog Verifikasi Operator di atas halaman saat ini
Future<bool?> showOperatorVerificationModal(
  BuildContext context, {
  required Mutation mutation,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Verifikasi Pengajuan',
    barrierColor: const Color(0xFF0F172A).withValues(alpha: 0.50),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (dialogCtx, anim1, anim2) =>
        OperatorVerificationModal(mutation: mutation),
    transitionBuilder: (dialogCtx, anim1, anim2, child) {
      final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
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

class OperatorVerificationModal extends ConsumerStatefulWidget {
  final Mutation mutation;

  const OperatorVerificationModal({
    super.key,
    required this.mutation,
  });

  @override
  ConsumerState<OperatorVerificationModal> createState() =>
      _OperatorVerificationModalState();
}

class _OperatorVerificationModalState
    extends ConsumerState<OperatorVerificationModal> {
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  TextStyle _m({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = const Color(0xFF1E293B),
    double? height,
  }) {
    return GoogleFonts.montserrat(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final notes = _notesController.text.trim();
    final success = await ref
        .read(verificationActionProvider.notifier)
        .verify(
          mutationId: widget.mutation.id,
          notes: notes.isNotEmpty ? notes : null,
        );

    if (!mounted) return;

    if (success) {
      try {
        ref.read(notificationProvider.notifier).notifyRole(
              targetRole: UserRole.bagianAset,
              title: 'Menunggu Verifikasi Data Aset',
              message:
                  'Pengajuan mutasi ${widget.mutation.ticketNumber} (${widget.mutation.asset.name}) telah diperiksa kelengkapannya oleh Operator dan siap diverifikasi.',
              type: NotificationType.action,
              relatedMutationId: widget.mutation.id,
            );
      } catch (_) {}

      ref.invalidate(operatorMutationDetailProvider(widget.mutation.id));
      ref.invalidate(mutationDetailProvider(widget.mutation.id));

      Navigator.of(context).pop(true);
      AppFeedback.showSuccess(
        context,
        'Pengajuan berhasil diteruskan ke Bagian Aset.',
      );
    } else {
      setState(() => _isSubmitting = false);
      final err = ref.read(verificationActionProvider).error;
      AppFeedback.showError(
        context,
        err ?? 'Gagal meneruskan pengajuan mutasi.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mutation;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 580,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x240F172A),
                blurRadius: 28,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── HEADER ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F3D56).withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.fact_check_outlined,
                            color: Color(0xFF0F3D56),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verifikasi Pengajuan',
                                style: _m(
                                  size: 17,
                                  weight: FontWeight.w700,
                                  color: const Color(0xFF0F3D56),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Pemeriksaan Kelengkapan Dokumen & Informasi Tiket ${m.ticketNumber}',
                                style: _m(
                                  size: 12,
                                  color: const Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(false),
                          icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                          tooltip: 'Tutup',
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  // ── RINGKASAN ASET & PENGAJUAN ──
                  Container(
                    color: const Color(0xFFF8FAFC),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.asset.name,
                                style: _m(
                                  size: 13,
                                  weight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Kode: ${m.asset.assetCode} • Pemohon: ${m.applicantName}',
                                style: _m(
                                  size: 11,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Tujuan: ${m.targetLocation}',
                            style: _m(
                              size: 11,
                              weight: FontWeight.w600,
                              color: const Color(0xFF0369A1),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  // ── LANGSUNG CATATAN HASIL PEMERIKSAAN (OPSIONAL) ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catatan Hasil Pemeriksaan (Opsional)',
                          style: _m(
                            size: 13,
                            weight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          key: const Key('input_catatan_operator'),
                          controller: _notesController,
                          maxLines: 5,
                          minLines: 4,
                          textAlignVertical: TextAlignVertical.top,
                          style: _m(size: 13, color: const Color(0xFF0F172A)),
                          decoration: InputDecoration(
                            hintText:
                                'Tuliskan catatan pemeriksaan kelengkapan dokumen dan data pengajuan untuk Bagian Aset...',
                            hintStyle: _m(
                              size: 12,
                              color: const Color(0xFF94A3B8),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.all(14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF0F3D56),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Catatan akan dilampirkan bersama pengajuan ke Bagian Aset.',
                          style: _m(size: 11, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  // ── FOOTER ACTIONS ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF475569),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            'Batal',
                            style: _m(
                              size: 13,
                              weight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          key: const Key('btn_teruskan_ke_bagian_aset'),
                          onPressed: _isSubmitting ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F3D56),
                            disabledBackgroundColor: const Color(0xFF94A3B8),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.send_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Teruskan ke Bagian Aset',
                                      style: _m(
                                        size: 13,
                                        weight: FontWeight.w600,
                                        color: Colors.white,
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
            ),
          ),
        ),
      ),
    );
  }
}
