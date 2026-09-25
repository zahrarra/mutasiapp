// lib/features/asset/presentation/screens/asset_category_screen.dart
//
// Screen: Asset Categories & Approval Criteria (Admin Management).
// Sumber: ROLE-FLOW.md §10, SCREEN-SPEC.md, PRD.md §6.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../providers/asset_provider.dart';

class AssetCategoryScreen extends ConsumerWidget {
  const AssetCategoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(assetCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kategori Aset & Kriteria Approval'),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // ── Banner Threshold Kriteria Approval Kadiv ─────────────────
              Card(
                elevation: 0,
                color: AppColors.primaryContainer.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.tune_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Kriteria Approval Kepala Divisi (Kadiv)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Aturan penentuan jalur approval saat verifikasi oleh Operator:',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildCriteriaRow(
                        icon: Icons.alt_route_outlined,
                        title: 'Mutasi Antar-Cabang / Regional',
                        desc: 'Wajib melalui approval Kadiv setelah disetujui Kabag.',
                        badge: 'Jalur Kadiv',
                        badgeColor: AppColors.warning,
                      ),
                      const SizedBox(height: 6),
                      _buildCriteriaRow(
                        icon: Icons.payments_outlined,
                        title: 'Nilai Aset > Rp 50.000.000',
                        desc: 'Kategori enterprise atau server memerlukan persetujuan Kadiv.',
                        badge: 'Jalur Kadiv',
                        badgeColor: AppColors.warning,
                      ),
                      const SizedBox(height: 6),
                      _buildCriteriaRow(
                        icon: Icons.check_circle_outline,
                        title: 'Mutasi Internal Gedung / Satu Wilayah',
                        desc: 'Langsung ke antrean Staff Aset setelah disetujui Kabag.',
                        badge: 'Tanpa Kadiv',
                        badgeColor: AppColors.info,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Header Daftar Kategori ────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daftar Kategori (${categories.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    'Format Tiket: KATEGORI-TAHUN-URUT',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── List of Categories ─────────────────────────────────────────
              ...categories.map((cat) {
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.infoContainer,
                      child: Text(
                        cat.code,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.info,
                        ),
                      ),
                    ),
                    title: Text(
                      cat.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      cat.description ?? '-',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
        loading: () =>
            const LoadingIndicator(message: 'Memuat kategori aset...'),
        error: (err, stack) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(assetCategoriesProvider),
        ),
      ),
    );
  }

  Widget _buildCriteriaRow({
    required IconData icon,
    required String title,
    required String desc,
    required String badge,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: badgeColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
