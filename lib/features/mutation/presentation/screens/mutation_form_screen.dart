// lib/features/mutation/presentation/screens/mutation_form_screen.dart
//
// Screen: Form Pengajuan Mutasi (REQ-004).
// Pemohon menginput data aset secara manual.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/custom_button.dart';
import '../providers/mutation_form_provider.dart';
import '../../../../core/widgets/mutasiku_page_header.dart';

class MutationFormScreen extends ConsumerWidget {
  const MutationFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(mutationFormProvider);
    final notifier = ref.read(mutationFormProvider.notifier);
    final locations = ref.watch(availableLocationsProvider);
    final pics = ref.watch(availablePicsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SafeArea(
            bottom: false,
            child: MutasiKuPageHeader(
              title: 'Form Pengajuan Mutasi',
              subtitle: 'Input data aset dan lokasi tujuan mutasi',
              onBack: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Aset',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: AppSpacing.md),

            _buildLabel('Nama Aset *'),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              initialValue: formState.assetName,
              onChanged: notifier.setAssetName,
              decoration: InputDecoration(
                hintText: 'Contoh: Laptop Dell Latitude',
                errorText: formState.fieldErrors['assetName'],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            _buildLabel('Kode / Nomor Aset *'),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              initialValue: formState.assetId,
              onChanged: notifier.setAssetId,
              decoration: InputDecoration(
                hintText: 'Contoh: AST-ELK-2026-001',
                errorText: formState.fieldErrors['assetId'],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            _buildLabel('Lokasi Aset Saat Ini *'),
            const SizedBox(height: AppSpacing.xs),
            _buildDropdown(
              value: formState.sourceLocation.isEmpty
                  ? null
                  : formState.sourceLocation,
              hint: 'Pilih lokasi aset saat ini',
              items: locations,
              errorText: formState.fieldErrors['sourceLocation'],
              onChanged: (value) {
                notifier.setSourceLocation(value ?? '');
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            const Text(
              'Detail Mutasi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: AppSpacing.md),

            _buildLabel('Lokasi Tujuan *'),
            const SizedBox(height: AppSpacing.xs),
            _buildDropdown(
              value: formState.targetLocation.isEmpty
                  ? null
                  : formState.targetLocation,
              hint: 'Pilih lokasi tujuan',
              items: locations,
              errorText: formState.fieldErrors['targetLocation'],
              onChanged: (value) {
                notifier.setTargetLocation(value ?? '');
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            _buildLabel('Penanggung Jawab (PIC) Baru *'),
            const SizedBox(height: AppSpacing.xs),
            _buildDropdown(
              value: formState.targetPic.isEmpty ? null : formState.targetPic,
              hint: 'Pilih PIC baru',
              items: pics,
              errorText: formState.fieldErrors['targetPic'],
              onChanged: (value) {
                notifier.setTargetPic(value ?? '');
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            _buildLabel('Alasan / Justifikasi Mutasi *'),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              initialValue: formState.reason,
              maxLines: 4,
              onChanged: notifier.setReason,
              decoration: InputDecoration(
                hintText: 'Jelaskan alasan mutasi aset...',
                errorText: formState.fieldErrors['reason'],
                contentPadding: const EdgeInsets.all(AppSpacing.md),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            _buildLabel('Surat Keputusan (SK) SDM *'),
            const SizedBox(height: AppSpacing.xs),
            InkWell(
              onTap: () {
                notifier.setDocumentName(
                  formState.documentName == null ? 'SK_SDM_Mutasi.pdf' : null,
                );
              },
              borderRadius: BorderRadius.circular(AppRadius.button),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(
                    color: formState.fieldErrors['documentName'] != null
                        ? AppColors.error
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      formState.documentName != null
                          ? Icons.description
                          : Icons.upload_file_outlined,
                      color: formState.fieldErrors['documentName'] != null
                          ? AppColors.error
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        formState.documentName ??
                            'Pilih dokumen SK SDM (PDF wajib, maks 30 MB)',
                        style: TextStyle(
                          fontSize: 13,
                          color: formState.fieldErrors['documentName'] != null
                              ? AppColors.error
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (formState.documentName != null)
                      const Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.textDisabled,
                      ),
                  ],
                ),
              ),
            ),
            if (formState.fieldErrors['documentName'] != null) ...[
              const SizedBox(height: 4),
              Text(
                formState.fieldErrors['documentName']!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.error,
                ),
              ),
            ],

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
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required String? errorText,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      hint: Text(
        hint,
        style: const TextStyle(color: AppColors.textDisabled, fontSize: 13),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 13)),
            ),
          )
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
        ),
      ),
    );
  }
}
