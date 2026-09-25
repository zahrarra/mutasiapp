// lib/features/pemohon/presentation/screens/pemohon_edit_mutation_screen.dart
//
// Screen: Edit & Ajukan Ulang Pengajuan Mutasi yang Dikembalikan (REQ-008).
// Sumber: SCREEN-SPEC.md REQ-008, ROLE-FLOW.md §3.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/inline_searchable_dropdown.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../../../mutation/domain/usecases/update_mutation_usecase.dart';
import '../../../mutation/presentation/providers/mutation_form_provider.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';
import '../../../operator/presentation/providers/operator_verification_provider.dart';

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

  void _prefillData(Mutation m) {
    if (!_prefilled) {
      _locationController.text = m.targetLocation;
      _picController.text = m.targetPic;
      _reasonController.text = m.reason;
      _prefilled = true;
    }
  }

  Future<void> _resubmit() async {
    final location = _locationController.text.trim();
    final pic = _picController.text.trim();
    final reason = _reasonController.text.trim();

    if (location.isEmpty || pic.isEmpty || reason.isEmpty) {
      AppFeedback.showWarning(
        context,
        'Lokasi tujuan, PIC baru, dan alasan wajib diisi.',
      );
      return;
    }

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
      // Invalidate list dan detail agar UI langsung menampilkan status terbaru
      ref.invalidate(mutationListProvider);
      ref.invalidate(mutationDetailProvider(widget.mutationId));
      ref.invalidate(operatorAllMutationsProvider);

      AppFeedback.showSuccess(
        context,
        'Pengajuan berhasil diajukan ulang ke antrean verifikasi Operator.',
      );

      // Arahkan kembali ke Detail Mutasi atau Mutasi Saya
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        try {
          context.go(
            RouteNames.pemohonMutasiDetailPath.replaceFirst(':id', widget.mutationId),
          );
        } catch (_) {}
      }
    } else {
      final err = ref.read(updateMutationProvider).error;
      AppFeedback.showError(
        context,
        err ?? 'Gagal mengirim ulang pengajuan.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncDetail = ref.watch(mutationDetailProvider(widget.mutationId));
    final submitState = ref.watch(updateMutationProvider);
    final availableLocations = ref.watch(availableLocationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Pengajuan'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Kembali',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.pemohonMutasiPath);
            }
          },
        ),
      ),
      body: asyncDetail.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (m) {
          if (m.status != MutationStatus.returned) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 56,
                      color: AppColors.success,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Pengajuan ini berstatus "${m.status.displayName}".',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Pengajuan hanya dapat diedit ketika berstatus "Dikembalikan ke Pemohon".',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(
                            RouteNames.pemohonMutasiDetailPath
                                .replaceFirst(':id', m.id),
                          );
                        }
                      },
                      icon: const Icon(Icons.description_outlined),
                      label: const Text('Lihat Detail Mutasi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(200, 44),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(RouteNames.pemohonMutasiPath);
                        }
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Kembali'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(200, 44),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          _prefillData(m);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 1. Penjelasan Singkat Alur ─────────────────────────────────
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.infoContainer,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.info,
                        size: 20,
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alur Perbaikan & Pengajuan Ulang',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Pengajuan dikembalikan → Perbaiki data pengajuan → Ajukan ulang → Kembali ke antrean Operator untuk diverifikasi ulang.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── 2. Catatan Operator (Hanya jika returnReason sebenarnya ada) ──
                if (m.returnReason != null && m.returnReason!.trim().isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warningContainer,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.feedback_outlined,
                          color: AppColors.warning,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Catatan dari Operator:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.warning,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                m.returnReason!.trim(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── 3. Kartu Informasi Aset ───────────────────────────────────
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              m.asset.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Kode: ${m.asset.assetCode}  •  Tiket: ${m.ticketNumber}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'Lokasi Asal: ${m.currentLocation}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // ── 4. Form Field ─────────────────────────────────────────────
                InlineSearchableDropdown(
                  key: const Key('dropdown_edit_target_location'),
                  fieldKey: const Key('input_edit_target_location'),
                  labelText: 'Lokasi Tujuan *',
                  hintText: 'Pilih lokasi tujuan',
                  controller: _locationController,
                  items: availableLocations,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  key: const Key('input_edit_target_pic'),
                  controller: _picController,
                  decoration: const InputDecoration(
                    labelText: 'PIC Baru *',
                    hintText: 'Nama penanggung jawab baru',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  key: const Key('input_edit_reason'),
                  controller: _reasonController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Alasan / Justifikasi Mutasi *',
                    hintText: 'Jelaskan alasan atau perbaikan yang dilakukan...',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── 5. Tombol Aksi ────────────────────────────────────────────
                ElevatedButton(
                  key: const Key('btn_ajukan_ulang'),
                  onPressed: submitState.isLoading ? null : () => _resubmit(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: submitState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Ajukan Ulang',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  key: const Key('btn_kembali_dashboard'),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(
                        RouteNames.pemohonMutasiDetailPath.replaceFirst(
                          ':id',
                          m.id,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Kembali'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
