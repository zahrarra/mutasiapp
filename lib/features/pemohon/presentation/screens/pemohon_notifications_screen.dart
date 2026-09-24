// lib/features/pemohon/presentation/screens/pemohon_notifications_screen.dart
//
// Screen: Notifikasi Pemohon (REQ-010).
// Sumber: SCREEN-SPEC.md, NotificationScreen (Operator baseline).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../notification/domain/entities/notification_item.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../../../notification/presentation/widgets/notification_tile.dart';

class PemohonNotificationsScreen extends ConsumerWidget {
  const PemohonNotificationsScreen({super.key});

  void _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    NotificationItem item,
  ) {
    // 1. Tandai notifikasi sebagai dibaca
    ref.read(notificationProvider.notifier).markAsRead(item.id);

    // 2. Jika notifikasi memiliki ID mutasi terkait, navigasi ke Detail Mutasi Pemohon
    final mutationId = item.relatedMutationId;
    if (mutationId != null && mutationId.isNotEmpty) {
      context.push(
        RouteNames.pemohonMutasiDetailPath.replaceFirst(':id', mutationId),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Kembali',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.pemohonDashboardPath);
            }
          },
        ),
        actions: [
          if (notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: () =>
                  ref.read(notificationProvider.notifier).markAllAsRead(),
              child: const Text(
                'Tandai semua dibaca',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 48,
                      color: AppColors.textDisabled,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'Belum ada notifikasi.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: notifications.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final item = notifications[index];
                return NotificationTile(
                  item: item,
                  onTap: () => _handleNotificationTap(context, ref, item),
                );
              },
            ),
    );
  }
}
