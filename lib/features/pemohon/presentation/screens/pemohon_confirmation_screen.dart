// lib/features/pemohon/presentation/screens/pemohon_confirmation_screen.dart
//
// Konfirmasi Mutasi — visual Stitch HTML.
// Logic: ownership, confirm, return for revision (kode lama).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/mutasiku_page_header.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';
import '../../../notification/domain/entities/notification_item.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../providers/pemohon_confirmation_provider.dart';

abstract final class _C {
  static const bg = Color(0xFFF6F8FA);
  static const white = Color(0xFFFFFFFF);
  static const primary = Color(0xFF00273A);
  static const textPrimary = Color(0xFF172B4D);
  static const textSecondary = Color(0xFF52606D);
  static const border = Color(0xFFD0D5DD);
  static const surfaceLow = Color(0xFFECF4FF);
  static const surfaceHigh = Color(0xFFDBEAF9);
  static const secondary = Color(0xFF006A63);
  static const success = Color(0xFF15803D);
  static const warning = Color(0xFFB45309);
  static const error = Color(0xFFB42318);
  static const info = Color(0xFF175CD3);
}

class PemohonConfirmationScreen extends ConsumerStatefulWidget {
  final String mutationId;

  const PemohonConfirmationScreen({super.key, required this.mutationId});

  @override
  ConsumerState<PemohonConfirmationScreen> createState() =>
      _PemohonConfirmationScreenState();
}

class _PemohonConfirmationScreenState
    extends ConsumerState<PemohonConfirmationScreen> {
  bool _checkSn = true;
  bool _checkLocation = true;
  bool _checkPic = true;
  bool _copiedSn = false;

  TextStyle _t({
    double size = 14,
    FontWeight w = FontWeight.w400,
    Color color = _C.textPrimary,
    double? h,
    double? ls,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: w,
      color: color,
      height: h,
      letterSpacing: ls,
    );
  }

  void _safePop(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
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

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$day ${months[dt.month - 1]} ${dt.year}, $hour:$min WIB';
  }


  @override
  Widget build(BuildContext context) {
    final asyncMutation = ref.watch(mutationDetailProvider(widget.mutationId));
    final actionState = ref.watch(pemohonConfirmationActionProvider);
    final user = ref.watch(authStateProvider).user;

    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: asyncMutation.when(
              data: (mutation) {
                if (!_isMutationOwnedBy(mutation, user)) {
                  return _accessDenied();
                }
                return _buildBody(mutation, actionState);
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: _C.primary),
              ),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () =>
                    ref.invalidate(mutationDetailProvider(widget.mutationId)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: MutasiKuPageHeader(
        title: 'Konfirmasi Mutasi',
        subtitle: 'Verifikasi fisik & serah terima mutasi aset',
        onBack: () => _safePop(context),
      ),
    );
  }

  Widget _accessDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: _C.error),
            const SizedBox(height: 12),
            Text('Akses Ditolak', style: _t(size: 18, w: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Anda hanya dapat melihat dan mengonfirmasi pengajuan mutasi milik Anda sendiri.',
              textAlign: TextAlign.center,
              style: _t(size: 14, color: _C.textSecondary),
            ),
            const SizedBox(height: 20),
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

  Widget _buildBody(
    Mutation mutation,
    PemohonConfirmationActionState actionState,
  ) {
    final m = actionState.result ?? mutation;
    final isPending = m.status == MutationStatus.waitingConfirmation ||
        m.status == MutationStatus.pendingConfirmation;
    final isCompleted = m.status == MutationStatus.completed;
    final isDisputedByApplicant = (m.status == MutationStatus.returned && m.staffUpdatedAt != null) ||
        (m.status == MutationStatus.waitingAssetVerification && m.confirmationReason != null);

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [

            if (actionState.successMessage != null) ...[
              _banner(
                actionState.successMessage!,
                _C.success,
                const Color(0xFFECFDF3),
                const Color(0xFFD1FADF),
                Icons.check_circle,
              ),
              const SizedBox(height: 12),
            ],
            if (actionState.error != null) ...[
              _banner(
                actionState.error!,
                _C.error,
                const Color(0xFFFEF3F2),
                const Color(0xFFFECDCA),
                Icons.error_outline,
              ),
              const SizedBox(height: 12),
            ],
            if (isCompleted) ...[
              _banner(
                'Konfirmasi telah diberikan. Mutasi aset telah selesai.',
                _C.success,
                const Color(0xFFECFDF3),
                const Color(0xFFD1FADF),
                Icons.check_circle_outline,
              ),
              const SizedBox(height: 12),
            ] else if (isDisputedByApplicant) ...[
              _banner(
                'Laporan ketidaksesuaian Anda sudah diteruskan ke Bagian Aset. '
                'Tidak ada tindakan lain yang perlu Anda lakukan saat ini — '
                'konfirmasi akan tersedia kembali setelah data diperbaiki.',
                _C.info,
                const Color(0xFFEFF6FF),
                const Color(0xFFBFDBFE),
                Icons.info_outline,
              ),
              const SizedBox(height: 12),
            ] else if (!isPending) ...[
              _banner(
                'Pengajuan ini berstatus "${m.status.displayName}". Konfirmasi hanya dapat dilakukan saat berstatus "Menunggu Konfirmasi".',
                _C.warning,
                const Color(0xFFFFFBEB),
                const Color(0xFFFEDF89),
                Icons.warning_amber_rounded,
              ),
              const SizedBox(height: 12),
            ],

            _ticketCard(m, isDisputedByApplicant: isDisputedByApplicant),
            const SizedBox(height: 12),
            _assetUpdateCard(m),
            const SizedBox(height: 12),
            _diffCard(m),
            const SizedBox(height: 12),
            if (isPending) ...[
              _checklistCard(m),
              const SizedBox(height: 16),
              _actionButtons(m, actionState),
            ],
          ],
        ),
        if (actionState.isLoading)
          Container(
            color: Colors.black26,
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: _C.primary),
                      SizedBox(height: 12),
                      Text(
                        'Memproses konfirmasi...',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _banner(String msg, Color fg, Color bg, Color border, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: _t(size: 12, w: FontWeight.w600, color: fg, h: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _ticketCard(Mutation m, {required bool isDisputedByApplicant}) {
    final pending = m.status == MutationStatus.waitingConfirmation ||
        m.status == MutationStatus.pendingConfirmation;
    final done = m.status == MutationStatus.completed;

    // Untuk kasus laporan ketidaksesuaian oleh pemohon, tampilkan badge
    // netral ("Menunggu Bagian Aset") — bukan "Dikembalikan ke Pemohon" yang
    // secara semantik menyalahkan pemohon padahal justru pemohon yang lapor.
    final badgeLabel = isDisputedByApplicant
        ? 'Menunggu Bagian Aset'
        : m.status.displayName;
    final badgeIcon = isDisputedByApplicant
        ? Icons.hourglass_top
        : pending
        ? Icons.pending_actions
        : done
        ? Icons.check_circle_outline
        : Icons.info_outline;
    final badgeColor = isDisputedByApplicant
        ? _C.info
        : done
        ? _C.success
        : pending
        ? _C.warning
        : _C.error;
    final badgeBg = isDisputedByApplicant
        ? const Color(0xFFEFF6FF)
        : done
        ? const Color(0xFFECFDF3)
        : pending
        ? const Color(0xFFFEF3C7)
        : const Color(0xFFFEF3F2);
    final badgeBorder = isDisputedByApplicant
        ? const Color(0xFFBFDBFE)
        : done
        ? const Color(0xFFD1FADF)
        : pending
        ? const Color(0xFFFDE68A)
        : const Color(0xFFFECDCA);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  m.ticketNumber,
                  style: _t(
                    size: 13,
                    w: FontWeight.w600,
                  ).copyWith(fontFamily: 'monospace', letterSpacing: 0.5),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: badgeBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 14, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      badgeLabel,
                      style: _t(
                        size: 11,
                        w: FontWeight.w600,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _C.surfaceLow.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _C.surfaceHigh),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info, size: 20, color: _C.info),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bagian Aset telah memverifikasi data aset pada sistem inventaris korporat. Harap lakukan verifikasi fisik sebelum melakukan konfirmasi final.',
                    style: _t(size: 12, color: const Color(0xFF42474D), h: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _assetUpdateCard(Mutation m) {
    final sn =
        (m.asset.serialNumber != null && m.asset.serialNumber!.isNotEmpty)
        ? m.asset.serialNumber!
        : '-';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.devices, size: 18, color: _C.textSecondary),
              const SizedBox(width: 6),
              Text(
                'HASIL UPDATE ASET',
                style: _t(
                  size: 12,
                  w: FontWeight.w600,
                  color: _C.textSecondary,
                  ls: 0.6,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _C.surfaceLow,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _C.border.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.badge, size: 13, color: _C.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Oleh: ${m.staffUpdatedBy ?? m.assetVerifiedBy ?? m.approvedBy ?? 'Bagian Aset'}',
                      style: _t(size: 11, color: _C.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _C.surfaceLow.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _C.border.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _C.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.laptop_mac,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.asset.assetCode,
                        style: _t(
                          size: 11,
                          color: _C.textSecondary,
                        ).copyWith(fontFamily: 'monospace'),
                      ),
                      Text(
                        m.asset.name,
                        style: _t(size: 15, w: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _C.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified,
                              size: 13,
                              color: _C.success,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Kondisi Baik & Normal',
                              style: _t(
                                size: 11,
                                w: FontWeight.w600,
                                color: _C.success,
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
          const SizedBox(height: 10),
          _kvRow(
            'Nomor Seri (SN)',
            sn,
            trailing: InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: sn));
                setState(() => _copiedSn = true);
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) setState(() => _copiedSn = false);
                });
              },
              child: Icon(
                _copiedSn ? Icons.check : Icons.content_copy,
                size: 15,
                color: _copiedSn ? _C.success : _C.textSecondary,
              ),
            ),
            mono: true,
          ),
          const SizedBox(height: 8),
          _kvRow(
            'Waktu Update Master',
            _formatDateTime(m.staffUpdatedAt ?? m.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _kvRow(
    String label,
    String value, {
    Widget? trailing,
    bool mono = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _C.surfaceLow.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _C.border.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(label, style: _t(size: 12, color: _C.textSecondary)),
          const Spacer(),
          Text(
            value,
            style: _t(
              size: 12,
              w: FontWeight.w600,
            ).copyWith(fontFamily: mono ? 'monospace' : null),
          ),
          if (trailing != null) ...[const SizedBox(width: 6), trailing],
        ],
      ),
    );
  }

  Widget _diffCard(Mutation m) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.swap_horiz, size: 18, color: _C.textSecondary),
              const SizedBox(width: 6),
              Text(
                'PERUBAHAN MUTASI',
                style: _t(
                  size: 12,
                  w: FontWeight.w600,
                  color: _C.textSecondary,
                  ls: 0.6,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _C.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '2 Data Berubah',
                  style: _t(size: 11, w: FontWeight.w600, color: _C.secondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _diffBlock(
            icon: Icons.corporate_fare,
            title: 'LOKASI PENEMPATAN',
            beforeLabel: 'Sebelum',
            beforeValue: m.currentLocation,
            afterLabel: 'Tujuan Baru',
            afterValue: m.targetLocation,
          ),
          const SizedBox(height: 12),
          _diffBlock(
            icon: Icons.person_outline,
            title: 'PENANGGUNG JAWAB (PIC)',
            beforeLabel: 'Lama',
            beforeValue: m.currentPic,
            afterLabel: 'PIC Baru',
            afterValue: m.targetPic,
          ),
        ],
      ),
    );
  }

  Widget _diffBlock({
    required IconData icon,
    required String title,
    required String beforeLabel,
    required String beforeValue,
    required String afterLabel,
    required String afterValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.surfaceLow.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _C.primary),
              const SizedBox(width: 6),
              Text(title, style: _t(size: 12, w: FontWeight.w600, ls: 0.4)),
            ],
          ),
          const SizedBox(height: 10),
          _diffRow(beforeLabel, beforeValue, isAfter: false),
          const SizedBox(height: 6),
          Center(
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: _C.secondary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_downward,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 6),
          _diffRow(afterLabel, afterValue, isAfter: true),
        ],
      ),
    );
  }

  Widget _diffRow(String label, String value, {required bool isAfter}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isAfter ? _C.secondary.withValues(alpha: 0.05) : _C.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAfter
              ? _C.secondary.withValues(alpha: 0.2)
              : _C.border.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isAfter
                  ? _C.secondary
                  : _C.textSecondary.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: _t(
              size: 11,
              w: isAfter ? FontWeight.w600 : FontWeight.w400,
              color: isAfter ? _C.secondary : _C.textSecondary,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: _t(
                size: 13,
                w: isAfter ? FontWeight.w600 : FontWeight.w500,
                color: isAfter ? _C.textPrimary : _C.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isAfter) ...[
            const SizedBox(width: 4),
            const Icon(Icons.check_circle, size: 16, color: _C.secondary),
          ],
        ],
      ),
    );
  }

  Widget _checklistCard(Mutation m) {
    final sn =
        (m.asset.serialNumber != null && m.asset.serialNumber!.isNotEmpty)
        ? m.asset.serialNumber!
        : '-';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist, size: 20, color: _C.primary),
              const SizedBox(width: 8),
              Text(
                'Verifikasi Fisik & Pernyataan',
                style: _t(size: 14, w: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Pastikan poin berikut divalidasi secara langsung di lapangan:',
            style: _t(size: 12, color: _C.textSecondary),
          ),
          const SizedBox(height: 12),
          _check(
            _checkSn,
            (v) => setState(() => _checkSn = v ?? false),
            'Nomor seri (SN) pada fisik aset sesuai dengan sistem ($sn)',
          ),
          const SizedBox(height: 8),
          _check(
            _checkLocation,
            (v) => setState(() => _checkLocation = v ?? false),
            'Unit fisik dan kelengkapan telah diterima di ${m.targetLocation}',
          ),
          const SizedBox(height: 8),
          _check(
            _checkPic,
            (v) => setState(() => _checkPic = v ?? false),
            'Serah terima fisik dan aksesoris telah divalidasi bersama PIC Baru (${m.targetPic})',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _C.surfaceLow.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _C.border.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user, size: 16, color: _C.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Setelah dikonfirmasi, Berita Acara Serah Terima (BAST) digital otomatis diterbitkan.',
                    style: _t(size: 11, color: _C.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _check(bool value, ValueChanged<bool?> onChanged, String text) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _C.surfaceLow.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _C.border.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: _C.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: _t(size: 12, h: 1.4))),
          ],
        ),
      ),
    );
  }

  Widget _actionButtons(
    Mutation m,
    PemohonConfirmationActionState actionState,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            key: const Key('btn_sesuai_konfirmasi'),
            onPressed: actionState.isLoading
                ? null
                : () => _onConfirmTap(context, ref, m),
            icon: const Icon(Icons.verified, size: 20),
            label: Text(
              'Konfirmasi & Terima Aset',
              style: _t(size: 14, w: FontWeight.w600, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            key: const Key('btn_tidak_sesuai_konfirmasi'),
            onPressed: actionState.isLoading
                ? null
                : () => _onTidakSesuaiTap(context),
            icon: const Icon(Icons.report_problem_outlined, size: 18),
            label: Text(
              'Lapor Ketidaksesuaian',
              style: _t(size: 12, w: FontWeight.w600, color: _C.warning),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _C.warning,
              side: BorderSide(color: _C.warning.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 14, color: _C.textSecondary),
            const SizedBox(width: 4),
            Text(
              'Audit Trail ISO 27001 Terenkripsi MutasiKu Enterprise',
              style: _t(
                size: 11,
                color: _C.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Actions (logic lama) ──────────────────────────────────────────────

  Future<void> _onConfirmTap(
    BuildContext context,
    WidgetRef ref,
    Mutation mutation,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Mutasi'),
        content: Text(
          'Anda akan mengonfirmasi bahwa data mutasi aset "${mutation.asset.name}" '
          'sudah sesuai dengan kondisi fisik.\n\n'
          'Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Konfirmasi'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success = await ref
        .read(pemohonConfirmationActionProvider.notifier)
        .confirm(mutationId: widget.mutationId);

    if (!context.mounted) return;

    if (success) {
      AppFeedback.showSuccess(
        context,
        'Konfirmasi berhasil. Mutasi aset telah selesai.',
      );
    } else {
      final state = ref.read(pemohonConfirmationActionProvider);
      AppFeedback.showError(
        context,
        state.error ?? 'Konfirmasi gagal. Coba lagi.',
      );
    }
  }

  void _onTidakSesuaiTap(BuildContext context) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF0C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.assignment_return_outlined,
                color: _C.warning,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Mutasi Tidak Sesuai',
                style: _t(size: 16, w: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Silakan berikan alasan atau catatan ketidaksesuaian aset/lokasi '
                'yang diterima. Laporan ini akan dikirim ke Bagian Aset agar '
                'data mutasi dapat ditindaklanjuti — bukan data pengajuan Anda.',
                style: _t(size: 12, color: _C.textSecondary, h: 1.4),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Alasan / Keterangan *',
                  hintText: 'Jelaskan ketidaksesuaian...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Alasan ketidaksesuaian wajib diisi';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              final reason = reasonController.text.trim();
              Navigator.of(ctx).pop();

              final success = await ref
                  .read(pemohonConfirmationActionProvider.notifier)
                  .returnForRevision(
                    mutationId: widget.mutationId,
                    reason: reason,
                  );

              if (!context.mounted) return;

              if (success) {
                AppFeedback.showSuccess(
                  context,
                  'Laporan ketidaksesuaian terkirim. Bagian Aset akan '
                  'memverifikasi dan memperbaiki data mutasi Anda.',
                );

                final currentMutation = ref
                    .read(mutationDetailProvider(widget.mutationId))
                    .valueOrNull;
                ref
                    .read(notificationProvider.notifier)
                    .notifyRole(
                      targetRole: UserRole.bagianAset,
                      title: 'Ketidaksesuaian Ditemukan',
                      message:
                          'Pemohon melaporkan ketidaksesuaian untuk pengajuan ${currentMutation?.ticketNumber ?? widget.mutationId}: $reason',
                      type: NotificationType.action,
                      relatedMutationId: widget.mutationId,
                    );
                ref.invalidate(mutationDetailProvider(widget.mutationId));
                // PENTING: pemohon TIDAK diarahkan ke halaman Edit Pengajuan.
                // Yang perlu diperbaiki adalah hasil update data aset oleh
                // Bagian Aset (SN/kondisi/lokasi fisik), bukan data pengajuan
                // (lokasi tujuan/PIC/alasan mutasi) milik pemohon. Form Edit
                // Pengajuan bukan tujuan yang tepat untuk kasus ini, jadi
                // cukup tetap di halaman ini — statusnya sudah ter-refresh
                // via invalidate() di atas.
              } else {
                final state = ref.read(pemohonConfirmationActionProvider);
                AppFeedback.showError(
                  context,
                  state.error ?? 'Gagal melaporkan ketidaksesuaian.',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('Kirim Laporan'),
          ),
        ],
      ),
    );
  }
}
