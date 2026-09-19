// Pilih aset untuk dimutasi.
// Sumber: SCREEN-SPEC, ROLE-FLOW §3, desain Stitch.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../asset/domain/entities/asset.dart';
import '../../../mutation/presentation/providers/mutation_form_provider.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';

class PemohonSelectAssetScreen extends ConsumerStatefulWidget {
  const PemohonSelectAssetScreen({super.key});

  @override
  ConsumerState<PemohonSelectAssetScreen> createState() =>
      _PemohonSelectAssetScreenState();
}

class _PemohonSelectAssetScreenState
    extends ConsumerState<PemohonSelectAssetScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  Asset? _selected;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assetsAsync = ref.watch(allUserAssetsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pilih Aset'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: assetsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(allUserAssetsProvider),
        ),
        data: (assets) {
          final filtered = assets.where((a) {
            if (_query.isEmpty) return true;
            final q = _query.toLowerCase();
            return a.name.toLowerCase().contains(q) ||
                a.assetCode.toLowerCase().contains(q);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Cari nama atau kode aset...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final asset = filtered[index];
                    final locked = asset.isLocked;
                    final selected = _selected?.id == asset.id;

                    return Card(
                      elevation: 0,
                      color: selected
                          ? AppColors.infoContainer
                          : AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: selected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: ListTile(
                        enabled: !locked,
                        onTap: locked
                            ? null
                            : () => setState(() => _selected = asset),
                        leading: Icon(
                          locked ? Icons.lock_outline : Icons.devices,
                          color: locked
                              ? AppColors.textDisabled
                              : AppColors.primary,
                        ),
                        title: Text(
                          asset.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: locked
                                ? AppColors.textDisabled
                                : AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(asset.assetCode),
                            Text('${asset.location} • PIC: ${asset.pic}'),
                            if (locked)
                              Text(
                                'Dalam proses mutasi: ${asset.activeMutationTicket ?? "-"}',
                                style: const TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        trailing: locked
                            ? null
                            : Icon(
                                selected
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: AppColors.primary,
                              ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _selected == null
                          ? null
                          : () {
                              ref
                                  .read(mutationFormProvider.notifier)
                                  .selectAsset(_selected!);
                              context.push(RouteNames.pemohonCreateMutationPath);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Pilih Aset →'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
