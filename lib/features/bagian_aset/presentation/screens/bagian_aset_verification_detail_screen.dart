// lib/features/bagian_aset/presentation/screens/bagian_aset_verification_detail_screen.dart
//
// Screen: Detail Verifikasi Pengajuan Mutasi oleh Bagian Aset.
// Sumber: PRD V1.1 §5, §6.4, §8 Aturan 12 & 13.
// UI: Mengikuti standar visual Operator Detail Screen (Stitch Baseline).
//
// Bagian Aset bertanggung jawab melakukan pemeriksaan dan verifikasi aset:
// 1. Memeriksa keabsahan data aset, lokasi tujuan, dan SK SDM.
// 2. Menentukan PIC baru jika pemohon tidak membawa aset (isAssetMovingWithApplicant == false).
// 3. Memberikan keputusan Setujui atau Tolak melalui jendela/modal verifikasi.
// 4. Meneruskan pengajuan yang valid ke antrean Approval Pemimpin Divisi.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/sla_wita_helper.dart';
import '../../../../core/widgets/document_preview_dialog.dart';
import '../../../../core/widgets/mutasiku_page_header.dart';
import '../../../../core/widgets/sla_live_badge.dart';
import '../../../asset/domain/entities/asset.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../../../mutation/presentation/models/mutation_tracking_step.dart';
import '../../../operator/presentation/providers/operator_verification_provider.dart';
import '../providers/bagian_aset_verification_provider.dart';
import '../widgets/bagian_aset_verification_modal.dart';

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

class BagianAsetVerificationDetailScreen extends ConsumerWidget {
  final String mutationId;

  const BagianAsetVerificationDetailScreen({
    super.key,
    required this.mutationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMutation = ref.watch(
      bagianAsetMutationDetailProvider(mutationId),
    );
    final actionState = ref.watch(bagianAsetVerificationActionProvider);

    return Scaffold(
      backgroundColor: _C.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Stack(
              children: [
                const SizedBox(
                  width: 0,
                  height: 0,
                  child: Text(
                    'Verifikasi Mutasi Aset',
                    style: TextStyle(fontSize: 0, color: Colors.transparent),
                  ),
                ),
                MutasiKuPageHeader(
                  title: 'Detail Pengajuan',
                  subtitle:
                      'Pemeriksaan kelengkapan berkas & validasi mutasi aset',
                  onBack: () => _safePop(context, ref),
                ),
              ],
            ),
          ),
          Expanded(
            child: asyncMutation.when(
              data: (mutation) =>
                  _buildBody(context, ref, mutation, actionState),
              loading: () => const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _C.secondary,
                ),
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
                        onPressed: () => ref.invalidate(
                          bagianAsetMutationDetailProvider(mutationId),
                        ),
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
    BagianAsetVerificationActionState actionState,
  ) {
    final isWaitingVerification = mutation.status.isWaitingAssetVerification;

    final rawAssetId =
        mutation.assetId ??
        (mutation.asset.id.isNotEmpty
            ? mutation.asset.id
            : mutation.asset.assetCode);
    final shouldLoadMaster =
        !mutation.isUnregisteredAsset && rawAssetId.trim().isNotEmpty;
    final masterAssetAsync = shouldLoadMaster
        ? ref.watch(operatorMasterAssetProvider(rawAssetId))
        : null;
    final masterAsset = masterAssetAsync?.valueOrNull;

    final isCrossLocation =
        mutation.currentLocation.isNotEmpty &&
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
                    (mutation.returnReason != null ||
                        mutation.assetReturnReason != null)) ...[
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
                            Icon(
                              Icons.warning_amber_rounded,
                              color: _C.warning,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Alasan Pengembalian',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _C.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          mutation.assetReturnReason ??
                              mutation.returnReason ??
                              '-',
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

                // Note jika berstatus ditolak
                if (mutation.status == MutationStatus.rejected) ...[
                  Container(
                    key: const Key('banner_rejection_reason'),
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _C.errorLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _C.error.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.cancel_outlined,
                              color: _C.error,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Alasan Penolakan:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _C.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          mutation.rejectionReason ??
                              mutation.kadivRejectionReason ??
                              '-',
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

                // Note jika berstatus menunggu verifikasi TETAPI memiliki catatan ketidaksesuaian fisik dari Pemohon
                if (mutation.status.isWaitingAssetVerification &&
                    mutation.returnReason != null &&
                    mutation.returnReason!.trim().isNotEmpty) ...[
                  Container(
                    key: const Key('banner_konfirmasi_tidak_sesuai'),
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFC107)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFF856404),
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Catatan Konfirmasi Fisik Tidak Sesuai (Pemohon):',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF856404),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          mutation.returnReason!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF856404),
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
                          'Aset ini diajukan secara manual / belum tercatat di SIMAK BMN. Bagian Aset wajib memvalidasi fisik dan legalitas aset.',
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
                _buildPhysicalAssetSection(mutation),
                const SizedBox(height: 16),

                // ── Data Aset Master (Database SIMAK BMN) ───────────
                if (!mutation.isUnregisteredAsset && masterAssetAsync != null)
                  masterAssetAsync.when(
                    data: (master) {
                      final validMaster = master ??
                          (!mutation.isUnregisteredAsset &&
                                  mutation.asset.name != 'Aset Tidak Terdaftar' &&
                                  mutation.asset.assetCode != '-'
                              ? mutation.asset
                              : null);
                      if (validMaster == null) {
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
                        child: _buildMasterAssetCard(validMaster),
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
                          Expanded(
                            child: Text(
                              'Memuat data aset master dari SIMAK BMN...',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    error: (err, _) {
                      if (!mutation.isUnregisteredAsset &&
                          mutation.asset.name != 'Aset Tidak Terdaftar' &&
                          mutation.asset.assetCode != '-') {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildMasterAssetCard(mutation.asset),
                        );
                      }
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.warningContainer.withValues(
                            alpha: 0.3,
                          ),
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
                      );
                    },
                  ),

                // ── Snapshot Saat Pengajuan (UI Versi Bagian Aset) ───────────
                _buildSectionCard([
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          mutation.isUnregisteredAsset
                              ? 'Data Aset Manual (Pengajuan)'
                              : 'Snapshot Saat Pengajuan',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _C.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!mutation.isUnregisteredAsset)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(
                              alpha: 0.5,
                            ),
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            mutation.asset.category.name,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(height: 1, color: _C.border),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDetailRow('Nama Pemohon', mutation.applicantName),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDetailRow(
                    'Tanggal Pengajuan',
                    _formatDateTime(mutation.createdAt),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (mutation.isUnregisteredAsset) ...[
                    _buildDetailRow(
                      'Nama Aset (Manual)',
                      mutation.customAssetName ?? mutation.asset.name,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildDetailRow(
                      'Nomor Seri',
                      mutation.customSerialNumber ??
                          mutation.displaySerialNumber,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildDetailRow(
                      'Kondisi Aset',
                      mutation.asset.condition.isNotEmpty
                          ? mutation.asset.condition
                          : 'Grade A (Normal)',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildDetailRow(
                      'Aset Ikut Pemohon Pindah?',
                      mutation.isAssetMovingWithApplicant
                          ? 'Ya (Dibawa Pemohon)'
                          : 'Tidak (Ditinggalkan di Unit Asal)',
                    ),
                  ] else ...[
                    _buildDetailRow('Nama Aset', mutation.asset.name),
                    const SizedBox(height: AppSpacing.sm),
                    _buildDetailRow('Kode Aset', mutation.asset.assetCode),
                    const SizedBox(height: AppSpacing.sm),
                    _buildDetailRow(
                      'Nomor Seri',
                      mutation.displaySerialNumber,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildDetailRow(
                      'Kondisi Aset',
                      mutation.asset.condition.isNotEmpty
                          ? mutation.asset.condition
                          : 'Grade A (Normal)',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildDetailRow(
                      'Aset Ikut Pemohon Pindah?',
                      mutation.isAssetMovingWithApplicant
                          ? 'Ya (Dibawa Pemohon)'
                          : 'Tidak (Ditinggalkan di Unit Asal)',
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  _buildTransitionRow(
                    label: 'Perpindahan Lokasi',
                    from: mutation.currentLocation,
                    to: mutation.targetLocation,
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
                  const SizedBox(height: AppSpacing.md),
                  _buildTransitionRow(
                    label: 'Perubahan Penanggung Jawab (PIC)',
                    from: mutation.currentPic,
                    to: mutation.targetPic.isNotEmpty
                        ? mutation.targetPic
                        : (mutation.isAssetMovingWithApplicant
                            ? mutation.applicantName
                            : 'Belum Ditentukan (Wajib Ditentukan Bagian Aset)'),
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
                  const SizedBox(height: AppSpacing.sm),
                  _buildDetailRow('Alasan Mutasi', mutation.reason),
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
        if (isWaitingVerification)
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
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('btn_setujui_approval'),
                  onPressed: actionState.isLoading
                      ? null
                      : () => _showVerifyConfirmDialog(
                          context,
                          ref,
                          mutation,
                        ),
                  icon: actionState.isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.verified_rounded, size: 19),
                  label: Text(
                    mutation.needsNewPic
                        ? 'Pilih PIC & Proses Verifikasi'
                        : 'Verifikasi Pengajuan Mutasi',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.primaryContainer,
                    disabledBackgroundColor:
                        _C.primaryContainer.withValues(alpha: 0.35),
                    foregroundColor: Colors.white,
                    disabledForegroundColor:
                        Colors.white.withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
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
          // Row 1: Status Pill & SLA (Responsive Wrap)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: mutation.status.backgroundColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: mutation.status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        mutation.status.displayNameForRole('bagian_aset'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: mutation.status.color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SlaLiveBadge(mutation: mutation),
            ],
          ),
          const SizedBox(height: 14),

          // Row 2: Ticket Number & Badge Jenis Mutasi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
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
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        style: TextStyle(fontSize: 11, color: _C.textSecondary),
                      ),
                      const SizedBox(height: 1),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 12,
                            color: _C.textPrimary,
                          ),
                          children: [
                            TextSpan(text: _formatDateTime(mutation.createdAt)),
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
          const Expanded(
            child: Row(
              children: [
                Icon(Icons.badge_outlined, size: 18, color: _C.secondary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pemegang Aset Saat Ini',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _C.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
                  style: const TextStyle(fontSize: 11, color: _C.textSecondary),
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
                    style: TextStyle(fontSize: 10, color: _C.textSecondary),
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
                    style: TextStyle(fontSize: 10, color: _C.textSecondary),
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
    final serialNumber = mutation.displaySerialNumber;

    return _buildSectionCard([
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.devices_outlined,
                  size: 18,
                  color: _C.primaryContainer,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Detail Aset Fisik',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _C.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _C.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 12,
                  color: _C.primaryContainer,
                ),
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
                  style: TextStyle(fontSize: 10, color: _C.textSecondary),
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
                  'SN: $serialNumber',
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
                    style: TextStyle(fontSize: 10, color: _C.textSecondary),
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
                    style: TextStyle(fontSize: 10, color: _C.textSecondary),
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
                      Expanded(
                        child: Text(
                          mutation.asset.condition.isNotEmpty
                              ? mutation.asset.condition
                              : 'Grade A (Normal)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _C.success,
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
        ],
      ),
      const SizedBox(height: 10),

      // Status Bawa Aset (Spesifik Bagian Aset)
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: mutation.isAssetMovingWithApplicant
              ? _C.successLight
              : _C.warningLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: mutation.isAssetMovingWithApplicant
                ? _C.success.withValues(alpha: 0.3)
                : _C.warning.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              mutation.isAssetMovingWithApplicant
                  ? Icons.person_pin_outlined
                  : Icons.swap_horiz_rounded,
              size: 16,
              color: mutation.isAssetMovingWithApplicant
                  ? _C.success
                  : _C.warning,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                mutation.isAssetMovingWithApplicant
                    ? 'Aset dibawa oleh Pemohon pindah tugas'
                    : 'Aset ditinggalkan di unit asal (Wajib penetapan PIC Baru)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: mutation.isAssetMovingWithApplicant
                      ? _C.success
                      : _C.warning,
                ),
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  // ── 4. RUTE & PENUGASAN MUTASI ─────────────────────────────────────────────
  Widget _buildRouteSection(Mutation mutation) {
    return _buildSectionCard([
      const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.alt_route_rounded, size: 18, color: _C.secondary),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'Rute & Penugasan Mutasi',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _C.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
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
                        style: TextStyle(fontSize: 10, color: _C.textSecondary),
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
                        style: TextStyle(fontSize: 10, color: _C.textSecondary),
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
                  _getInitials(
                    mutation.targetPic.isNotEmpty
                        ? mutation.targetPic
                        : (mutation.isAssetMovingWithApplicant
                              ? mutation.applicantName
                              : '??'),
                  ),
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
                    style: TextStyle(fontSize: 10, color: _C.textSecondary),
                  ),
                  Text(
                    mutation.targetPic.isNotEmpty
                        ? 'PIC • ${mutation.targetPic}'
                        : (mutation.isAssetMovingWithApplicant
                              ? '${mutation.applicantName} (Pemohon)'
                              : 'Belum Ditentukan (Wajib Ditentukan Bagian Aset)'),
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
    Mutation mutation,
    BuildContext context,
    WidgetRef ref,
  ) {
    final docName = mutation.documentName;
    final hasDoc = docName != null && docName.trim().isNotEmpty;
    final isPdf = docName != null && docName.toLowerCase().endsWith('.pdf');

    return _buildSectionCard([
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: [
          const Row(
            mainAxisSize: MainAxisSize.min,
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
                  isPdf ? Icons.picture_as_pdf_rounded : Icons.image_outlined,
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
                      style: TextStyle(fontSize: 10, color: _C.textSecondary),
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
                    apiClient: ref.read(apiClientProvider),
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
    final steps = MutationTrackingHelper.getStepsForMutation(
      mutation.status,
      mutation: mutation,
    );
    final activeStage = MutationTrackingHelper.getActiveStageNumber(steps);

    return _buildSectionCard([
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: [
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.linear_scale_rounded,
                size: 18,
                color: _C.primaryContainer,
              ),
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
            child: Text(
              'Langkah $activeStage dari ${steps.length}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _C.warning,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),

      for (int i = 0; i < steps.length; i++) ...[
        () {
          final step = steps[i];
          final badgeColor = step.isCompleted
              ? _C.secondary
              : step.isAlert
              ? _C.error
              : step.isCurrent
              ? _C.warning
              : _C.textSecondary;

          return _buildTimelineStep(
            isFirst: i == 0,
            isLast: i == steps.length - 1,
            isCompleted: step.isCompleted,
            isActive: step.isCurrent,
            isAlert: step.isAlert,
            title: step.title,
            subtitle: step.subtitle,
            badgeText: step.badgeText,
            badgeColor: badgeColor,
          );
        }(),
      ],
    ]);
  }

  Widget _buildTimelineStep({
    bool isFirst = false,
    bool isLast = false,
    required bool isCompleted,
    bool isActive = false,
    bool isAlert = false,
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
                      : isAlert
                      ? _C.errorLight
                      : isActive
                      ? _C.surface
                      : _C.surfaceContainerLow,
                  border: Border.all(
                    color: isCompleted
                        ? _C.secondary
                        : isAlert
                        ? _C.error
                        : isActive
                        ? _C.primaryContainer
                        : _C.surfaceContainerHighest,
                    width: (isActive || isAlert) ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : isAlert
                      ? const Icon(
                          Icons.priority_high,
                          size: 14,
                          color: _C.error,
                        )
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
                            color: isCompleted || isActive || isAlert
                                ? _C.textPrimary
                                : _C.textSecondary,
                          ),
                        ),
                      ),
                      if (badgeText != null && badgeColor != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
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

  Widget _buildTransitionRow({
    required String label,
    required String from,
    required String to,
    Widget? extraBottom,
  }) {
    return Column(
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
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                from,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _C.textPrimary,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            Expanded(
              child: Text(
                to,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        ?extraBottom,
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
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
            style: const TextStyle(fontSize: 11, color: _C.textSecondary),
          ),
        ],
        ?extraBottom,
      ],
    );
  }


  String _formatDateTime(DateTime dt) {
    return SlaWitaHelper.formatDateTimeWita(dt);
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
    startBagianAsetVerificationFlow(
      context,
      mutation: mutation,
    ).then((verified) {
      if (verified == true && context.mounted) {
        _safePop(context, ref);
      }
    });
  }

  void _safePop(BuildContext context, WidgetRef ref) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      try {
        context.go(RouteNames.bagianAsetVerificationsPath);
      } catch (_) {}
    }
  }
}
