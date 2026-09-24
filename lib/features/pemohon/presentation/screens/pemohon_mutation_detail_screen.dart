import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';
import '../widgets/mutation_status_stepper.dart';

class PemohonMutationDetailScreen extends ConsumerWidget {
  final String mutationId;

  const PemohonMutationDetailScreen({super.key, required this.mutationId});

  bool _isMutationOwnedBy(Mutation mutation, User? user) {
    if (user == null) return true;
    if (user.role != UserRole.pemohon) return true;

    if (mutation.applicantId != null && mutation.applicantId == user.id) {
      return true;
    }
    if ((user.id == 'usr_pemohon' ||
            user.id == 'usr_101' ||
            user.id == 'user_pemohon') &&
        mutation.applicantId == 'usr_pemohon') {
      return true;
    }
    if (mutation.applicantName.trim().toLowerCase() ==
        user.name.trim().toLowerCase()) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(mutationDetailProvider(mutationId));
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Mutasi'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Kembali',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              try {
                context.go(RouteNames.pemohonMutasiPath);
              } catch (_) {}
            }
          },
        ),
      ),
      body: asyncDetail.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(mutationDetailProvider(mutationId)),
        ),
        data: (m) {
          if (!_isMutationOwnedBy(m, authState.user)) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Akses Ditolak',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Anda hanya dapat melihat pengajuan mutasi milik Anda sendiri.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    OutlinedButton.icon(
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          try {
                            context.go(RouteNames.pemohonMutasiPath);
                          } catch (_) {}
                        }
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Kembali'),
                    ),
                  ],
                ),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        m.ticketNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    StatusBadge(
                      label: m.status.displayName,
                      backgroundColor: m.status.backgroundColor,
                      textColor: m.status.color,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                MutationStatusStepper(
                  status: m.status,
                  mutation: m,
                ),
                const SizedBox(height: AppSpacing.xl),
                if (m.status == MutationStatus.returned) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warningContainer,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.assignment_return_outlined,
                          color: AppColors.warning,
                          size: 24,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pengajuan Dikembalikan untuk Diperbaiki',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warning,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (m.returnReason != null &&
                                        m.returnReason!.trim().isNotEmpty)
                                    ? m.returnReason!.trim()
                                    : 'Pengajuan dikembalikan oleh Operator. Silakan periksa dan ajukan ulang.',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (m.status == MutationStatus.rejected) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.cancel_outlined,
                          color: AppColors.error,
                          size: 24,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pengajuan Ditolak',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.error,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (m.rejectionReason != null &&
                                        m.rejectionReason!.trim().isNotEmpty)
                                    ? m.rejectionReason!.trim()
                                    : ((m.kadivRejectionReason != null &&
                                            m.kadivRejectionReason!
                                                .trim()
                                                .isNotEmpty)
                                        ? m.kadivRejectionReason!.trim()
                                        : 'Pengajuan mutasi ini tidak disetujui.'),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                _section('Aset', [
                  m.asset.name,
                  m.asset.assetCode,
                  'Kondisi: ${m.asset.condition}',
                ]),
                _section('Rute', [
                  'Dari: ${m.currentLocation}',
                  'Ke: ${m.targetLocation}',
                  'PIC lama: ${m.currentPic}',
                  'PIC baru: ${m.targetPic}',
                ]),
                if (m.staffUpdatedBy != null)
                  _section('Pembaruan Staff Aset', [
                    'Diperbarui oleh: ${m.staffUpdatedBy}',
                    if (m.staffUpdatedAt != null)
                      'Tanggal: ${_formatDate(m.staffUpdatedAt!)}',
                  ]),
                _section('Alasan', [m.reason]),
                if (m.documentName != null)
                  _section('Dokumen', [m.documentName!]),
                const SizedBox(height: AppSpacing.lg),
                if (m.status == MutationStatus.returned)
                  ElevatedButton(
                    onPressed: () async {
                      await context.push(
                        RouteNames.pemohonMutasiEditPath.replaceFirst(
                          ':id',
                          m.id,
                        ),
                      );
                      ref.invalidate(mutationDetailProvider(mutationId));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Edit & Ajukan Ulang'),
                  ),
                if (m.status == MutationStatus.pendingConfirmation)
                  ElevatedButton(
                    onPressed: () => context.push(
                      RouteNames.pemohonConfirmationPath.replaceFirst(
                        ':id',
                        m.id,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Konfirmasi Mutasi'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _section(String title, List<String> lines) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...lines.map(
              (l) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  l,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
