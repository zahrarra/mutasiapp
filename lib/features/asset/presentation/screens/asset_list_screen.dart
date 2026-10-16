// lib/features/asset/presentation/screens/asset_list_screen.dart
//
// Screen: Daftar Aset & Pencarian.
// Sumber: SKILLS.md §7, SCREEN-SPEC.md, TECHNICAL-DESIGN.md §8.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/asset_status.dart';
import '../providers/asset_provider.dart';
import '../widgets/admin_create_asset_dialog.dart';
import '../widgets/asset_card.dart';
import '../../../../core/widgets/mutasiku_page_header.dart';

/// Screen daftar aset perusahaan dengan fitur pencarian & filter.
class AssetListScreen extends ConsumerWidget {
  const AssetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final isAdmin = user?.role == UserRole.admin;

    final assetListAsync = ref.watch(assetListProvider);
    final categoriesAsync = ref.watch(assetCategoriesProvider);
    final selectedCategory = ref.watch(assetCategoryFilterProvider);
    final selectedStatus = ref.watch(assetStatusFilterProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                final created = await AdminCreateAssetDialog.show(context);
                if (created == true) {
                  ref.invalidate(assetListProvider);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text(
                'Tambah Aset',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: const Color(0xFF0F3D56),
              foregroundColor: Colors.white,
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SafeArea(
            bottom: false,
            child: MutasiKuPageHeader(
              title: 'Daftar Aset MutasiKu',
              subtitle: 'Pencarian & inventaris mutasi aset terpadu',
              onBack: () => Navigator.of(context).pop(),
              trailing: isAdmin
                  ? ElevatedButton.icon(
                      onPressed: () async {
                        final created =
                            await AdminCreateAssetDialog.show(context);
                        if (created == true) {
                          ref.invalidate(assetListProvider);
                        }
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('+ Tambah Aset'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F3D56),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          // Search & Filter Header Section
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.surface,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: (val) {
                    ref.read(assetSearchQueryProvider.notifier).state = val;
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari kode, nama, lokasi, atau PIC aset...',
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
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Category Filter Chips
                categoriesAsync.when(
                  data: (categories) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Semua Kategori'),
                          selected: selectedCategory == null,
                          onSelected: (_) {
                            ref
                                    .read(assetCategoryFilterProvider.notifier)
                                    .state =
                                null;
                          },
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        ...categories.map((cat) {
                          final isSel = selectedCategory == cat.id;
                          return Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.xs,
                            ),
                            child: ChoiceChip(
                              label: Text(cat.name),
                              selected: isSel,
                              onSelected: (_) {
                                ref
                                    .read(assetCategoryFilterProvider.notifier)
                                    .state = isSel
                                    ? null
                                    : cat.id;
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                ),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Semua Status'),
                        selected: selectedStatus == null,
                        onSelected: (_) {
                          ref.read(assetStatusFilterProvider.notifier).state =
                              null;
                        },
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      ...AssetStatus.values.map((st) {
                        final isSel = selectedStatus == st;
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.xs),
                          child: FilterChip(
                            label: Text(st.displayName),
                            selected: isSel,
                            onSelected: (_) {
                              ref
                                  .read(assetStatusFilterProvider.notifier)
                                  .state = isSel
                                  ? null
                                  : st;
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Asset List Items
          Expanded(
            child: assetListAsync.when(
              data: (assets) {
                if (assets.isEmpty) {
                  return const Center(
                    child: Text(
                      'Tidak ada aset yang ditemukan.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: assets.length,
                  itemBuilder: (context, index) {
                    final asset = assets[index];
                    return AssetCard(
                      asset: asset,
                      onTap: () {
                        context.push('/assets/${asset.id}');
                      },
                    );
                  },
                );
              },
              loading: () =>
                  const LoadingIndicator(message: 'Memuat data aset...'),
              error: (err, stack) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.refresh(assetListProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
