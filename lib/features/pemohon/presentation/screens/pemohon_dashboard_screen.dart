// lib/features/pemohon/presentation/screens/pemohon_dashboard_screen.dart
//
// Dashboard Screen untuk Role: Pemohon.
// Sumber: ROLE-FLOW.md §3, WIREFRAME.md §2.

import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../auth/presentation/widgets/role_dashboard_layout.dart';

class PemohonDashboardScreen extends StatelessWidget {
  const PemohonDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleDashboardLayout(
      title: 'Dashboard Pemohon',
      navItems: [
        RoleNavItem(label: 'Home', icon: Icons.home_outlined),
        RoleNavItem(label: 'Mutasi Saya', icon: Icons.assignment_outlined),
        RoleNavItem(label: 'Notifikasi', icon: Icons.notifications_outlined),
        RoleNavItem(label: 'Profil', icon: Icons.person_outline),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Layanan Pengajuan Mutasi Aset',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Sebagai Pemohon, Anda dapat membuat pengajuan mutasi aset baru, melacak tiket pengajuan, serta mengonfirmasi hasil perpindahan aset.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.md),

          Card(
            elevation: 0,
            color: AppColors.primary,
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.add_to_photos_outlined, color: Colors.white, size: 32),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buat Pengajuan Mutasi Baru',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Pilih aset & isi formulir mutasi lokasi/PIC',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
