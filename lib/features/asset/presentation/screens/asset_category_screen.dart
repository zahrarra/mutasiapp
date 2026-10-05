// lib/features/asset/presentation/screens/asset_category_screen.dart
//
// Screen: Master Data & Tata Kelola Admin (Kategori Aset & Kriteria Approval)
// Sumber Visual: Stitch HTML "MutasiKu — Master Data & Tata Kelola Admin" (30d8b59bafad49a9ab9b3fbb9724136d)
// PRD & Role-Flow: PRD.md §6, ROLE-FLOW.md §10.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/config/business_config.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_floating_nav_bar.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mutation/presentation/providers/mutation_form_provider.dart';
import '../../domain/entities/asset_category.dart';
import '../providers/asset_provider.dart';
import '../../../../core/widgets/mutasiku_page_header.dart';

typedef AdminMasterDataScreen = AssetCategoryScreen;

class AssetCategoryScreen extends ConsumerStatefulWidget {
  const AssetCategoryScreen({super.key});

  @override
  ConsumerState<AssetCategoryScreen> createState() =>
      _AssetCategoryScreenState();
}

class _AssetCategoryScreenState extends ConsumerState<AssetCategoryScreen> {
  TextStyle _inter({
    double? size,
    FontWeight? w,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: w,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
    );
  }

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  String _activeFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final q = _searchController.text.trim().toLowerCase();
      if (q != _searchQuery) {
        setState(() => _searchQuery = q);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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
        title: Text('Ubah Threshold Approval Kadiv', style: _inter(size: 16, w: FontWeight.bold, color: const Color(0xFF0F172A))),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tentukan batas minimum nilai aset yang secara otomatis memerlukan eskalasi persetujuan Kepala Divisi (Kadiv):',
                style: _inter(size: 13, color: const Color(0xFF475569), height: 1.4),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: thresholdCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: _inter(size: 13, w: FontWeight.w500, color: const Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Nilai Nominal Threshold (Rupiah) *',
                  labelStyle: _inter(size: 13, color: const Color(0xFF64748B)),
                  prefixText: 'Rp ',
                  prefixStyle: _inter(size: 13, w: FontWeight.w600, color: const Color(0xFF0F172A)),
                  hintText: '50000000',
                  hintStyle: _inter(size: 13, color: const Color(0xFF94A3B8)),
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
            child: Text('Batal', style: _inter(size: 13, w: FontWeight.w600, color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F3D56),
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
            child: Text('Simpan Threshold', style: _inter(size: 13, w: FontWeight.bold, color: Colors.white)),
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
        title: Text('Tambah Kategori Aset Baru', style: _inter(size: 16, w: FontWeight.bold, color: const Color(0xFF0F172A))),
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
                  style: _inter(size: 13, w: FontWeight.w500, color: const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    labelText: 'Kode Kategori *',
                    labelStyle: _inter(size: 13, color: const Color(0xFF64748B)),
                    hintText: 'Misal: MED, OTO, LAB',
                    hintStyle: _inter(size: 13, color: const Color(0xFF94A3B8)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Kode kategori tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: nameCtrl,
                  style: _inter(size: 13, w: FontWeight.w500, color: const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    labelText: 'Nama Kategori *',
                    labelStyle: _inter(size: 13, color: const Color(0xFF64748B)),
                    hintText: 'Misal: Peralatan Medis & Lab',
                    hintStyle: _inter(size: 13, color: const Color(0xFF94A3B8)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nama kategori tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: descCtrl,
                  style: _inter(size: 13, w: FontWeight.w500, color: const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    labelText: 'Deskripsi / Contoh Barang',
                    labelStyle: _inter(size: 13, color: const Color(0xFF64748B)),
                    hintText: 'Misal: USG, Mikroskop, Timbangan Digital',
                    hintStyle: _inter(size: 13, color: const Color(0xFF94A3B8)),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('Batal', style: _inter(size: 13, w: FontWeight.w600, color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F3D56),
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
            child: Text('Simpan Kategori', style: _inter(size: 13, w: FontWeight.bold, color: Colors.white)),
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
        title: Text('Edit Kategori: ${cat.code}', style: _inter(size: 16, w: FontWeight.bold, color: const Color(0xFF0F172A))),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  style: _inter(size: 13, w: FontWeight.w500, color: const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    labelText: 'Kode Kategori *',
                    labelStyle: _inter(size: 13, color: const Color(0xFF64748B)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Kode kategori tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: nameCtrl,
                  style: _inter(size: 13, w: FontWeight.w500, color: const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    labelText: 'Nama Kategori *',
                    labelStyle: _inter(size: 13, color: const Color(0xFF64748B)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nama kategori tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: descCtrl,
                  style: _inter(size: 13, w: FontWeight.w500, color: const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    labelText: 'Deskripsi / Contoh Barang',
                    labelStyle: _inter(size: 13, color: const Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('Batal', style: _inter(size: 13, w: FontWeight.w600, color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F3D56),
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
            child: Text('Simpan Perubahan', style: _inter(size: 13, w: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCategory(BuildContext context, AssetCategory cat) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Hapus Kategori Aset', style: _inter(size: 16, w: FontWeight.bold, color: const Color(0xFF0F172A))),
        content: Text(
          'Apakah Anda yakin ingin menghapus kategori "${cat.name}" (${cat.code})?\n\n'
          'Kategori yang terikat dengan aset master tidak dapat dihapus permanen. Gunakan opsi nonaktifkan jika kategori sudah tidak digunakan.',
          style: _inter(size: 13, color: const Color(0xFF475569), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('Batal', style: _inter(size: 13, w: FontWeight.w600, color: const Color(0xFF64748B))),
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
            child: Text('Hapus', style: _inter(size: 13, w: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showQuickAddDataSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tambah Master Data',
                    style: _inter(
                      size: 16,
                      w: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.category, color: Color(0xFFB45309)),
                ),
                title: Text(
                  'Tambah Kategori Aset',
                  style: _inter(size: 13, w: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
                subtitle: Text(
                  'Tambah kode kategori dan klasifikasi aset baru',
                  style: _inter(size: 11, color: const Color(0xFF64748B)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddCategoryDialog(context);
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_add, color: Color(0xFF1D4ED8)),
                ),
                title: Text(
                  'Tambah Pengguna Baru',
                  style: _inter(size: 13, w: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
                subtitle: Text(
                  'Daftarkan NIP, nama, email, dan role sistem',
                  style: _inter(size: 11, color: const Color(0xFF64748B)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  try {
                    context.push(RouteNames.adminUsersPath);
                  } catch (_) {}
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDFA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_location_alt,
                      color: Color(0xFF0F766E)),
                ),
                title: Text(
                  'Tambah Unit Kerja / Lokasi',
                  style: _inter(size: 13, w: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
                subtitle: Text(
                  'Tambah KC, KCP, Kantor Pusat, atau Pool Gudang',
                  style: _inter(size: 11, color: const Color(0xFF64748B)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  try {
                    context.push(RouteNames.adminLocationsPath);
                  } catch (_) {}
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAuditSystemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.verified_user,
                        color: Color(0xFF047857), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Audit Tata Kelola Sistem',
                          style: _inter(
                            size: 15,
                            w: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Integritas data & sinkronisasi keamanan normal',
                          style: _inter(
                            size: 11,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildAuditRow(
                icon: Icons.check_circle_outline,
                color: const Color(0xFF10B981),
                title: 'Integritas Master Data',
                subtitle: '100% konsisten terhadap skema relasional',
              ),
              const SizedBox(height: 8),
              _buildAuditRow(
                icon: Icons.shield_outlined,
                color: const Color(0xFF0F3D56),
                title: 'Enkripsi & Keamanan SIPA',
                subtitle: 'Protokol enkripsi aktif dan tersertifikasi',
              ),
              const SizedBox(height: 8),
              _buildAuditRow(
                icon: Icons.gavel,
                color: const Color(0xFFB45309),
                title: 'Otorisasi Kadiv',
                subtitle: '3 aturan batas nominal & wilayah terverifikasi',
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F3D56),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Tutup Audit', style: _inter(size: 13, w: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRbacSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.security,
                        color: Color(0xFF047857), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Role & Hak Akses (RBAC)',
                          style: _inter(
                            size: 15,
                            w: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '5 Role MVP Sesuai PRD • 1 Role Per User',
                          style: _inter(
                            size: 11,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildRoleItem('Pemohon', 'Staff / Unit Kerja Pengaju Mutasi Aset'),
              _buildRoleItem('Operator', 'Verifikasi Dokumen & Cek Fisik Lapangan'),
              _buildRoleItem('Bagian Aset', 'Verifikator Kelengkapan & Penunjukan PIC'),
              _buildRoleItem('Pemimpin Divisi (Kadiv)', 'Otorisasi Final Nilai Tinggi & Antar Wilayah'),
              _buildRoleItem('Administrator', 'Master Data, Manajemen Pengguna & Tata Kelola'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: _inter(
                  size: 12,
                  color: const Color(0xFF334155),
                ),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: _inter(size: 12, w: FontWeight.bold, color: const Color(0xFF0F172A)),
                  ),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: _inter(
                  size: 12,
                  w: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                subtitle,
                style: _inter(
                  size: 11,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Tampilan Master Data',
                style: _inter(
                  size: 15,
                  w: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  'Semua',
                  'Kategori Aset',
                  'User Management',
                  'Unit Kerja',
                  'Regulasi Kadiv',
                ].map((f) {
                  final isSelected = _activeFilter == f;
                  return ChoiceChip(
                    label: Text(f),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() => _activeFilter = f);
                      Navigator.pop(ctx);
                    },
                    selectedColor: const Color(0xFF0F3D56),
                    labelStyle: _inter(
                      size: 12,
                      w: FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF334155),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(assetCategoriesProvider);
    final currentThreshold = ref.watch(kadivApprovalThresholdProvider);
    final usersAsync = ref.watch(masterUsersProvider);
    final locationsAsync = ref.watch(masterLocationsProvider);
    final totalUsersCount = usersAsync.maybeWhen(
      data: (users) => users.length,
      orElse: () => 142,
    );

    final totalLocationsCount = locationsAsync.maybeWhen(
      data: (locations) => locations.length,
      orElse: () => 34,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        // Responsive breakpoints: Mobile (360-430), Tablet (768-1024), Desktop (1280+)
        final bool isDesktop = availableWidth >= 1200;

        // Proportional horizontal padding
        final double horizontalPadding;
        if (availableWidth >= 1600) {
          horizontalPadding = 72.0;
        } else if (availableWidth >= 1200) {
          horizontalPadding = 48.0;
        } else if (availableWidth >= 768) {
          horizontalPadding = 28.0;
        } else {
          horizontalPadding = 16.0;
        }

        // Adaptive content maximum width (scales fluidly instead of rigid clamp)
        final double maxContentWidth;
        if (availableWidth >= 1600) {
          maxContentWidth = 1360.0;
        } else if (availableWidth >= 1280) {
          maxContentWidth = 1120.0;
        } else if (availableWidth >= 1024) {
          maxContentWidth = 920.0;
        } else if (availableWidth >= 768) {
          maxContentWidth = 720.0;
        } else {
          maxContentWidth = double.infinity;
        }

        Widget buildTambahButton() {
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F3D56),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            onPressed: () => _showQuickAddDataSheet(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, size: 18, color: Color(0xFF0F3D56)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Tambah Data',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _inter(
                      size: 13,
                      w: FontWeight.bold,
                      color: const Color(0xFF0F3D56),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        Widget buildAuditButton() {
          return OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            onPressed: () => _showAuditSystemSheet(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_user, size: 18, color: Colors.white),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Audit Sistem',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _inter(
                      size: 13,
                      w: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            textTheme: GoogleFonts.interTextTheme(theme.textTheme),
          ),
          child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          extendBody: true,
          body: Column(
            children: [
              SafeArea(
                bottom: false,
                child: MutasiKuPageHeader(
                  title: 'Kategori & Master Aset',
                  subtitle: 'Kelola Master Data & Tata Kelola Sistem MutasiKu',
                  roleLabel: 'MUTASIKU ADMIN',
                  onBack: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      try {
                        context.go(RouteNames.adminDashboardPath);
                      } catch (_) {}
                    }
                  },
                ),
              ),

              // ── Scrollable Body ─────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    isDesktop ? 16 : 12,
                    horizontalPadding,
                    110,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── 1. Hero Card: Ringkasan Master Data Sistem ──────
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(isDesktop ? 22 : 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F3D56),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x140F3D56),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'RINGKASAN MASTER DATA SISTEM',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: _inter(
                                              size: 11,
                                              w: FontWeight.bold,
                                              letterSpacing: 0.8,
                                              color: const Color(0xFFCBD5E1),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            spacing: 8,
                                            children: [
                                              Text(
                                                '$totalUsersCount',
                                                style: _inter(
                                                  size: isDesktop ? 32 : 28,
                                                  w: FontWeight.w800,
                                                  letterSpacing: -0.5,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              Text(
                                                'Pengguna & $totalLocationsCount Unit Terdaftar',
                                                style: _inter(
                                                  size: isDesktop ? 14 : 13,
                                                  w: FontWeight.w500,
                                                  color: const Color(0xFFE2E8F0),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: isDesktop ? 46 : 40,
                                      height: isDesktop ? 46 : 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.dns,
                                        size: isDesktop ? 26 : 22,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: isDesktop ? 16 : 12),
                                Container(
                                  height: 1,
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                                SizedBox(height: isDesktop ? 16 : 12),
                                availableWidth < 768
                                    ? Row(
                                        children: [
                                          Expanded(
                                            child: SizedBox(
                                              height: 40,
                                              child: buildTambahButton(),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: SizedBox(
                                              height: 40,
                                              child: buildAuditButton(),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          SizedBox(
                                            height: isDesktop ? 44 : 40,
                                            width: isDesktop ? 190 : 160,
                                            child: buildTambahButton(),
                                          ),
                                          const SizedBox(width: 12),
                                          SizedBox(
                                            height: isDesktop ? 44 : 40,
                                            width: isDesktop ? 190 : 160,
                                            child: buildAuditButton(),
                                          ),
                                        ],
                                      ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ── 2. Search Bar with Filter Icon (Stitch 1:1) ──────
                          Container(
                            height: isDesktop ? 48 : 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0A000000),
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 14),
                                Icon(
                                  Icons.search,
                                  size: isDesktop ? 20 : 18,
                                  color: const Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    style: _inter(
                                      size: isDesktop ? 14 : 13,
                                      w: FontWeight.w500,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Cari entitas master data, user, cabang...',
                                      hintStyle: _inter(
                                        size: isDesktop ? 14 : 13,
                                        w: FontWeight.w500,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                                Semantics(
                                  label: 'Filter',
                                  button: true,
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.tune,
                                      size: isDesktop ? 20 : 18,
                                      color: const Color(0xFF64748B),
                                    ),
                                    onPressed: () => _showFilterSheet(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ── 3. Notification / Alert Banner (amber-50) ──────
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(isDesktop ? 16 : 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              border: Border.all(
                                color: const Color(0xFFFDE68A),
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0A000000),
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: isDesktop ? 36 : 32,
                                  height: isDesktop ? 36 : 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.gavel,
                                    size: isDesktop ? 20 : 18,
                                    color: const Color(0xFFB45309),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '3 Kriteria Kadiv Aktif',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: _inter(
                                          size: isDesktop ? 13 : 12,
                                          w: FontWeight.bold,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        'Peraturan batas otorisasi transfer aset antar wilayah',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: _inter(
                                          size: isDesktop ? 12 : 11,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  height: isDesktop ? 36 : 32,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0F3D56),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: isDesktop ? 14 : 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () => _showEditThresholdDialog(
                                      context,
                                      currentThreshold,
                                    ),
                                    child: Text(
                                      'Atur Regulasi',
                                      style: _inter(
                                        size: isDesktop ? 12 : 11,
                                        w: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── 4. Daftar Modul Master Data (Vertical List) ─────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'Daftar Modul Master Data',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _inter(
                                    size: isDesktop ? 16 : 14,
                                    w: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {},
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Lihat Semua',
                                      style: _inter(
                                        size: isDesktop ? 13 : 12,
                                        w: FontWeight.w600,
                                        color: const Color(0xFF0F3D56),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      size: 16,
                                      color: Color(0xFF0F3D56),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Item 1: Kelola Pengguna (User Management)
                          _buildModuleListItem(
                            context: context,
                            icon: Icons.manage_accounts,
                            iconBg: const Color(0xFFEFF6FF),
                            iconColor: const Color(0xFF1D4ED8),
                            title: 'Kelola Pengguna (User Management)',
                            subtitle: '$totalUsersCount User Terdaftar • NIP & SSO Aktif',
                            badgeText: '100% Aktif',
                            badgeColor: const Color(0xFF047857),
                            badgeBg: const Color(0xFFECFDF5),
                            badgeBorder: const Color(0xFFA7F3D0),
                            isDesktop: isDesktop,
                            onTap: () {
                              try {
                                context.push(RouteNames.adminUsersPath);
                              } catch (_) {}
                            },
                          ),
                          const SizedBox(height: 10),

                          // Item 2: Role & Hak Akses (RBAC)
                          _buildModuleListItem(
                            context: context,
                            icon: Icons.security,
                            iconBg: const Color(0xFFECFDF5),
                            iconColor: const Color(0xFF047857),
                            title: 'Role & Hak Akses (RBAC)',
                            subtitle: '5 Role MVP Sesuai PRD • 1 Role Per User',
                            badgeText: 'Terkonfigurasi',
                            badgeColor: const Color(0xFF047857),
                            badgeBg: const Color(0xFFECFDF5),
                            badgeBorder: const Color(0xFFA7F3D0),
                            isDesktop: isDesktop,
                            onTap: () => _showRbacSheet(context),
                          ),
                          const SizedBox(height: 10),

                          // Item 3: Master Unit Kerja & Pool Cabang
                          _buildModuleListItem(
                            context: context,
                            icon: Icons.hub,
                            iconBg: const Color(0xFFF0FDFA),
                            iconColor: const Color(0xFF0F766E),
                            title: 'Master Unit Kerja & Pool Cabang',
                            subtitle:
                                'Kantor Pusat, $totalLocationsCount KC/KCP & 3 Pool Gudang',
                            badgeText: '$totalLocationsCount Lokasi',
                            badgeColor: const Color(0xFF0F3D56),
                            badgeBg: const Color(0xFFF1F5F9),
                            badgeBorder: const Color(0xFFCBD5E1),
                            isDesktop: isDesktop,
                            onTap: () {
                              try {
                                context.push(RouteNames.adminLocationsPath);
                              } catch (_) {}
                            },
                          ),
                          const SizedBox(height: 10),

                          // Item 4: Kriteria Approval Kadiv
                          _buildModuleListItem(
                            context: context,
                            icon: Icons.rule,
                            iconBg: const Color(0xFFFFFBEB),
                            iconColor: const Color(0xFFB45309),
                            title: 'Kriteria Approval Kadiv',
                            subtitle: 'Parameter Nilai Mutasi & Lintas Wilayah',
                            badgeText: '3 Aturan',
                            badgeColor: const Color(0xFFB45309),
                            badgeBg: const Color(0xFFFFFBEB),
                            badgeBorder: const Color(0xFFFDE68A),
                            isDesktop: isDesktop,
                            onTap: () => _showEditThresholdDialog(
                              context,
                              currentThreshold,
                            ),
                          ),
                      const SizedBox(height: 24),

                      // ── 5. Kategori Aset & Kriteria Approval Section ───
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Kategori Aset & Kriteria Approval',
                              style: _inter(
                                size: 14,
                                w: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F3D56),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.add, size: 16),
                            label: Text(
                              'Tambah Kategori',
                              style: _inter(
                                size: 11,
                                w: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            onPressed: () => _showAddCategoryDialog(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Sub-banner aturan approval Kadiv
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.verified_user_outlined,
                                      size: 16,
                                      color: Color(0xFF15803D),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Aturan Approval Kadiv',
                                      style: _inter(
                                        size: 12,
                                        w: FontWeight.bold,
                                        color: const Color(0xFF15803D),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  child: Text(
                                    'Batas: ${_formatRupiah(currentThreshold)}',
                                    style: _inter(
                                      size: 11,
                                      w: FontWeight.bold,
                                      color: const Color(0xFF166534),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Aset dengan nilai estimasi di atas batas nominal atau lintas wilayah otomatis memerlukan otorisasi Kepala Divisi (Kadiv).',
                              style: _inter(
                                size: 11,
                                color: const Color(0xFF475569),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Category items list
                      categoriesAsync.when(
                        data: (categories) {
                          final filteredCats = categories.where((cat) {
                            if (_searchQuery.isEmpty) return true;
                            return cat.name
                                    .toLowerCase()
                                    .contains(_searchQuery) ||
                                cat.code
                                    .toLowerCase()
                                    .contains(_searchQuery) ||
                                (cat.description ?? '')
                                    .toLowerCase()
                                    .contains(_searchQuery);
                          }).toList();

                          if (filteredCats.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFFE2E8F0)),
                              ),
                              child: Center(
                                child: Text(
                                  _searchQuery.isNotEmpty
                                      ? 'Tidak ada kategori matching "$_searchQuery"'
                                      : 'Belum ada kategori aset',
                                  style: _inter(
                                    size: 12,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: filteredCats.map((cat) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: cat.isActive
                                        ? const Color(0xFFE2E8F0)
                                        : const Color(0xFFFCA5A5),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x06000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: cat.isActive
                                            ? const Color(0xFFEFF6FF)
                                            : const Color(0xFFF1F5F9),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          cat.code,
                                          style: _inter(
                                            size: 11,
                                            w: FontWeight.bold,
                                            color: cat.isActive
                                                ? const Color(0xFF1D4ED8)
                                                : const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  cat.name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: _inter(
                                                    size: 13,
                                                    w: FontWeight.bold,
                                                    color: cat.isActive
                                                        ? const Color(
                                                            0xFF0F172A)
                                                        : const Color(
                                                            0xFF64748B),
                                                    decoration: cat.isActive
                                                        ? null
                                                        : TextDecoration
                                                            .lineThrough,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 1.5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: cat.isActive
                                                      ? const Color(0xFFDCFCE7)
                                                      : const Color(0xFFF1F5F9),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          9999),
                                                ),
                                                child: Text(
                                                  cat.isActive
                                                      ? 'Aktif'
                                                      : 'Nonaktif',
                                                  style: _inter(
                                                    size: 10,
                                                    w: FontWeight.bold,
                                                    color: cat.isActive
                                                        ? const Color(
                                                            0xFF15803D)
                                                        : const Color(
                                                            0xFF64748B),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            cat.description ??
                                                'Tidak ada deskripsi',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: _inter(
                                              size: 11,
                                              color: const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            cat.isActive
                                                ? Icons.toggle_on
                                                : Icons.toggle_off,
                                            color: cat.isActive
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFF94A3B8),
                                            size: 26,
                                          ),
                                          tooltip: cat.isActive
                                              ? 'Nonaktifkan Kategori'
                                              : 'Aktifkan Kategori',
                                          onPressed: () async {
                                            final newStatus = !cat.isActive;
                                            final repo = ref.read(
                                                assetRepositoryProvider);
                                            final res = await repo
                                                .toggleCategoryActive(
                                              cat.id,
                                              newStatus,
                                            );
                                            if (!context.mounted) return;
                                            if (res is Success<void>) {
                                              ref.invalidate(
                                                  assetCategoriesProvider);
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
                                            color: Color(0xFF64748B),
                                          ),
                                          tooltip: 'Edit Kategori',
                                          onPressed: () =>
                                              _showEditCategoryDialog(
                                            context,
                                            cat,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                            color: Color(0xFFEF4444),
                                          ),
                                          tooltip: 'Hapus Kategori',
                                          onPressed: () =>
                                              _confirmDeleteCategory(
                                            context,
                                            cat,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: LoadingIndicator(
                                message: 'Memuat kategori aset...'),
                          ),
                        ),
                        error: (err, stack) => ErrorView(
                          message: err.toString(),
                          onRetry: () =>
                              ref.refresh(assetCategoriesProvider),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomFloatingNavBar.scaffoldBottomBar(
        items: RoleNavConfig.getNavItemsForRole(UserRole.admin),
        currentRoute: RouteNames.adminCategoriesPath,
      ),
    ),
  );
  },
);
  }

  Widget _buildModuleListItem({
    required BuildContext context,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBg,
    required Color badgeBorder,
    required VoidCallback onTap,
    bool isDesktop = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 18 : 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: isDesktop ? 46 : 40,
              height: isDesktop ? 46 : 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: isDesktop ? 22 : 20,
                  color: iconColor,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _inter(
                      size: isDesktop ? 14 : 13,
                      w: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _inter(
                      size: isDesktop ? 12 : 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 10 : 8,
                vertical: isDesktop ? 3 : 2,
              ),
              decoration: BoxDecoration(
                color: badgeBg,
                border: Border.all(color: badgeBorder),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                badgeText,
                style: _inter(
                  size: isDesktop ? 12 : 11,
                  w: FontWeight.w600,
                  color: badgeColor,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}
