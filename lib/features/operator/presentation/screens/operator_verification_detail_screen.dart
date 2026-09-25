// lib/features/operator/presentation/screens/operator_verification_detail_screen.dart
//
// Screen: Detail Verifikasi Pengajuan Mutasi (OPR-003).
// Sumber: SCREEN-SPEC.md OPR-003, ROLE-FLOW.md §4, WIREFRAME.md §2.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../asset/domain/entities/asset.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';
import '../../../notification/domain/entities/notification_item.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../../../../core/config/business_config.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/document_preview_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/operator_verification_provider.dart';

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
      appBar: AppBar(
        title: const Text('Detail Verifikasi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.operatorMutationsPath);
            }
          },
        ),
      ),
      body: asyncMutation.when(
        data: (mutation) => _buildBody(context, ref, mutation, actionState),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Gagal memuat detail pengajuan: $err',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(mutationDetailProvider(mutationId)),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
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
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: No Tiket & Status Badge
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.border),
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
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            mutation.ticketNumber,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: mutation.status.backgroundColor,
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          mutation.status.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: mutation.status.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Note jika berstatus returned
                if (mutation.status == MutationStatus.returned &&
                    mutation.returnReason != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warningContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.warning),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: AppColors.warning, size: 20),
                            SizedBox(width: AppSpacing.xs),
                            Text(
                              'Alasan Pengembalian (Operator)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          mutation.returnReason!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
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

        // Bottom Actions (Hanya jika status submitted)
        if (isSubmitted)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
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
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.button),
                        ),
                      ),
                      child: const Text(
                        'Kembalikan',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

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
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.button),
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
                                  fontWeight: FontWeight.bold, fontSize: 14),
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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
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
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: const Color(0xFF93C5FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified, size: 18, color: AppColors.primary),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    'Data Aset Master',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
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
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        if (subtext != null) ...[
          const SizedBox(height: 2),
          Text(
            subtext,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dokumen',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
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
                color: AppColors.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_outlined,
                      size: 20, color: AppColors.error),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      documentName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.open_in_new,
                      size: 16, color: AppColors.primary),
                ],
              ),
            ),
          )
        else
          const Text(
            'Tidak ada dokumen dilampirkan',
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
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

    // Nilai aset berasal dari master asset. Jika memenuhi threshold -> true, jika tidak -> false (kecuali ada flag mutasi aktif)
    bool requiresKadiv = mutation.requiresKadivApproval || meetsValueThreshold || isCrossLocation;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Konfirmasi Verifikasi'),
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
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ya, Verifikasi Valid'),
            ),
          ],
        ),
      ),
    );
  }
}
