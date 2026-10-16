// lib/features/bagian_aset/presentation/widgets/pic_selection_dialog.dart
//
// Dialog Langkah 1: Pemilihan PIC Baru untuk Aset yang tidak dibawa Pemohon.
// Muncul saat staf Bagian Aset menekan "Pilih PIC & Verifikasi".
//
// Aturan:
// 1. Data PIC diambil dari master data pengguna aktif (masterUsersProvider).
// 2. Tombol Lanjutkan hanya dapat memproses setelah PIC dipilih.
// 3. Menampilkan instruksi jelas:
//    "Pemohon tidak membawa aset. Pilih PIC baru yang bertanggung jawab atas aset ini sebelum melanjutkan verifikasi."
// 4. Jika dibatalkan, dialog ditutup tanpa mengubah status pengajuan atau master aset.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mutation/domain/entities/mutation.dart';

/// Helper untuk menampilkan Dialog Pemilihan PIC Baru Bagian Aset.
/// Mengembalikan ID PIC yang dipilih, atau `null` jika dibatalkan.
Future<String?> showPicSelectionDialog(
  BuildContext context, {
  required Mutation mutation,
  String? initialSelectedPicId,
}) {
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Pemilihan PIC Baru',
    barrierColor: const Color(0xFF0F172A).withValues(alpha: 0.50),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (dialogCtx, anim1, anim2) => PicSelectionDialog(
      mutation: mutation,
      initialSelectedPicId: initialSelectedPicId,
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

class PicSelectionDialog extends ConsumerStatefulWidget {
  final Mutation mutation;
  final String? initialSelectedPicId;

  const PicSelectionDialog({
    super.key,
    required this.mutation,
    this.initialSelectedPicId,
  });

  @override
  ConsumerState<PicSelectionDialog> createState() => _PicSelectionDialogState();
}

class _PicSelectionDialogState extends ConsumerState<PicSelectionDialog> {
  String? _selectedPicId;
  bool _showValidationError = false;

  static const Color primaryColor = Color(0xFF0F766E); // Teal Deep
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderInactive = Color(0xFFCBD5E1);

  @override
  void initState() {
    super.initState();
    if (widget.initialSelectedPicId != null &&
        widget.initialSelectedPicId!.trim().isNotEmpty &&
        widget.initialSelectedPicId!.trim() != '-' &&
        widget.initialSelectedPicId!.trim() != 'null') {
      _selectedPicId = widget.initialSelectedPicId!.trim();
    } else if (widget.mutation.targetPicId != null &&
        widget.mutation.targetPicId!.trim().isNotEmpty &&
        widget.mutation.targetPicId!.trim() != '-' &&
        widget.mutation.targetPicId!.trim() != 'null') {
      _selectedPicId = widget.mutation.targetPicId!.trim();
    }
  }

  TextStyle _font({
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

  void _handleContinue() {
    final clean = _selectedPicId?.trim();
    if (clean == null ||
        clean.isEmpty ||
        clean == '-' ||
        clean == '0' ||
        clean == 'null' ||
        clean.toLowerCase() == 'belum ditentukan') {
      setState(() => _showValidationError = true);
      return;
    }
    Navigator.of(context).pop(clean);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mutation;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 540,
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
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.person_add_alt_1_outlined,
                            color: primaryColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pilih PIC Baru Aset',
                                style: _font(
                                  size: 16.5,
                                  weight: FontWeight.w700,
                                  color: textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Langkah 1 dari 2 • Penetapan Penanggung Jawab',
                                style: _font(
                                  size: 11.5,
                                  weight: FontWeight.w500,
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          key: const Key('btn_close_pic_dialog'),
                          icon: const Icon(Icons.close, size: 20),
                          color: const Color(0xFF94A3B8),
                          tooltip: 'Tutup',
                          onPressed: () => Navigator.of(context).pop(null),
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
                                  style: _font(
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
                                  style: _font(
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
                                  style: _font(
                                    size: 11,
                                    weight: FontWeight.w500,
                                    color: const Color(0xFF334155),
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

                  // ── INSTRUKSI KHUSUS PIC BARU ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFFD97706),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Pemohon tidak membawa aset. Pilih PIC baru yang bertanggung jawab atas aset ini sebelum melanjutkan verifikasi.',
                              style: _font(
                                size: 11.5,
                                weight: FontWeight.w600,
                                color: const Color(0xFF92400E),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── SECTION DROPDOWN PIC ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 6),
                    child: RichText(
                      text: TextSpan(
                        text: 'Penanggung Jawab (PIC) Baru ',
                        style: _font(
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
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
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

                        final cleanPic = _selectedPicId?.trim();
                        final bool hasInvalidPic = cleanPic == null ||
                            cleanPic.isEmpty ||
                            cleanPic == '-' ||
                            cleanPic == '0' ||
                            cleanPic == 'null' ||
                            cleanPic.toLowerCase() == 'belum ditentukan';
                        final bool isErrorBorder =
                            _showValidationError && hasInvalidPic;

                        if (activeUsers.isEmpty && !usersAsync.isLoading) {
                          return TextField(
                            key: const Key('input_pic_baru_bagian_aset'),
                            style: _font(size: 12.5, color: textDark),
                            decoration: InputDecoration(
                              hintText: 'Masukkan nama / NIP PIC Baru...',
                              hintStyle: _font(size: 12, color: textMuted),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
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
                                if (val.trim().isNotEmpty && val.trim() != '-') {
                                  _showValidationError = false;
                                }
                              });
                            },
                          );
                        }

                        final hasMatchingItem =
                            activeUsers.any((u) => u.id == _selectedPicId);
                        final effectiveDropdownValue =
                            hasMatchingItem ? _selectedPicId : null;

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isErrorBorder
                                  ? const Color(0xFFDC2626)
                                  : borderInactive,
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
                                style: _font(size: 12.5, color: textMuted),
                              ),
                              items: activeUsers.map((u) {
                                return DropdownMenuItem<String>(
                                  value: u.id,
                                  child: Text(
                                    '${u.name} (${u.role.displayName})',
                                    style: _font(size: 12.5, color: textDark),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedPicId = val;
                                  if (val != null && val.isNotEmpty && val != '-') {
                                    _showValidationError = false;
                                  }
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Pesan validasi jika PIC belum dipilih
                  if (_showValidationError &&
                      (_selectedPicId == null ||
                          _selectedPicId!.trim().isEmpty ||
                          _selectedPicId!.trim() == '-' ||
                          _selectedPicId!.trim() == 'null' ||
                          _selectedPicId!.trim().toLowerCase() ==
                              'belum ditentukan')) ...[
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
                              'Pilih PIC baru terlebih dahulu sebelum melanjutkan verifikasi.',
                              style: _font(
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

                  const SizedBox(height: 24),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),

                  // ── FOOTER ACTIONS ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 24, 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          key: const Key('btn_batal_pic_dialog'),
                          onPressed: () => Navigator.of(context).pop(null),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF475569),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            'Batal',
                            style: _font(
                              size: 13,
                              weight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          key: const Key('btn_lanjutkan_verifikasi'),
                          onPressed: _handleContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Lanjutkan',
                                style: _font(
                                  size: 13,
                                  weight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: Colors.white,
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
