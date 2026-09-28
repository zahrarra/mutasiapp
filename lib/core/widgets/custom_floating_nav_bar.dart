// lib/core/widgets/custom_floating_nav_bar.dart
//
// Floating Bottom Navigation Bar terstandarisasi untuk seluruh role MutasiKu.
// Active state: oval di belakang icon (GoRouter matchedLocation).
// Item per role: RoleNavConfig.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/route_names.dart';
import '../../app/theme/app_colors.dart';
import '../../features/auth/domain/entities/user_role.dart';
import '../../features/notification/presentation/providers/notification_provider.dart';

class CustomNavItem {
  final IconData icon;
  final String label;
  final String route;
  final bool? hasBadge;

  const CustomNavItem({
    required this.icon,
    required this.label,
    required this.route,
    this.hasBadge,
  });
}

abstract final class RoleNavConfig {
  static List<CustomNavItem> getNavItemsForRole(UserRole role) {
    switch (role) {
      case UserRole.pemohon:
        return const [
          CustomNavItem(
            icon: Icons.home_outlined,
            label: 'Beranda',
            route: RouteNames.pemohonDashboardPath,
          ),
          CustomNavItem(
            icon: Icons.swap_horiz_rounded,
            label: 'Mutasi Saya',
            route: RouteNames.pemohonMutasiPath,
          ),
          CustomNavItem(
            icon: Icons.notifications_none_rounded,
            label: 'Notifikasi',
            route: RouteNames.pemohonNotificationsPath,
          ),
          CustomNavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profil',
            route: RouteNames.pemohonProfilePath,
          ),
        ];

      case UserRole.operator:
        return const [
          CustomNavItem(
            icon: Icons.home_outlined,
            label: 'Home',
            route: RouteNames.operatorDashboardPath,
          ),
          CustomNavItem(
            icon: Icons.fact_check_outlined,
            label: 'Pengajuan',
            route: RouteNames.operatorMutationsPath,
          ),
          CustomNavItem(
            icon: Icons.notifications_none_rounded,
            label: 'Notifikasi',
            route: RouteNames.operatorNotificationsPath,
          ),
          CustomNavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profil',
            route: RouteNames.profilePath,
          ),
        ];

      case UserRole.bagianAset:
        return const [
          CustomNavItem(
            icon: Icons.home_outlined,
            label: 'Home',
            route: RouteNames.bagianAsetDashboardPath,
          ),
          CustomNavItem(
            icon: Icons.assignment_ind_outlined,
            label: 'Verifikasi',
            route: RouteNames.bagianAsetVerificationsPath,
          ),
          CustomNavItem(
            icon: Icons.notifications_none_rounded,
            label: 'Notifikasi',
            route: RouteNames.bagianAsetNotificationsPath,
          ),
          CustomNavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profil',
            route: RouteNames.profilePath,
          ),
        ];

      case UserRole.kabagAset:
        return const [
          CustomNavItem(
            icon: Icons.home_outlined,
            label: 'Home',
            route: RouteNames.kabagDashboardPath,
          ),
          CustomNavItem(
            icon: Icons.assignment_ind_outlined,
            label: 'Approval',
            route: RouteNames.kabagApprovalsPath,
          ),
          CustomNavItem(
            icon: Icons.notifications_none_rounded,
            label: 'Notifikasi',
            route: RouteNames.kabagNotificationsPath,
          ),
          CustomNavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profil',
            route: RouteNames.profilePath,
          ),
        ];

      case UserRole.kadiv:
        return const [
          CustomNavItem(
            icon: Icons.home_outlined,
            label: 'Home',
            route: RouteNames.kadivDashboardPath,
          ),
          CustomNavItem(
            icon: Icons.assignment_ind_outlined,
            label: 'Approval',
            route: RouteNames.kadivApprovalsPath,
          ),
          CustomNavItem(
            icon: Icons.notifications_none_rounded,
            label: 'Notifikasi',
            route: RouteNames.kadivNotificationsPath,
          ),
          CustomNavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profil',
            route: RouteNames.profilePath,
          ),
        ];

      case UserRole.staffAset:
        return const [
          CustomNavItem(
            icon: Icons.home_outlined,
            label: 'Home',
            route: RouteNames.staffDashboardPath,
          ),
          CustomNavItem(
            icon: Icons.edit_location_alt_outlined,
            label: 'Update Aset',
            route: RouteNames.staffMutationsPath,
          ),
          CustomNavItem(
            icon: Icons.notifications_none_rounded,
            label: 'Notifikasi',
            route: RouteNames.staffNotificationsPath,
          ),
          CustomNavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profil',
            route: RouteNames.profilePath,
          ),
        ];

      case UserRole.admin:
        return const [
          CustomNavItem(
            icon: Icons.grid_view_rounded,
            label: 'Home',
            route: RouteNames.adminDashboardPath,
          ),
          CustomNavItem(
            icon: Icons.dns_outlined,
            label: 'Master Data',
            route: RouteNames.adminCategoriesPath,
          ),
          CustomNavItem(
            icon: Icons.group_outlined,
            label: 'Users',
            route: RouteNames.adminUsersPath,
          ),
          CustomNavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profil',
            route: RouteNames.profilePath,
          ),
        ];
    }
  }
}

class CustomFloatingNavBar extends ConsumerWidget {
  final List<CustomNavItem> items;
  final String? currentRoute;
  final ValueChanged<CustomNavItem>? onItemTap;

  const CustomFloatingNavBar({
    super.key,
    required this.items,
    this.currentRoute,
    this.onItemTap,
  });

  factory CustomFloatingNavBar.forRole(
    UserRole role, {
    Key? key,
    String? currentRoute,
    ValueChanged<CustomNavItem>? onItemTap,
  }) {
    return CustomFloatingNavBar(
      key: key,
      items: RoleNavConfig.getNavItemsForRole(role),
      currentRoute: currentRoute,
      onItemTap: onItemTap,
    );
  }

  static Widget scaffoldBottomBar({
    required List<CustomNavItem> items,
    String? currentRoute,
    ValueChanged<CustomNavItem>? onItemTap,
  }) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: CustomFloatingNavBar(
          items: items,
          currentRoute: currentRoute,
          onItemTap: onItemTap,
        ),
      ),
    );
  }

  String _getActiveRoute(BuildContext context) {
    if (currentRoute != null) return currentRoute!;
    try {
      return GoRouterState.of(context).matchedLocation;
    } catch (_) {
      return '';
    }
  }

  bool _isItemActive(CustomNavItem item, String activeLocation) {
    if (activeLocation.isEmpty) return false;
    if (activeLocation == item.route) return true;

    // Alias Pemohon mutasi
    if (item.route == RouteNames.pemohonMutasiPath) {
      if (activeLocation == '/pemohon/mutations' ||
          activeLocation == '/pemohon/history' ||
          activeLocation == '/pemohon/mutation-history' ||
          activeLocation.startsWith('${RouteNames.pemohonMutasiPath}/')) {
        return true;
      }
    }

    // Sub-route detail tetap aktif di tab induk (opsional)
    if (item.route != RouteNames.pemohonMutasiPath &&
        activeLocation.startsWith('${item.route}/')) {
      return true;
    }

    return false;
  }

  void _onTap(BuildContext context, CustomNavItem item, bool isActive) {
    if (onItemTap != null) {
      onItemTap!(item);
    }
    if (isActive) return;
    context.go(item.route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeLocation = _getActiveRoute(context);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Container(
      height: 66,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.map((item) {
          final isActive = _isItemActive(item, activeLocation);
          final isNotif = item.label.toLowerCase() == 'notifikasi';
          final showBadge = item.hasBadge ?? (isNotif && unreadCount > 0);

          final color = isActive
              ? const Color(0xFF0F3D56)
              : const Color(0xFF94A3B8);

          Widget iconWidget = Icon(item.icon, size: 22, color: color);
          if (showBadge) {
            iconWidget = Badge(
              smallSize: 8,
              backgroundColor: AppColors.error,
              child: iconWidget,
            );
          }

          return Expanded(
            child: InkWell(
              onTap: () => _onTap(context, item, isActive),
              borderRadius: BorderRadius.circular(35),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: isActive
                            ? BoxDecoration(
                                color: const Color(0xFF0F3D56)
                                    .withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(999),
                              )
                            : null,
                        child: iconWidget,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          height: 1.0,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
