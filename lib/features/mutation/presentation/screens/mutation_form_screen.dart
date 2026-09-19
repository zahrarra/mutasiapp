// lib/features/mutation/presentation/screens/mutation_form_screen.dart
//
// Screen: Form Pengajuan Mutasi (REQ-004).
// Sumber: SCREEN-SPEC.md REQ-004, ROLE-FLOW.md §3.
//
// Langkah 2 dari alur Pengajuan Mutasi: isi lokasi tujuan, PIC baru,
// alasan, dan dokumen pendukung (opsional) untuk aset yang sudah dipilih
// di AssetSelectionScreen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/custom_button.dart';
import '../providers/mutation_form_provider.dart';

/// Screen form pengajuan mutasi (langkah 2 dari alur Pengajuan Mutasi).
class MutationFormScreen extends ConsumerWidget {
  const MutationFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(mutationFormProvider);
    final notifier = ref.read(mutationFormProvider.notifier);
    final locations = ref.watch(availableLocationsProvider);
    final pics = ref.watch(availablePicsProvider);

    final asset = formState.selectedAsset;

    if (asset == null) {
      // Guard: form diakses tanpa aset terpilih (mis. deep link langsung).
      return Scaffold(
        appBar: AppBar(title: const Text('Form Mutasi')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textDisabled),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Belum ada aset yang dipilih.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.md),
                CustomButton(
                  label: 'Pilih Aset',
                  onPressed: () => context.go(RouteNames.pemohonMutasiCreatePath),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Form Mutasi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Ringkasan Aset Terpilih ────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.infoContainer,
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                    child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asset.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '${asset.assetCode} · ${asset.location}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Ganti'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            _buildLabel('Lokasi Tujuan *'),
            const SizedBox(height: AppSpacing.xs),
            _buildDropdown(
              value: formState.targetLocation.isEmpty ? null : formState.targetLocation,
              hint: 'Pilih lokasi tujuan',
              items: locations,
              errorText: formState.fieldErrors['targetLocation'],
              onChanged: (val) => notifier.setTargetLocation(val ?? ''),
            ),
            const SizedBox(height: AppSpacing.lg),

            _buildLabel('Penanggung Jawab (PIC) Baru *'),
            const SizedBox(height: AppSpacing.xs),
            _buildDropdown(
              value: formState.targetPic.isEmpty ? null : formState.targetPic,
              hint: 'Pilih PIC baru',
              items: pics,
              errorText: formState.fieldErrors['targetPic'],
              onChanged: (val) => notifier.setTargetPic(val ?? ''),
            ),
            const SizedBox(height: AppSpacing.lg),

            _buildLabel('Alasan / Justifikasi Mutasi *'),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              initialValue: formState.reason,
              maxLines: 4,
              onChanged: notifier.setReason,
              decoration: InputDecoration(
                hintText: 'Jelaskan alasan mutasi aset ini...',
                errorText: formState.fieldErrors['reason'],
                contentPadding: const EdgeInsets.all(AppSpacing.md),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            _buildLabel('Dokumen Pendukung (Opsional)'),
            const SizedBox(height: AppSpacing.xs),
            InkWell(
              onTap: () {
                // Upload dokumen aktual memerlukan integrasi backend/storage
                // yang belum final (lihat TECHNICAL-DESIGN.md - Open Questions).
                // Untuk MVP, disimulasikan sebagai nama file statis.
                notifier.setDocumentName(
                  formState.documentName == null ? 'surat_pengantar.pdf' : null,
                );
              },
              borderRadius: BorderRadius.circular(AppRadius.button),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(
                    color: AppColors.border,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      formState.documentName != null
                          ? Icons.description
                          : Icons.upload_file_outlined,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        formState.documentName ?? 'Ketuk untuk melampirkan dokumen',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                    if (formState.documentName != null)
                      const Icon(Icons.close, size: 18, color: AppColors.textDisabled),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            CustomButton(
              label: 'Lanjut ke Review',
              width: double.infinity,
              onPressed: () {
                if (notifier.validate()) {
                  context.push(RouteNames.pemohonMutasiReviewPath);
                }
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
      );

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required String? errorText,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      hint: Text(hint, style: const TextStyle(color: AppColors.textDisabled, fontSize: 13)),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13))))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        errorText: errorText,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
