// lib/features/mutation/presentation/screens/mutation_edit_screen.dart
//
// Screen: Edit Pengajuan Mutasi yang Dikembalikan (REQ-008).
// Sumber: SCREEN-SPEC.md REQ-008, ROLE-FLOW.md §3.
//
// Hanya dapat diakses untuk mutasi berstatus `returned`.
// Menggunakan mutationFormProvider untuk state form yang di-prefill
// dari data mutasi, lalu dikirim melalui updateMutationProvider.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../domain/entities/mutation.dart';
import '../../domain/entities/mutation_status.dart';
import '../../domain/usecases/update_mutation_usecase.dart';
import '../providers/mutation_form_provider.dart';
import '../providers/mutation_provider.dart';

/// Screen edit pengajuan mutasi yang dikembalikan Operator (REQ-008).
class MutationEditScreen extends ConsumerStatefulWidget {
  final String mutationId;

  const MutationEditScreen({super.key, required this.mutationId});

  @override
  ConsumerState<MutationEditScreen> createState() => _MutationEditScreenState();
}

class _MutationEditScreenState extends ConsumerState<MutationEditScreen> {
  bool _prefilled = false;
  late final TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  /// Mengisi form berdasarkan data mutasi yang dikembalikan.
  ///
  /// Tidak menggunakan selectAsset() karena form sekarang menggunakan
  /// input aset manual.
  void _prefillOnce(Mutation mutation) {
    if (_prefilled) return;

    _prefilled = true;

    final notifier = ref.read(mutationFormProvider.notifier);

    notifier.reset();

    // Data aset.
    notifier.setAssetName(mutation.asset.name);
    notifier.setAssetId(mutation.asset.assetCode);
    notifier.setSourceLocation(mutation.currentLocation);

    // Data mutasi.
    notifier.setTargetLocation(mutation.targetLocation);
    notifier.setTargetPic(mutation.targetPic);
    notifier.setReason(mutation.reason);

    if (mutation.documentName != null) {
      notifier.setDocumentName(mutation.documentName);
    }

    _reasonController.text = mutation.reason;
  }

  @override
  Widget build(BuildContext context) {
    final asyncMutation = ref.watch(mutationDetailProvider(widget.mutationId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Edit Pengajuan')),
      body: asyncMutation.when(
        data: (mutation) {
          if (mutation.status != MutationStatus.returned) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 48,
                      color: AppColors.textDisabled,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Pengajuan ini tidak dapat diedit karena statusnya\n'
                      'bukan "Dikembalikan ke Pemohon".',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    CustomButton(
                      label: 'Kembali',
                      onPressed: () => context.pop(),
                    ),
                  ],
                ),
              ),
            );
          }

          _prefillOnce(mutation);

          return _buildForm(context, mutation);
        },
        loading: () => const LoadingIndicator(),
        error: (err, _) => ErrorView(
          message: 'Gagal memuat data pengajuan.\n${err.toString()}',
          onRetry: () {
            ref.invalidate(mutationDetailProvider(widget.mutationId));
          },
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, Mutation mutation) {
    final formState = ref.watch(mutationFormProvider);
    final notifier = ref.read(mutationFormProvider.notifier);

    final locations = ref.watch(availableLocationsProvider);
    final pics = ref.watch(availablePicsProvider);

    final updateState = ref.watch(updateMutationProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alasan pengembalian.
          if (mutation.returnReason != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.warningContainer,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Alasan dikembalikan Operator: '
                      '${mutation.returnReason}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.warning,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Error update.
          if (updateState.error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Text(
                updateState.error!,
                style: const TextStyle(fontSize: 13, color: AppColors.error),
              ),
            ),

          // Informasi aset.
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${mutation.asset.name} · '
                    '${mutation.asset.assetCode}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Lokasi tujuan.
          const Text(
            'Lokasi Tujuan *',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.xs),

          DropdownButtonFormField<String>(
            initialValue: formState.targetLocation.isEmpty
                ? null
                : formState.targetLocation,
            isExpanded: true,
            items: locations
                .map(
                  (location) => DropdownMenuItem<String>(
                    value: location,
                    child: Text(location, style: const TextStyle(fontSize: 13)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              notifier.setTargetLocation(value ?? '');
            },
            decoration: InputDecoration(
              errorText: formState.fieldErrors['targetLocation'],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // PIC baru.
          const Text(
            'Penanggung Jawab (PIC) Baru *',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.xs),

          DropdownButtonFormField<String>(
            initialValue: formState.targetPic.isEmpty
                ? null
                : formState.targetPic,
            isExpanded: true,
            items: pics
                .map(
                  (pic) => DropdownMenuItem<String>(
                    value: pic,
                    child: Text(pic, style: const TextStyle(fontSize: 13)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              notifier.setTargetPic(value ?? '');
            },
            decoration: InputDecoration(
              errorText: formState.fieldErrors['targetPic'],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Alasan.
          const Text(
            'Alasan / Justifikasi Mutasi *',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.xs),

          TextFormField(
            controller: _reasonController,
            maxLines: 4,
            onChanged: notifier.setReason,
            decoration: InputDecoration(
              errorText: formState.fieldErrors['reason'],
              contentPadding: const EdgeInsets.all(AppSpacing.md),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xxxl),

          // Submit.
          CustomButton(
            label: 'Kirim Ulang Pengajuan',
            width: double.infinity,
            isLoading: updateState.isLoading,
            onPressed: updateState.isLoading ? null : () => _onSubmit(mutation),
          ),

          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Future<void> _onSubmit(Mutation mutation) async {
    final formNotifier = ref.read(mutationFormProvider.notifier);

    if (!formNotifier.validate()) {
      return;
    }

    final formState = ref.read(mutationFormProvider);

    final result = await ref
        .read(updateMutationProvider.notifier)
        .submit(
          UpdateMutationParams(
            mutationId: mutation.id,
            targetLocation: formState.targetLocation,
            targetPic: formState.targetPic,
            reason: formState.reason,
            documentName: formState.documentName,
          ),
        );

    if (!mounted) return;

    if (result != null) {
      ref.read(mutationFormProvider.notifier).reset();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengajuan berhasil dikirim ulang untuk verifikasi.'),
          backgroundColor: AppColors.success,
        ),
      );

      context.pop();
    }
  }
}
