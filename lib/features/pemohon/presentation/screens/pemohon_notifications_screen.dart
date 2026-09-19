import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

class PemohonNotificationsScreen extends StatelessWidget {
  const PemohonNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // MVP: dummy. Nanti ganti provider notifikasi.
    final items = [
      ('Pengajuan diverifikasi', 'TIK-2026-00042 lolos verifikasi Operator'),
      ('Menunggu konfirmasi', 'Update aset selesai — silakan konfirmasi'),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, i) {
          final item = items[i];
          return Card(
            elevation: 0,
            color: AppColors.surface,
            child: ListTile(
              leading: const Icon(
                Icons.notifications,
                color: AppColors.primary,
              ),
              title: Text(item.$1),
              subtitle: Text(item.$2),
            ),
          );
        },
      ),
    );
  }
}
