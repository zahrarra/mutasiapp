// lib/features/auth/presentation/screens/unauthorized_screen.dart
//
// Skeleton Screen: Access Denied / Unauthorized.
// Sumber: SKILLS.md §6 (rbac), TECHNICAL-DESIGN.md §6.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/custom_button.dart';

/// Screen yang ditampilkan jika user mencoba mengkases route tanpa izin role yang sesuai.
class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Akses Ditolak'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.gpp_bad_rounded,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Akses Dibatasi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Peran (Role) akun Anda tidak memiliki hak akses untuk membuka halaman ini.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              CustomButton(
                label: 'Kembali ke Dashboard',
                onPressed: () {
                  context.go(RouteNames.dashboardPath);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
