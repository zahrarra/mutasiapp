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
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';
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

                // Detail Fields
                _buildSectionCard([
                  _buildDetailRow('Pemohon', mutation.applicantName),
                  const Divider(height: AppSpacing.md, color: AppColors.border),
                  _buildDetailRow(
                    'Aset',
                    mutation.asset.name,
                    subtext:
                        'Kode: ${mutation.asset.id} • ${mutation.asset.category.name}',
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
                  _buildDocumentRow(mutation.documentName),
                  const Divider(height: AppSpacing.md, color: AppColors.border),
                  _buildDetailRow(
                      'Waktu Pengajuan', _formatDateTime(mutation.createdAt)),
                ]),
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
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Verifikasi'),
        content: Text(
          'Apakah Anda yakin data dan dokumen pengajuan ${mutation.ticketNumber} sudah valid dan lengkap?\n\nPengajuan akan diteruskan ke Kabag Aset.',
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
                  .verify(mutationId: mutation.id);

              if (context.mounted) {
                if (success) {
                  ref.invalidate(mutationDetailProvider(mutation.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pengajuan berhasil diverifikasi dan diteruskan ke Kabag Aset.'),
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
                  final err = ref.read(verificationActionProvider).error;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(err ?? 'Gagal memverifikasi pengajuan.'),
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
            child: const Text('Ya, Verifikasi Valid'),
          ),
        ],
      ),
    );
  }
}
