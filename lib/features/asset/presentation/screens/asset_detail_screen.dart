// lib/features/asset/presentation/screens/asset_detail_screen.dart
//
// Screen: Detail Aset & Riwayat Mutasi.
// Sumber: SKILLS.md §7, SCREEN-SPEC.md, TECHNICAL-DESIGN.md §8.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../providers/asset_provider.dart';
import '../widgets/asset_status_badge.dart';

/// Screen detail aset dengan informasi spesifikasi & riwayat mutasi.
class AssetDetailScreen extends ConsumerWidget {
  final String assetId;

  const AssetDetailScreen({
    super.key,
    required this.assetId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetAsync = ref.watch(assetDetailProvider(assetId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Aset'),
      ),
      body: assetAsync.when(
        data: (asset) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Asset Header Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    side: BorderSide(
                      color: asset.isLocked ? AppColors.warning : AppColors.border,
                      width: asset.isLocked ? 1.5 : 1.0,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              asset.assetCode,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            ),
                            AssetStatusBadge(status: asset.status, isLocked: asset.isLocked),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          asset.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Kategori: ${asset.category.name}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        if (asset.isLocked) ...[
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.warningContainer,
                              borderRadius: BorderRadius.circular(AppRadius.button),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lock, color: AppColors.warning, size: 18),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    'Aset terkunci karena sedang berada dalam proses mutasi aktif (${asset.activeMutationTicket ?? "Mutasi Transaksi"}). Pengajuan mutasi baru tidak diperbolehkan.',
                                    style: const TextStyle(
                                      color: AppColors.warning,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
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
                const SizedBox(height: AppSpacing.lg),

                // Asset Specification Specs
                const Text(
                  'Spesifikasi & Lokasi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _SpecTile(
                        icon: Icons.location_on_outlined,
                        label: 'Lokasi Fisik',
                        value: asset.location,
                      ),
                      const Divider(height: 1, color: AppColors.border),
                      _SpecTile(
                        icon: Icons.person_outline,
                        label: 'Penanggung Jawab (PIC)',
                        value: asset.pic,
                      ),
                      const Divider(height: 1, color: AppColors.border),
                      _SpecTile(
                        icon: Icons.build_outlined,
                        label: 'Kondisi Aset',
                        value: asset.condition,
                      ),
                      const Divider(height: 1, color: AppColors.border),
                      _SpecTile(
                        icon: Icons.calendar_today_outlined,
                        label: 'Tahun Pengadaan',
                        value: asset.acquisitionYear.toString(),
                      ),
                      if (asset.serialNumber != null) ...[
                        const Divider(height: 1, color: AppColors.border),
                        _SpecTile(
                          icon: Icons.qr_code_outlined,
                          label: 'Nomor Seri Manufaktur',
                          value: asset.serialNumber!,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Mutation History Timeline
                const Text(
                  'Riwayat Mutasi & Perubahan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                if (asset.history.isEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Text(
                      'Belum ada riwayat mutasi untuk aset ini.',
                      style: TextStyle(color: AppColors.textDisabled, fontSize: 13),
                    ),
                  ),
                ] else ...[
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: asset.history.length,
                    itemBuilder: (context, index) {
                      final h = asset.history[index];
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Tiket: ${h.ticketNumber}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Text(
                                    '${h.date.day}/${h.date.month}/${h.date.year}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textDisabled,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Lokasi: ${h.previousLocation} → ${h.newLocation}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                              ),
                              Text(
                                'PIC: ${h.previousPic} → ${h.newPic}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                'Di-update oleh: ${h.updatedBy}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textDisabled),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const LoadingIndicator(message: 'Memuat detail aset...'),
        error: (err, stack) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(assetDetailProvider(assetId)),
        ),
      ),
    );
  }
}

class _SpecTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SpecTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 20),
      title: Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      ),
    );
  }
}
