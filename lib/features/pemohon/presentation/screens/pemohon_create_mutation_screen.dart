// Form pengajuan mutasi Pemohon.
// Sumber: ROLE-FLOW §3, SubmitMutationParams, mutation_form_provider.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../mutation/domain/repositories/mutation_repository.dart';
import '../../../mutation/presentation/providers/mutation_form_provider.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';

class PemohonCreateMutationScreen extends ConsumerStatefulWidget {
  const PemohonCreateMutationScreen({super.key});

  @override
  ConsumerState<PemohonCreateMutationScreen> createState() =>
      _PemohonCreateMutationScreenState();
}

class _PemohonCreateMutationScreenState
    extends ConsumerState<PemohonCreateMutationScreen> {
  final _locationController = TextEditingController();
  final _picController = TextEditingController();
  final _reasonController = TextEditingController();
  String? _documentName;

  @override
  void dispose() {
    _locationController.dispose();
    _picController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = ref.read(mutationFormProvider);
    final asset = form.selectedAsset;

    if (asset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih aset terlebih dahulu')),
      );
      return;
    }

    final location = _locationController.text.trim();
    final pic = _picController.text.trim();
    final reason = _reasonController.text.trim();

    if (location.isEmpty || pic.isEmpty || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi, PIC, dan alasan wajib diisi')),
      );
      return;
    }

    final params = SubmitMutationParams(
      assetId: asset.id,
      targetLocation: location,
      targetPic: pic,
      reason: reason,
      documentName: _documentName,
    );

    final mutation = await ref
        .read(submitMutationProvider.notifier)
        .submit(params);

    if (!mounted) return;

    if (mutation != null) {
      context.go(
        '${RouteNames.pemohonSubmitSuccessPath}?ticket=${Uri.encodeComponent(mutation.ticketNumber)}&id=${mutation.id}',
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
    final form = ref.watch(mutationFormProvider);
    final submitState = ref.watch(submitMutationProvider);
    final asset = form.selectedAsset;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Buat Pengajuan'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: asset == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Belum ada aset dipilih'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () =>
                        context.go(RouteNames.pemohonSelectAssetPath),
                    child: const Text('Pilih Aset'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 0,
                    color: AppColors.surface,
                    child: ListTile(
                      leading: const Icon(
                        Icons.devices,
                        color: AppColors.primary,
                      ),
                      title: Text(asset.name),
                      subtitle: Text('${asset.assetCode}\n${asset.location}'),
                      isThreeLine: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Lokasi / Cabang Tujuan *',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.formFieldGap),
                  TextField(
                    controller: _picController,
                    decoration: const InputDecoration(
                      labelText: 'Penanggung Jawab (PIC) Baru *',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.formFieldGap),
                  TextField(
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
    );
  }
}
