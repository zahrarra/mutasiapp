// lib/features/mutation/presentation/screens/mutation_list_screen.dart
//
// Screen: Daftar Mutasi Saya (REQ-002).
// Sumber: SCREEN-SPEC.md REQ-002, ROLE-FLOW.md §3, WIREFRAME.md.
//
// Menampilkan seluruh riwayat pengajuan mutasi milik Pemohon yang sedang
// login, dengan status badge, dan akses cepat ke Buat Pengajuan Baru.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../domain/entities/mutation.dart';
import '../../domain/entities/mutation_status.dart';
import '../providers/mutation_provider.dart';

/// Screen daftar mutasi milik Pemohon (REQ-002: "Mutasi Saya").
class MutationListScreen extends ConsumerWidget {
  const MutationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mutationsAsync = ref.watch(mutationListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mutasi Saya'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Kembali',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.pemohonDashboardPath);
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.pemohonMutasiCreatePath),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Ajukan Mutasi'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(mutationListProvider),
        child: mutationsAsync.when(
          data: (mutations) => _buildList(context, mutations),
          loading: () => const LoadingIndicator(message: 'Memuat data mutasi...'),
          error: (err, _) => ErrorView(
            message: 'Gagal memuat data mutasi.\n${err.toString()}',
            onRetry: () => ref.invalidate(mutationListProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Mutation> mutations) {
    if (mutations.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: const _EmptyState(),
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.giant + AppSpacing.giant,
      ),
      itemCount: mutations.length,
      itemBuilder: (context, index) {
        final mutation = mutations[index];
        return _MutationListItem(mutation: mutation);
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.assignment_outlined,
              size: 56,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Belum ada pengajuan mutasi',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Tekan tombol "Ajukan Mutasi" untuk membuat\npengajuan mutasi aset pertama Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _MutationListItem extends StatelessWidget {
  final Mutation mutation;

  const _MutationListItem({required this.mutation});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => context.push(
          RouteNames.pemohonMutasiDetailPath.replaceFirst(':id', mutation.id),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      mutation.ticketNumber,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  _StatusChip(status: mutation.status),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                mutation.asset.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Row(
                children: [
                  const Icon(Icons.arrow_forward, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.xxs),
                  Expanded(
                    child: Text(
                      mutation.targetLocation,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (mutation.status == MutationStatus.returned) ...[
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warningContainer,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_note, size: 14, color: AppColors.warning),
                      const SizedBox(width: 4),
                      const Text(
                        'Perlu diperbaiki — ketuk untuk mengedit',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (mutation.status == MutationStatus.pendingConfirmation) ...[
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.infoContainer,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.touch_app_outlined, size: 14, color: AppColors.info),
                      const SizedBox(width: 4),
                      const Text(
                        'Menunggu konfirmasi Anda',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final MutationStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: status.color),
      ),
    );
  }
}
