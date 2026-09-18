import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';
import '../widgets/mutation_status_stepper.dart';

class PemohonMutationDetailScreen extends ConsumerWidget {
  final String mutationId;

  const PemohonMutationDetailScreen({super.key, required this.mutationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(mutationDetailProvider(mutationId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Mutasi'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: asyncDetail.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(mutationDetailProvider(mutationId)),
        ),
        data: (m) {
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
                MutationStatusStepper(status: m.status),
                const SizedBox(height: AppSpacing.xxl),
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
                _section('Alasan', [m.reason]),
                if (m.documentName != null)
                  _section('Dokumen', [m.documentName!]),
                if (m.returnReason != null && m.returnReason!.isNotEmpty)
                  _section('Catatan pengembalian', [m.returnReason!]),
                if (m.rejectionReason != null && m.rejectionReason!.isNotEmpty)
                  _section('Alasan penolakan', [m.rejectionReason!]),
                const SizedBox(height: AppSpacing.lg),
                if (m.status == MutationStatus.returned)
                  ElevatedButton(
                    onPressed: () => context.push(
                      RouteNames.pemohonEditMutationPath.replaceFirst(
                        ':id',
                        m.id,
                      ),
                    ),
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
}
