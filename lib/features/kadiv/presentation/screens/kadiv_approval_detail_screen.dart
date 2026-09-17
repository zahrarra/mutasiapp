// lib/features/kadiv/presentation/screens/kadiv_approval_detail_screen.dart
//
// Screen: Detail Approval Pengajuan Mutasi oleh Kepala Divisi (KDV-003).
// Sumber: SCREEN-SPEC.md KDV-003, ROLE-FLOW.md §6, DESIGN.md.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';
import '../providers/kadiv_approval_provider.dart';

class KadivApprovalDetailScreen extends ConsumerWidget {
  final String mutationId;

  const KadivApprovalDetailScreen({
    super.key,
    required this.mutationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMutation = ref.watch(mutationDetailProvider(mutationId));
    final actionState = ref.watch(kadivApprovalActionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Approval Kadiv'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
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
                'Gagal memuat detail approval: $err',
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
    KadivApprovalActionState actionState,
  ) {
    final isWaitingApproval =
        mutation.status == MutationStatus.waitingKadivApproval;

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
                          borderRadius: BorderRadius.circular(AppRadius.pill),
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

                // Note jika berstatus ditolak
                if (mutation.status == MutationStatus.rejected &&
                    (mutation.kadivRejectionReason != null ||
                        mutation.rejectionReason != null)) ...[
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
                        Row(
                          children: [
                            const Icon(Icons.cancel_outlined,
                                color: AppColors.error, size: 20),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              mutation.kadivRejectedBy != null
                                  ? 'Alasan Penolakan (${mutation.kadivRejectedBy})'
                                  : 'Alasan Penolakan',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          mutation.kadivRejectionReason ??
                              mutation.rejectionReason ??
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

                // ─── TAMPILAN HASIL APPROVAL KABAG (Mandatory Task Scope) ───
                _buildKabagApprovalResultCard(mutation),
                const SizedBox(height: AppSpacing.md),

                // Detail Fields Card
                _buildSectionCard([
                  _buildDetailRow(
                    'Aset',
                    mutation.asset.name,
                    subtext: 'Kode: ${mutation.asset.id}',
                  ),
                  const Divider(height: AppSpacing.md, color: AppColors.border),
                  _buildDetailRow('Pemohon', mutation.applicantName),
                  const Divider(height: AppSpacing.md, color: AppColors.border),
                  _buildTransitionRow(
                    label: 'Lokasi',
                    from: mutation.currentLocation,
                    to: mutation.targetLocation,
                  ),
                  const Divider(height: AppSpacing.md, color: AppColors.border),
                  _buildTransitionRow(
                    label: 'PIC / Penanggung Jawab',
                    from: mutation.currentPic,
                    to: mutation.targetPic,
                  ),
                  const Divider(height: AppSpacing.md, color: AppColors.border),
                  _buildDetailRow('Alasan Mutasi', mutation.reason),
                  if (mutation.documentName != null) ...[
                    const Divider(
                        height: AppSpacing.md, color: AppColors.border),
                    _buildDocumentRow(mutation.documentName!),
                  ],
                ]),
                const SizedBox(height: AppSpacing.md),

                // Timeline Workflow Card (WF-KBG-003, KDV-003 & SCREEN-SPEC)
                _buildSectionCard([
                  const Text(
                    'Timeline Workflow',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTimelineItem(
                    title: 'Diajukan',
                    subtitle: 'Diajukan oleh ${mutation.applicantName}',
                    isCompleted: true,
                    isCurrent: false,
                  ),
                  _buildTimelineLine(),
                  _buildTimelineItem(
                    title: 'Verifikasi Operator',
                    subtitle: mutation.verifiedBy != null
                        ? 'Diverifikasi valid oleh ${mutation.verifiedBy}'
                        : 'Lolos verifikasi kelengkapan dokumen',
                    isCompleted: true,
                    isCurrent: false,
                  ),
                  _buildTimelineLine(),
                  _buildTimelineItem(
                    title: 'Approval Kabag Aset',
                    subtitle: mutation.approvedBy != null
                        ? 'Disetujui oleh ${mutation.approvedBy}'
                        : 'Telah disetujui Kabag Aset',
                    isCompleted: true,
                    isCurrent: false,
                  ),
                  _buildTimelineLine(),
                  _buildTimelineItem(
                    title: 'Approval Kadiv',
                    subtitle: mutation.kadivApprovedBy != null ||
                            (mutation.status == MutationStatus.approved &&
                                mutation.kadivApprovedAt != null)
                        ? 'Disetujui oleh ${mutation.kadivApprovedBy ?? "Kepala Divisi"}'
                        : mutation.status == MutationStatus.rejected &&
                                mutation.kadivRejectedBy != null
                            ? 'Ditolak oleh ${mutation.kadivRejectedBy}'
                            : isWaitingApproval
                                ? 'Menunggu keputusan Kepala Divisi'
                                : 'Selesai',
                    isCompleted: mutation.status == MutationStatus.approved ||
                        mutation.status == MutationStatus.rejected,
                    isCurrent: isWaitingApproval,
                    isRejected: mutation.status == MutationStatus.rejected &&
                        mutation.kadivRejectedBy != null,
                  ),
                ]),
              ],
            ),
          ),
        ),

        // Bottom Action Buttons (Hanya tampil bila berstatus waitingKadivApproval)
        if (isWaitingApproval)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Secondary Action: [ Tolak ]
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('btn_tolak_approval_kadiv'),
                      onPressed: actionState.isLoading
                          ? null
                          : () {
                              context.push(
                                  '/kadiv/approvals/${mutation.id}/reject');
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                      ),
                      child: const Text(
                        'Tolak',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Primary Action: [ Setujui ]
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      key: const Key('btn_setujui_approval_kadiv'),
                      onPressed: actionState.isLoading
                          ? null
                          : () => _showApproveConfirmDialog(
                              context, ref, mutation),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md),
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
                              'Setujui Pengajuan',
                              style: TextStyle(fontWeight: FontWeight.bold),
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

  /// Card Khusus Menampilkan Hasil Approval Kabag Aset
  Widget _buildKabagApprovalResultCard(Mutation mutation) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified, color: AppColors.success, size: 20),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    'Hasil Approval Kabag Aset',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.successContainer,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Text(
                  'Disetujui',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              const Text(
                'Disetujui Oleh: ',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                mutation.approvedBy ?? 'Kabag Aset',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.schedule,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              const Text(
                'Tanggal Approval: ',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                mutation.approvedAt != null
                    ? _formatDate(mutation.approvedAt!)
                    : 'Telah disetujui',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Catatan: Pengajuan telah lolos kriteria review operasional Kabag Aset dan diteruskan ke Kepala Divisi untuk penetapan akhir kriteria khusus.',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        if (subtext != null) ...[
          const SizedBox(height: 2),
          Text(
            subtext,
            style: const TextStyle(
              fontSize: 11,
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
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  from,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Icon(
                Icons.arrow_forward,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.infoContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.3)),
                ),
                child: Text(
                  to,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentRow(String docName) {
    return Row(
      children: [
        const Icon(Icons.attach_file, size: 16, color: AppColors.primary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            docName,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
              decoration: TextDecoration.underline,
            ),
          ),
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
    Color iconColor;
    IconData icon;

    if (isRejected) {
      iconColor = AppColors.error;
      icon = Icons.cancel;
    } else if (isCompleted) {
      iconColor = AppColors.success;
      icon = Icons.check_circle;
    } else if (isCurrent) {
      iconColor = AppColors.warning;
      icon = Icons.radio_button_checked;
    } else {
      iconColor = AppColors.disabled;
      icon = Icons.radio_button_unchecked;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isCurrent || isCompleted ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent
                      ? AppColors.primary
                      : isRejected
                          ? AppColors.error
                          : AppColors.textPrimary,
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
      margin: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
      width: 2,
      height: 16,
      color: AppColors.border,
    );
  }

  void _showApproveConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    Mutation mutation,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Konfirmasi Approval Kadiv'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Apakah Anda yakin ingin memberikan persetujuan final Kepala Divisi untuk pengajuan mutasi ini?',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mutation.ticketNumber,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '${mutation.asset.name} (${mutation.asset.id})',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Tujuan: ${mutation.targetLocation}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Setelah disetujui, pengajuan akan diteruskan ke Staff Aset untuk pembaruan lokasi aset.',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              key: const Key('btn_confirm_setujui_kadiv'),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();

                final success = await ref
                    .read(kadivApprovalActionProvider.notifier)
                    .approve(mutationId: mutation.id);

                if (context.mounted) {
                  if (success) {
                    ref.invalidate(mutationDetailProvider(mutation.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Pengajuan mutasi berhasil disetujui oleh Kadiv.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    context.pop();
                  } else {
                    final err = ref.read(kadivApprovalActionProvider).error;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(err ?? 'Gagal menyetujui mutasi.'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ya, Setujui'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
