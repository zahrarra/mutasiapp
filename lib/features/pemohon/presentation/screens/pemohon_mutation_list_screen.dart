// lib/features/pemohon/presentation/screens/pemohon_mutation_list_screen.dart
//
// Screen: Daftar Mutasi Saya (REQ-002).
// Menampilkan daftar mutasi milik Pemohon dengan filter status interaktif dan navigasi back.

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
import '../widgets/mutation_filter_bottom_sheet.dart';
import '../widgets/pemohon_mutation_card.dart';

class PemohonMutationListScreen extends ConsumerStatefulWidget {
  const PemohonMutationListScreen({super.key});

  @override
  ConsumerState<PemohonMutationListScreen> createState() =>
      _PemohonMutationListScreenState();
}

class _PemohonMutationListScreenState
    extends ConsumerState<PemohonMutationListScreen> {
  MutationStatus? _selectedStatus;

  List<Mutation> _applyFilter(List<Mutation> list) {
    if (_selectedStatus == null) {
      return list;
    }
    return list.where((m) => m.status == _selectedStatus).toList();
  }

  Future<void> _openFilterBottomSheet(
    BuildContext context,
    List<Mutation> list,
  ) async {
    final Map<MutationStatus?, int> counts = {
      null: list.length,
    };
    for (final s in MutationStatus.values) {
      counts[s] = list.where((m) => m.status == s).length;
    }

    final selected = await showMutationFilterBottomSheet(
      context: context,
      currentStatus: _selectedStatus,
      counts: counts,
    );

    if (mounted) {
      setState(() {
        _selectedStatus = selected;
      });
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.tune,
              color: _selectedStatus != null
                  ? AppColors.primary
                  : AppColors.textPrimary,
            ),
            tooltip: 'Filter Status',
            onPressed: () {
              asyncList.whenData((list) {
                _openFilterBottomSheet(context, list);
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
            onPressed: () => ref.invalidate(mutationListProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.pemohonMutasiCreatePath),
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
              // ── Filter Chips Bar ──────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    _filterChip(
                      label: 'Semua',
                      status: null,
                      count: list.length,
                    ),
                    _filterChip(
                      label: 'Diajukan',
                      status: MutationStatus.submitted,
                      count: list
                          .where((m) => m.status == MutationStatus.submitted)
                          .length,
                    ),
                    _filterChip(
                      label: 'Menunggu Konfirmasi',
                      status: MutationStatus.pendingConfirmation,
                      count: list
                          .where(
                            (m) =>
                                m.status == MutationStatus.pendingConfirmation,
                          )
                          .length,
                    ),
                    _filterChip(
                      label: 'Dikembalikan',
                      status: MutationStatus.returned,
                      count: list
                          .where((m) => m.status == MutationStatus.returned)
                          .length,
                    ),
                    _filterChip(
                      label: 'Disetujui',
                      status: MutationStatus.approved,
                      count: list
                          .where((m) => m.status == MutationStatus.approved)
                          .length,
                    ),
                    _filterChip(
                      label: 'Selesai',
                      status: MutationStatus.completed,
                      count: list
                          .where((m) => m.status == MutationStatus.completed)
                          .length,
                    ),
                    _filterChip(
                      label: 'Ditolak',
                      status: MutationStatus.rejected,
                      count: list
                          .where((m) => m.status == MutationStatus.rejected)
                          .length,
                    ),
                    // Action button to open full filter modal
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: ActionChip(
                        avatar: Icon(
                          Icons.filter_list,
                          size: 16,
                          color: _selectedStatus != null
                              ? Colors.white
                              : AppColors.primary,
                        ),
                        label: Text(
                          _selectedStatus != null
                              ? 'Filter: ${_selectedStatus!.displayName}'
                              : 'Lainnya...',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _selectedStatus != null
                                ? Colors.white
                                : AppColors.primary,
                          ),
                        ),
                        backgroundColor: _selectedStatus != null
                            ? AppColors.primary
                            : AppColors.surface,
                        side: BorderSide(
                          color: _selectedStatus != null
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                        onPressed: () => _openFilterBottomSheet(context, list),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Active Filter Banner ──────────────────────────────
              if (_selectedStatus != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedStatus!.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedStatus!.color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_alt,
                        size: 16,
                        color: _selectedStatus!.color,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Menampilkan: ${_selectedStatus!.displayName} (${filtered.length} data)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _selectedStatus!.color,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => _selectedStatus = null),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: _selectedStatus!.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── List View ─────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size: 48,
                              color: AppColors.textDisabled,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedStatus != null
                                  ? 'Tidak ada mutasi dengan status "${_selectedStatus!.displayName}"'
                                  : 'Belum ada pengajuan mutasi',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            if (_selectedStatus != null) ...[
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _selectedStatus = null),
                                child: const Text('Hapus Filter'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          80,
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, i) {
                          final m = filtered[i];
                          return PemohonMutationCard(
                            mutation: m,
                            onTap: () => context.push(
                              RouteNames.pemohonMutasiDetailPath.replaceFirst(
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

  Widget _filterChip({
    required String label,
    required MutationStatus? status,
    required int count,
  }) {
    final isSelected = _selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text('$label ($count)'),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedStatus = status;
          });
        },
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
      ),
    );
  }
}
