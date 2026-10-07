// lib/features/bagian_aset/presentation/screens/bagian_aset_return_form_screen.dart
//
// Screen: Form Pengembalian Pengajuan Mutasi oleh Bagian Aset ke Pemohon.
// Sumber: PRD V1.1 §5, §6.4, §8 Aturan 13.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/mutasiku_page_header.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';
import '../providers/bagian_aset_verification_provider.dart';

class BagianAsetReturnFormScreen extends ConsumerStatefulWidget {
  final String mutationId;

  const BagianAsetReturnFormScreen({
    super.key,
    required this.mutationId,
  });

  @override
  ConsumerState<BagianAsetReturnFormScreen> createState() =>
      _BagianAsetReturnFormScreenState();
}

class _BagianAsetReturnFormScreenState
    extends ConsumerState<BagianAsetReturnFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncMutation = ref.watch(mutationDetailProvider(widget.mutationId));
    final actionState = ref.watch(bagianAsetVerificationActionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SafeArea(
            bottom: false,
            child: MutasiKuPageHeader(
              title: 'Kembalikan Pengajuan',
              subtitle: 'Tuliskan catatan perbaikan berkas untuk pemohon',
              onBack: () => _safePop(context),
            ),
          ),
          Expanded(
            child: asyncMutation.when(
              data: (mutation) => Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      // Header Card Info Mutasi
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    mutation.ticketNumber,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: mutation.status.backgroundColor,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.pill,
                                      ),
                                    ),
                                    child: Text(
                                      mutation.status.displayName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: mutation.status.color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                mutation.asset.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Pemohon: ${mutation.applicantName} • Asal: ${mutation.currentLocation} → ${mutation.targetLocation}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Input Catatan / Alasan Pengembalian
                      const Text(
                        'Alasan Pengembalian *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Jelaskan alasan ketidaksesuaian data aset, lokasi, atau kelengkapan SK SDM agar dapat diperbaiki oleh pemohon.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        key: const Key('input_alasan_penolakan'),
                        controller: _reasonController,
                        maxLines: 5,
                        maxLength: 500,
                        decoration: InputDecoration(
                          hintText:
                              'Contoh: Serial number aset tidak cocok dengan fisik, atau lokasi tujuan belum sesuai SK SDM.',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.input),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.input),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.input),
                            borderSide:
                                const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Alasan penolakan wajib diisi.';
                          }
                          if (value.trim().length < 5) {
                            return 'Alasan penolakan terlalu pendek (minimal 5 karakter).';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Tombol Konfirmasi
                      ElevatedButton(
                        key: const Key('btn_submit_tolak'),
                        onPressed: actionState.isLoading
                            ? null
                            : () => _handleSubmit(context, mutation.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.button),
                          ),
                        ),
                        child: actionState.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Kembalikan ke Pemohon',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton(
                        onPressed: () => _safePop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.button),
                          ),
                        ),
                        child: const Text('Batal'),
                      ),
                    ],
                  ),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text('Gagal memuat data mutasi: $err'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit(BuildContext context, String mutationId) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final reason = _reasonController.text.trim();

    final success = await ref
        .read(bagianAsetVerificationActionProvider.notifier)
        .returnToApplicant(
          mutationId: mutationId,
          reason: reason,
        );

    if (context.mounted) {
      if (success) {
        AppFeedback.showReturned(
          context,
          'Pengajuan mutasi berhasil dikembalikan.',
        );
        _safePop(context);
      } else {
        final err = ref.read(bagianAsetVerificationActionProvider).error;
        AppFeedback.showError(
          context,
          err ?? 'Gagal mengembalikan pengajuan.',
        );
      }
    }
  }

  void _safePop(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      try {
        context.go(RouteNames.bagianAsetVerificationsPath);
      } catch (_) {
        // Fallback for tests without GoRouter ancestor
      }
    }
  }
}
