// lib/features/mutation/presentation/screens/asset_selection_screen.dart
//
// Screen: Pilih Aset untuk Pengajuan Mutasi (REQ-003).
// Sumber: SCREEN-SPEC.md REQ-003, ROLE-FLOW.md §3, TECHNICAL-DESIGN.md §23 (Asset Lock).
//
// Hanya menampilkan aset yang eligible (tidak locked) untuk mutasi.
// Aset yang sedang locked ditampilkan terpisah (read-only) agar Pemohon
// paham kenapa aset tersebut tidak bisa dipilih, alih-alih disembunyikan
// begitu saja.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../asset/domain/entities/asset.dart';
import '../../../asset/presentation/widgets/asset_card.dart';
import '../providers/mutation_form_provider.dart';
import '../providers/mutation_provider.dart';

/// Screen pemilihan aset (langkah 1 dari alur Pengajuan Mutasi).
class AssetSelectionScreen extends ConsumerStatefulWidget {
  const AssetSelectionScreen({super.key});

  @override
  ConsumerState<AssetSelectionScreen> createState() =>
      _AssetSelectionScreenState();
}

class _AssetSelectionScreenState extends ConsumerState<AssetSelectionScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allAssetsAsync = ref.watch(allUserAssetsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Pilih Aset')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.surface,
            child: TextField(
              controller: _searchController,
              onChanged: (val) =>
                  setState(() => _query = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Cari kode, nama, atau lokasi aset...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: allAssetsAsync.when(
              data: (assets) => _buildList(assets),
              loading: () =>
                  const LoadingIndicator(message: 'Memuat daftar aset...'),
              error: (err, _) => ErrorView(
                message: 'Gagal memuat daftar aset.\n${err.toString()}',
                onRetry: () => ref.invalidate(allUserAssetsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Asset> assets) {
    final filtered = _query.isEmpty
        ? assets
        : assets.where((a) {
            return a.name.toLowerCase().contains(_query) ||
                a.assetCode.toLowerCase().contains(_query) ||
                a.location.toLowerCase().contains(_query);
          }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: Text(
            'Tidak ada aset yang cocok dengan pencarian.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final eligible = filtered.where((a) => !a.isLocked).toList();
    final locked = filtered.where((a) => a.isLocked).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (eligible.isEmpty && locked.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.warningContainer,
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Semua aset Anda sedang memiliki mutasi aktif dan tidak dapat diajukan mutasi baru.',
                    style: TextStyle(fontSize: 12, color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ),
        for (final asset in eligible)
          AssetCard(asset: asset, onTap: () => _onAssetSelected(asset)),
        if (locked.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              'Aset Terkunci (Tidak Dapat Diajukan)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          for (final asset in locked)
            Opacity(opacity: 0.6, child: AssetCard(asset: asset, onTap: null)),
        ],
      ],
    );
  }

  void _onAssetSelected(Asset asset) {
    ref.read(mutationFormProvider.notifier).reset();
    ref.read(mutationFormProvider.notifier).selectAsset(asset);
    context.push(RouteNames.pemohonMutasiCreatePath);
  }
}
