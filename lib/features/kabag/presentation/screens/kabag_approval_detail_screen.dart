// lib/features/kabag/presentation/screens/kabag_approval_detail_screen.dart
//
// Screen: Detail Approval Pengajuan Mutasi oleh Kabag Aset (KBG-003).
// Sumber: SCREEN-SPEC.md KBG-003, ROLE-FLOW.md §5, WIREFRAME.md §7.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';
import '../providers/kabag_approval_provider.dart';

class KabagApprovalDetailScreen extends ConsumerWidget {
  final String mutationId;

  const KabagApprovalDetailScreen({
    super.key,
    required this.mutationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMutation = ref.watch(mutationDetailProvider(mutationId));
    final actionState = ref.watch(kabagApprovalActionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Approval'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.kabagApprovalsPath);
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
    KabagApprovalActionState actionState,
  ) {
    final isWaitingApproval =
        mutation.status == MutationStatus.waitingKabagApproval;

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

                // Note jika berstatus ditolak
                if (mutation.status == MutationStatus.rejected &&
                    mutation.rejectionReason != null) ...[
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
                            Icon(Icons.cancel_outlined,
                                color: AppColors.error, size: 20),
                            SizedBox(width: AppSpacing.xs),
                            Text(
                              'Alasan Penolakan (Kabag Aset)',
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
                          mutation.rejectionReason!,
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

                // Detail Fields Card
                _buildSectionCard([
                  _buildDetailRow(
                    'Aset',
                    mutation.asset.name,
                    subtext:
                        'Kode: ${mutation.asset.id} • ${mutation.asset.category.name}',
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
                  const Divider(height: AppSpacing.md, color: AppColors.border),
                  _buildDocumentRow(mutation.documentName),
                  const Divider(height: AppSpacing.md, color: AppColors.border),
                  _buildDetailRow(
                      'Waktu Pengajuan', _formatDateTime(mutation.createdAt)),
                ]),
                const SizedBox(height: AppSpacing.md),

                // Timeline Workflow Card (WF-KBG-003 & SCREEN-SPEC KBG-003)
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
                    title: 'Approval Kabag',
                    subtitle: (mutation.status == MutationStatus.approved ||
                                mutation.status ==
                                    MutationStatus.waitingKadivApproval ||
                                mutation.status ==
                                    MutationStatus.pendingConfirmation ||
                                mutation.status == MutationStatus.completed)
                        ? 'Disetujui oleh ${mutation.approvedBy ?? "Kabag Aset"}'
                        : mutation.status == MutationStatus.rejected
                            ? 'Ditolak oleh ${mutation.rejectedBy ?? "Kabag Aset"}'
                            : 'Menunggu keputusan Kabag Aset',
                    isCompleted: mutation.status == MutationStatus.approved ||
                        mutation.status ==
                            MutationStatus.waitingKadivApproval ||
                        mutation.status ==
                            MutationStatus.pendingConfirmation ||
                        mutation.status == MutationStatus.completed ||
                        mutation.status == MutationStatus.rejected,
                    isCurrent: isWaitingApproval,
                    isRejected: mutation.status == MutationStatus.rejected,
                  ),
                  // Tampilkan step Kadiv jika mutasi memerlukan Kadiv approval
                  if (mutation.requiresKadivApproval) ...[ 
                    _buildTimelineLine(),
                    _buildTimelineItem(
                      title: 'Approval Kadiv',
                      subtitle: mutation.status ==
                                  MutationStatus.waitingKadivApproval
                              ? 'Menunggu keputusan Kadiv'
                              : mutation.kadivApprovedBy != null
                                  ? 'Disetujui oleh ${mutation.kadivApprovedBy}'
                                  : mutation.kadivRejectedBy != null
                                      ? 'Ditolak oleh ${mutation.kadivRejectedBy}'
                                      : 'Menunggu Kadiv',
                      isCompleted: mutation.kadivApprovedBy != null ||
                          mutation.kadivRejectedBy != null,
                      isCurrent: mutation.status ==
                          MutationStatus.waitingKadivApproval,
                      isRejected: mutation.kadivRejectedBy != null,
                    ),
                  ],
                ]),
              ],
            ),
          ),
        ),

        // Bottom Action Buttons (Hanya tampil bila berstatus waitingKabagApproval)
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
                      key: const Key('btn_tolak_approval'),
                      onPressed: actionState.isLoading
                          ? null
                          : () {
                              context.push(
                                  '/kabag/approvals/${mutation.id}/reject');
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
                      key: const Key('btn_setujui_approval'),
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
                              'Setujui',
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

  Widget _buildDetailRow(String label, String value, {String? subtext}) {
    return Column(
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
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
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
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Icon(Icons.arrow_forward_rounded,
                  size: 16, color: AppColors.primary),
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

  Widget _buildDocumentRow(String? documentName) {
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
          Row(
            children: [
              const Icon(Icons.picture_as_pdf_outlined,
                  size: 20, color: AppColors.error),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  documentName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
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

  void _showApproveConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    Mutation mutation,
  ) {
    bool requiresKadiv = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Konfirmasi Persetujuan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apakah Anda yakin menyetujui pengajuan mutasi '
                '${mutation.ticketNumber} untuk aset '
                '"${mutation.asset.name}"?',
              ),
              const SizedBox(height: 16),
              const Text(
                'Apakah mutasi ini memerlukan approval Kadiv?',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  // ignore: deprecated_member_use
                  Radio<bool>(
                    value: true,
                    // ignore: deprecated_member_use
                    groupValue: requiresKadiv,
                    // ignore: deprecated_member_use
                    onChanged: (v) => setState(() => requiresKadiv = v!),
                  ),
                  InkWell(
                    onTap: () => setState(() => requiresKadiv = true),
                    child: const Text('Ya, butuh Kadiv',
                        style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  // ignore: deprecated_member_use
                  Radio<bool>(
                    value: false,
                    // ignore: deprecated_member_use
                    groupValue: requiresKadiv,
                    // ignore: deprecated_member_use
                    onChanged: (v) => setState(() => requiresKadiv = v!),
                  ),
                  InkWell(
                    onTap: () => setState(() => requiresKadiv = false),
                    child: const Text('Tidak perlu',
                        style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              key: const Key('btn_confirm_setujui'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final success = await ref
                    .read(kabagApprovalActionProvider.notifier)
                    .approve(
                      mutationId: mutation.id,
                      requiresKadivApproval: requiresKadiv,
                    );

                if (context.mounted) {
                  if (success) {
                    ref.invalidate(mutationDetailProvider(mutation.id));
                    final msg = requiresKadiv
                        ? 'Disetujui. Menunggu approval Kadiv.'
                        : 'Pengajuan mutasi berhasil disetujui.';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(msg),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      try {
                        context.pop();
                      } catch (_) {}
                    }
                  } else {
                    final err = ref.read(kabagApprovalActionProvider).error;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(err ?? 'Gagal menyetujui pengajuan.'),
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
        ),
      ),
    );
  }
}
