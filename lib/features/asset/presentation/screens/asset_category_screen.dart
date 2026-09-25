// lib/features/asset/presentation/screens/asset_category_screen.dart
//
// Screen: Kategori Aset & Konfigurasi Kriteria Approval Kadiv (Admin Management).
// Sumber: ROLE-FLOW.md §10, SCREEN-SPEC.md, PRD.md §6.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/config/business_config.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../domain/entities/asset_category.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../../core/widgets/custom_floating_nav_bar.dart';
import '../providers/asset_provider.dart';

class AssetCategoryScreen extends ConsumerStatefulWidget {
  const AssetCategoryScreen({super.key});

  @override
  ConsumerState<AssetCategoryScreen> createState() =>
      _AssetCategoryScreenState();
}

class _AssetCategoryScreenState extends ConsumerState<AssetCategoryScreen> {
  String _formatRupiah(double value) {
    final intVal = value.toInt();
    final s = intVal.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(s[i]);
    }
    return 'Rp $buffer';
  }

  void _showEditThresholdDialog(BuildContext context, double currentThreshold) {
    final formKey = GlobalKey<FormState>();
    final thresholdCtrl = TextEditingController(
      text: currentThreshold.toInt().toString(),
    );

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Ubah Threshold Approval Kadiv'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tentukan batas minimum nilai aset yang secara otomatis memerlukan eskalasi persetujuan Kepala Divisi (Kadiv):',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: thresholdCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Nilai Nominal Threshold (Rupiah) *',
                  prefixText: 'Rp ',
                  hintText: '50000000',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Threshold tidak boleh kosong';
                  }
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Threshold harus berupa angka positif';
                  }
                  return null;
                },
              ),
            ],
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
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final newThreshold = double.parse(thresholdCtrl.text.trim());
              Navigator.of(dialogCtx).pop();

              ref.read(kadivApprovalThresholdProvider.notifier).state =
                  newThreshold;

              AppFeedback.showSuccess(
                context,
                'Threshold approval Kadiv berhasil diperbarui.',
                details:
                    'Kini aset dengan estimasi nilai >= ${_formatRupiah(newThreshold)} akan otomatis mewajibkan persetujuan Kadiv saat diverifikasi Operator.',
              );
            },
            child: const Text('Simpan Threshold'),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Tambah Kategori Aset Baru'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Kode Kategori *',
                    hintText: 'Misal: MED, OTO, LAB',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Kode kategori tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Kategori *',
                    hintText: 'Misal: Peralatan Medis & Lab',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nama kategori tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi / Contoh Barang',
                    hintText: 'Misal: USG, Mikroskop, Timbangan Digital',
                  ),
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

              final newCat = AssetCategory(
                id: '',
                code: codeCtrl.text.trim().toUpperCase(),
                name: nameCtrl.text.trim(),
                description: descCtrl.text.trim().isNotEmpty
                    ? descCtrl.text.trim()
                    : null,
                isActive: true,
              );

              final repo = ref.read(assetRepositoryProvider);
              final result = await repo.addCategory(newCat);

              if (!context.mounted) return;
              if (result is Success<AssetCategory>) {
                ref.invalidate(assetCategoriesProvider);
                AppFeedback.showSuccess(
                  context,
                  'Kategori "${result.data.name}" (${result.data.code}) berhasil ditambahkan.',
                );
              } else if (result is AppFailure<AssetCategory>) {
                AppFeedback.showError(
                  context,
                  'Gagal Menambahkan Kategori',
                  details: result.failure.message,
                );
              }
            },
            child: const Text('Simpan Kategori'),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, AssetCategory cat) {
    final formKey = GlobalKey<FormState>();
    final codeCtrl = TextEditingController(text: cat.code);
    final nameCtrl = TextEditingController(text: cat.name);
    final descCtrl = TextEditingController(text: cat.description ?? '');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Edit Kategori: ${cat.code}'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Kode Kategori *',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Kode kategori tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Kategori *',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nama kategori tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi / Contoh Barang',
                  ),
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

              final updated = cat.copyWith(
                code: codeCtrl.text.trim().toUpperCase(),
                name: nameCtrl.text.trim(),
                description: descCtrl.text.trim(),
              );

              final repo = ref.read(assetRepositoryProvider);
              final result = await repo.updateCategory(updated);

              if (!context.mounted) return;
              if (result is Success<AssetCategory>) {
                ref.invalidate(assetCategoriesProvider);
                AppFeedback.showSuccess(
                  context,
                  'Kategori "${result.data.name}" berhasil diperbarui.',
                );
              } else if (result is AppFailure<AssetCategory>) {
                AppFeedback.showError(
                  context,
                  'Gagal Memperbarui Kategori',
                  details: result.failure.message,
                );
              }
            },
            child: const Text('Simpan Perubahan'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCategory(BuildContext context, AssetCategory cat) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hapus Kategori Aset'),
        content: Text(
          'Apakah Anda yakin ingin menghapus kategori "${cat.name}" (${cat.code})?\n\n'
          'Kategori yang terikat dengan aset master tidak dapat dihapus permanen. Gunakan opsi nonaktifkan jika kategori sudah tidak digunakan.',
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
              final repo = ref.read(assetRepositoryProvider);
              final result = await repo.deleteCategory(cat.id);

              if (!context.mounted) return;
              if (result is Success<void>) {
                ref.invalidate(assetCategoriesProvider);
                AppFeedback.showSuccess(
                  context,
                  'Kategori "${cat.name}" berhasil dihapus.',
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
    final categoriesAsync = ref.watch(assetCategoriesProvider);
    final currentThreshold = ref.watch(kadivApprovalThresholdProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      appBar: AppBar(
        title: const Text('Kategori Aset & Kriteria Approval'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Kategori Baru',
            onPressed: () => _showAddCategoryDialog(context),
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              100,
            ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                'Kriteria Approval Kadiv',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              side: const BorderSide(color: AppColors.primary),
                            ),
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            label: const Text(
                              'Ubah Threshold',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () => _showEditThresholdDialog(
                              context,
                              currentThreshold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Aturan penentuan otomatis jalur approval saat verifikasi oleh Operator:',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildCriteriaRow(
                        icon: Icons.payments_outlined,
                        title:
                            'Nilai Aset >= ${_formatRupiah(currentThreshold)} (Aktif)',
                        desc:
                            'Aset bernilai tinggi otomatis memerlukan persetujuan Kepala Divisi.',
                        badge: 'Jalur Kadiv',
                        badgeColor: AppColors.warning,
                      ),
                      const SizedBox(height: 6),
                      _buildCriteriaRow(
                        icon: Icons.alt_route_outlined,
                        title: 'Mutasi Antar-Cabang / Regional',
                        desc:
                            'Perpindahan lintas gedung/cabang memerlukan persetujuan Kadiv.',
                        badge: 'Jalur Kadiv',
                        badgeColor: AppColors.warning,
                      ),
                      const SizedBox(height: 6),
                      _buildCriteriaRow(
                        icon: Icons.check_circle_outline,
                        title:
                            'Nilai Aset < ${_formatRupiah(currentThreshold)} & Internal',
                        desc:
                            'Langsung ke antrean Staff Aset setelah disetujui Kabag.',
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
                  Expanded(
                    child: Text(
                      'Daftar Kategori (${categories.length}) • ${categories.where((c) => c.isActive).length} Aktif',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Format: KATEGORI-TAHUN-URUT',
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
                    side: BorderSide(
                      color: cat.isActive
                          ? AppColors.border
                          : AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cat.isActive
                          ? AppColors.infoContainer
                          : const Color(0xFFF1F5F9),
                      child: Text(
                        cat.code,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: cat.isActive
                              ? AppColors.info
                              : AppColors.textDisabled,
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            cat.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: cat.isActive
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              decoration: cat.isActive
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
                            color: cat.isActive
                                ? AppColors.successContainer
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            cat.isActive ? 'Aktif' : 'Nonaktif',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: cat.isActive
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      cat.description ?? '-',
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
                            cat.isActive ? Icons.toggle_on : Icons.toggle_off,
                            color: cat.isActive
                                ? AppColors.success
                                : AppColors.textDisabled,
                            size: 28,
                          ),
                          tooltip: cat.isActive
                              ? 'Nonaktifkan Kategori'
                              : 'Aktifkan Kategori',
                          onPressed: () async {
                            final newStatus = !cat.isActive;
                            final repo = ref.read(assetRepositoryProvider);
                            final res = await repo.toggleCategoryActive(
                              cat.id,
                              newStatus,
                            );
                            if (!context.mounted) return;
                            if (res is Success<void>) {
                              ref.invalidate(assetCategoriesProvider);
                              AppFeedback.showSuccess(
                                context,
                                newStatus
                                    ? 'Kategori "${cat.name}" diaktifkan.'
                                    : 'Kategori "${cat.name}" dinonaktifkan.',
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                          ),
                          tooltip: 'Edit Kategori',
                          onPressed: () =>
                              _showEditCategoryDialog(context, cat),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: AppColors.error,
                          ),
                          tooltip: 'Hapus Kategori',
                          onPressed: () =>
                              _confirmDeleteCategory(context, cat),
                        ),
                      ],
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Kategori'),
        onPressed: () => _showAddCategoryDialog(context),
      ),
      bottomNavigationBar: CustomFloatingNavBar.scaffoldBottomBar(
        items: RoleNavConfig.getNavItemsForRole(UserRole.admin),
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
