// Edit pengajuan yang dikembalikan Operator, lalu resubmit.
// Untuk MVP: isi ulang form dengan data lama + submit sebagai pengajuan baru
// ATAU panggil API update jika repository sudah mendukung.
// Saat ini: prefill + submit ulang via SubmitMutationParams (aset sama).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../mutation/domain/repositories/mutation_repository.dart';
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

  Future<void> _resubmit(String assetId) async {
    final params = SubmitMutationParams(
      assetId: assetId,
      targetLocation: _locationController.text.trim(),
      targetPic: _picController.text.trim(),
      reason: _reasonController.text.trim(),
    );

    final mutation = await ref
        .read(submitMutationProvider.notifier)
        .submit(params);

    if (!mounted) return;
    if (mutation != null) {
      context.go(
        '${RouteNames.pemohonSubmitSuccessPath}?ticket=${Uri.encodeComponent(mutation.ticketNumber)}&id=${mutation.id}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncDetail = ref.watch(mutationDetailProvider(widget.mutationId));
    final submitState = ref.watch(submitMutationProvider);

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
                  onPressed: submitState.isLoading
                      ? null
                      : () => _resubmit(m.asset.id),
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
