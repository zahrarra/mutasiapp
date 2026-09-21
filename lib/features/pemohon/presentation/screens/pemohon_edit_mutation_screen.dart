// Edit pengajuan yang dikembalikan Operator, lalu resubmit.
// Untuk MVP: isi ulang form dengan data lama + submit sebagai pengajuan baru
// ATAU panggil API update jika repository sudah mendukung.
// Saat ini: prefill + submit ulang via SubmitMutationParams (aset sama).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../mutation/domain/usecases/update_mutation_usecase.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';

class PemohonEditMutationScreen extends ConsumerStatefulWidget {
  final String mutationId;

  const PemohonEditMutationScreen({super.key, required this.mutationId});

  @override
  ConsumerState<PemohonEditMutationScreen> createState() =>
      _PemohonEditMutationScreenState();
}

class _PemohonEditMutationScreenState
    extends ConsumerState<PemohonEditMutationScreen> {
  final _locationController = TextEditingController();
  final _picController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _prefilled = false;

  @override
  void dispose() {
    _locationController.dispose();
    _picController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _resubmit() async {
    final location = _locationController.text.trim();
    final pic = _picController.text.trim();
    final reason = _reasonController.text.trim();

    if (location.isEmpty || pic.isEmpty || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi, PIC, dan alasan wajib diisi')),
      );
      return;
    }

    // PENTING: pakai UpdateMutationUseCase (bukan SubmitMutationUseCase) agar
    // pengajuan yang sudah ada di-UPDATE di tempat (nomor tiket tetap sama),
    // bukan membuat tiket baru. Sumber: SCREEN-SPEC.md REQ-008.
    final mutation = await ref
        .read(updateMutationProvider.notifier)
        .submit(
          UpdateMutationParams(
            mutationId: widget.mutationId,
            targetLocation: location,
            targetPic: pic,
            reason: reason,
          ),
        );

    if (!mounted) return;
    if (mutation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengajuan berhasil dikirim ulang untuk verifikasi.'),
          backgroundColor: AppColors.success,
        ),
      );
      // Kembali ke detail mutasi yang sama (bukan layar sukses baru),
      // karena ini melanjutkan tiket yang sudah ada, bukan tiket baru.
      context.pop();
    } else {
      final err = ref.read(updateMutationProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Gagal mengirim ulang pengajuan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncDetail = ref.watch(mutationDetailProvider(widget.mutationId));
    final submitState = ref.watch(updateMutationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Pengajuan'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: asyncDetail.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (m) {
          if (!_prefilled) {
            _locationController.text = m.targetLocation;
            _picController.text = m.targetPic;
            _reasonController.text = m.reason;
            _prefilled = true;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (m.returnReason != null)
                  Card(
                    color: AppColors.warningContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        'Catatan Operator: ${m.returnReason}',
                        style: const TextStyle(color: AppColors.warning),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                Text('Aset: ${m.asset.name} (${m.asset.assetCode})'),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Lokasi Tujuan *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _picController,
                  decoration: const InputDecoration(
                    labelText: 'PIC Baru *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _reasonController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Alasan *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                ElevatedButton(
                  onPressed: submitState.isLoading ? null : () => _resubmit(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Ajukan Ulang'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
