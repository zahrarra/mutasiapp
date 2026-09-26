// lib/features/operator/presentation/screens/operator_verification_detail_screen.dart
//
// Screen: Detail Verifikasi Pengajuan Mutasi (OPR-003).
// Sumber: SCREEN-SPEC.md OPR-003, ROLE-FLOW.md §4, WIREFRAME.md §2.
// UI: Premium Stitch design — custom top bar, section cards, styled action bar.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../asset/domain/entities/asset.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';
import '../../../notification/domain/entities/notification_item.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/config/business_config.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/document_preview_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/operator_verification_provider.dart';

// ── Stitch Design Tokens ─────────────────────────────────────────────────────
class _C {
  static const navy = Color(0xFF0F3D56);
  static const teal = Color(0xFF0F766E);
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF6F8FA);
  static const textPrimary = Color(0xFF172B4D);
  static const textSecondary = Color(0xFF52606D);
  static const border = Color(0xFFE2E8F0);
  static const warning = Color(0xFFD97706);
  static const warningLight = Color(0xFFFEF3C7);
  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFEF2F2);
  static const info = Color(0xFF3B82F6);
  static const infoLight = Color(0xFFEFF6FF);
  static const slate = Color(0xFF475569);
  static const slateLight = Color(0xFFF1F5F9);
  static const slateBorder = Color(0xFFCBD5E1);
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

    return Scaffold(
      backgroundColor: _C.background,
      body: Column(
        children: [
          // ── Custom Top Bar ────────────────────────────────────────
          Container(
            color: _C.surface,
            child: SafeArea(
              bottom: false,
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: _C.surface,
                  border: Border(bottom: BorderSide(color: _C.border, width: 1)),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(RouteNames.operatorMutationsPath);
                        }
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _C.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _C.border),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            size: 18, color: _C.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detail Verifikasi',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _C.textPrimary,
                            ),
                          ),
                          Text(
                            'Tinjauan Pengajuan Mutasi',
                            style: TextStyle(
                              fontSize: 11,
                              color: _C.textSecondary,
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

          // ── Body content ─────────────────────────────────────────
          Expanded(
            child: asyncMutation.when(
              data: (mutation) => _buildBody(context, ref, mutation, actionState),
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2, color: _C.teal),
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
                        child: const Icon(Icons.error_outline_rounded,
                            size: 32, color: _C.error),
                      ),
                      const SizedBox(height: 16),
                      const Text('Gagal Memuat Data',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _C.textPrimary)),
                      const SizedBox(height: 6),
                      Text('$err',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12, color: _C.textSecondary)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () =>
                            ref.invalidate(mutationDetailProvider(mutationId)),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Coba Lagi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
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
    final shouldLoadMaster = !mutation.isUnregisteredAsset &&
        rawAssetId.trim().isNotEmpty;
    final masterAssetAsync = shouldLoadMaster
        ? ref.watch(operatorMasterAssetProvider(rawAssetId))
        : null;
    final masterAsset = masterAssetAsync?.valueOrNull;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: Ticket & Status ─────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _C.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _C.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nomor Tiket',
                            style: TextStyle(
                              fontSize: 11,
                              color: _C.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            mutation.ticketNumber,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                              color: _C.navy,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: mutation.status.backgroundColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          mutation.status.displayName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: mutation.status.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Note jika berstatus returned
                if (mutation.status == MutationStatus.returned &&
                    mutation.returnReason != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _C.warningLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.warning.withValues(alpha: 0.5)),
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
                  const SizedBox(height: 12),
                ],

                // ── Warning Jika Aset Tidak Terdaftar ─────────────────────────
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
                  const SizedBox(height: AppSpacing.md),

                  // Data Manual Pengajuan
                  _buildSectionCard([
                    _buildSectionHeader(
                      title: 'Data Aset Manual (Pengajuan)',
                      badge: 'Aset Non-Master',
                      icon: Icons.edit_note,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: AppSpacing.sm),
                    _buildDetailRow('Pemohon', mutation.applicantName),
                    const Divider(height: AppSpacing.md, color: AppColors.border),
                    _buildDetailRow(
                      'Aset (Manual)',
                      mutation.customAssetName ?? mutation.asset.name,
                      subtext:
                          'Nomor Seri / Kode Manual: ${mutation.customSerialNumber ?? mutation.asset.assetCode}',
                    ),
                    const Divider(height: AppSpacing.md, color: AppColors.border),
                    _buildDetailRow('Lokasi Asal', mutation.currentLocation),
                    const Divider(height: AppSpacing.md, color: AppColors.border),
                    _buildDetailRow('Lokasi Tujuan', mutation.targetLocation),
                    const Divider(height: AppSpacing.md, color: AppColors.border),
                    _buildDetailRow(
                        'Pemakai Lama (PIC Asal)', mutation.currentPic),
                    const Divider(height: AppSpacing.md, color: AppColors.border),
                    _buildDetailRow('PIC Baru (Tujuan)', mutation.targetPic),
                    const Divider(height: AppSpacing.md, color: AppColors.border),
                    _buildDetailRow('Alasan Mutasi', mutation.reason),
                    const Divider(height: AppSpacing.md, color: AppColors.border),
                    _buildDocumentRow(mutation, context, ref),
                    const Divider(height: AppSpacing.md, color: AppColors.border),
                    _buildDetailRow(
                        'Waktu Pengajuan', _formatDateTime(mutation.createdAt)),
                  ]),
                ] else ...[
                  // ── Data Aset Master (Database SIMAK BMN) ───────────────────
                  if (masterAssetAsync != null)
                    masterAssetAsync.when(
                      data: (master) {
                        if (master == null) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _buildMasterAssetCard(master),
                        );
                      },
                      loading: () => Container(
                        key: const Key('card_master_asset_loading'),
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
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

                  // ── Snapshot Saat Pengajuan ─────────────────────────────────
                  _buildSectionCard([
                    _buildSectionHeader(
                      title: 'Snapshot Saat Pengajuan',
                      badge: 'Data Pemohon',
                      icon: Icons.history,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: AppSpacing.sm),
                    _buildDetailRow('Pemohon', mutation.applicantName),
                    const Divider(height: AppSpacing.md, color: AppColors.border),
                    _buildDetailRow(
                      'Aset',
                      mutation.asset.name,
                      subtext:
                          'Kode: ${mutation.asset.id} • ${mutation.asset.category.name}',
                    ),
                    const Divider(height: AppSpacing.md, color: AppColors.border),
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
                    const Divider(height: AppSpacing.md, color: AppColors.border),
                    _buildDetailRow('Lokasi Tujuan', mutation.targetLocation),
                    const Divider(height: AppSpacing.md, color: AppColors.border),
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
                    const Divider(height: AppSpacing.md, color: AppColors.border),
                    _buildDetailRow('PIC Baru (Tujuan)', mutation.targetPic),
                    const Divider(height: AppSpacing.md, color: AppColors.border),
                    _buildDetailRow('Alasan Mutasi', mutation.reason),
                    const Divider(height: AppSpacing.md, color: AppColors.border),
                    _buildDocumentRow(mutation, context, ref),
                    const Divider(height: AppSpacing.md, color: AppColors.border),
                    _buildDetailRow(
                        'Waktu Pengajuan', _formatDateTime(mutation.createdAt)),
                  ]),
                ],
              ],
            ),
          ),
        ),

        // ── Bottom Actions (Hanya jika status submitted) ────────
        if (isSubmitted)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            decoration: const BoxDecoration(
              color: _C.surface,
              border: Border(top: BorderSide(color: _C.border)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Secondary: [ Kembalikan ]
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('btn_kembalikan_pengajuan'),
                      onPressed: actionState.isLoading
                          ? null
                          : () {
                              context.push(
                                  '/operator/mutations/${mutation.id}/return');
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _C.error,
                        side: const BorderSide(color: _C.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Kembalikan',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Primary: [ Verifikasi Valid ]
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      key: const Key('btn_verifikasi_valid'),
                      onPressed: actionState.isLoading
                          ? null
                          : () => _showVerifyConfirmDialog(
                              context, ref, mutation),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: actionState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Verifikasi Valid',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13),
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
            color: Colors.black.withValues(alpha: 0.04),
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
            Icon(icon, size: 16, color: _C.teal),
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
            color: _C.slateLight,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _C.slateBorder),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _C.slate,
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
            color: Colors.black.withValues(alpha: 0.04),
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
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.sm),
          _buildDetailRow(
            'Nama Aset (Master)',
            master.name,
            key: const Key('master_asset_name'),
          ),
          const Divider(height: AppSpacing.md, color: AppColors.border),
          _buildDetailRow(
            'Kode / Nomor Inventaris',
            master.assetCode,
            key: const Key('master_asset_code'),
          ),
          const Divider(height: AppSpacing.md, color: AppColors.border),
          _buildDetailRow(
            'Nomor Seri (Serial Number)',
            (master.serialNumber != null && master.serialNumber!.isNotEmpty)
                ? master.serialNumber!
                : '-',
            key: const Key('master_asset_sn'),
          ),
          const Divider(height: AppSpacing.md, color: AppColors.border),
          _buildDetailRow(
            'Kategori Aset',
            master.category.name,
            key: const Key('master_asset_category'),
          ),
          const Divider(height: AppSpacing.md, color: AppColors.border),
          _buildDetailRow(
            'Lokasi Master',
            '${master.location} (SIMAK BMN)',
            key: const Key('master_asset_location'),
          ),
          const Divider(height: AppSpacing.md, color: AppColors.border),
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
    final isPdf = documentName != null && documentName.toLowerCase().endsWith('.pdf');
    final isImage = documentName != null &&
        ['png', 'jpg', 'jpeg', 'webp'].any((ext) => documentName.toLowerCase().endsWith(ext));

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
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year $hour:$minute';
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

    // Nilai aset berasal dari master asset: jika nilai aset >= threshold -> true, jika < threshold -> false (kecuali mutasi antar-lokasi)
    bool requiresKadiv = meetsValueThreshold || isCrossLocation;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('Konfirmasi Verifikasi',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary)),
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
                backgroundColor: _C.teal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Ya, Verifikasi Valid',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
