// lib/features/admin/presentation/screens/admin_locations_screen.dart
//
// Screen: Kelola Lokasi & Unit oleh Admin (Full Functional CRUD).
// Terintegrasi langsung dengan LocationRepository & master data pengajuan mutasi.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../domain/entities/location_item.dart';
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

  void _showAddLocationDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isBranch = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Tambah Lokasi / Unit Baru'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lokasi / Unit *',
                      hintText: 'Misal: Lantai 5 — Ruang Direksi',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nama lokasi tidak boleh kosong'
                        : null,
                    onChanged: (val) {
                      if (val.toLowerCase().contains('cabang')) {
                        setDialogState(() => isBranch = true);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Keterangan Unit / Wilayah',
                      hintText: 'Misal: Kantor Pusat / Gedung Utama',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CheckboxListTile(
                    value: isBranch,
                    title: const Text(
                      'Unit Kerja Kantor Cabang Regional',
                      style: TextStyle(fontSize: 13),
                    ),
                    subtitle: const Text(
                      'Mutasi ke/dari cabang akan memerlukan eskalasi persetujuan Kadiv.',
                      style: TextStyle(fontSize: 11),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setDialogState(() => isBranch = val ?? false);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.of(dialogCtx).pop();

                final newLocation = LocationItem(
                  id: '',
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim().isNotEmpty
                      ? descCtrl.text.trim()
                      : (isBranch
                          ? 'Unit Kerja Kantor Cabang Regional'
                          : 'Unit Kerja Kantor Pusat'),
                  isBranch: isBranch,
                  isActive: true,
                );

                final result = await ref
                    .read(masterLocationsProvider.notifier)
                    .addLocation(newLocation);

                if (!context.mounted) return;
                if (result is Success<LocationItem>) {
                  AppFeedback.showSuccess(
                    context,
                    'Lokasi "${result.data.name}" berhasil ditambahkan.',
                    details:
                        'Lokasi baru kini otomatis tersedia pada form mutasi Pemohon dan verifikasi Operator.',
                  );
                } else if (result is AppFailure<LocationItem>) {
                  AppFeedback.showError(
                    context,
                    'Gagal Menambahkan Lokasi',
                    details: result.failure.message,
                  );
                }
              },
              child: const Text('Simpan Lokasi'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditLocationDialog(BuildContext context, LocationItem item) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: item.name);
    final descCtrl = TextEditingController(text: item.description ?? '');
    bool isBranch = item.isBranch;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Lokasi / Unit'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lokasi / Unit *',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nama lokasi tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Keterangan Unit / Wilayah',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CheckboxListTile(
                    value: isBranch,
                    title: const Text(
                      'Unit Kerja Kantor Cabang Regional',
                      style: TextStyle(fontSize: 13),
                    ),
                    subtitle: const Text(
                      'Mutasi ke/dari cabang akan memerlukan eskalasi persetujuan Kadiv.',
                      style: TextStyle(fontSize: 11),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setDialogState(() => isBranch = val ?? false);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.of(dialogCtx).pop();

                final updated = item.copyWith(
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  isBranch: isBranch,
                );

                final result = await ref
                    .read(masterLocationsProvider.notifier)
                    .updateLocation(updated);

                if (!context.mounted) return;
                if (result is Success<LocationItem>) {
                  AppFeedback.showSuccess(
                    context,
                    'Lokasi "${result.data.name}" berhasil diperbarui.',
                  );
                } else if (result is AppFailure<LocationItem>) {
                  AppFeedback.showError(
                    context,
                    'Gagal Memperbarui Lokasi',
                    details: result.failure.message,
                  );
                }
              },
              child: const Text('Simpan Perubahan'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteLocation(BuildContext context, LocationItem item) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hapus Lokasi'),
        content: Text(
          'Apakah Anda yakin ingin menghapus lokasi "${item.name}"?\n\n'
          'Lokasi yang terikat dengan histori mutasi atau aset aktif tidak dapat dihapus permanen. Gunakan fitur nonaktifkan jika lokasi sudah tidak digunakan.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final result = await ref
                  .read(masterLocationsProvider.notifier)
                  .deleteLocation(item.id);

              if (!context.mounted) return;
              if (result is Success<void>) {
                AppFeedback.showSuccess(
                  context,
                  'Lokasi "${item.name}" berhasil dihapus.',
                );
              } else if (result is AppFailure<void>) {
                AppFeedback.showError(
                  context,
                  'Penghapusan Ditolak',
                  details: result.failure.message,
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(masterLocationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lokasi & Unit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined),
            tooltip: 'Tambah Lokasi Baru',
            onPressed: () => _showAddLocationDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Informasi Unit',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Informasi Lokasi & Unit'),
                  content: const Text(
                    'Daftar lokasi master ini disinkronisasi ke seluruh formulir pengajuan mutasi Pemohon, verifikasi Operator, dan pemindahan fisik Staff Aset.',
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
      body: locationsAsync.when(
        data: (allLocations) {
          final filtered = allLocations.where((loc) {
            final q = _searchQuery.toLowerCase();
            return loc.name.toLowerCase().contains(q) ||
                (loc.description ?? '').toLowerCase().contains(q);
          }).toList();

          return Column(
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
                      'Total ${filtered.length} Lokasi (${filtered.where((l) => l.isActive).length} Aktif di Form)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        'Master Lokasi Aktif',
                        style: const TextStyle(
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
                          final isCabang = item.isBranch;

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                              side: BorderSide(
                                color: item.isActive
                                    ? AppColors.border
                                    : AppColors.error.withValues(alpha: 0.3),
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: !item.isActive
                                    ? const Color(0xFFF1F5F9)
                                    : isCabang
                                        ? AppColors.warningContainer
                                        : AppColors.infoContainer,
                                child: Icon(
                                  !item.isActive
                                      ? Icons.location_off_outlined
                                      : isCabang
                                          ? Icons.location_city_outlined
                                          : Icons.apartment_outlined,
                                  color: !item.isActive
                                      ? AppColors.textDisabled
                                      : isCabang
                                          ? AppColors.warning
                                          : AppColors.info,
                                  size: 20,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: item.isActive
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                        decoration: item.isActive
                                            ? null
                                            : TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: item.isActive
                                          ? AppColors.successContainer
                                          : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.pill,
                                      ),
                                    ),
                                    child: Text(
                                      item.isActive ? 'Aktif' : 'Nonaktif',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: item.isActive
                                            ? AppColors.success
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                item.description ??
                                    (isCabang
                                        ? 'Unit Kerja Kantor Cabang Regional'
                                        : 'Unit Kerja Kantor Pusat / Data Center'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      item.isActive
                                          ? Icons.toggle_on
                                          : Icons.toggle_off,
                                      color: item.isActive
                                          ? AppColors.success
                                          : AppColors.textDisabled,
                                      size: 28,
                                    ),
                                    tooltip: item.isActive
                                        ? 'Nonaktifkan Lokasi'
                                        : 'Aktifkan Lokasi',
                                    onPressed: () async {
                                      final newStatus = !item.isActive;
                                      final res = await ref
                                          .read(
                                              masterLocationsProvider.notifier)
                                          .toggleActive(item.id, newStatus);
                                      if (!context.mounted) return;
                                      if (res is Success<void>) {
                                        AppFeedback.showSuccess(
                                          context,
                                          newStatus
                                              ? 'Lokasi "${item.name}" diaktifkan.'
                                              : 'Lokasi "${item.name}" dinonaktifkan.',
                                        );
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                    ),
                                    tooltip: 'Edit Lokasi',
                                    onPressed: () => _showEditLocationDialog(
                                        context, item),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: AppColors.error,
                                    ),
                                    tooltip: 'Hapus Lokasi',
                                    onPressed: () => _confirmDeleteLocation(
                                        context, item),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const LoadingIndicator(message: 'Memuat data lokasi...'),
        error: (err, stack) => ErrorView(
          message: err.toString(),
          onRetry: () =>
              ref.read(masterLocationsProvider.notifier).loadLocations(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Tambah Lokasi'),
        onPressed: () => _showAddLocationDialog(context),
      ),
    );
  }
}
