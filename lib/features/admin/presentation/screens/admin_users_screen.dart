// lib/features/admin/presentation/screens/admin_users_screen.dart
//
// Screen: Kelola User & Permission oleh Admin (Full Functional CRUD).
// Terintegrasi langsung dengan AuthRepository & login system.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../../core/widgets/custom_floating_nav_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _getRolePermissions(UserRole role) {
    switch (role) {
      case UserRole.pemohon:
        return [
          'Ajukan Mutasi',
          'Edit Mutasi Dikembalikan',
          'Konfirmasi Fisik',
        ];
      case UserRole.operator:
        return [
          'Verifikasi Pengajuan',
          'Kembalikan Pengajuan',
          'Tentukan Jalur Kadiv',
        ];
      case UserRole.kabagAset:
        return [
          'Setujui Mutasi',
          'Tolak Mutasi',
          'Tinjau Riwayat Approval',
        ];
      case UserRole.kadiv:
        return [
          'Approval Tingkat Kadiv',
          'Tolak Mutasi',
          'Review Lintas Wilayah',
        ];
      case UserRole.staffAset:
        return [
          'Update Lokasi Fisik',
          'Update PIC Fisik',
          'Serah Terima Aset',
        ];
      case UserRole.admin:
        return [
          'Kelola Master Data',
          'Audit Log',
          'Kelola Role & Akses',
        ];
    }
  }

  void _showAddUserDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final deptCtrl = TextEditingController();
    UserRole selectedRole = UserRole.pemohon;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Tambah User Baru'),
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
                      labelText: 'Nama Lengkap *',
                      hintText: 'Misal: Andi Prasetyo',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nama tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: usernameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Username Login *',
                      hintText: 'Misal: andi_aset',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Username tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      hintText: 'andi@mutasiku.id',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Email tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: deptCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Divisi / Departemen *',
                      hintText: 'Misal: Bagian Logistik',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Departemen tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<UserRole>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(labelText: 'Role Akun *'),
                    items: UserRole.values.map((r) {
                      return DropdownMenuItem(
                        value: r,
                        child: Text(r.displayName),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedRole = val);
                      }
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

                final newUser = User(
                  id: '',
                  username: usernameCtrl.text.trim(),
                  name: nameCtrl.text.trim(),
                  role: selectedRole,
                  email: emailCtrl.text.trim(),
                  department: deptCtrl.text.trim(),
                  isActive: true,
                );

                final result = await ref
                    .read(masterUsersProvider.notifier)
                    .createUser(newUser);

                if (!context.mounted) return;
                if (result is Success<User>) {
                  AppFeedback.showSuccess(
                    context,
                    'User "${result.data.name}" berhasil ditambahkan.',
                    details:
                        'User kini dapat langsung digunakan untuk login dengan role ${selectedRole.displayName}.',
                  );
                } else if (result is AppFailure<User>) {
                  AppFeedback.showError(
                    context,
                    'Gagal Menambahkan User',
                    details: result.failure.message,
                  );
                }
              },
              child: const Text('Simpan User'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, User user) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: user.name);
    final emailCtrl = TextEditingController(text: user.email ?? '');
    final deptCtrl = TextEditingController(text: user.department ?? '');
    UserRole selectedRole = user.role;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Edit User: @${user.username}'),
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
                      labelText: 'Nama Lengkap *',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nama tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email *'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Email tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: deptCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Divisi / Departemen *',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Departemen tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<UserRole>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(labelText: 'Role Akun *'),
                    items: UserRole.values.map((r) {
                      return DropdownMenuItem(
                        value: r,
                        child: Text(r.displayName),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedRole = val);
                      }
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

                final updatedUser = user.copyWith(
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  department: deptCtrl.text.trim(),
                  role: selectedRole,
                );

                final result = await ref
                    .read(masterUsersProvider.notifier)
                    .updateUser(updatedUser);

                if (!context.mounted) return;
                if (result is Success<User>) {
                  AppFeedback.showSuccess(
                    context,
                    'Data user "${result.data.username}" berhasil diperbarui.',
                  );
                } else if (result is AppFailure<User>) {
                  AppFeedback.showError(
                    context,
                    'Gagal Memperbarui User',
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

  void _confirmDeleteUser(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hapus Pengguna'),
        content: Text(
          'Apakah Anda yakin ingin menghapus user "${user.name}" (@${user.username})?\n\n'
          'Perhatian: User dengan riwayat aktivitas mutasi tidak dapat dihapus permanen untuk menjaga integritas data.',
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
                  .read(masterUsersProvider.notifier)
                  .deleteUser(user.id);

              if (!context.mounted) return;
              if (result is Success<void>) {
                AppFeedback.showSuccess(
                  context,
                  'User "${user.name}" berhasil dihapus.',
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
    final usersAsync = ref.watch(masterUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      appBar: AppBar(
        title: const Text('User & Permission'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            tooltip: 'Tambah User Baru',
            onPressed: () => _showAddUserDialog(context),
          ),
        ],
      ),
      body: usersAsync.when(
        data: (allUsers) {
          final filtered = allUsers.where((u) {
            final name = u.name.toLowerCase();
            final username = u.username.toLowerCase();
            final dept = (u.department ?? '').toLowerCase();
            final q = _searchQuery.toLowerCase();
            return name.contains(q) || username.contains(q) || dept.contains(q);
          }).toList();

          return Column(
            children: [
              // Search Field
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                color: AppColors.surface,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari user, username, atau divisi...',
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

              // Total Count
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
                      '${filtered.length} Pengguna Terdaftar (${filtered.where((u) => u.isActive).length} Aktif)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Text(
                      '6 Role RBAC Terdaftar',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // User List
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'User tidak ditemukan.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.md,
                          100,
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final user = filtered[index];
                          final role = user.role;
                          final permissions = _getRolePermissions(role);

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                              side: BorderSide(
                                color: user.isActive
                                    ? AppColors.border
                                    : AppColors.error.withValues(alpha: 0.3),
                              ),
                            ),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: user.isActive
                                    ? AppColors.primaryContainer
                                    : const Color(0xFFF1F5F9),
                                child: Icon(
                                  user.isActive
                                      ? Icons.person_outline
                                      : Icons.person_off_outlined,
                                  color: user.isActive
                                      ? AppColors.primary
                                      : AppColors.textDisabled,
                                  size: 20,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      user.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: user.isActive
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                        decoration: user.isActive
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
                                      color: user.isActive
                                          ? AppColors.successContainer
                                          : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.pill,
                                      ),
                                    ),
                                    child: Text(
                                      user.isActive ? 'Aktif' : 'Nonaktif',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: user.isActive
                                            ? AppColors.success
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                '${role.displayName} • ${user.department ?? "-"}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.pill),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  role.displayName,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Divider(height: 1),
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        'Username: @${user.username}  |  Email: ${user.email ?? "-"}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      const Text(
                                        'Hak Akses & Permission:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: permissions.map((p) {
                                          return Chip(
                                            label: Text(
                                              p,
                                              style:
                                                  const TextStyle(fontSize: 11),
                                            ),
                                            backgroundColor:
                                                AppColors.primaryContainer,
                                            visualDensity:
                                                VisualDensity.compact,
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      // Action Buttons
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          OutlinedButton.icon(
                                            icon: Icon(
                                              user.isActive
                                                  ? Icons.block
                                                  : Icons.check_circle_outline,
                                              size: 14,
                                              color: user.isActive
                                                  ? AppColors.warning
                                                  : AppColors.success,
                                            ),
                                            label: Text(
                                              user.isActive
                                                  ? 'Nonaktifkan'
                                                  : 'Aktifkan',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: user.isActive
                                                  ? AppColors.warning
                                                  : AppColors.success,
                                              ),
                                            ),
                                            onPressed: () async {
                                              final newStatus = !user.isActive;
                                              final res = await ref
                                                  .read(masterUsersProvider
                                                      .notifier)
                                                  .toggleActive(
                                                      user.id, newStatus);
                                              if (!context.mounted) return;
                                              if (res is Success<void>) {
                                                AppFeedback.showSuccess(
                                                  context,
                                                  newStatus
                                                      ? 'User "${user.name}" berhasil diaktifkan.'
                                                      : 'User "${user.name}" dinonaktifkan.',
                                                );
                                              }
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          OutlinedButton.icon(
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              size: 14,
                                            ),
                                            label: const Text(
                                              'Edit',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            onPressed: () => _showEditUserDialog(
                                                context, user),
                                          ),
                                          const SizedBox(width: 8),
                                          OutlinedButton.icon(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              size: 14,
                                              color: AppColors.error,
                                            ),
                                            label: const Text(
                                              'Hapus',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.error,
                                              ),
                                            ),
                                            onPressed: () => _confirmDeleteUser(
                                                context, user),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const LoadingIndicator(message: 'Memuat data user...'),
        error: (err, stack) => ErrorView(
          message: err.toString(),
          onRetry: () =>
              ref.read(masterUsersProvider.notifier).loadUsers(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah User'),
        onPressed: () => _showAddUserDialog(context),
      ),
      bottomNavigationBar: CustomFloatingNavBar.scaffoldBottomBar(
        items: RoleNavConfig.getNavItemsForRole(UserRole.admin),
      ),
    );
  }
}
