// lib/features/pemohon/presentation/screens/pemohon_shell_screen.dart
//
// Shell navigasi bottom bar Pemohon.
// Sumber: ROLE-FLOW.md §3, desain Stitch Pemohon.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../notification/presentation/providers/notification_provider.dart';

class PemohonShellScreen extends ConsumerWidget {
  final Widget child;
  final int currentIndex;

  const PemohonShellScreen({
    super.key,
    required this.child,
    this.currentIndex = 0,
  });

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(RouteNames.pemohonDashboardPath);
        break;
      case 1:
        context.go(RouteNames.pemohonMutasiPath);
        break;
      case 2:
        context.go(RouteNames.pemohonNotificationsPath);
        break;
      case 3:
        context.go(RouteNames.pemohonProfilePath);
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => _onTap(context, i),
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          const NavigationDestination(
            icon: Icon(Icons.swap_horiz_outlined),
            selectedIcon: Icon(Icons.swap_horiz),
            label: 'Mutasi Saya',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: unreadCount > 0,
              child: const Icon(Icons.notifications),
            ),
            label: 'Notifikasi',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
