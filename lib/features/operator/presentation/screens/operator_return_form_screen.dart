// lib/features/operator/presentation/screens/operator_return_form_screen.dart
//
// Screen: Form Pengembalian Pengajuan Mutasi oleh Operator (OPR-004).
// Sumber: SCREEN-SPEC.md OPR-004, ROLE-FLOW.md §4, PRD.md §6.3.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';
import '../../../notification/domain/entities/notification_item.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../providers/operator_verification_provider.dart';

class OperatorReturnFormScreen extends ConsumerStatefulWidget {
  final String mutationId;

  const OperatorReturnFormScreen({
    super.key,
    required this.mutationId,
  });

  @override
  ConsumerState<OperatorReturnFormScreen> createState() =>
      _OperatorReturnFormScreenState();
}

class _OperatorReturnFormScreenState
    extends ConsumerState<OperatorReturnFormScreen> {
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
    final actionState = ref.watch(verificationActionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kembalikan Pengajuan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.operatorMutationsPath);
            }
          },
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
                                'Pemohon: ${mutation.applicantName}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Form Header
                        const Text(
                          'Alasan Pengembalian',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        const Text(
                          'Jelaskan kekurangan data atau dokumen agar pemohon dapat memperbaikinya.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Reason TextFormField
                        TextFormField(
                          key: const Key('input_alasan_pengembalian'),
                          controller: _reasonController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Contoh: "Dokumen pendukung SK Mutasi belum dilampirkan atau tidak terbaca."',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                              borderSide:
                                  const BorderSide(color: AppColors.error),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Alasan pengembalian wajib diisi.';
                            }
                            if (value.trim().length < 5) {
                              return 'Alasan pengembalian terlalu pendek (minimal 5 karakter).';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Buttons: [ Batal ] & [ Kembalikan Pengajuan ]
                SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          key: const Key('btn_batal_kembalikan'),
                          onPressed: actionState.isLoading
                              ? null
                              : () => context.pop(),
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
                          key: const Key('btn_submit_kembalikan'),
                          onPressed: actionState.isLoading
                              ? null
                              : () => _submitReturn(context),
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
                                  'Kembalikan Pengajuan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
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
          child: Text('Gagal memuat pengajuan: $err'),
        ),
      ),
    );
  }

  Future<void> _submitReturn(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final reason = _reasonController.text.trim();
    final success = await ref
        .read(verificationActionProvider.notifier)
        .returnMutation(mutationId: widget.mutationId, reason: reason);

    if (context.mounted) {
      if (success) {
        final currentMutation = ref.read(verificationActionProvider).result;
        ref.read(notificationProvider.notifier).notifyUser(
              targetUserId: currentMutation?.applicantId ?? 'usr_pemohon',
              targetRole: UserRole.pemohon,
              title: 'Pengajuan Dikembalikan Operator',
              message:
                  'Pengajuan ${currentMutation?.ticketNumber ?? widget.mutationId} dikembalikan oleh Operator: $reason',
              type: NotificationType.warning,
              relatedMutationId: widget.mutationId,
            );
        ref.invalidate(mutationDetailProvider(widget.mutationId));
        AppFeedback.showSuccess(
          context,
          'Pengajuan berhasil dikembalikan ke Pemohon.',
        );
        // Pop back to list (pop return screen and pop detail screen)
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        } else {
          try {
            if (context.canPop()) {
              context.pop();
              if (context.canPop()) {
                context.pop();
              }
            }
          } catch (_) {}
        }
      } else {
        final err = ref.read(verificationActionProvider).error;
        AppFeedback.showError(
          context,
          err ?? 'Gagal mengembalikan pengajuan.',
        );
      }
    }
  }
}
