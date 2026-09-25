// lib/features/admin/presentation/screens/admin_users_screen.dart
//
// Screen: Kelola User & Permission oleh Admin.
// Sumber: ROLE-FLOW.md §2, PRD.md §5, TECHNICAL-DESIGN.md.

import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../auth/domain/entities/user_role.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static final List<Map<String, dynamic>> _mockUsers = [
    {
      'name': 'Rina (Pemohon)',
      'username': 'pemohon',
      'email': 'pemohon@mutasiku.id',
      'role': UserRole.pemohon,
      'department': 'Divisi Keuangan & Akuntansi',
      'permissions': ['Ajukan Mutasi', 'Edit Mutasi Dikembalikan', 'Konfirmasi Fisik'],
    },
    {
      'name': 'Operator Aset',
      'username': 'operator',
      'email': 'operator@mutasiku.id',
      'role': UserRole.operator,
      'department': 'Operasional Logistik & Inventaris',
      'permissions': ['Verifikasi Pengajuan', 'Kembalikan Pengajuan', 'Tentukan Jalur Kadiv'],
    },
    {
      'name': 'H. M. Yusuf (Kabag Aset)',
      'username': 'kabag',
      'email': 'kabag@mutasiku.id',
      'role': UserRole.kabagAset,
      'department': 'Bagian Pengelolaan Aset Perusahaan',
      'permissions': ['Setujui Mutasi', 'Tolak Mutasi', 'Tinjau Riwayat Approval'],
    },
    {
      'name': 'Drs. Ahmad Dahlan (Kadiv)',
      'username': 'kadiv',
      'email': 'kadiv@mutasiku.id',
      'role': UserRole.kadiv,
      'department': 'Divisi Umum & Perlengkapan',
      'permissions': ['Approval Tingkat Kadiv', 'Tolak Mutasi', 'Review Lintas Wilayah'],
    },
    {
      'name': 'Rizky Pratama (Staff Aset)',
      'username': 'staff',
      'email': 'staff@mutasiku.id',
      'role': UserRole.staffAset,
      'department': 'Staf Pemeliharaan & Lapangan',
      'permissions': ['Update Lokasi Fisik', 'Update PIC Fisik', 'Serah Terima Aset'],
    },
    {
      'name': 'System Administrator',
      'username': 'admin',
      'email': 'admin@mutasiku.id',
      'role': UserRole.admin,
      'department': 'IT Enterprise & Governance',
      'permissions': ['Kelola Master Data', 'Audit Log', 'Kelola Role & Akses'],
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _mockUsers.where((u) {
      final name = (u['name'] as String).toLowerCase();
      final username = (u['username'] as String).toLowerCase();
      final dept = (u['department'] as String).toLowerCase();
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || username.contains(q) || dept.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('User & Permission'),
      ),
      body: Column(
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
                  '${filtered.length} Akun Pengguna Aktif',
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
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final user = filtered[index];
                      final role = user['role'] as UserRole;
                      final permissions = user['permissions'] as List<String>;

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryContainer,
                            child: const Icon(
                              Icons.person_outline,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            user['name'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            '${role.displayName} • ${user['department']}',
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(height: 1),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'Username: @${user['username']}  |  Email: ${user['email']}',
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
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        backgroundColor:
                                            AppColors.primaryContainer,
                                        visualDensity: VisualDensity.compact,
                                      );
                                    }).toList(),
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
      ),
    );
  }
}
