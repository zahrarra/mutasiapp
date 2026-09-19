// lib/features/profile/presentation/screens/profile_screen.dart
//
// Screen: Profil Pengguna (dipakai bersama oleh semua role).
// Sumber: WIREFRAME.md §2 (nav item "Profil" ada di semua role dashboard,
// namun screen-nya belum dispesifikasikan detail — dibuat generik & aman).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    user?.name ?? 'Pengguna',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(user?.email ?? '-', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.infoContainer,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      user?.role.displayName ?? '-',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            CustomButton(
              label: 'Keluar (Logout)',
              variant: ButtonVariant.outline,
              icon: const Icon(Icons.logout, size: 18, color: AppColors.primary),
              onPressed: () => ref.read(authStateProvider.notifier).logout(),
            ),
          ],
        ),
      ),
    );
  }
}
