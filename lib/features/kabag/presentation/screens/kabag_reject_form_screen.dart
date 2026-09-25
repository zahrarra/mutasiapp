// lib/features/kabag/presentation/screens/kabag_reject_form_screen.dart
//
// Screen: Form Penolakan Pengajuan Mutasi oleh Kabag Aset (KBG-004).
// Sumber: SCREEN-SPEC.md KBG-004, ROLE-FLOW.md §5, PRD.md §8 Aturan 7.

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
import '../providers/kabag_approval_provider.dart';

class KabagRejectFormScreen extends ConsumerStatefulWidget {
  final String mutationId;

  const KabagRejectFormScreen({
    super.key,
    required this.mutationId,
  });

  @override
  ConsumerState<KabagRejectFormScreen> createState() =>
      _KabagRejectFormScreenState();
}

class _KabagRejectFormScreenState extends ConsumerState<KabagRejectFormScreen> {
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
    final actionState = ref.watch(kabagApprovalActionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tolak Pengajuan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.kabagApprovalsPath);
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

                        // Form Label & Info
                        const Row(
                          children: [
                            Text(
                              'Alasan Penolakan',
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
                          'Sesuai aturan bisnis, penolakan mutasi oleh Kabag Aset wajib menyertakan alasan yang jelas.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Reason TextFormField
                        TextFormField(
                          key: const Key('input_alasan_penolakan'),
                          controller: _reasonController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText:
                                'Contoh: "Aset masih dibutuhkan di unit kerja saat ini untuk proyek berjalan."',
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
                              return 'Alasan penolakan wajib diisi.';
                            }
                            if (value.trim().length < 5) {
                              return 'Alasan penolakan terlalu pendek (minimal 5 karakter).';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Buttons: [ Batal ] & [ Tolak Pengajuan ]
                SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          key: const Key('btn_batal_tolak'),
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
                          key: const Key('btn_submit_tolak'),
                          onPressed: actionState.isLoading
                              ? null
                              : () => _submitReject(context),
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

  Future<void> _submitReject(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final reason = _reasonController.text.trim();
    final success = await ref
        .read(kabagApprovalActionProvider.notifier)
        .reject(mutationId: widget.mutationId, reason: reason);

    if (context.mounted) {
      if (success) {
        final currentMutation = ref.read(kabagApprovalActionProvider).result;
        ref.read(notificationProvider.notifier).notifyUser(
              targetUserId: currentMutation?.applicantId ?? 'usr_pemohon',
              targetRole: UserRole.pemohon,
              title: 'Pengajuan Ditolak Kabag Aset',
              message:
                  'Pengajuan ${currentMutation?.ticketNumber ?? widget.mutationId} ditolak oleh Kabag Aset: $reason',
              type: NotificationType.warning,
              relatedMutationId: widget.mutationId,
            );
        ref.invalidate(mutationDetailProvider(widget.mutationId));
        AppFeedback.showSuccess(
          context,
          'Pengajuan mutasi berhasil ditolak.',
        );
        // Pop back to list (pop KBG-004 and pop KBG-003 back to KBG-002 list)
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
        final err = ref.read(kabagApprovalActionProvider).error;
        AppFeedback.showError(
          context,
          err ?? 'Gagal menolak pengajuan.',
        );
      }
    }
  }
}
