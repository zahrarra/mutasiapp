// lib/features/pemohon/presentation/screens/pemohon_create_mutation_screen.dart
//
// Form pengajuan mutasi — aset diisi manual di form (tanpa halaman Pilih Aset).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../mutation/domain/repositories/mutation_repository.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';

class PemohonCreateMutationScreen extends ConsumerStatefulWidget {
  const PemohonCreateMutationScreen({super.key});

  @override
  ConsumerState<PemohonCreateMutationScreen> createState() =>
      _PemohonCreateMutationScreenState();
}

class _PemohonCreateMutationScreenState
    extends ConsumerState<PemohonCreateMutationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _assetNameController = TextEditingController();
  final _assetCodeController = TextEditingController();
  final _sourceLocationController = TextEditingController();
  final _locationController = TextEditingController();
  final _picController = TextEditingController();
  final _reasonController = TextEditingController();
  String? _documentName;

  @override
  void dispose() {
    _assetNameController.dispose();
    _assetCodeController.dispose();
    _sourceLocationController.dispose();
    _locationController.dispose();
    _picController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final params = SubmitMutationParams(
      assetId: _assetCodeController.text.trim(),
      assetName: _assetNameController.text.trim(),
      sourceLocation: _sourceLocationController.text.trim(),
      targetLocation: _locationController.text.trim(),
      targetPic: _picController.text.trim(),
      reason: _reasonController.text.trim(),
      documentName: _documentName,
    );

    final mutation = await ref
        .read(submitMutationProvider.notifier)
        .submit(params);

    if (!mounted) return;

    if (mutation != null) {
      context.go(
        '${RouteNames.pemohonSubmitSuccessPath}'
        '?ticket=${Uri.encodeComponent(mutation.ticketNumber)}'
        '&id=${mutation.id}',
      );
    } else {
      final err = ref.read(submitMutationProvider).error;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(err ?? 'Gagal mengajukan mutasi')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(submitMutationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Form Pengajuan Mutasi'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.pemohonDashboardPath);
            }
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Data Aset',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _assetNameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Aset *',
                  hintText: 'Contoh: Laptop Dell Latitude 5420',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: AppSpacing.formFieldGap),
              TextFormField(
                controller: _assetCodeController,
                decoration: const InputDecoration(
                  labelText: 'Kode / Nomor Aset / Serial *',
                  hintText: 'Contoh: L-2024-0087',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: AppSpacing.formFieldGap),
              TextFormField(
                controller: _sourceLocationController,
                decoration: const InputDecoration(
                  labelText: 'Lokasi Asal *',
                  hintText: 'Contoh: Cabang Palu',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Data Mutasi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Lokasi / Cabang Tujuan *',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: AppSpacing.formFieldGap),
              TextFormField(
                controller: _picController,
                decoration: const InputDecoration(
                  labelText: 'Penanggung Jawab (PIC) Baru *',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: AppSpacing.formFieldGap),
              TextFormField(
                controller: _reasonController,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Alasan Mutasi *',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _documentName = 'SK_Mutasi.pdf');
                },
                icon: const Icon(Icons.attach_file),
                label: Text(_documentName ?? 'Pilih dokumen (opsional)'),
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: submitState.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: submitState.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Kirim Pengajuan Mutasi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
