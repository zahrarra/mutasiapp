// lib/features/staff/presentation/screens/staff_dashboard_screen.dart
//
// Dashboard Screen untuk Role: Staff Aset.
// Sumber: ROLE-FLOW.md §7, WIREFRAME.md §2.

import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../auth/presentation/widgets/role_dashboard_layout.dart';

class StaffAsetDashboardScreen extends StatelessWidget {
  const StaffAsetDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleDashboardLayout(
      title: 'Dashboard Staff Aset',
      navItems: [
        RoleNavItem(label: 'Home', icon: Icons.home_outlined),
        RoleNavItem(label: 'Update Aset', icon: Icons.edit_location_alt_outlined),
        RoleNavItem(label: 'Notifikasi', icon: Icons.notifications_outlined),
        RoleNavItem(label: 'Profil', icon: Icons.person_outline),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pembaruan Lokasi & Penanggung Jawab Aset',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Sebagai Staff Aset, Anda bertugas melakukan perpindahan fisik aset, memperbarui data lokasi & PIC, serta menyimpan riwayat mutasi.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.md),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusMd)),
              side: BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.published_with_changes_outlined, color: AppColors.success, size: 32),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Menunggu Pembaruan Aset',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          'Pengajuan yang telah disetujui & siap di-update',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
