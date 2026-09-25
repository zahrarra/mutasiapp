// lib/features/kadiv/presentation/screens/kadiv_reject_form_screen.dart
//
// Screen: Form Penolakan Pengajuan Mutasi oleh Kadiv (KDV-004).
// Sumber: SCREEN-SPEC.md KDV-004, ROLE-FLOW.md §6, PRD.md §8 Aturan 7.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../providers/kadiv_approval_provider.dart';

class KadivRejectFormScreen extends ConsumerStatefulWidget {
  final String mutationId;

  const KadivRejectFormScreen({
    super.key,
    required this.mutationId,
  });

  @override
  ConsumerState<KadivRejectFormScreen> createState() =>
      _KadivRejectFormScreenState();
}

class _KadivRejectFormScreenState extends ConsumerState<KadivRejectFormScreen> {
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
    final actionState = ref.watch(kadivApprovalActionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tolak Pengajuan (Kadiv)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _safePop(context),
        ),
      ),
      body: asyncMutation.when(
        data: (mutation) => Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ticket & Asset Context Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(AppRadius.card),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mutation.ticketNumber,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${mutation.asset.name} (${mutation.asset.id})',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Pemohon: ${mutation.applicantName} • Lokasi: ${mutation.currentLocation} → ${mutation.targetLocation}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (mutation.approvedBy != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Telah disetujui sebelumnya oleh: ${mutation.approvedBy}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Form Label & Info
                        const Row(
                          children: [
                            Text(
                              'Alasan Penolakan Kadiv',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '*',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        const Text(
                          'Sesuai aturan bisnis, penolakan mutasi oleh Kepala Divisi wajib menyertakan alasan yang jelas dan dapat dipertanggungjawabkan.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Reason TextFormField
                        TextFormField(
                          key: const Key('input_alasan_penolakan_kadiv'),
                          controller: _reasonController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText:
                                'Contoh: "Aset perangkat utama tidak diizinkan dialihkan ke cabang sebelum pengadaan unit pengganti rampung."',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding:
                                const EdgeInsets.all(AppSpacing.md),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.button),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.button),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.button),
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.button),
                              borderSide:
                                  const BorderSide(color: AppColors.error),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Alasan penolakan tidak boleh kosong.';
                            }
                            if (value.trim().length < 5) {
                              return 'Alasan penolakan minimal 5 karakter.';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Submit Button
                SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: actionState.isLoading
                              ? null
                              : () => _safePop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.button),
                            ),
                          ),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          key: const Key('btn_submit_tolak_kadiv'),
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
                                  'Tolak Pengajuan',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
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
    );
  }

  void _handleSubmit(BuildContext context, String mutationId) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final reason = _reasonController.text.trim();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Konfirmasi Penolakan Kadiv'),
          content: Text(
            'Apakah Anda yakin ingin menolak pengajuan ini dengan alasan:\n\n"$reason"',
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Kembali'),
            ),
            ElevatedButton(
              key: const Key('btn_confirm_tolak_kadiv_dialog'),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();

                final success = await ref
                    .read(kadivApprovalActionProvider.notifier)
                    .reject(
                      mutationId: mutationId,
                      reason: reason,
                    );

                if (context.mounted) {
                  if (success) {
                    ref.invalidate(mutationDetailProvider(mutationId));
                    AppFeedback.showSuccess(
                      context,
                      'Pengajuan mutasi berhasil ditolak.',
                    );
                    _safePopBackToList(context);
                  } else {
                    final err = ref.read(kadivApprovalActionProvider).error;
                    AppFeedback.showError(
                      context,
                      err ?? 'Gagal menolak pengajuan.',
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ya, Tolak'),
            ),
          ],
        );
      },
    );
  }

  void _safePopBackToList(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        try {
          context.go(RouteNames.kadivApprovalsPath);
        } catch (_) {}
      }
    } else {
      try {
        context.go(RouteNames.kadivApprovalsPath);
      } catch (_) {}
    }
  }

  void _safePop(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      try {
        context.go(RouteNames.kadivApprovalsPath);
      } catch (_) {
        // Fallback for tests without GoRouter ancestor
      }
    }
  }
}
