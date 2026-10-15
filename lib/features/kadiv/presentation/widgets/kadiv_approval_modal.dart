// lib/features/kadiv/presentation/widgets/kadiv_approval_modal.dart
//
// Modal Dialog Persetujuan Pengajuan Mutasi oleh Pemimpin Divisi (Kadiv):
// - Pilihan radio eksklusif: Setujui (Persetujuan final, teruskan ke Pemohon) vs Tolak (Tolak secara final)
// - Kolom Catatan Persetujuan / Arahan (Opsional untuk Setujui, Wajib untuk Tolak min. 5 karakter)
// - Ringkasan pengajuan, aset, lokasi, dan status verifikasi Bagian Aset
// - Mengikuti pola interaksi dan standar desain BagianAsetVerificationModal
// - Label khusus persetujuan akhir Pemimpin Divisi

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';
import '../providers/kadiv_approval_provider.dart';

enum KadivDecision {
  approve,
  reject,
}

/// Alur persetujuan Pemimpin Divisi terpadu (single modal):
/// - Membuka satu modal persetujuan Kadiv langsung untuk keputusan Setujui maupun Tolak.
/// - Menyajikan ringkasan tiket, aset, lokasi, serta hasil verifikasi Bagian Aset.
Future<bool?> startKadivApprovalFlow(
  BuildContext context, {
  required Mutation mutation,
  KadivDecision initialDecision = KadivDecision.approve,
}) async {
  return showKadivApprovalModal(
    context,
    mutation: mutation,
    initialDecision: initialDecision,
  );
}

/// Helper untuk menampilkan Dialog Persetujuan Kadiv di atas halaman saat ini
Future<bool?> showKadivApprovalModal(
  BuildContext context, {
  required Mutation mutation,
  KadivDecision initialDecision = KadivDecision.approve,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Persetujuan Pemimpin Divisi',
    barrierColor: const Color(0xFF0F172A).withValues(alpha: 0.50),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (dialogCtx, anim1, anim2) => KadivApprovalModal(
      mutation: mutation,
      initialDecision: initialDecision,
    ),
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

class KadivApprovalModal extends ConsumerStatefulWidget {
  final Mutation mutation;
  final KadivDecision initialDecision;

  const KadivApprovalModal({
    super.key,
    required this.mutation,
    this.initialDecision = KadivDecision.approve,
  });

  @override
  ConsumerState<KadivApprovalModal> createState() => _KadivApprovalModalState();
}

class _KadivApprovalModalState extends ConsumerState<KadivApprovalModal> {
  late KadivDecision _decision;
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  // Design tokens selaras dengan BagianAsetVerificationModal & Kadiv Stitch theme
  static const Color navyPrimary = Color(0xFF0F3D56);
  static const Color tealLightBg = Color(0xFFF0FDFA);
  static const Color tealBorder = Color(0xFF0F766E);

  static const Color redPrimary = Color(0xFF991B1B);
  static const Color redLightBg = Color(0xFFFFF1F2);
  static const Color redBorder = Color(0xFFE11D48);

  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _decision = widget.initialDecision;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  TextStyle _m({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = textDark,
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

    final notes = _notesController.text.trim();

    // Validasi Tolak: Catatan alasan wajib diisi dan minimal 5 karakter
    if (_decision == KadivDecision.reject) {
      if (notes.isEmpty) {
        AppFeedback.showError(
          context,
          'Alasan penolakan tidak boleh kosong.',
        );
        return;
      }
      if (notes.length < 5) {
        AppFeedback.showError(
          context,
          'Alasan penolakan minimal 5 karakter.',
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    bool success = false;

    if (_decision == KadivDecision.approve) {
      success = await ref
          .read(kadivApprovalActionProvider.notifier)
          .approve(mutationId: widget.mutation.id);
    } else {
      success = await ref
          .read(kadivApprovalActionProvider.notifier)
          .reject(
            mutationId: widget.mutation.id,
            reason: notes,
          );
    }

    if (!mounted) return;

    if (success) {
      ref.invalidate(kadivMutationDetailProvider(widget.mutation.id));
      ref.invalidate(mutationDetailProvider(widget.mutation.id));

      Navigator.of(context).pop(true);

      if (_decision == KadivDecision.approve) {
        AppFeedback.showSuccess(
          context,
          'Pengajuan mutasi berhasil disetujui oleh Pemimpin Divisi.',
        );
      } else {
        AppFeedback.showSuccess(
          context,
          'Pengajuan mutasi telah ditolak.',
        );
      }
    } else {
      setState(() => _isSubmitting = false);
      final err = ref.read(kadivApprovalActionProvider).error;
      AppFeedback.showError(
        context,
        err ?? 'Gagal memproses persetujuan Pemimpin Divisi.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mutation;
    final isApprove = _decision == KadivDecision.approve;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 580,
            maxHeight: MediaQuery.sizeOf(context).height - 16,
          ),
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x280F172A),
                blurRadius: 32,
                offset: Offset(0, 16),
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
                    padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: navyPrimary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.gavel_rounded,
                            color: navyPrimary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Persetujuan Pemimpin Divisi',
                                style: _m(
                                  size: 16.5,
                                  weight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isApprove
                                    ? 'Konfirmasi Approval Kadiv'
                                    : 'Konfirmasi Penolakan Kadiv',
                                style: _m(
                                  size: 11,
                                  weight: FontWeight.w500,
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          key: const Key('btn_close_kadiv_modal'),
                          icon: const Icon(Icons.close, size: 20),
                          color: const Color(0xFF94A3B8),
                          tooltip: 'Tutup',
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(false),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: Color(0xFFF1F5F9)),

                  // ── RINGKASAN PENGAJUAN & ASET ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2F6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  m.ticketNumber,
                                  style: _m(
                                    size: 11,
                                    weight: FontWeight.w700,
                                    color: navyPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  m.displayAssetName,
                                  style: _m(
                                    size: 12,
                                    weight: FontWeight.w700,
                                    color: textDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: textMuted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${m.currentLocation}  ➔  ${m.targetLocation}',
                                  style: _m(
                                    size: 11,
                                    weight: FontWeight.w500,
                                    color: const Color(0xFF334155),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline_rounded,
                                size: 13,
                                color: textMuted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Pemohon: ${m.applicantName}  •  PIC: ${m.targetPic}',
                                  style: _m(
                                    size: 11,
                                    weight: FontWeight.w500,
                                    color: const Color(0xFF475569),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Badge Hasil Verifikasi Bagian Aset
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 12,
                                  color: Color(0xFF059669),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Lolos Verifikasi Bagian Aset (${m.assetVerifiedBy ?? m.approvedBy ?? 'Valid'})',
                                    style: _m(
                                      size: 10,
                                      weight: FontWeight.w600,
                                      color: const Color(0xFF065F46),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── SECTION: KEPUTUSAN PEMIMPIN DIVISI * ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
                    child: RichText(
                      text: TextSpan(
                        text: 'Keputusan Pemimpin Divisi ',
                        style: _m(
                          size: 12.5,
                          weight: FontWeight.w700,
                          color: textDark,
                        ),
                        children: const [
                          TextSpan(
                            text: '*',
                            style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── DUA CARD RADIO: SETUJUI & TOLAK ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 380;
                        final cards = [
                          _buildDecisionCard(
                            key: const Key('card_decision_kadiv_approve'),
                            decision: KadivDecision.approve,
                            title: 'Setujui',
                            subtitle:
                                'Persetujuan final, teruskan ke Pemohon',
                            isSelected: isApprove,
                            primaryColor: navyPrimary,
                            bgColor: tealLightBg,
                            borderColor: tealBorder,
                          ),
                          _buildDecisionCard(
                            key: const Key('card_decision_kadiv_reject'),
                            decision: KadivDecision.reject,
                            title: 'Tolak',
                            subtitle: 'Tolak pengajuan secara final (Ditolak)',
                            isSelected: !isApprove,
                            primaryColor: redPrimary,
                            bgColor: redLightBg,
                            borderColor: redBorder,
                          ),
                        ];

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: cards[0]),
                              const SizedBox(width: 10),
                              Expanded(child: cards[1]),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              cards[0],
                              const SizedBox(height: 8),
                              cards[1],
                            ],
                          );
                        }
                      },
                    ),
                  ),

                  // ── SECTION: CATATAN PERSETUJUAN / ALASAN PENOLAKAN ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                    child: RichText(
                      text: TextSpan(
                        text: isApprove
                            ? 'Catatan Persetujuan / Arahan (Opsional)'
                            : 'Catatan Persetujuan / Alasan Penolakan ',
                        style: _m(
                          size: 12,
                          weight: FontWeight.w700,
                          color: textDark,
                        ),
                        children: [
                          if (!isApprove)
                            const TextSpan(
                              text: '*',
                              style: TextStyle(
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      key: isApprove
                          ? const Key('input_catatan_kadiv')
                          : const Key('input_alasan_penolakan_kadiv'),
                      controller: _notesController,
                      maxLines: 3,
                      minLines: 2,
                      style: _m(size: 12, color: textDark),
                      decoration: InputDecoration(
                        hintText: isApprove
                            ? 'Tuliskan catatan arahan atau pesan persetujuan final (opsional)...'
                            : 'Jelaskan alasan penolakan mutasi untuk Pemohon (wajib, min. 5 karakter)...',
                        hintStyle: _m(size: 11.5, color: const Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isApprove ? tealBorder : redBorder,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),

                  // ── FOOTER ACTIONS ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          key: const Key('btn_batal_kadiv_modal'),
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF475569),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
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
                        const SizedBox(width: 8),
                        Flexible(
                          child: ElevatedButton(
                            key: isApprove
                                ? const Key('btn_confirm_setujui_kadiv')
                                : const Key('btn_confirm_tolak_kadiv_dialog'),
                            onPressed: _isSubmitting ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isApprove ? navyPrimary : const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFF94A3B8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
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
                                : FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      isApprove
                                          ? 'Simpan Persetujuan'
                                          : 'Simpan Penolakan',
                                      style: _m(
                                        size: 13,
                                        weight: FontWeight.w600,
                                        color: Colors.white,
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDecisionCard({
    required Key key,
    required KadivDecision decision,
    required String title,
    required String subtitle,
    required bool isSelected,
    required Color primaryColor,
    required Color bgColor,
    required Color borderColor,
  }) {
    return InkWell(
      key: key,
      onTap: _isSubmitting
          ? null
          : () {
              setState(() {
                _decision = decision;
              });
            },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? borderColor : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? borderColor : const Color(0xFF94A3B8),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: borderColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: _m(
                      size: 13,
                      weight: FontWeight.w700,
                      color: isSelected ? primaryColor : textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: _m(
                      size: 11,
                      color: isSelected ? primaryColor.withValues(alpha: 0.85) : textMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
