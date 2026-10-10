// lib/features/bagian_aset/presentation/screens/bagian_aset_verification_detail_screen.dart
//
// Screen: Detail Verifikasi Pengajuan Mutasi oleh Bagian Aset.
// Sumber: PRD V1.1 §5, §6.4, §8 Aturan 12 & 13.
//
// Bagian Aset BUKAN approver:
// 1. Memeriksa keabsahan data aset, lokasi tujuan, dan SK SDM.
// 2. Menentukan PIC baru jika pemohon tidak membawa aset (isAssetMovingWithApplicant == false).
// 3. Mengembalikan pengajuan jika tidak valid.
// 4. Meneruskan pengajuan yang valid ke antrean Approval Pemimpin Divisi.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/sla_wita_helper.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/document_preview_dialog.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/widgets/inline_searchable_dropdown.dart';
import '../../../../core/widgets/mutasiku_page_header.dart';
import '../../../../core/widgets/sla_live_badge.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../../../mutation/presentation/models/mutation_tracking_step.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';
import '../../../mutation/presentation/widgets/mutation_return_dialog.dart';
import '../../../notification/domain/entities/notification_item.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../providers/bagian_aset_verification_provider.dart';

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
      backgroundColor: const Color(0xFFF6F8FA),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SafeArea(
            bottom: false,
            child: MutasiKuPageHeader(
              title: 'Verifikasi Mutasi Aset',
              subtitle: 'Detail dan verifikasi pengajuan mutasi aset',
              onBack: () => _safePop(context, ref),
            ),
          ),
          Expanded(
            child: asyncMutation.when(
              data: (mutation) =>
                  _buildBody(context, ref, mutation, actionState),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Gagal memuat detail pengajuan: $err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(
                        bagianAsetMutationDetailProvider(mutationId),
                      ),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
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

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header No. Tiket & Status Badge
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
                      Expanded(
                        child: Column(
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
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          alignment: WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: mutation.status.backgroundColor,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                mutation.status.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: mutation.status.color,
                                ),
                              ),
                            ),
                            SlaLiveBadge(mutation: mutation),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Note jika berstatus dikembalikan atau ditolak
                if (mutation.status == MutationStatus.returned &&
                    (mutation.returnReason != null ||
                        mutation.assetReturnReason != null)) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.error,
                              size: 18,
                            ),
                            SizedBox(width: AppSpacing.xs),
                            Text(
                              'Alasan Pengembalian:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                                fontSize: 13,
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
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Note jika berstatus menunggu verifikasi TETAPI memiliki catatan ketidaksesuaian fisik dari Pemohon
                if (mutation.status.isWaitingAssetVerification &&
                    mutation.returnReason != null &&
                    mutation.returnReason!.trim().isNotEmpty) ...[
                  Container(
                    key: const Key('banner_konfirmasi_tidak_sesuai'),
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(AppRadius.card),
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
                            SizedBox(width: AppSpacing.xs),
                            Text(
                              'Catatan Konfirmasi Fisik Tidak Sesuai (Pemohon):',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF856404),
                                fontSize: 13,
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
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // 1. Data Pemohon
                _buildSectionCard([
                  const Text(
                    'Informasi Pemohon',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDetailRow('Nama Pemohon', mutation.applicantName),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDetailRow(
                    'Tanggal Pengajuan',
                    _formatDateTime(mutation.createdAt),
                  ),
                ]),
                const SizedBox(height: AppSpacing.md),

                // 2. Data Aset
                _buildSectionCard([
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Data Aset',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(
                              alpha: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
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
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDetailRow('Nama Aset', mutation.asset.name),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDetailRow('Kode Aset', mutation.asset.assetCode),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDetailRow('Nomor Seri', mutation.displaySerialNumber),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDetailRow('Kondisi Aset', mutation.asset.condition),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDetailRow(
                    'Aset Ikut Pemohon Pindah?',
                    mutation.isAssetMovingWithApplicant
                        ? 'Ya (Dibawa Pemohon)'
                        : 'Tidak (Ditinggalkan di Unit Asal)',
                  ),
                ]),
                const SizedBox(height: AppSpacing.md),

                // 3. Perpindahan Lokasi & PIC
                _buildSectionCard([
                  const Text(
                    'Rencana Perpindahan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: AppSpacing.sm),
                  _buildTransitionRow(
                    label: 'Perpindahan Lokasi',
                    from: mutation.currentLocation,
                    to: mutation.targetLocation,
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
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDetailRow('Alasan Mutasi', mutation.reason),
                ]),
                const SizedBox(height: AppSpacing.md),

                // 4. Dokumen Pendukung (SK SDM)
                _buildSectionCard([
                  const Text(
                    'Dokumen Pendukung (SK SDM)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDocumentRow(mutation, context, ref),
                ]),
                const SizedBox(height: AppSpacing.md),

                // 5. Timeline Alur Mutasi (5 Langkah PRD V1.1)
                _buildSectionCard([
                  const Text(
                    'Riwayat & Status Alur',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: AppSpacing.md),
                  ..._buildTimelineSteps(mutation),
                ]),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),

        // Action Buttons Bottom Bar jika berstatus waitingAssetVerification
        if (isWaitingVerification)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Secondary Action: [ Kembalikan ]
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      key: const Key('btn_tolak_approval'),
                      onPressed: actionState.isLoading
                          ? null
                          : () => _showReturnModal(context, ref, mutation),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                      ),
                      child: const Text(
                        'Kembalikan',
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // Primary Action: [ Verifikasi & Teruskan ke Pemimpin Divisi ]
                  Expanded(
                    flex: 3,
                    child: ElevatedButton(
                      key: const Key('btn_setujui_approval'),
                      onPressed: actionState.isLoading
                          ? null
                          : () => _showVerifyConfirmDialog(
                              context,
                              ref,
                              mutation,
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
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
                              'Verifikasi & Teruskan',
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
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

  List<Widget> _buildTimelineSteps(Mutation mutation) {
    final steps = MutationTrackingHelper.buildTrackingSteps(
      status: mutation.status,
      requiresKadivApproval: true,
      applicantName: mutation.applicantName,
      createdAt: mutation.createdAt,
      verifiedBy: mutation.verifiedBy,
      returnReason: mutation.returnReason,
      assetVerifiedBy: mutation.assetVerifiedBy,
      assetReturnReason: mutation.assetReturnReason,
      approvedBy: mutation.approvedBy,
      rejectedBy: mutation.rejectedBy,
      rejectionReason: mutation.rejectionReason,
      kadivApprovedBy: mutation.kadivApprovedBy,
      kadivRejectedBy: mutation.kadivRejectedBy,
      kadivRejectionReason: mutation.kadivRejectionReason,
      kadivRejectedAt: mutation.kadivRejectedAt,
      confirmationReason: mutation.confirmationReason,
    );

    final widgets = <Widget>[];
    for (int i = 0; i < steps.length; i++) {
      final s = steps[i];
      widgets.add(
        _buildTimelineItem(
          title: s.title,
          subtitle: s.subtitle,
          isCompleted: s.isCompleted,
          isCurrent: s.isCurrent,
          isRejected: s.isAlert,
        ),
      );
      if (i < steps.length - 1) {
        widgets.add(_buildTimelineLine());
      }
    }
    return widgets;
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

  Widget _buildDetailRow(String label, String value, {String? subtext}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
      ],
    );
  }

  Widget _buildTransitionRow({
    required String label,
    required String from,
    required String to,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
      ],
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isCurrent,
    bool isRejected = false,
  }) {
    final Color iconColor = isRejected
        ? AppColors.error
        : isCompleted
        ? AppColors.success
        : isCurrent
        ? AppColors.warning
        : AppColors.border;

    final IconData icon = isRejected
        ? Icons.cancel
        : isCompleted
        ? Icons.check_circle
        : isCurrent
        ? Icons.radio_button_checked
        : Icons.radio_button_unchecked;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isCurrent || isCompleted
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineLine() {
    return Container(
      margin: const EdgeInsets.only(left: 9, top: 2, bottom: 2),
      width: 2,
      height: 16,
      color: AppColors.border,
    );
  }

  String _formatDateTime(DateTime dt) {
    return SlaWitaHelper.formatDateTimeWita(dt);
  }

  Widget _buildDocumentRow(
    Mutation mutation,
    BuildContext context,
    WidgetRef ref,
  ) {
    final documentName = mutation.documentName;
    final isPdf =
        documentName != null && documentName.toLowerCase().endsWith('.pdf');
    final isImage =
        documentName != null &&
        [
          'png',
          'jpg',
          'jpeg',
          'webp',
        ].any((ext) => documentName.toLowerCase().endsWith(ext));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dokumen',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        if (documentName != null && documentName.isNotEmpty)
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isPdf
                        ? Icons.picture_as_pdf_outlined
                        : isImage
                        ? Icons.image_outlined
                        : Icons.description_outlined,
                    size: 20,
                    color: isPdf
                        ? AppColors.error
                        : isImage
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
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
                  const Icon(
                    Icons.open_in_new,
                    size: 16,
                    color: AppColors.primary,
                  ),
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

  void _showVerifyConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    Mutation mutation,
  ) {
    final isLeftBehind = !mutation.isAssetMovingWithApplicant;
    final needsPic = isLeftBehind || mutation.targetPic.trim().isEmpty;
    final picController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Verifikasi Data Aset'),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Apakah Anda yakin data aset ${mutation.ticketNumber} '
                    '("${mutation.asset.name}") telah valid dan siap diteruskan ke Pemimpin Divisi?',
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (needsPic) ...[
                    const SizedBox(height: 16),
                    Text(
                      isLeftBehind
                          ? 'Penentuan PIC Baru (Aset Ditinggalkan) *'
                          : 'Penentuan PIC Baru *',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (isLeftBehind) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Aset fisik ditinggalkan di unit asal. Bagian Aset menentukan PIC baru melalui sistem dari data master.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: Consumer(
                        builder: (ctx, modalRef, _) {
                          final usersAsync = modalRef.watch(masterUsersProvider);
                          final users = usersAsync.valueOrNull ?? [];
                          final activeUsers = users.where((u) => u.isActive).toList();
                          final picNames = activeUsers
                              .map((u) => '${u.name} (${u.role.displayName})')
                              .toList();

                          final isLoading = usersAsync.isLoading && activeUsers.isEmpty;
                          final hasError = usersAsync.hasError && activeUsers.isEmpty;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InlineSearchableDropdown(
                                fieldKey: const Key('input_pic_baru_bagian_aset'),
                                labelText: isLeftBehind
                                    ? 'PIC Baru Unit Asal (Master Data) *'
                                    : 'PIC Baru (Master Data) *',
                                hintText: isLoading
                                    ? 'Memuat daftar PIC dari server...'
                                    : (isLeftBehind
                                        ? 'Pilih atau cari PIC baru di unit asal...'
                                        : 'Pilih nama PIC baru...'),
                                controller: picController,
                                items: picNames,
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'PIC baru wajib ditentukan oleh Bagian Aset'
                                    : null,
                              ),
                              if (isLoading)
                                const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(strokeWidth: 1.5),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Menghubungkan ke server...',
                                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              if (hasError)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info_outline, size: 14, color: Color(0xFFDC2626)),
                                      const SizedBox(width: 4),
                                      const Expanded(
                                        child: Text(
                                          'Koneksi server offline. Anda tetap dapat mengetik nama PIC.',
                                          style: TextStyle(fontSize: 11, color: Color(0xFF991B1B)),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => modalRef.read(masterUsersProvider.notifier).loadUsers(),
                                        child: const Text('Coba Lagi', style: TextStyle(fontSize: 11)),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.infoContainer,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.forward_outlined,
                          color: AppColors.info,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Alur Mutasi: Pengajuan yang valid akan langsung diteruskan ke antrean Approval Pemimpin Divisi.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.info,
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            key: const Key('btn_confirm_setujui'),
            onPressed: () async {
              if (needsPic && !(formKey.currentState?.validate() ?? false)) {
                return;
              }
              Navigator.of(dialogContext).pop();

              String? picIdToSubmit;
              if (needsPic) {
                final input = picController.text.trim();
                final users = ref.read(masterUsersProvider).valueOrNull ?? [];
                final activeUsers = users.where((u) => u.isActive).toList();
                User? matchedUser;
                for (final u in activeUsers) {
                  final fullLabel = '${u.name} (${u.role.displayName})';
                  if (fullLabel == input ||
                      u.name.toLowerCase() == input.toLowerCase() ||
                      u.id == input) {
                    matchedUser = u;
                    break;
                  }
                }
                picIdToSubmit = matchedUser?.id ?? input;
              }

              final success = await ref
                  .read(bagianAsetVerificationActionProvider.notifier)
                  .verifyAndForward(
                    mutationId: mutation.id,
                    newPic: picIdToSubmit,
                  );

              if (context.mounted) {
                if (success) {
                  AppFeedback.showSuccess(
                    context,
                    'Data aset diverifikasi dan diteruskan ke Pemimpin Divisi.',
                  );
                  _safePop(context, ref);
                } else {
                  final err = ref
                      .read(bagianAsetVerificationActionProvider)
                      .error;
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
            child: const Text('Ya, Teruskan'),
          ),
        ],
      ),
    );
  }

  void _showReturnModal(
    BuildContext context,
    WidgetRef ref,
    Mutation mutation,
  ) {
    showMutationReturnDialog(
      context: context,
      mutation: mutation,
      onConfirm: (reason) async {
        final success = await ref
            .read(bagianAsetVerificationActionProvider.notifier)
            .returnToApplicant(mutationId: mutation.id, reason: reason);

        if (context.mounted) {
          if (success) {
            ref
                .read(notificationProvider.notifier)
                .notifyUser(
                  targetUserId: mutation.applicantId ?? 'usr_pemohon',
                  targetRole: UserRole.pemohon,
                  title: 'Pengajuan Dikembalikan Bagian Aset',
                  message:
                      'Pengajuan mutasi ${mutation.ticketNumber} (${mutation.asset.name}) dikembalikan oleh Bagian Aset: $reason',
                  type: NotificationType.warning,
                  relatedMutationId: mutation.id,
                );
            ref.invalidate(mutationDetailProvider(mutation.id));
            AppFeedback.showReturned(context, 'Pengajuan dikembalikan');
            return true;
          } else {
            final err = ref.read(bagianAsetVerificationActionProvider).error;
            AppFeedback.showError(
              context,
              err ?? 'Gagal mengembalikan pengajuan.',
            );
            return false;
          }
        }
        return false;
      },
    );
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
