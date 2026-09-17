// lib/features/asset/presentation/screens/asset_category_screen.dart
//
// Screen: Asset Categories (Admin Management).
// Sumber: ROLE-FLOW.md §10, SCREEN-SPEC.md.

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
      appBar: AppBar(
        title: const Text('Kategori Aset'),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    cat.description ?? '-',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const LoadingIndicator(message: 'Memuat kategori aset...'),
        error: (err, stack) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(assetCategoriesProvider),
        ),
      ),
    );
  }
}
