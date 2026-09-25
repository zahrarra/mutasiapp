// lib/features/admin/presentation/screens/admin_locations_screen.dart
//
// Screen: Kelola Lokasi & Unit oleh Admin.
// Sumber: ROLE-FLOW.md §2, SCREEN-SPEC.md.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../mutation/presentation/providers/mutation_form_provider.dart';

class AdminLocationsScreen extends ConsumerStatefulWidget {
  const AdminLocationsScreen({super.key});

  @override
  ConsumerState<AdminLocationsScreen> createState() =>
      _AdminLocationsScreenState();
}

class _AdminLocationsScreenState extends ConsumerState<AdminLocationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locations = ref.watch(availableLocationsProvider);
    final filtered = locations
        .where(
          (loc) => loc.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lokasi & Unit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Informasi Unit',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Informasi Lokasi & Unit'),
                  content: const Text(
                    'Daftar lokasi ini digunakan oleh seluruh role sistem pada formulir pengajuan, verifikasi, dan pemindahan fisik aset.',
                    style: TextStyle(fontSize: 13),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Tutup'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.surface,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari gedung, lantai, atau cabang...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
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
              onChanged: (val) {
                setState(() => _searchQuery = val.trim());
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Total Count Info
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total ${filtered.length} Lokasi Terdaftar',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const Text(
                    'Aktif',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List of Locations
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Lokasi tidak ditemukan.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isCabang = item.toLowerCase().contains('cabang');

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isCabang
                                ? AppColors.warningContainer
                                : AppColors.infoContainer,
                            child: Icon(
                              isCabang
                                  ? Icons.location_city_outlined
                                  : Icons.apartment_outlined,
                              color: isCabang
                                  ? AppColors.warning
                                  : AppColors.info,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            item,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            isCabang
                                ? 'Unit Kerja Kantor Cabang Regional'
                                : 'Unit Kerja Kantor Pusat / Data Center',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isCabang
                                  ? AppColors.warningContainer
                                  : AppColors.infoContainer,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              isCabang ? 'Cabang' : 'Pusat',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isCabang
                                    ? AppColors.warning
                                    : AppColors.info,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
