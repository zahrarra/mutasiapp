// lib/features/notification/presentation/screens/notification_screen.dart
//
// Screen: Notifikasi (dipakai bersama oleh semua role).
//
// CATATAN: Backend notifikasi belum final (lihat Open Questions di
// TECHNICAL-DESIGN.md/PRD.md). Screen ini adalah implementasi MVP
// berbasis mock data agar tab "Notifikasi" di setiap role dashboard
// fungsional, bukan dead-end. Saat backend notifikasi final tersedia,
// cukup ganti provider di notification_provider.dart tanpa mengubah UI.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/notification_item.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_tile.dart';
import '../../../../core/widgets/custom_floating_nav_bar.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  void _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    NotificationItem item,
  ) {
    final currentUser = ref.read(authStateProvider).user;
    ref.read(notificationProvider.notifier).markAsRead(
          item.id,
          userId: currentUser?.id,
        );

    final mutationId = item.relatedMutationId;
    if (mutationId != null && mutationId.isNotEmpty) {
      final userRole = ref.read(authStateProvider).user?.role;
      final targetPath = switch (userRole) {
        UserRole.operator => '/operator/mutations/$mutationId',
        UserRole.kabagAset => '/kabag/approvals/$mutationId',
        UserRole.kadiv => '/kadiv/approvals/$mutationId',
        UserRole.staffAset => '/staff-aset/mutations/$mutationId',
        UserRole.pemohon => '/pemohon/mutasi/$mutationId',
        _ => null,
      };
      if (targetPath != null) {
        context.push(targetPath);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(roleNotificationsProvider);
    final currentUser = ref.watch(authStateProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Kembali',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              final defaultRoute =
                  ref.read(authStateProvider).user?.role.defaultRoute ??
                      RouteNames.dashboardPath;
              context.go(defaultRoute);
            }
          },
        ),
        actions: [
          if (notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: () => ref
                  .read(notificationProvider.notifier)
                  .markAllAsRead(
                    role: currentUser?.role,
                    userId: currentUser?.id,
                  ),
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
              child: Text(
                'Belum ada notifikasi.',
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
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final item = notifications[index];
                return NotificationTile(
                  item: item,
                  onTap: () => _handleNotificationTap(context, ref, item),
                );
              },
            ),
      bottomNavigationBar: currentUser?.role != null
          ? CustomFloatingNavBar.scaffoldBottomBar(
              items: RoleNavConfig.getNavItemsForRole(currentUser!.role),
            )
          : null,
    );
  }
}

