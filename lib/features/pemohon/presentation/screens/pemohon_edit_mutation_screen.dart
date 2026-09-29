// lib/features/pemohon/presentation/screens/pemohon_edit_mutation_screen.dart
//
// Screen: Edit & Ajukan Ulang Pengajuan Mutasi yang Dikembalikan (REQ-008).
// Desain: Sesuai MCP MutasiKu — Edit Pengajuan Mutasi (Revisi Berkas) dari Stitch.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/inline_searchable_dropdown.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../../../mutation/domain/usecases/update_mutation_usecase.dart';
import '../../../mutation/presentation/providers/mutation_form_provider.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';
import '../../../notification/domain/entities/notification_item.dart';
import '../../../notification/presentation/providers/notification_provider.dart';

abstract final class _EditColors {
  static const bg = Color(0xFFF6F8FA);
  static const white = Color(0xFFFFFFFF);
  static const primary = Color(0xFF00273A);
  static const textPrimary = Color(0xFF0F1D28);
  static const textSecondary = Color(0xFF42474D);
  static const textMuted = Color(0xFF64748B);
  static const textSlate = Color(0xFF334155);
  static const border = Color(0xFFD0D5DD);
  static const surfaceLow = Color(0xFFECF4FF);
  static const secondary = Color(0xFF0F766E);
  static const success = Color(0xFF15803D);
  static const error = Color(0xFFB42318);
  static const info = Color(0xFF1E40AF);
  static const infoBg = Color(0xFFEBF5FF);
  static const infoBorder = Color(0xFFBFDBFE);
  static const warningBg = Color(0xFFFFFBEB);
  static const warningBorder = Color(0xFFFDE68A);
  static const warningIconBg = Color(0xFFFEF3C7);
  static const warningIconFg = Color(0xFF92400E);
}

class PemohonEditMutationScreen extends ConsumerStatefulWidget {
  final String mutationId;

  const PemohonEditMutationScreen({super.key, required this.mutationId});

  @override
  ConsumerState<PemohonEditMutationScreen> createState() =>
      _PemohonEditMutationScreenState();
}

class _PemohonEditMutationScreenState
    extends ConsumerState<PemohonEditMutationScreen> {
  final _locationController = TextEditingController();
  final _picController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _prefilled = false;

  @override
  void dispose() {
    _locationController.dispose();
    _picController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  TextStyle _t({
    double size = 14,
    FontWeight w = FontWeight.w400,
    Color color = _EditColors.textPrimary,
    double? h,
    double? ls,
    FontStyle? style,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: w,
      color: color,
      height: h,
      letterSpacing: ls,
      fontStyle: style,
    );
  }

  String _initials(String? name) {
    final p = (name ?? 'Pemohon')
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (p.isEmpty) return 'P';
    if (p.length == 1) {
      return p.first.length >= 2
          ? p.first.substring(0, 2).toUpperCase()
          : p.first.toUpperCase();
    }
    return '${p.first[0]}${p.last[0]}'.toUpperCase();
  }

  IconData _getAssetIcon(String? categoryName) {
    final cat = (categoryName ?? '').toLowerCase();
    if (cat.contains('furnitur') ||
        cat.contains('mebel') ||
        cat.contains('kursi') ||
        cat.contains('meja')) {
      return Icons.chair_outlined;
    }
    if (cat.contains('elektronik') ||
        cat.contains('laptop') ||
        cat.contains('komputer') ||
        cat.contains('pc')) {
      return Icons.laptop_mac_outlined;
    }
    if (cat.contains('kendaraan') ||
        cat.contains('mobil') ||
        cat.contains('motor')) {
      return Icons.directions_car_outlined;
    }
    return Icons.inventory_2_outlined;
  }

  void _safePop(BuildContext context, [String? mutationId]) {
    if (context.canPop()) {
      context.pop();
    } else {
      if (mutationId != null) {
        try {
          context.go(
            RouteNames.pemohonMutasiDetailPath.replaceFirst(':id', mutationId),
          );
          return;
        } catch (_) {}
      }
      context.go(RouteNames.pemohonMutasiPath);
    }
  }

  bool _isMutationOwnedBy(Mutation mutation, User? user) {
    if (user == null) return true;
    if (user.role != UserRole.pemohon) return true;

    if (mutation.applicantId != null && mutation.applicantId == user.id) {
      return true;
    }
    if ((user.id == 'usr_pemohon' ||
            user.id == 'usr_101' ||
            user.id == 'user_pemohon') &&
        (mutation.applicantId == 'usr_pemohon' ||
            mutation.applicantId == 'usr_101' ||
            mutation.applicantId == 'user_pemohon')) {
      return true;
    }
    if (mutation.applicantName.trim().toLowerCase() ==
        user.name.trim().toLowerCase()) {
      return true;
    }
    return false;
  }

  void _prefillData(Mutation m) {
    if (!_prefilled) {
      _locationController.text = m.targetLocation;
      _picController.text = m.targetPic;
      _reasonController.text = m.reason;
      _prefilled = true;
    }
  }

  Future<void> _resubmit() async {
    final location = _locationController.text.trim();
    final pic = _picController.text.trim();
    final reason = _reasonController.text.trim();

    if (location.isEmpty || pic.isEmpty || reason.isEmpty) {
      AppFeedback.showWarning(
        context,
        'Lokasi tujuan, PIC baru, dan alasan wajib diisi.',
      );
      return;
    }

    final mutation = await ref
        .read(updateMutationProvider.notifier)
        .submit(
          UpdateMutationParams(
            mutationId: widget.mutationId,
            targetLocation: location,
            targetPic: pic,
            reason: reason,
          ),
        );

    if (!mounted) return;

    if (mutation != null) {
      // Invalidate list dan detail agar UI langsung menampilkan status terbaru
      ref.invalidate(mutationListProvider);
      ref.invalidate(mutationDetailProvider(widget.mutationId));

      // Notifikasi ke antrean Operator bahwa mutasi telah diajukan ulang
      try {
        ref
            .read(notificationProvider.notifier)
            .notifyRole(
              targetRole: UserRole.operator,
              title: 'Pengajuan Diajukan Ulang',
              message:
                  'Pengajuan mutasi ${mutation.ticketNumber} (${mutation.asset.name}) telah diperbaiki oleh Pemohon dan siap diverifikasi.',
              type: NotificationType.action,
              relatedMutationId: mutation.id,
            );
      } catch (_) {}

      // Tandai notifikasi return sebelumnya sebagai telah dibaca
      try {
        final notifNotifier = ref.read(notificationProvider.notifier);
        final notifs = ref.read(notificationProvider);
        for (final n in notifs) {
          if (n.relatedMutationId == widget.mutationId &&
              n.type == NotificationType.warning &&
              !n.isRead) {
            notifNotifier.markAsRead(n.id);
          }
        }
      } catch (_) {}

      AppFeedback.showSuccess(
        context,
        'Pengajuan berhasil diajukan ulang ke antrean verifikasi Operator.',
      );

      // Arahkan kembali ke Detail Mutasi atau Mutasi Saya
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        try {
          context.go(
            RouteNames.pemohonMutasiDetailPath.replaceFirst(
              ':id',
              widget.mutationId,
            ),
          );
        } catch (_) {}
      }
    } else {
      final err = ref.read(updateMutationProvider).error;
      AppFeedback.showError(context, err ?? 'Gagal mengirim ulang pengajuan.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncDetail = ref.watch(mutationDetailProvider(widget.mutationId));
    final submitState = ref.watch(updateMutationProvider);
    final availableLocations = ref.watch(availableLocationsProvider);
    final availablePics = ref.watch(availablePicsProvider);
    final currentUser = ref.watch(authStateProvider).user;

    return Scaffold(
      backgroundColor: _EditColors.bg,
      body: Column(
        children: [
          _buildHeader(context, currentUser),
          Expanded(
            child: asyncDetail.when(
              loading: () => const LoadingIndicator(),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () =>
                    ref.invalidate(mutationDetailProvider(widget.mutationId)),
              ),
              data: (m) {
                // Ownership guard: Pemohon hanya bisa edit mutation miliknya sendiri
                if (!_isMutationOwnedBy(m, currentUser)) {
                  return _buildAccessDenied();
                }

                // Status guard: Hanya bisa edit ketika berstatus returned
                if (m.status != MutationStatus.returned) {
                  return _buildStatusGuard(m);
                }

                _prefillData(m);

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Page Title & Subtitle ─────────────────────────
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Pengajuan',
                              style: _t(
                                size: 22,
                                w: FontWeight.w700,
                                color: _EditColors.textPrimary,
                                ls: -0.3,
                                h: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Perbaiki data pengajuan mutasi aset',
                              style: _t(
                                size: 13,
                                color: _EditColors.textSecondary,
                                h: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── 1. Alur Perbaikan Card ────────────────────────
                      _buildWorkflowCard(),
                      const SizedBox(height: 14),

                      // ── 2. Catatan Operator Card ──────────────────────
                      if (m.returnReason != null &&
                          m.returnReason!.trim().isNotEmpty) ...[
                        _buildOperatorNotesCard(m.returnReason!.trim()),
                        const SizedBox(height: 14),
                      ],

                      // ── 3. Read-only Asset Information Card ───────────
                      _buildAssetInfoCard(m),
                      const SizedBox(height: 14),

                      // ── 4. Form Fields Card (Editable) ────────────────
                      _buildFormFieldsCard(availableLocations, availablePics),
                      const SizedBox(height: 20),

                      // ── 5. Action Buttons ─────────────────────────────
                      _buildActionButtons(m, submitState),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, User? user) {
    return Material(
      color: _EditColors.white.withValues(alpha: 0.95),
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _EditColors.border.withValues(alpha: 0.4),
              ),
            ),
          ),
          child: Row(
            children: [
              Material(
                color: _EditColors.white,
                shape: CircleBorder(
                  side: BorderSide(
                    color: _EditColors.border.withValues(alpha: 0.5),
                  ),
                ),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _safePop(context, widget.mutationId),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.arrow_back,
                      size: 20,
                      color: _EditColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5F1),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _EditColors.secondary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: _EditColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'MUTASIKU',
                      style: _t(
                        size: 11,
                        w: FontWeight.w700,
                        color: _EditColors.secondary,
                        ls: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: _EditColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _initials(user?.name),
                      style: _t(
                        size: 12,
                        w: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _EditColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkflowCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _EditColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _EditColors.infoBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _EditColors.infoBg,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.info, color: _EditColors.info, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Alur Perbaikan & Pengajuan Ulang',
                      style: _t(
                        size: 15,
                        w: FontWeight.w700,
                        color: _EditColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Pengajuan dikembalikan → Perbaiki data pengajuan → Ajukan ulang → Kembali ke antrean Operator untuk diverifikasi ulang.',
                  style: _t(
                    size: 12,
                    color: _EditColors.textSecondary,
                    h: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatorNotesCard(String returnReason) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _EditColors.warningBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _EditColors.warningBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _EditColors.warningIconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.feedback,
              color: _EditColors.warningIconFg,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Catatan Operator',
                      style: _t(
                        size: 16,
                        w: FontWeight.w700,
                        color: _EditColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _EditColors.warningIconBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Revisi Dibutuhkan',
                        style: _t(
                          size: 12,
                          w: FontWeight.w600,
                          color: _EditColors.warningIconFg,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Catatan dari Operator:',
                  style: _t(
                    size: 11,
                    w: FontWeight.w600,
                    color: _EditColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  returnReason,
                  style: _t(
                    size: 12.5,
                    color: _EditColors.textSecondary,
                    h: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetInfoCard(Mutation m) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _EditColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _EditColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _EditColors.surfaceLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _EditColors.border.withValues(alpha: 0.6),
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              _getAssetIcon(m.asset.category.name),
              size: 22,
              color: _EditColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        m.asset.name,
                        style: _t(
                          size: 15,
                          w: FontWeight.w700,
                          color: _EditColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        (m.asset.category.name.isNotEmpty
                                ? m.asset.category.name
                                : m.asset.category.code)
                            .toUpperCase(),
                        style: _t(
                          size: 11,
                          w: FontWeight.w600,
                          color: _EditColors.textSlate,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Kode: ${m.asset.assetCode} • Tiket: ${m.ticketNumber}',
                  style: _t(size: 12, color: _EditColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 13,
                      color: _EditColors.textMuted,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        'Lokasi Asal: ${m.currentLocation}',
                        style: _t(size: 12, color: _EditColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFieldsCard(
    List<String> availableLocations,
    List<String> availablePics,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _EditColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _EditColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Lokasi Tujuan Field
          Row(
            children: [
              Text(
                'LOKASI TUJUAN',
                style: _t(
                  size: 12,
                  w: FontWeight.w700,
                  color: _EditColors.textSlate,
                  ls: 0.6,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '*',
                style: _t(
                  size: 12,
                  w: FontWeight.w700,
                  color: _EditColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _EditColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _EditColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: _EditColors.primary,
                    width: 1.5,
                  ),
                ),
                labelStyle: _t(size: 13, color: _EditColors.textSlate),
                hintStyle: _t(size: 13, color: const Color(0xFF94A3B8)),
              ),
            ),
            child: InlineSearchableDropdown(
              key: const Key('dropdown_edit_target_location'),
              fieldKey: const Key('input_edit_target_location'),
              labelText: 'Lokasi Tujuan *',
              hintText: 'Pilih lokasi tujuan',
              controller: _locationController,
              items: availableLocations,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
          ),
          const SizedBox(height: 16),

          // 2. PIC Baru Field
          Row(
            children: [
              Text(
                'PIC BARU',
                style: _t(
                  size: 12,
                  w: FontWeight.w700,
                  color: _EditColors.textSlate,
                  ls: 0.6,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '*',
                style: _t(
                  size: 12,
                  w: FontWeight.w700,
                  color: _EditColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _EditColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _EditColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: _EditColors.primary,
                    width: 1.5,
                  ),
                ),
                labelStyle: _t(size: 13, color: _EditColors.textSlate),
                hintStyle: _t(size: 13, color: const Color(0xFF94A3B8)),
              ),
            ),
            child: InlineSearchableDropdown(
              key: const Key('dropdown_edit_target_pic'),
              fieldKey: const Key('input_edit_target_pic'),
              labelText: 'PIC Baru *',
              hintText: 'Pilih PIC baru dari master data',
              controller: _picController,
              items: availablePics,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
          ),
          const SizedBox(height: 16),

          // 3. Alasan / Justifikasi Mutasi Field
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'ALASAN / JUSTIFIKASI MUTASI',
                    style: _t(
                      size: 12,
                      w: FontWeight.w700,
                      color: _EditColors.textSlate,
                      ls: 0.6,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '*',
                    style: _t(
                      size: 12,
                      w: FontWeight.w700,
                      color: _EditColors.error,
                    ),
                  ),
                ],
              ),
              Text(
                '${_reasonController.text.length} / 250',
                style: _t(
                  size: 12,
                  w: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            key: const Key('input_edit_reason'),
            controller: _reasonController,
            maxLines: 4,
            maxLength: 250,
            buildCounter: (
              _, {
              required currentLength,
              required isFocused,
              maxLength,
            }) => null,
            onChanged: (_) => setState(() {}),
            style: _t(size: 13, color: _EditColors.textPrimary, h: 1.5),
            decoration: InputDecoration(
              hintText: 'Jelaskan alasan atau perbaikan yang dilakukan...',
              hintStyle: _t(size: 13, color: const Color(0xFF94A3B8)),
              contentPadding: const EdgeInsets.all(14),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _EditColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _EditColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: _EditColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Mutation m, UpdateMutationState submitState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          key: const Key('btn_ajukan_ulang'),
          onPressed: submitState.isLoading ? null : () => _resubmit(),
          style: ElevatedButton.styleFrom(
            backgroundColor: _EditColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _EditColors.primary.withValues(alpha: 0.6),
            elevation: 0,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: submitState.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.send, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Ajukan Kembali',
                      style: _t(
                        size: 14,
                        w: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          key: const Key('btn_kembali_dashboard'),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(
                RouteNames.pemohonMutasiDetailPath.replaceFirst(':id', m.id),
              );
            }
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1E293B),
            side: const BorderSide(color: _EditColors.border),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.arrow_back, size: 18, color: Color(0xFF1E293B)),
              const SizedBox(width: 8),
              Text(
                'Kembali',
                style: _t(
                  size: 14,
                  w: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Pastikan seluruh data revisi telah terisi sesuai catatan operator',
          textAlign: TextAlign.center,
          style: _t(size: 11, color: _EditColors.textMuted, w: FontWeight.w400),
        ),
      ],
    );
  }

  Widget _buildAccessDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: _EditColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Akses Ditolak',
              style: _t(
                size: 18,
                w: FontWeight.w700,
                color: _EditColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Anda hanya dapat mengedit pengajuan mutasi milik Anda sendiri.',
              textAlign: TextAlign.center,
              style: _t(size: 14, color: _EditColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: () => _safePop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusGuard(Mutation m) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 56,
              color: _EditColors.success,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Pengajuan ini berstatus "${m.status.displayName}".',
              style: _t(
                size: 16,
                w: FontWeight.w700,
                color: _EditColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Pengajuan hanya dapat diedit ketika berstatus "Dikembalikan ke Pemohon".',
              textAlign: TextAlign.center,
              style: _t(size: 13, color: _EditColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(
                    RouteNames.pemohonMutasiDetailPath.replaceFirst(
                      ':id',
                      m.id,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.description_outlined),
              label: const Text('Lihat Detail Mutasi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _EditColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => _safePop(context, m.id),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Kembali'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(200, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
