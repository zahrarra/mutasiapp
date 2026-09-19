// lib/features/mutation/presentation/screens/mutation_review_screen.dart
//
// Screen: Review Pengajuan Mutasi sebelum submit (REQ-005).
// Sumber: SCREEN-SPEC.md REQ-005, ROLE-FLOW.md §3.
//
// Langkah 3 dari alur Pengajuan Mutasi: konfirmasi ulang seluruh data
// sebelum dikirim ke server (submitMutation).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/repositories/mutation_repository.dart';
import '../providers/mutation_form_provider.dart';
import '../providers/mutation_provider.dart';

/// Screen review pengajuan mutasi (langkah 3 dari alur Pengajuan Mutasi).
class MutationReviewScreen extends ConsumerWidget {
  const MutationReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(mutationFormProvider);
    final submitState = ref.watch(submitMutationProvider);
    final asset = formState.selectedAsset;

    if (asset == null) {
      // Guard: review diakses tanpa data form lengkap.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(RouteNames.pemohonMutasiCreatePath);
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Review Pengajuan')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.giant + AppSpacing.giant,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (submitState.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            submitState.error!,
                            style: const TextStyle(fontSize: 13, color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                const _SectionTitle('Aset yang Dimutasi'),
                const SizedBox(height: AppSpacing.sm),
                _InfoCard(
                  children: [
                    _InfoRow(label: 'Nama Aset', value: asset.name),
                    _InfoRow(label: 'Kode Aset', value: asset.assetCode),
                    _InfoRow(label: 'Kategori', value: asset.category.name),
                    _InfoRow(label: 'Lokasi Saat Ini', value: asset.location, isLast: true),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                const _SectionTitle('Detail Mutasi'),
                const SizedBox(height: AppSpacing.sm),
                _InfoCard(
                  children: [
                    _InfoRow(label: 'Lokasi Tujuan', value: formState.targetLocation, highlight: true),
                    _InfoRow(label: 'PIC Baru', value: formState.targetPic, highlight: true, isLast: true),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                const _SectionTitle('Alasan Mutasi'),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    formState.reason,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5),
                  ),
                ),

                if (formState.documentName != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  const _SectionTitle('Dokumen Pendukung'),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.description, color: AppColors.textSecondary),
                        const SizedBox(width: AppSpacing.sm),
                        Text(formState.documentName!, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
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
              child: ElevatedButton(
                onPressed: submitState.isLoading
                    ? null
                    : () => _onSubmit(context, ref, asset.id, formState),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                child: submitState.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Ajukan Mutasi', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSubmit(
    BuildContext context,
    WidgetRef ref,
    String assetId,
    MutationFormState formState,
  ) async {
    final notifier = ref.read(submitMutationProvider.notifier);
    final mutation = await notifier.submit(
      SubmitMutationParams(
        assetId: assetId,
        targetLocation: formState.targetLocation,
        targetPic: formState.targetPic,
        reason: formState.reason,
        documentName: formState.documentName,
      ),
    );

    if (!context.mounted) return;

    if (mutation != null) {
      ref.read(mutationFormProvider.notifier).reset();
      context.go(
        '${RouteNames.pemohonMutasiSuccessPath}?ticket=${Uri.encodeComponent(mutation.ticketNumber)}',
      );
    }
    // Jika gagal, error sudah ditampilkan lewat submitState.error di atas.
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
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
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
  final bool highlight;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                color: highlight ? AppColors.secondary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
