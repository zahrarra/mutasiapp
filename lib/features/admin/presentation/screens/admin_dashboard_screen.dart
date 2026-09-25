// lib/features/admin/presentation/screens/admin_dashboard_screen.dart
//
// Dashboard Screen untuk Role: Admin.
// Sumber: ROLE-FLOW.md §2, WIREFRAME.md §2.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../auth/presentation/widgets/role_dashboard_layout.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleDashboardLayout(
      title: 'Dashboard Admin',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pengelolaan Master Data Sistem',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Sebagai Admin, Anda memiliki wewenang penuh untuk mengelola User, Role, Lokasi, Kategori Aset, dan Kriteria Approval.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),

          _AdminMenuCard(
            key: const Key('card_admin_users'),
            title: 'User & Permission',
            subtitle: 'Kelola akun pengguna dan penugasan 6 role aktif',
            icon: Icons.manage_accounts_outlined,
            onTap: () => context.push(RouteNames.adminUsersPath),
          ),
          const SizedBox(height: AppSpacing.sm),
          _AdminMenuCard(
            key: const Key('card_admin_locations'),
            title: 'Lokasi & Unit',
            subtitle: 'Kelola daftar gedung, ruangan, dan unit organisasi',
            icon: Icons.location_city_outlined,
            onTap: () => context.push(RouteNames.adminLocationsPath),
          ),
          const SizedBox(height: AppSpacing.sm),
          _AdminMenuCard(
            key: const Key('card_admin_categories'),
            title: 'Kategori Aset & Kriteria Approval',
            subtitle:
                'Atur threshold kriteria approval mutasi untuk level Kadiv',
            icon: Icons.tune_outlined,
            onTap: () => context.push(RouteNames.adminCategoriesPath),
          ),
        ],
      ),
    );
  }
}

class _AdminMenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _AdminMenuCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary, size: 28),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textDisabled,
        ),
        onTap: onTap,
      ),
    );
  }
}
