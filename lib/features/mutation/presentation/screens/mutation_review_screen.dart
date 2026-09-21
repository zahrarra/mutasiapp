// lib/features/mutation/presentation/screens/mutation_review_screen.dart
//
// Review pengajuan mutasi sebelum dikirim.
// Flow:
// Form Manual -> Review -> Submit -> Success
//
// CATATAN:
// Pengajuan menggunakan data aset yang diinput manual oleh Pemohon.
// Tidak ada pencarian AssetRepository pada proses submit.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../domain/repositories/mutation_repository.dart';
import '../providers/mutation_form_provider.dart';
import '../providers/mutation_provider.dart';

class MutationReviewScreen extends ConsumerWidget {
  const MutationReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(mutationFormProvider);
    final submitState = ref.watch(submitMutationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Review Pengajuan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Data Aset'),
            const SizedBox(height: AppSpacing.sm),

            _InfoCard(
              children: [
                _InfoRow(label: 'Nama Aset', value: formState.assetName),
                _InfoRow(label: 'Kode / Nomor Aset', value: formState.assetId),
                _InfoRow(
                  label: 'Lokasi Asal',
                  value: formState.sourceLocation,
                  isLast: true,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            const _SectionTitle('Detail Mutasi'),
            const SizedBox(height: AppSpacing.sm),

            _InfoCard(
              children: [
                _InfoRow(
                  label: 'Lokasi Tujuan',
                  value: formState.targetLocation,
                ),
                _InfoRow(label: 'PIC Baru', value: formState.targetPic),
                _InfoRow(label: 'Alasan Mutasi', value: formState.reason),
                _InfoRow(
                  label: 'Dokumen Pendukung',
                  value: formState.documentName ?? 'Tidak ada',
                  isLast: true,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Pastikan seluruh data pengajuan sudah benar '
                      'sebelum dikirim.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            CustomButton(
              label: 'Kirim Pengajuan',
              width: double.infinity,
              isLoading: submitState.isLoading,
              onPressed: submitState.isLoading
                  ? null
                  : () => _onSubmit(context, ref, formState),
            ),

            const SizedBox(height: AppSpacing.md),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: submitState.isLoading ? null : () => context.pop(),
                child: const Text('Kembali'),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Future<void> _onSubmit(
    BuildContext context,
    WidgetRef ref,
    MutationFormState formState,
  ) async {
    final notifier = ref.read(submitMutationProvider.notifier);

    final params = SubmitMutationParams(
      assetId: formState.assetId.trim(),
      assetName: formState.assetName.trim(),
      sourceLocation: formState.sourceLocation.trim(),
      targetLocation: formState.targetLocation.trim(),
      targetPic: formState.targetPic.trim(),
      reason: formState.reason.trim(),
      documentName: formState.documentName,
    );

    final mutation = await notifier.submit(params);

    if (!context.mounted) return;

    // Submit berhasil.
    //
    // mutation sudah merupakan object yang baru saja dibuat
    // oleh submitMutation(). Jadi tidak perlu memanggil
    // getMutationById() lagi.
    if (mutation != null) {
      final ticketNumber = mutation.ticketNumber;

      // Bersihkan form setelah data berhasil disimpan.
      ref.read(mutationFormProvider.notifier).reset();

      // Langsung menuju halaman sukses.
      context.go(
        '${RouteNames.pemohonSubmitSuccessPath}'
        '?ticket=${Uri.encodeComponent(ticketNumber)}',
      );
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
      child: Column(
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
          Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
