// lib/features/kabag/presentation/screens/kabag_approval_detail_screen.dart
//
// Screen: Detail Approval Pengajuan Mutasi oleh Kabag Aset (KBG-003).
// Sumber: SCREEN-SPEC.md KBG-003, ROLE-FLOW.md §5, WIREFRAME.md §7.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
                    subtitle: mutation.status == MutationStatus.approved
                        ? 'Disetujui oleh ${mutation.approvedBy ?? "Kabag Aset"}'
                        : mutation.status == MutationStatus.rejected
                            ? 'Ditolak oleh ${mutation.rejectedBy ?? "Kabag Aset"}'
                            : 'Menunggu keputusan Kabag Aset',
                    isCompleted: mutation.status == MutationStatus.approved ||
                        mutation.status == MutationStatus.rejected,
                    isCurrent: isWaitingApproval,
                    isRejected: mutation.status == MutationStatus.rejected,
                  ),
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

  void _showApproveConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    Mutation mutation,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Persetujuan'),
        content: Text(
          'Apakah Anda yakin menyetujui pengajuan mutasi ${mutation.ticketNumber} untuk aset "${mutation.asset.name}"?',
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
                  .approve(mutationId: mutation.id);

              if (context.mounted) {
                if (success) {
                  ref.invalidate(mutationDetailProvider(mutation.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pengajuan mutasi berhasil disetujui.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  context.pop();
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
    );
  }
}
