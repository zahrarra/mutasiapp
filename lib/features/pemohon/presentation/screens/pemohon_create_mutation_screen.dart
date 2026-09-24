// lib/features/pemohon/presentation/screens/pemohon_create_mutation_screen.dart
//
// Form pengajuan mutasi — aset diisi manual di form (tanpa halaman Pilih Aset).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/searchable_picker_bottom_sheet.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _assetNameController = TextEditingController();
  final _assetCodeController = TextEditingController();
  final _sourceLocationController = TextEditingController();
  final _currentPicController = TextEditingController();
  final _locationController = TextEditingController();
  final _picController = TextEditingController();
  final _reasonController = TextEditingController();
  String? _documentName;

  @override
  void dispose() {
    _assetNameController.dispose();
    _assetCodeController.dispose();
    _sourceLocationController.dispose();
    _currentPicController.dispose();
    _locationController.dispose();
    _picController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = ref.read(authStateProvider).user;

    final params = SubmitMutationParams(
      applicantId: user?.id,
      applicantName: user?.name,
      assetId: _assetCodeController.text.trim(),
      assetName: _assetNameController.text.trim(),
      sourceLocation: _sourceLocationController.text.trim(),
      targetLocation: _locationController.text.trim(),
      currentPic: _currentPicController.text.trim(),
      targetPic: _picController.text.trim(),
      reason: _reasonController.text.trim(),
      documentName: _documentName,
    );

    final mutation = await ref
        .read(submitMutationProvider.notifier)
        .submit(params);

    if (!mounted) return;

    if (mutation != null) {
      ref.invalidate(mutationListProvider);
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

  Future<void> _pickSourceLocation(List<String> locations) async {
    final selected = await SearchablePickerBottomSheet.show(
      context: context,
      title: 'Pilih Lokasi Asal',
      items: locations,
      selectedItem: _sourceLocationController.text.trim().isEmpty
          ? null
          : _sourceLocationController.text.trim(),
      searchHint: 'Cari lokasi asal...',
    );
    if (selected != null) {
      setState(() {
        _sourceLocationController.text = selected;
      });
    }
  }

  Future<void> _pickTargetLocation(List<String> locations) async {
    final selected = await SearchablePickerBottomSheet.show(
      context: context,
      title: 'Pilih Lokasi / Cabang Tujuan',
      items: locations,
      selectedItem: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      searchHint: 'Cari cabang tujuan...',
    );
    if (selected != null) {
      setState(() {
        _locationController.text = selected;
      });
    }
  }

  Future<void> _pickPic(List<String> pics) async {
    final currentPic = _currentPicController.text.trim();
    final quickActions = <String>[];
    if (currentPic.isNotEmpty) {
      quickActions.add(currentPic);
    }

    final selected = await SearchablePickerBottomSheet.show(
      context: context,
      title: 'Pilih Penanggung Jawab (PIC)',
      items: pics,
      selectedItem: _picController.text.trim().isEmpty
          ? null
          : _picController.text.trim(),
      searchHint: 'Cari nama PIC...',
      quickActions: quickActions,
    );
    if (selected != null) {
      setState(() {
        _picController.text = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(submitMutationProvider);
    final availableLocations = ref.watch(availableLocationsProvider);
    final availablePics = ref.watch(availablePicsProvider);

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
                decoration: InputDecoration(
                  labelText: 'Lokasi Asal *',
                  hintText: 'Pilih lokasi asal',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_drop_down),
                    onPressed: () => _pickSourceLocation(availableLocations),
                  ),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: AppSpacing.formFieldGap),
              TextFormField(
                controller: _currentPicController,
                decoration: const InputDecoration(
                  labelText: 'Nama Pengguna/Pemakai Aset Lama *',
                  hintText: 'Contoh: Budi Santoso (IT Dept)',
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
                decoration: InputDecoration(
                  labelText: 'Lokasi / Cabang Tujuan *',
                  hintText: 'Pilih cabang tujuan',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_drop_down),
                    onPressed: () => _pickTargetLocation(availableLocations),
                  ),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: AppSpacing.formFieldGap),
              TextFormField(
                controller: _picController,
                decoration: InputDecoration(
                  labelText: 'Penanggung Jawab (PIC) Tujuan *',
                  hintText: 'Pilih PIC lama atau PIC baru',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_drop_down),
                    onPressed: () => _pickPic(availablePics),
                  ),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              if (_currentPicController.text.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ActionChip(
                    avatar: const Icon(Icons.history, size: 16),
                    label: Text(
                      'Sama dengan Pemakai Lama: ${_currentPicController.text.trim()}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () {
                      setState(() {
                        _picController.text = _currentPicController.text.trim();
                      });
                    },
                  ),
                ),
              ],
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
