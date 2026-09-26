// lib/features/operator/presentation/screens/operator_verification_detail_screen.dart
//
// Screen: Detail Verifikasi Pengajuan Mutasi (OPR-003).
// Sumber: SCREEN-SPEC.md OPR-003, ROLE-FLOW.md §4, WIREFRAME.md §2.
// UI: Stitch design baseline — Status banner with SLA, Pemegang Aset card,
//     Detail Aset Fisik & Master SIMAK BMN, Visual Route, Kelengkapan Dokumen,
//     Operational Timeline, and Sticky Action Bar with verification modal.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/config/business_config.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/document_preview_dialog.dart';
import '../../../asset/domain/entities/asset.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';
import '../../../notification/domain/entities/notification_item.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../providers/operator_verification_provider.dart';

// ── Stitch Design Tokens ─────────────────────────────────────────────────────
class _C {
  static const primaryContainer = Color(0xFF0F3D56);
  static const secondary = Color(0xFF006A63);
  static const secondaryFixed = Color(0xFF9CF2E8);
  static const onSecondaryFixed = Color(0xFF00201D);
  static const background = Color(0xFFF6F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF1F5F9);
  static const surfaceContainerHigh = Color(0xFFDBEAF9);
  static const surfaceContainerHighest = Color(0xFFCBD5E1);
  static const textPrimary = Color(0xFF172B4D);
  static const textSecondary = Color(0xFF52606D);
  static const border = Color(0xFFD0D5DD);
  static const warning = Color(0xFFB45309);
  static const warningLight = Color(0xFFFEF3C7);
  static const success = Color(0xFF15803D);
  static const successLight = Color(0xFFDCFCE7);
  static const error = Color(0xFFB42318);
  static const errorLight = Color(0xFFFEE2E2);
  static const info = Color(0xFF175CD3);
  static const infoLight = Color(0xFFEFF6FF);
}

class OperatorVerificationDetailScreen extends ConsumerWidget {
  final String mutationId;

  const OperatorVerificationDetailScreen({
    super.key,
    required this.mutationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMutation = ref.watch(mutationDetailProvider(mutationId));
    final actionState = ref.watch(verificationActionProvider);
    final currentUser = ref.watch(authStateProvider).user;

    return Scaffold(
      backgroundColor: _C.background,
      body: Column(
        children: [
          // ── Header / Top Bar (Stitch Baseline) ─────────────────────
          Container(
            color: _C.surface,
            child: SafeArea(
              bottom: false,
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: _C.surface,
                  border: Border(
                    bottom: BorderSide(color: _C.border, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    // Back button
                    InkWell(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(RouteNames.operatorMutationsPath);
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _C.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _C.border),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          size: 20,
                          color: _C.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title & ticket number breadcrumb
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detail Pengajuan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _C.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const Text(
                            'Tinjauan Pengajuan Mutasi',
                            style: TextStyle(
                              fontSize: 11,
                              color: _C.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Action buttons: info button & user avatar initials
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _C.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: _C.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: _C.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(currentUser?.name ?? 'OP'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body Content ──────────────────────────────────────────
          Expanded(
            child: asyncMutation.when(
              data: (mutation) =>
                  _buildBody(context, ref, mutation, actionState),
              loading: () => const Center(
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: _C.secondary),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: _C.errorLight,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          size: 32,
                          color: _C.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Gagal Memuat Data',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _C.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$err',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _C.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () =>
                            ref.invalidate(mutationDetailProvider(mutationId)),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Coba Lagi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.secondary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    Mutation mutation,
    VerificationActionState actionState,
  ) {
    final isSubmitted = mutation.status == MutationStatus.submitted;

    final rawAssetId = mutation.assetId ??
        (mutation.asset.id.isNotEmpty
            ? mutation.asset.id
            : mutation.asset.assetCode);
    final shouldLoadMaster =
        !mutation.isUnregisteredAsset && rawAssetId.trim().isNotEmpty;
    final masterAssetAsync = shouldLoadMaster
        ? ref.watch(operatorMasterAssetProvider(rawAssetId))
        : null;
    final masterAsset = masterAssetAsync?.valueOrNull;

    final isCrossLocation = mutation.currentLocation.isNotEmpty &&
        mutation.targetLocation.isNotEmpty &&
        mutation.currentLocation.trim().toLowerCase() !=
            mutation.targetLocation.trim().toLowerCase();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. STATUS & TICKET BANNER (Stitch Baseline) ─────
                _buildStatusBanner(mutation, isCrossLocation),
                const SizedBox(height: 16),

                // Note jika berstatus returned
                if (mutation.status == MutationStatus.returned &&
                    mutation.returnReason != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _C.warningLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _C.warning.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: _C.warning, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Alasan Pengembalian (Operator)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _C.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          mutation.returnReason!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _C.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Warning Jika Aset Tidak Terdaftar ───────────────
                if (mutation.isUnregisteredAsset) ...[
                  Container(
                    key: const Key('banner_unregistered_asset'),
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFFB45309),
                              size: 20,
                            ),
                            SizedBox(width: AppSpacing.xs),
                            Text(
                              'Aset Tidak Terdaftar',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Aset ini diajukan secara manual / belum tercatat di SIMAK BMN (Mode Fallback). Operator wajib memverifikasi dokumen fisik dan legalitas aset.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF78350F),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── 2. DATA PEMOHON & PEMEGANG SAAT INI (Stitch) ────
                _buildApplicantSection(mutation),
                const SizedBox(height: 16),

                // ── 3. INFORMASI ASET FISIK (Stitch) ────────────────
                if (!mutation.isUnregisteredAsset) ...[
                  _buildPhysicalAssetSection(mutation),
                  const SizedBox(height: 16),
                ],

                // ── Data Aset Master (Database SIMAK BMN) ───────────
                if (!mutation.isUnregisteredAsset && masterAssetAsync != null)
                  masterAssetAsync.when(
                    data: (master) {
                      if (master == null) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            border: Border.all(color: const Color(0xFFF59E0B)),
                          ),
                          child: Text(
                            'Data aset master tidak ditemukan di SIMAK BMN (ID: $rawAssetId).',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildMasterAssetCard(master),
                      );
                    },
                    loading: () => Container(
                      key: const Key('card_master_asset_loading'),
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Text(
                            'Memuat data aset master dari SIMAK BMN...',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    error: (err, _) => Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.warningContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.warning),
                      ),
                      child: Text(
                        'Gagal sinkronisasi data master: $err',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),

                // ── Snapshot Saat Pengajuan / Data Manual ────────────
                if (mutation.isUnregisteredAsset)
                  _buildSectionCard([
                    _buildSectionHeader(
                      title: 'Data Aset Manual (Pengajuan)',
                      badge: 'Aset Non-Master',
                      icon: Icons.edit_note_rounded,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Divider(height: 1, color: _C.border),
                    const SizedBox(height: AppSpacing.sm),
                    _buildDetailRow('Pemohon', mutation.applicantName),
                    const Divider(height: AppSpacing.md, color: _C.border),
                    _buildDetailRow(
                      'Aset (Manual)',
                      mutation.customAssetName ?? mutation.asset.name,
                      subtext:
                          'Nomor Seri / Kode Manual: ${mutation.customSerialNumber ?? mutation.asset.assetCode}',
                    ),
                    const Divider(height: AppSpacing.md, color: _C.border),
                    _buildDetailRow('Lokasi Asal', mutation.currentLocation),
                    const Divider(height: AppSpacing.md, color: _C.border),
                    _buildDetailRow('Lokasi Tujuan', mutation.targetLocation),
                    const Divider(height: AppSpacing.md, color: _C.border),
                    _buildDetailRow(
                        'Pemakai Lama (PIC Asal)', mutation.currentPic),
                    const Divider(height: AppSpacing.md, color: _C.border),
                    _buildDetailRow('PIC Baru (Tujuan)', mutation.targetPic),
                    const Divider(height: AppSpacing.md, color: _C.border),
                    _buildDetailRow('Alasan Mutasi', mutation.reason),
                    const Divider(height: AppSpacing.md, color: _C.border),
                    _buildDocumentRow(mutation, context, ref),
                    const Divider(height: AppSpacing.md, color: _C.border),
                    _buildDetailRow(
                        'Waktu Pengajuan', _formatDateTime(mutation.createdAt)),
                  ])
                else
                  _buildSectionCard([
                    _buildSectionHeader(
                      title: 'Snapshot Saat Pengajuan',
                      badge: 'Data Pemohon',
                      icon: Icons.history_rounded,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Divider(height: 1, color: _C.border),
                    const SizedBox(height: AppSpacing.sm),
                    _buildDetailRow('Pemohon', mutation.applicantName),
                    const Divider(height: AppSpacing.md, color: _C.border),
                    _buildDetailRow(
                      'Aset',
                      mutation.asset.name,
                      subtext:
                          'Kode: ${mutation.asset.id} • ${mutation.asset.category.name}',
                    ),
                    const Divider(height: AppSpacing.md, color: _C.border),
                    _buildDetailRow(
                      'Lokasi Asal',
                      mutation.currentLocation,
                      extraBottom: masterAsset != null
                          ? (masterAsset.location.trim().toLowerCase() !=
                                  mutation.currentLocation.trim().toLowerCase()
                              ? _buildDiffIndicator(
                                  label: 'Lokasi',
                                  masterValue: masterAsset.location,
                                  key: const Key('indicator_diff_location'),
                                )
                              : _buildMatchIndicator(
                                  'Sesuai dengan Lokasi Master',
                                  key: const Key('indicator_match_location'),
                                ))
                          : null,
                    ),
                    const Divider(height: AppSpacing.md, color: _C.border),
                    _buildDetailRow('Lokasi Tujuan', mutation.targetLocation),
                    const Divider(height: AppSpacing.md, color: _C.border),
                    _buildDetailRow(
                      'Pemakai Lama (PIC Asal)',
                      mutation.currentPic,
                      extraBottom: masterAsset != null
                          ? (masterAsset.pic.trim().toLowerCase() !=
                                  mutation.currentPic.trim().toLowerCase()
                              ? _buildDiffIndicator(
                                  label: 'PIC',
                                  masterValue: masterAsset.pic,
                                  key: const Key('indicator_diff_pic'),
                                )
                              : _buildMatchIndicator(
                                  'Sesuai dengan PIC Master',
                                  key: const Key('indicator_match_pic'),
                                ))
                          : null,
                    ),
                    const Divider(height: AppSpacing.md, color: _C.border),
                    _buildDetailRow('PIC Baru (Tujuan)', mutation.targetPic),
                    const Divider(height: AppSpacing.md, color: _C.border),
                    _buildDetailRow('Alasan Mutasi', mutation.reason),
                    const Divider(height: AppSpacing.md, color: _C.border),
                    _buildDocumentRow(mutation, context, ref),
                    const Divider(height: AppSpacing.md, color: _C.border),
                    _buildDetailRow(
                        'Waktu Pengajuan', _formatDateTime(mutation.createdAt)),
                  ]),
                const SizedBox(height: 16),

                // ── 4. RUTE & PENUGASAN MUTASI (Stitch) ─────────────
                _buildRouteSection(mutation),
                const SizedBox(height: 16),

                // ── 5. KELENGKAPAN DOKUMEN (Stitch) ─────────────────
                _buildDocumentSection(mutation, context, ref),
                const SizedBox(height: 16),

                // ── 6. PROGRES ALUR PENGAJUAN (Stitch Timeline) ─────
                _buildTimelineSection(mutation),
              ],
            ),
          ),
        ),

        // ── 7. STICKY BOTTOM ACTIONS (Stitch Baseline) ──────────────
        if (isSubmitted)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: _C.surface,
              border: const Border(top: BorderSide(color: _C.border)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Button: [ Kembalikan ]
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('btn_kembalikan_pengajuan'),
                      onPressed: actionState.isLoading
                          ? null
                          : () {
                              context.push(
                                  '/operator/mutations/${mutation.id}/return');
                            },
                      icon: const Icon(Icons.undo_rounded, size: 18),
                      label: const Text(
                        'Kembalikan',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _C.error,
                        backgroundColor: _C.surfaceContainerLow,
                        side: BorderSide(
                          color: _C.error.withValues(alpha: 0.3),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Button: [ Verifikasi Valid / Teruskan ]
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      key: const Key('btn_verifikasi_valid'),
                      onPressed: actionState.isLoading
                          ? null
                          : () => _showVerifyConfirmDialog(
                              context, ref, mutation),
                      icon: actionState.isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_rounded, size: 19),
                      label: const Text(
                        'Verifikasi Valid',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.primaryContainer,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ── 1. STATUS & TICKET BANNER WIDGET ───────────────────────────────────────
  Widget _buildStatusBanner(Mutation mutation, bool isCrossLocation) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Status Pill & SLA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: mutation.status == MutationStatus.submitted
                      ? _C.warningLight
                      : mutation.status.backgroundColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: mutation.status == MutationStatus.submitted
                            ? _C.warning
                            : mutation.status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      mutation.status == MutationStatus.submitted
                          ? 'Menunggu Verifikasi Operator'
                          : mutation.status.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: mutation.status == MutationStatus.submitted
                            ? _C.warning
                            : mutation.status.color,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 13, color: _C.primaryContainer),
                    SizedBox(width: 4),
                    Text(
                      'SLA: 2 Jam Tersisa',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _C.primaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Row 2: Ticket Number & Badge Jenis Mutasi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NOMOR PENGAJUAN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _C.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mutation.ticketNumber,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                      color: _C.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.secondaryFixed.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isCrossLocation ? 'Mutasi Cabang' : 'Mutasi Internal',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _C.onSecondaryFixed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Row 3: Submission Info Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _C.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: _C.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.history_edu_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Waktu Pengajuan',
                        style: TextStyle(
                          fontSize: 11,
                          color: _C.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 12,
                            color: _C.textPrimary,
                          ),
                          children: [
                            TextSpan(
                                text: _formatDateTime(mutation.createdAt)),
                            const TextSpan(text: ' • Oleh '),
                            TextSpan(
                              text: mutation.applicantName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _C.secondary,
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
        ],
      ),
    );
  }

  // ── 2. DATA PEMOHON SECTION ────────────────────────────────────────────────
  Widget _buildApplicantSection(Mutation mutation) {
    return _buildSectionCard([
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.badge_outlined, size: 18, color: _C.secondary),
              SizedBox(width: 8),
              Text(
                'Pemegang Aset Saat Ini',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _C.successLight,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Terverifikasi Pemilik',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _C.success,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),

      // Profile Info
      Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: _C.secondary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getInitials(mutation.applicantName),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mutation.applicantName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _C.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pemohon Mutasi • ID: ${mutation.applicantId}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _C.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),

      // 2-Col Grid: Unit Kerja & Kontak PIC
      Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _C.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Unit Kerja',
                    style: TextStyle(
                      fontSize: 10,
                      color: _C.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mutation.currentLocation.isNotEmpty
                        ? 'Unit • ${mutation.currentLocation}'
                        : '-',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _C.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _C.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kontak Kantor',
                    style: TextStyle(
                      fontSize: 10,
                      color: _C.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mutation.currentPic.isNotEmpty ? mutation.currentPic : '-',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _C.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ]);
  }

  // ── 3. INFORMASI ASET FISIK ────────────────────────────────────────────────
  Widget _buildPhysicalAssetSection(Mutation mutation) {
    final assetName = mutation.isUnregisteredAsset
        ? (mutation.customAssetName ?? mutation.asset.name)
        : mutation.asset.name;
    final assetCode = mutation.isUnregisteredAsset
        ? (mutation.customSerialNumber ?? mutation.asset.assetCode)
        : (mutation.asset.serialNumber != null &&
                mutation.asset.serialNumber!.isNotEmpty
            ? mutation.asset.serialNumber!
            : mutation.asset.assetCode);

    return _buildSectionCard([
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.devices_outlined, size: 18, color: _C.primaryContainer),
              SizedBox(width: 8),
              Text(
                'Detail Aset Fisik',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _C.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline_rounded,
                    size: 12, color: _C.primaryContainer),
                SizedBox(width: 4),
                Text(
                  'Dalam Mutasi',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _C.primaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),

      // Asset Row with Visual Box
      Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _C.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _C.border),
            ),
            child: const Center(
              child: Icon(
                Icons.laptop_chromebook_rounded,
                size: 32,
                color: _C.primaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nama Perangkat',
                  style: TextStyle(
                    fontSize: 10,
                    color: _C.textSecondary,
                  ),
                ),
                Text(
                  assetName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _C.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'SN / Kode: $assetCode',
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: _C.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),

      // 2-Col Grid: Kategori Aset & Kondisi Fisik
      Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _C.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kategori Aset',
                    style: TextStyle(
                      fontSize: 10,
                      color: _C.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${mutation.asset.category.name} (${mutation.asset.category.code})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _C.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _C.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kondisi Fisik',
                    style: TextStyle(
                      fontSize: 10,
                      color: _C.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: _C.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        mutation.asset.condition.isNotEmpty
                            ? mutation.asset.condition
                            : 'Grade A (Normal)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _C.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ]);
  }

  // ── 4. RUTE & PENUGASAN MUTASI ─────────────────────────────────────────────
  Widget _buildRouteSection(Mutation mutation) {
    return _buildSectionCard([
      const Row(
        children: [
          Icon(Icons.alt_route_rounded, size: 18, color: _C.secondary),
          SizedBox(width: 8),
          Text(
            'Rute & Penugasan Mutasi',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _C.textPrimary,
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),

      // Visual Route Container
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Origin
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: _C.secondaryFixed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: _C.onSecondaryFixed,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Asal Lokasi (Origin)',
                        style: TextStyle(
                          fontSize: 10,
                          color: _C.textSecondary,
                        ),
                      ),
                      Text(
                        '${mutation.currentLocation} (Asal)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _C.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Route connector line
            Padding(
              padding: const EdgeInsets.only(left: 13, top: 4, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 2,
                  height: 20,
                  color: _C.surfaceContainerHighest,
                ),
              ),
            ),

            // Destination
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: _C.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flag_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tujuan Mutasi (Destination)',
                        style: TextStyle(
                          fontSize: 10,
                          color: _C.textSecondary,
                        ),
                      ),
                      Text(
                        '${mutation.targetLocation} (Tujuan)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _C.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),

      // PIC Penerima Card
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _C.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: _C.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getInitials(mutation.targetPic),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _C.primaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PIC Penerima Aset',
                    style: TextStyle(
                      fontSize: 10,
                      color: _C.textSecondary,
                    ),
                  ),
                  Text(
                    mutation.targetPic,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _C.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _C.border),
              ),
              child: const Text(
                'Penerima Aset',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _C.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),

      // Justifikasi / Alasan Mutasi Note
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _C.surfaceContainerHigh.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dasar / Justifikasi Mutasi:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _C.primaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '“${mutation.reason}”',
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: _C.textPrimary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  // ── 5. KELENGKAPAN DOKUMEN ─────────────────────────────────────────────────
  Widget _buildDocumentSection(
      Mutation mutation, BuildContext context, WidgetRef ref) {
    final docName = mutation.documentName;
    final hasDoc = docName != null && docName.trim().isNotEmpty;
    final isPdf = docName != null && docName.toLowerCase().endsWith('.pdf');

    return _buildSectionCard([
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.attachment_rounded, size: 18, color: _C.info),
              SizedBox(width: 8),
              Text(
                'Kelengkapan Dokumen',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary,
                ),
              ),
            ],
          ),
          Text(
            hasDoc ? '1 Lampiran Valid' : '0 Lampiran',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _C.textSecondary,
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      if (hasDoc)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _C.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isPdf ? _C.errorLight : _C.infoLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPdf
                      ? Icons.picture_as_pdf_rounded
                      : Icons.image_outlined,
                  size: 20,
                  color: isPdf ? _C.error : _C.info,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      docName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _C.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Dokumen Pendukung • Ditandatangani Pemohon',
                      style: TextStyle(
                        fontSize: 10,
                        color: _C.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  DocumentPreviewDialog.show(
                    context,
                    mutation: mutation,
                    currentUser: ref.read(authStateProvider).user,
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _C.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _C.border),
                  ),
                  child: const Icon(
                    Icons.visibility_outlined,
                    size: 18,
                    color: _C.primaryContainer,
                  ),
                ),
              ),
            ],
          ),
        )
      else
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Tidak ada dokumen dilampirkan',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: _C.textSecondary,
            ),
          ),
        ),
    ]);
  }

  // ── 6. PROGRES ALUR PENGAJUAN (TIMELINE) ──────────────────────────────────
  Widget _buildTimelineSection(Mutation mutation) {
    return _buildSectionCard([
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.linear_scale_rounded,
                  size: 18, color: _C.primaryContainer),
              SizedBox(width: 8),
              Text(
                'Progres Alur Pengajuan',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _C.warningLight,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Langkah 2 dari 5',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _C.warning,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),

      // Timeline Steps
      // Step 1: Diajukan oleh Pemohon (Done)
      _buildTimelineStep(
        isFirst: true,
        isCompleted: true,
        title: 'Diajukan oleh Pemohon',
        subtitle:
            '${_formatDateTime(mutation.createdAt)} • ${mutation.applicantName}',
        badgeText: 'Selesai',
        badgeColor: _C.success,
      ),

      // Step 2: Verifikasi Operator (Active)
      _buildTimelineStep(
        isCompleted: false,
        isActive: true,
        title: 'Verifikasi Operator Aset',
        subtitle: 'Pengecekan fisik aset & validasi kelengkapan berkas',
        badgeText: 'Sedang Proses',
        badgeColor: _C.warning,
      ),

      // Step 3: Approval Kabag Aset
      _buildTimelineStep(
        isCompleted: false,
        isActive: false,
        title: 'Approval Kabag Aset',
        subtitle: 'Menunggu verifikasi operator',
      ),

      // Step 4: Otorisasi Kadiv / Update Data Aset
      _buildTimelineStep(
        isCompleted: false,
        isActive: false,
        title: 'Update Data Aset di SIMAK BMN',
        subtitle: 'Otomatisasi pemindahan record inventaris',
      ),

      // Step 5: Konfirmasi Penerimaan oleh PIC
      _buildTimelineStep(
        isLast: true,
        isCompleted: false,
        isActive: false,
        title: 'Konfirmasi Penerimaan oleh PIC',
        subtitle: 'Serah terima fisik di lokasi tujuan',
      ),
    ]);
  }

  Widget _buildTimelineStep({
    bool isFirst = false,
    bool isLast = false,
    required bool isCompleted,
    bool isActive = false,
    required String title,
    required String subtitle,
    String? badgeText,
    Color? badgeColor,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Node & Line
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? _C.secondary
                      : isActive
                          ? _C.surface
                          : _C.surfaceContainerLow,
                  border: Border.all(
                    color: isCompleted
                        ? _C.secondary
                        : isActive
                            ? _C.primaryContainer
                            : _C.surfaceContainerHighest,
                    width: isActive ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : isActive
                          ? Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: _C.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                            )
                          : Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: _C.surfaceContainerHighest,
                                shape: BoxShape.circle,
                              ),
                            ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted
                        ? _C.secondary
                        : _C.surfaceContainerHighest,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isCompleted || isActive
                                ? _C.textPrimary
                                : _C.textSecondary,
                          ),
                        ),
                      ),
                      if (badgeText != null && badgeColor != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _C.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HELPER WIDGETS & SECTIONS ──────────────────────────────────────────────
  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String badge,
    required IconData icon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: _C.secondary),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _C.textPrimary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _C.surfaceContainerLow,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _C.border),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _C.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMasterAssetCard(Asset master) {
    return Container(
      key: const Key('card_master_asset_data'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF93C5FD)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_rounded, size: 16, color: _C.info),
                  SizedBox(width: 6),
                  Text(
                    'Data Aset Master',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _C.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Text(
                  'Database SIMAK BMN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1, color: _C.border),
          const SizedBox(height: AppSpacing.sm),
          _buildDetailRow(
            'Nama Aset (Master)',
            master.name,
            key: const Key('master_asset_name'),
          ),
          const Divider(height: AppSpacing.md, color: _C.border),
          _buildDetailRow(
            'Kode / Nomor Inventaris',
            master.assetCode,
            key: const Key('master_asset_code'),
          ),
          const Divider(height: AppSpacing.md, color: _C.border),
          _buildDetailRow(
            'Nomor Seri (Serial Number)',
            (master.serialNumber != null && master.serialNumber!.isNotEmpty)
                ? master.serialNumber!
                : '-',
            key: const Key('master_asset_sn'),
          ),
          const Divider(height: AppSpacing.md, color: _C.border),
          _buildDetailRow(
            'Kategori Aset',
            master.category.name,
            key: const Key('master_asset_category'),
          ),
          const Divider(height: AppSpacing.md, color: _C.border),
          _buildDetailRow(
            'Lokasi Master',
            '${master.location} (SIMAK BMN)',
            key: const Key('master_asset_location'),
          ),
          const Divider(height: AppSpacing.md, color: _C.border),
          _buildDetailRow(
            'PIC / Pemakai Master',
            master.pic,
            key: const Key('master_asset_pic'),
          ),
        ],
      ),
    );
  }

  Widget _buildDiffIndicator({
    required String label,
    required String masterValue,
    Key? key,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 14,
            color: Color(0xFFB45309),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '⚠️ Berbeda dengan Master (Master: $masterValue)',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchIndicator(String text, {Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 13,
            color: AppColors.success,
          ),
          const SizedBox(width: 4),
          Text(
            '✓ $text',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    String? subtext,
    Key? key,
    Widget? extraBottom,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: _C.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _C.textPrimary,
          ),
        ),
        if (subtext != null) ...[
          const SizedBox(height: 2),
          Text(
            subtext,
            style: const TextStyle(
              fontSize: 11,
              color: _C.textSecondary,
            ),
          ),
        ],
        ?extraBottom,
      ],
    );
  }

  Widget _buildDocumentRow(
      Mutation mutation, BuildContext context, WidgetRef ref) {
    final documentName = mutation.documentName;
    final isPdf =
        documentName != null && documentName.toLowerCase().endsWith('.pdf');
    final isImage = documentName != null &&
        ['png', 'jpg', 'jpeg', 'webp']
            .any((ext) => documentName.toLowerCase().endsWith(ext));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dokumen',
          style: TextStyle(
            fontSize: 11,
            color: _C.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        if (documentName != null && documentName.isNotEmpty)
          InkWell(
            onTap: () {
              DocumentPreviewDialog.show(
                context,
                mutation: mutation,
                currentUser: ref.read(authStateProvider).user,
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _C.infoLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _C.info.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    isPdf
                        ? Icons.picture_as_pdf_outlined
                        : isImage
                            ? Icons.image_outlined
                            : Icons.description_outlined,
                    size: 18,
                    color: isPdf
                        ? _C.error
                        : isImage
                            ? _C.info
                            : _C.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      documentName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _C.info,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.open_in_new_rounded,
                      size: 14, color: _C.info),
                ],
              ),
            ),
          )
        else
          const Text(
            'Tidak ada dokumen dilampirkan',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: _C.textSecondary,
            ),
          ),
      ],
    );
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
      'Des'
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year $hour:$minute';
  }

  static String _getInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return '??';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  void _showVerifyConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    Mutation mutation,
  ) {
    final threshold = ref.read(kadivApprovalThresholdProvider);
    final assetValue = mutation.asset.estimatedValue ?? 0.0;
    final meetsValueThreshold = assetValue >= threshold;
    final isCrossLocation = mutation.currentLocation.isNotEmpty &&
        mutation.targetLocation.isNotEmpty &&
        mutation.currentLocation.trim().toLowerCase() !=
            mutation.targetLocation.trim().toLowerCase();

    bool requiresKadiv = meetsValueThreshold || isCrossLocation;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Konfirmasi Verifikasi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _C.textPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apakah Anda yakin data dan dokumen pengajuan ${mutation.ticketNumber} sudah valid dan lengkap?\n\nPengajuan akan diteruskan ke antrean Kabag Aset.',
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: meetsValueThreshold
                        ? AppColors.warningContainer.withValues(alpha: 0.3)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                      color: meetsValueThreshold
                          ? AppColors.warning.withValues(alpha: 0.5)
                          : AppColors.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            meetsValueThreshold
                                ? Icons.verified_user
                                : Icons.info_outline,
                            size: 16,
                            color: meetsValueThreshold
                                ? AppColors.warning
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Kriteria Approval Kadiv',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        assetValue > 0
                            ? 'Estimasi Nilai Aset: Rp ${assetValue.toStringAsFixed(0)} (Threshold: Rp ${threshold.toStringAsFixed(0)})'
                            : 'Threshold Kadiv: Rp ${threshold.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      if (meetsValueThreshold)
                        const Text(
                          '• Nilai aset memenuhi threshold approval Kadiv.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: CheckboxListTile(
                      key: const Key('checkbox_requires_kadiv'),
                      value: requiresKadiv,
                      onChanged: (val) {
                        setDialogState(() {
                          requiresKadiv = val ?? false;
                        });
                      },
                      title: const Text(
                        'Memerlukan Approval Kadiv',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'Otomatis terisi sesuai konfigurasi threshold atau mutasi antar-lokasi.',
                        style: TextStyle(fontSize: 11),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(foregroundColor: _C.textSecondary),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              key: const Key('btn_confirm_verifikasi'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final success = await ref
                    .read(verificationActionProvider.notifier)
                    .verify(
                      mutationId: mutation.id,
                      requiresKadivApproval: requiresKadiv,
                    );

                if (context.mounted) {
                  if (success) {
                    ref.read(notificationProvider.notifier).notifyRole(
                          targetRole: UserRole.kabagAset,
                          title: 'Menunggu Approval Kabag',
                          message:
                              'Pengajuan mutasi ${mutation.ticketNumber} (${mutation.asset.name}) telah diverifikasi Operator dan siap ditinjau.',
                          type: NotificationType.action,
                          relatedMutationId: mutation.id,
                        );
                    ref.invalidate(mutationDetailProvider(mutation.id));
                    AppFeedback.showSuccess(
                      context,
                      'Pengajuan berhasil diverifikasi.',
                      details: requiresKadiv
                          ? 'Jalur: Kabag Aset → Kadiv'
                          : 'Jalur: Kabag Aset → Staff Aset',
                    );
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      try {
                        context.pop();
                      } catch (_) {}
                    }
                  } else {
                    final err = ref.read(verificationActionProvider).error;
                    AppFeedback.showError(
                      context,
                      err ?? 'Gagal memverifikasi pengajuan.',
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.primaryContainer,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Ya, Verifikasi Valid',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
