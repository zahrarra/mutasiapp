import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';
import '../widgets/pemohon_mutation_card.dart';

enum _Filter { all, running, waitingConfirm }

class PemohonMutationListScreen extends ConsumerStatefulWidget {
  const PemohonMutationListScreen({super.key});

  @override
  ConsumerState<PemohonMutationListScreen> createState() =>
      _PemohonMutationListScreenState();
}

class _PemohonMutationListScreenState
    extends ConsumerState<PemohonMutationListScreen> {
  _Filter _filter = _Filter.all;

  List<Mutation> _applyFilter(List<Mutation> list) {
    switch (_filter) {
      case _Filter.all:
        return list;
      case _Filter.running:
        return list
            .where(
              (m) =>
                  m.status != MutationStatus.completed &&
                  m.status != MutationStatus.rejected &&
                  m.status != MutationStatus.pendingConfirmation,
            )
            .toList();
      case _Filter.waitingConfirm:
        return list
            .where((m) => m.status == MutationStatus.pendingConfirmation)
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(mutationListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mutasi Saya'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(mutationListProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.pemohonSelectAssetPath),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Pengajuan Baru'),
      ),
      body: asyncList.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(mutationListProvider),
        ),
        data: (list) {
          final filtered = _applyFilter(list);
          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    _chip('Semua', _Filter.all, list.length),
                    _chip(
                      'Berjalan',
                      _Filter.running,
                      list
                          .where(
                            (m) =>
                                m.status != MutationStatus.completed &&
                                m.status != MutationStatus.rejected &&
                                m.status != MutationStatus.pendingConfirmation,
                          )
                          .length,
                    ),
                    _chip(
                      'Menunggu Konfirmasi',
                      _Filter.waitingConfirm,
                      list
                          .where(
                            (m) =>
                                m.status == MutationStatus.pendingConfirmation,
                          )
                          .length,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('Belum ada pengajuan'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          80,
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, i) {
                          final m = filtered[i];
                          return PemohonMutationCard(
                            mutation: m,
                            onTap: () => context.push(
                              RouteNames.pemohonMutationDetailPath.replaceFirst(
                                ':id',
                                m.id,
                              ),
                            ),
                            trailingAction:
                                m.status == MutationStatus.pendingConfirmation
                                ? SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => context.push(
                                        RouteNames.pemohonConfirmationPath
                                            .replaceFirst(':id', m.id),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text(
                                        'Konfirmasi Penerimaan Aset',
                                      ),
                                    ),
                                  )
                                : null,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(String label, _Filter value, int count) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text('$label ($count)'),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textPrimary,
        ),
        checkmarkColor: Colors.white,
      ),
    );
  }
}
