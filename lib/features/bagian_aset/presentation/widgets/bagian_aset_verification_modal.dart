// lib/features/bagian_aset/presentation/widgets/bagian_aset_verification_modal.dart
//
// Modal Dialog Verifikasi Pengajuan Mutasi oleh Bagian Aset:
// - Pilihan radio eksklusif: Setujui (Lolos verifikasi, teruskan ke Pimpinan/Kadiv) vs Tolak (Tolak & tutup pengajuan)
// - Kolom Catatan Verifikasi / Instruksi (Opsional untuk Setujui, Wajib untuk Tolak)
// - Penetapan PIC baru jika aset ditinggalkan / tidak ikut pemohon (khusus pilihan Setujui)
// - Terintegrasi penuh dengan verifyAndForward (Setujui) dan guard penolakan sesuai kewenangan bisnis
// - UI presisi 1:1 sesuai spesifikasi dan sistem desain MutasiKu.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';
import '../providers/bagian_aset_verification_provider.dart';

enum BagianAsetDecision {
  approve,
  reject,
}

/// Alur verifikasi Bagian Aset terpadu (single modal):
/// - Membuka satu modal verifikasi Bagian Aset langsung.
/// - Jika aset tidak dibawa pemohon & belum memiliki PIC valid, bagian pemilihan PIC
///   tersedia dan wajib dipilih di dalam modal verifikasi sebelum dapat menyetujui mutasi.
/// - Jika aset dibawa pemohon:
///   Pemilihan PIC baru tidak diwajibkan / disembunyikan.
Future<bool?> startBagianAsetVerificationFlow(
  BuildContext context, {
  required Mutation mutation,
  String? initialSelectedPicId,
  BagianAsetDecision initialDecision = BagianAsetDecision.approve,
}) async {
  return showBagianAsetVerificationModal(
    context,
    mutation: mutation,
    initialSelectedPicId: initialSelectedPicId,
    initialDecision: initialDecision,
  );
}

/// Helper untuk menampilkan Dialog Verifikasi Bagian Aset di atas halaman saat ini
Future<bool?> showBagianAsetVerificationModal(
  BuildContext context, {
  required Mutation mutation,
  String? initialSelectedPicId,
  BagianAsetDecision initialDecision = BagianAsetDecision.approve,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Verifikasi Bagian Aset',
    barrierColor: const Color(0xFF0F172A).withValues(alpha: 0.50),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (dialogCtx, anim1, anim2) => BagianAsetVerificationModal(
      mutation: mutation,
      initialSelectedPicId: initialSelectedPicId,
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

class BagianAsetVerificationModal extends ConsumerStatefulWidget {
  final Mutation mutation;
  final String? initialSelectedPicId;
  final BagianAsetDecision initialDecision;

  const BagianAsetVerificationModal({
    super.key,
    required this.mutation,
    this.initialSelectedPicId,
    this.initialDecision = BagianAsetDecision.approve,
  });

  @override
  ConsumerState<BagianAsetVerificationModal> createState() =>
      _BagianAsetVerificationModalState();
}

class _BagianAsetVerificationModalState
    extends ConsumerState<BagianAsetVerificationModal> {
  late BagianAsetDecision _decision;
  final _notesController = TextEditingController();
  String? _selectedPicId;
  bool _showValidationError = false;
  bool _isSubmitting = false;

  static const Color purplePrimary = Color(0xFF7C3AED);
  static const Color purpleLightBg = Color(0xFFFAF5FF);
  static const Color purpleBorder = Color(0xFF7C3AED);

  static const Color redPrimary = Color(0xFF991B1B);
  static const Color redLightBg = Color(0xFFFFF1F2);
  static const Color redBorder = Color(0xFFE11D48);

  static const Color borderInactive = Color(0xFFE2E8F0);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _decision = widget.initialDecision;
    final candidatePic =
        widget.initialSelectedPicId ?? widget.mutation.targetPicId;
    if (_isPicValid(candidatePic)) {
      _selectedPicId = candidatePic!.trim();
    }
  }

  bool _isPicValid(String? pic) {
    if (pic == null) return false;
    final clean = pic.trim();
    if (clean.isEmpty ||
        clean == '-' ||
        clean == '0' ||
        clean == 'null' ||
        clean.toLowerCase() == 'belum ditentukan' ||
        clean.toLowerCase() == 'belum ada') {
      return false;
    }
    return true;
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

  bool get _needsNewPic => widget.mutation.needsNewPic;

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    final notes = _notesController.text.trim();

    // Validasi Tolak: Catatan alasan wajib diisi
    if (_decision == BagianAsetDecision.reject) {
      if (notes.isEmpty) {
        AppFeedback.showError(
          context,
          'Catatan alasan penolakan wajib diisi.',
        );
        return;
      }
    }

    // Validasi Setujui: PIC baru wajib jika aset ditinggalkan / butuh PIC baru
    if (_decision == BagianAsetDecision.approve && _needsNewPic) {
      if (!_isPicValid(_selectedPicId)) {
        setState(() => _showValidationError = true);
        AppFeedback.showError(
          context,
          'Penanggung jawab (PIC) baru wajib dipilih sebelum menyimpan verifikasi.',
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    bool success = false;

    if (_decision == BagianAsetDecision.approve) {
      success = await ref
          .read(bagianAsetVerificationActionProvider.notifier)
          .verifyAndForward(
            mutationId: widget.mutation.id,
            newPic: _selectedPicId,
            notes: notes.isNotEmpty ? notes : null,
          );
    } else {
      // Tolak: Dieksekusi melalui notifier dengan menjaga batas kewenangan bisnis
      success = await ref
          .read(bagianAsetVerificationActionProvider.notifier)
          .reject(
            mutationId: widget.mutation.id,
            reason: notes,
          );
    }

    if (!mounted) return;

    if (success) {
      ref.invalidate(bagianAsetMutationDetailProvider(widget.mutation.id));
      ref.invalidate(mutationDetailProvider(widget.mutation.id));

      Navigator.of(context).pop(true);

      if (_decision == BagianAsetDecision.approve) {
        AppFeedback.showSuccess(
          context,
          'Verifikasi berhasil. Pengajuan telah diteruskan ke Pemimpin Divisi.',
        );
      } else {
        AppFeedback.showSuccess(
          context,
          'Pengajuan mutasi berhasil ditolak.',
        );
      }
    } else {
      setState(() => _isSubmitting = false);
      final err = ref.read(bagianAsetVerificationActionProvider).error;
      AppFeedback.showError(
        context,
        err ?? 'Gagal memproses verifikasi Bagian Aset.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mutation;
    final isApprove = _decision == BagianAsetDecision.approve;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 580),
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                    padding: const EdgeInsets.fromLTRB(24, 20, 16, 14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: purplePrimary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.verified_user_outlined,
                            color: purplePrimary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Verifikasi Bagian Aset',
                            style: _m(
                              size: 17,
                              weight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        IconButton(
                          key: const Key('btn_close_verification_modal'),
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
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
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
                                    color: const Color(0xFF0F3D56),
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
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
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
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                m.isAssetMovingWithApplicant
                                    ? Icons.person_pin_outlined
                                    : Icons.swap_horiz_rounded,
                                size: 14,
                                color: m.isAssetMovingWithApplicant
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFD97706),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  m.isAssetMovingWithApplicant
                                      ? 'Aset dibawa Pemohon (${m.applicantName})'
                                      : 'Aset masuk pool unit / butuh penetapan PIC baru',
                                  style: _m(
                                    size: 10.5,
                                    weight: FontWeight.w500,
                                    color: m.isAssetMovingWithApplicant
                                        ? const Color(0xFF059669)
                                        : const Color(0xFFD97706),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── SECTION: KEPUTUSAN BAGIAN ASET * ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 6),
                    child: RichText(
                      text: TextSpan(
                        text: 'Keputusan Bagian Aset ',
                        style: _m(
                          size: 13,
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
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 380;
                        final cards = [
                          _buildDecisionCard(
                            key: const Key('card_decision_approve'),
                            decision: BagianAsetDecision.approve,
                            title: 'Setujui',
                            subtitle:
                                'Lolos verifikasi, teruskan ke Pimpinan/Kadiv',
                            isSelected: isApprove,
                            primaryColor: purplePrimary,
                            bgColor: purpleLightBg,
                            borderColor: purpleBorder,
                          ),
                          _buildDecisionCard(
                            key: const Key('card_decision_reject'),
                            decision: BagianAsetDecision.reject,
                            title: 'Tolak',
                            subtitle: 'Tolak & tutup pengajuan',
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
                              const SizedBox(width: 14),
                              Expanded(child: cards[1]),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              cards[0],
                              const SizedBox(height: 10),
                              cards[1],
                            ],
                          );
                        }
                      },
                    ),
                  ),

                  // ── BAGIAN PEMILIHAN PIC BARU ASET (Hanya jika Setujui & butuh PIC) ──
                  if (isApprove && _needsNewPic) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Penanggung Jawab (PIC) Baru Aset',
                                style: _m(
                                  size: 12.5,
                                  weight: FontWeight.w700,
                                  color: textDark,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                '*',
                                style: TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Aset ditinggalkan di unit asal / masuk pool. Pilih staf aktif yang ditunjuk sebagai penanggung jawab aset baru.',
                            style: _m(size: 11, color: textMuted),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Consumer(
                        builder: (context, ref, _) {
                          final usersAsync = ref.watch(masterUsersProvider);
                          final users = usersAsync.valueOrNull ?? [];
                          final activeUsers =
                              users.where((u) => u.isActive).toList();

                          if (usersAsync.isLoading && activeUsers.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: const Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Memuat daftar pengguna aktif...',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          }

                          final bool isErrorBorder = _showValidationError &&
                              !_isPicValid(_selectedPicId);

                          if (activeUsers.isEmpty && !usersAsync.isLoading) {
                            return TextField(
                              key: const Key('input_pic_baru_bagian_aset'),
                              style: _m(size: 12.5, color: textDark),
                              decoration: InputDecoration(
                                hintText: 'Masukkan nama / NIP PIC Baru...',
                                hintStyle: _m(
                                    size: 12, color: const Color(0xFF94A3B8)),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: isErrorBorder
                                        ? const Color(0xFFDC2626)
                                        : borderInactive,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: isErrorBorder
                                        ? const Color(0xFFDC2626)
                                        : borderInactive,
                                  ),
                                ),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _selectedPicId = val.trim();
                                  if (_isPicValid(_selectedPicId)) {
                                    _showValidationError = false;
                                  }
                                });
                              },
                            );
                          }

                          final hasMatchingItem = activeUsers
                              .any((u) => u.id == _selectedPicId);
                          final effectiveDropdownValue =
                              hasMatchingItem ? _selectedPicId : null;

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isErrorBorder
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFFCBD5E1),
                                width: isErrorBorder ? 1.5 : 1.0,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                key: const Key('dropdown_pilih_pic_baru'),
                                isExpanded: true,
                                value: effectiveDropdownValue,
                                hint: Text(
                                  '-- Pilih PIC Baru --',
                                  style: _m(size: 12, color: textMuted),
                                ),
                                items: activeUsers.map((u) {
                                  return DropdownMenuItem<String>(
                                    value: u.id,
                                    child: Text(
                                      '${u.name} (${u.role.displayName})',
                                      style: _m(size: 12, color: textDark),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedPicId = val;
                                      if (_isPicValid(val)) {
                                        _showValidationError = false;
                                      }
                                    });
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (_showValidationError &&
                        !_isPicValid(_selectedPicId)) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 14,
                              color: Color(0xFFDC2626),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'Pilih PIC baru terlebih dahulu sebelum menyimpan verifikasi.',
                                style: _m(
                                  size: 11,
                                  weight: FontWeight.w500,
                                  color: const Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],

                  // ── SECTION: CATATAN VERIFIKASI / INSTRUKSI ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 6),
                    child: RichText(
                      text: TextSpan(
                        text: isApprove
                            ? 'Catatan Verifikasi / Instruksi (Opsional)'
                            : 'Catatan Verifikasi / Alasan Penolakan ',
                        style: _m(
                          size: 12.5,
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
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TextField(
                      key: const Key('input_catatan_bagian_aset'),
                      controller: _notesController,
                      maxLines: 4,
                      minLines: 3,
                      style: _m(size: 12.5, color: textDark),
                      decoration: InputDecoration(
                        hintText: isApprove
                            ? 'Catatan hasil verifikasi aset untuk Pemimpin Divisi...'
                            : 'Jelaskan alasan penolakan dan instruksi penutupan pengajuan...',
                        hintStyle: _m(size: 12, color: const Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide(
                            color: isApprove ? purplePrimary : redBorder,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),

                  // ── FOOTER ACTIONS ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 24, 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          key: const Key('btn_batal_verifikasi_modal'),
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF475569),
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
                        const SizedBox(width: 10),
                        Flexible(
                          child: ElevatedButton(
                            key: const Key('btn_simpan_verifikasi_bagian_aset'),
                            onPressed: _isSubmitting ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isApprove
                                  ? purplePrimary
                                  : const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFF94A3B8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
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
                                : FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      isApprove
                                          ? 'Simpan Verifikasi Bagian Aset'
                                          : 'Konfirmasi Penolakan',
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
    required BagianAsetDecision decision,
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? borderColor : borderInactive,
            width: isSelected ? 1.6 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio Indicator
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? borderColor : const Color(0xFF94A3B8),
                  width: isSelected ? 6.0 : 1.5,
                ),
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: _m(
                      size: 14,
                      weight: FontWeight.w700,
                      color: isSelected ? primaryColor : textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: _m(
                      size: 11,
                      weight: FontWeight.w400,
                      color: textMuted,
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
