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
import '../../../mutation/presentation/models/mutation_tracking_step.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/document_preview_dialog.dart';
import '../../../../core/widgets/inline_searchable_dropdown.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mutation/presentation/providers/mutation_form_provider.dart';
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
        title: const Text('Verifikasi Mutasi Aset'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.bagianAsetVerificationsPath);
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
        mutation.status.isWaitingAssetVerification;

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
                  _buildDocumentRow(mutation, context, ref),
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
                  ...() {
                    final trackingSteps =
                        MutationTrackingHelper.getStepsForMutation(
                      mutation.status,
                      mutation: mutation,
                    );
                    final widgets = <Widget>[];
                    for (var i = 0; i < trackingSteps.length; i++) {
                      if (i > 0) widgets.add(_buildTimelineLine());
                      final step = trackingSteps[i];
                      widgets.add(
                        _buildTimelineItem(
                          title: step.title,
                          subtitle: step.subtitle,
                          isCompleted: step.isCompleted,
                          isCurrent: step.isCurrent,
                          isRejected: step.isAlert,
                        ),
                      );
                    }
                    return widgets;
                  }(),
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
                  // Secondary Action: [ Kembalikan / Tolak ]
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('btn_tolak_approval'),
                      onPressed: actionState.isLoading
                          ? null
                          : () {
                              context.push(
                                RouteNames.bagianAsetReturnFormPath
                                    .replaceFirst(':id', mutation.id),
                              );
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

                  // Primary Action: [ Verifikasi & Teruskan / Setujui ]
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
                              'Verifikasi & Teruskan',
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

  void _showApproveConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    Mutation mutation,
  ) {
    final isLeftBehind = !mutation.isAssetMovingWithApplicant;
    final needsPic = isLeftBehind || mutation.targetPic.trim().isEmpty;
    final picController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final pics = ref.read(availablePicsProvider);

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
                      child: InlineSearchableDropdown(
                        fieldKey: const Key('input_pic_baru_bagian_aset'),
                        labelText: isLeftBehind
                            ? 'PIC Baru Unit Asal (Master Data) *'
                            : 'PIC Baru (Master Data) *',
                        hintText: isLeftBehind
                            ? 'Pilih atau cari PIC baru di unit asal...'
                            : 'Pilih nama PIC baru...',
                        controller: picController,
                        items: pics,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'PIC baru wajib ditentukan oleh Bagian Aset'
                            : null,
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
                            'Alur PRD V1.1: Pengajuan yang valid akan langsung diteruskan ke antrean Approval Pemimpin Divisi.',
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
              final success = await ref
                  .read(kabagApprovalActionProvider.notifier)
                  .approve(
                    mutationId: mutation.id,
                    newPic: needsPic ? picController.text.trim() : null,
                  );

              if (context.mounted) {
                if (success) {
                  AppFeedback.showSuccess(
                    context,
                    'Data aset diverifikasi dan diteruskan ke Pemimpin Divisi.',
                  );
                  _safePop(context, ref);
                } else {
                  final err = ref.read(kabagApprovalActionProvider).error;
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
