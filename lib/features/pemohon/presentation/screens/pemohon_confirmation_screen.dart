// lib/features/pemohon/presentation/screens/pemohon_confirmation_screen.dart
//
// Screen: Konfirmasi Mutasi oleh Pemohon (REQ-009).
// Sumber: SCREEN-SPEC.md REQ-009, ROLE-FLOW.md §3, DESIGN.md.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';
import '../providers/pemohon_confirmation_provider.dart';

class PemohonConfirmationScreen extends ConsumerStatefulWidget {
  final String mutationId;

  const PemohonConfirmationScreen({
    super.key,
    required this.mutationId,
  });

  @override
  ConsumerState<PemohonConfirmationScreen> createState() =>
      _PemohonConfirmationScreenState();
}

class _PemohonConfirmationScreenState
    extends ConsumerState<PemohonConfirmationScreen> {
  @override
  Widget build(BuildContext context) {
    final asyncMutation =
        ref.watch(mutationDetailProvider(widget.mutationId));
    final actionState = ref.watch(pemohonConfirmationActionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Konfirmasi Mutasi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: asyncMutation.when(
        data: (mutation) =>
            _buildBody(context, ref, mutation, actionState),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Data belum dapat dimuat.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: () =>
                      ref.invalidate(mutationDetailProvider(widget.mutationId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    Mutation mutation,
    PemohonConfirmationActionState actionState,
  ) {
    final isPendingConfirmation =
        mutation.status == MutationStatus.pendingConfirmation;
    final isCompleted = mutation.status == MutationStatus.completed;

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Success Result Banner (setelah konfirmasi berhasil) ───
                    if (actionState.successMessage != null) ...[
                      _buildSuccessBanner(actionState.successMessage!),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // ─── Header Tiket & Status ────────────────────────────────
                    _buildTicketHeader(mutation),
                    const SizedBox(height: AppSpacing.md),

                    // ─── Info Banner ──────────────────────────────────────────
                    if (isPendingConfirmation)
                      _buildInfoBanner(),
                    if (isCompleted)
                      _buildCompletedBanner(),
                    if (isPendingConfirmation || isCompleted)
                      const SizedBox(height: AppSpacing.md),

                    // ─── Error Banner ─────────────────────────────────────────
                    if (actionState.error != null) ...[
                      _buildErrorBanner(actionState.error!),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // ─── Detail Aset ──────────────────────────────────────────
                    _buildSectionTitle('Detail Aset'),
                    const SizedBox(height: AppSpacing.sm),
                    _buildAssetCard(mutation),
                    const SizedBox(height: AppSpacing.md),

                    // ─── Hasil Mutasi ─────────────────────────────────────────
                    _buildSectionTitle('Hasil Mutasi'),
                    const SizedBox(height: AppSpacing.sm),
                    _buildMutationResultCard(mutation),
                    const SizedBox(height: AppSpacing.md),

                    // ─── Timeline ─────────────────────────────────────────────
                    _buildSectionTitle('Timeline Pengajuan'),
                    const SizedBox(height: AppSpacing.sm),
                    _buildTimeline(mutation),
                    const SizedBox(height: AppSpacing.md),

                    // ─── Alasan ───────────────────────────────────────────────
                    _buildSectionTitle('Alasan Mutasi'),
                    const SizedBox(height: AppSpacing.sm),
                    _buildReasonCard(mutation),

                    // Extra space for sticky action bar
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // ─── Sticky Action Bar ────────────────────────────────────────────
            if (isPendingConfirmation)
              _buildActionBar(context, ref, mutation, actionState),
          ],
        ),

        // ─── Loading Overlay ──────────────────────────────────────────────────
        if (actionState.isLoading)
          Container(
            color: Colors.black26,
            child: const Center(
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: AppSpacing.md),
                      Text(
                        'Memproses konfirmasi...',
                        style: TextStyle(fontWeight: FontWeight.w500),
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

  // ─── Header Tiket & Status ────────────────────────────────────────────────

  Widget _buildTicketHeader(Mutation mutation) {
    return Container(
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
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mutation.ticketNumber,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          _buildStatusBadge(mutation.status),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(MutationStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: status.color,
        ),
      ),
    );
  }

  // ─── Info / Completed Banners ─────────────────────────────────────────────

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.infoContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.info, size: 18),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text(
              'Data aset telah diperbarui oleh Staff Aset. Silakan periksa dan konfirmasi kesesuaian data.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.info,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.successContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: AppColors.success, size: 18),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text(
              'Konfirmasi telah diberikan. Mutasi aset telah selesai.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.success,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.successContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.error,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section Title ────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }

  // ─── Asset Card ───────────────────────────────────────────────────────────

  Widget _buildAssetCard(Mutation mutation) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.infoContainer,
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mutation.asset.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mutation.asset.assetCode,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _buildAssetInfoChip(
                Icons.category_outlined,
                mutation.asset.category.name,
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildAssetInfoChip(
                Icons.star_outline,
                mutation.asset.condition,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssetInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ─── Mutation Result Card (Lokasi & PIC) ──────────────────────────────────

  Widget _buildMutationResultCard(Mutation mutation) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lokasi
          _buildTransferRow(
            label: 'Lokasi',
            icon: Icons.location_on_outlined,
            fromValue: mutation.currentLocation,
            toValue: mutation.targetLocation,
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: AppSpacing.md),
          // PIC
          _buildTransferRow(
            label: 'Penanggung Jawab (PIC)',
            icon: Icons.person_outline,
            fromValue: mutation.currentPic,
            toValue: mutation.targetPic,
          ),
        ],
      ),
    );
  }

  Widget _buildTransferRow({
    required String label,
    required IconData icon,
    required String fromValue,
    required String toValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Text(
                  fromValue,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Icon(
                Icons.arrow_forward,
                size: 16,
                color: AppColors.secondary,
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.successContainer,
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Text(
                  toValue,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Timeline ─────────────────────────────────────────────────────────────

  Widget _buildTimeline(Mutation mutation) {
    final currentStatus = mutation.status;

    final steps = [
      _TimelineStep(
        label: 'Diajukan',
        subtitle:
            '${mutation.applicantName} · ${_formatDate(mutation.createdAt)}',
        isDone: true,
      ),
      _TimelineStep(
        label: 'Verifikasi Operator',
        subtitle: mutation.verifiedAt != null
            ? '${mutation.verifiedBy ?? 'Operator'} · ${_formatDate(mutation.verifiedAt!)}'
            : null,
        isDone: mutation.verifiedAt != null,
      ),
      _TimelineStep(
        label: 'Approval',
        subtitle: mutation.approvedAt != null
            ? '${mutation.approvedBy ?? 'Pejabat'} · ${_formatDate(mutation.approvedAt!)}'
            : (mutation.rejectedAt != null
                ? 'Ditolak'
                : null),
        isDone: mutation.approvedAt != null,
        isRejected: mutation.rejectedAt != null &&
            mutation.approvedAt == null,
      ),
      _TimelineStep(
        label: 'Update Data Aset',
        subtitle: (currentStatus == MutationStatus.pendingConfirmation ||
                currentStatus == MutationStatus.completed)
            ? 'Selesai'
            : null,
        isDone: currentStatus == MutationStatus.pendingConfirmation ||
            currentStatus == MutationStatus.completed,
      ),
      _TimelineStep(
        label: 'Konfirmasi Pemohon',
        subtitle: currentStatus == MutationStatus.completed ? 'Selesai' : null,
        isDone: currentStatus == MutationStatus.completed,
        isCurrent: currentStatus == MutationStatus.pendingConfirmation,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: steps.asMap().entries.map((entry) {
          final idx = entry.key;
          final step = entry.value;
          final isLast = idx == steps.length - 1;
          return _buildTimelineStep(step, isLast);
        }).toList(),
      ),
    );
  }

  Widget _buildTimelineStep(_TimelineStep step, bool isLast) {
    Color dotColor;
    IconData dotIcon;

    if (step.isRejected) {
      dotColor = AppColors.error;
      dotIcon = Icons.close;
    } else if (step.isDone) {
      dotColor = AppColors.success;
      dotIcon = Icons.check;
    } else if (step.isCurrent) {
      dotColor = AppColors.warning;
      dotIcon = Icons.radio_button_checked;
    } else {
      dotColor = AppColors.border;
      dotIcon = Icons.radio_button_unchecked;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: step.isDone || step.isCurrent || step.isRejected
                      ? dotColor.withOpacity(0.15)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: dotColor, width: 1.5),
                ),
                child: Icon(dotIcon, size: 13, color: dotColor),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: step.isCurrent
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: step.isRejected
                          ? AppColors.error
                          : step.isCurrent
                              ? AppColors.textPrimary
                              : step.isDone
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                    ),
                  ),
                  if (step.isCurrent)
                    const Text(
                      'Saat ini',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (step.subtitle != null)
                    Text(
                      step.subtitle!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
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

  // ─── Reason Card ─────────────────────────────────────────────────────────

  Widget _buildReasonCard(Mutation mutation) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        mutation.reason,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textPrimary,
          height: 1.5,
        ),
      ),
    );
  }

  // ─── Sticky Action Bar ────────────────────────────────────────────────────

  Widget _buildActionBar(
    BuildContext context,
    WidgetRef ref,
    Mutation mutation,
    PemohonConfirmationActionState actionState,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pertanyaan konfirmasi
          const Text(
            'Apakah data di atas sudah sesuai dengan kondisi fisik?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Tombol Sesuai (Primary)
          ElevatedButton.icon(
            onPressed: actionState.isLoading
                ? null
                : () => _onConfirmTap(context, ref, mutation),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('✓ Sesuai'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Tombol Tidak Sesuai (Outlined/Destructive)
          OutlinedButton.icon(
            onPressed: actionState.isLoading
                ? null
                : () => _onTidakSesuaiTap(context),
            icon: const Icon(Icons.info_outline, size: 18),
            label: const Text('Tidak Sesuai'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.warning,
              side: const BorderSide(color: AppColors.warning),
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Actions ─────────────────────────────────────────────────────────────

  Future<void> _onConfirmTap(
    BuildContext context,
    WidgetRef ref,
    Mutation mutation,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
              backgroundColor: AppColors.secondary,
            ),
            child: const Text('Ya, Konfirmasi'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final notifier = ref.read(pemohonConfirmationActionProvider.notifier);
    final success = await notifier.confirm(mutationId: widget.mutationId);

    if (!mounted) return;

    if (success) {
      // Refresh detail
      ref.invalidate(mutationDetailProvider(widget.mutationId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konfirmasi berhasil. Mutasi aset telah selesai.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      final state = ref.read(pemohonConfirmationActionProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error ?? 'Konfirmasi gagal. Coba lagi.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _onTidakSesuaiTap(BuildContext context) {
    // Flow "Tidak Sesuai" belum dikunci oleh PRD — hanya tampilkan dialog info.
    // Sumber: SCREEN-SPEC.md REQ-009: "Flow setelah 'Tidak Sesuai' belum dikunci karena merupakan Open Question pada PRD."
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.warning),
            SizedBox(width: AppSpacing.sm),
            Text('Informasi'),
          ],
        ),
        content: const Text(
          'Tindak lanjut untuk kondisi "Tidak Sesuai" sedang dalam proses finalisasi.\n\n'
          'Silakan hubungi Staff Aset atau atasan Anda untuk penanganan lebih lanjut.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// ─── Internal Model ──────────────────────────────────────────────────────────

class _TimelineStep {
  final String label;
  final String? subtitle;
  final bool isDone;
  final bool isCurrent;
  final bool isRejected;

  const _TimelineStep({
    required this.label,
    this.subtitle,
    this.isDone = false,
    this.isCurrent = false,
    this.isRejected = false,
  });
}
