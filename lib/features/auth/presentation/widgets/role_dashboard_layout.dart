// lib/features/auth/presentation/widgets/role_dashboard_layout.dart
//
// Layout terpusat untuk Dashboard 6 Role MutasiKu.
// Sumber: ROLE-FLOW.md §2–7, WIREFRAME.md §2.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/custom_floating_nav_bar.dart';
import '../../domain/entities/user_role.dart';
import '../providers/auth_provider.dart';

/// Item navigasi bottom bar per role (alias untuk [CustomNavItem]).
typedef RoleNavItem = CustomNavItem;

/// Layout dashboard standar role MutasiKu.
class RoleDashboardLayout extends ConsumerWidget {
  final String title;
  final List<CustomNavItem>? navItems;
  final int selectedIndex;
  final ValueChanged<int>? onNavDestinationSelected;
  final Widget child;

  const RoleDashboardLayout({
    super.key,
    required this.title,
    this.navItems,
    this.selectedIndex = 0,
    this.onNavDestinationSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final connectivityAsync = ref.watch(connectivityStatusProvider);
    final user = authState.user;
    final activeNavItems = navItems ??
        RoleNavConfig.getNavItemsForRole(user?.role ?? UserRole.operator);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar (Logout)',
            onPressed: () {
              ref.read(authStateProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connectivity Status Banner
            connectivityAsync.when(
              data: (status) {
                if (status == ConnectivityStatus.offline) {
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.warningContainer,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.wifi_off, color: AppColors.warning, size: 18),
                        SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            'Status Offline: Menggunakan penyimpanan lokal sementara.',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (error, stackTrace) => const SizedBox.shrink(),
            ),

            // Profile Header Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary,
                      radius: 24,
                      child: Text(
                        (user?.name.isNotEmpty ?? false) ? user!.name[0] : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                user?.name ?? 'Pengguna',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              if (user != null)
                                StatusBadge.info(user.role.displayName),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            user?.email ?? '-',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Role Content Child
            child,
          ],
        ),
      ),
      extendBody: true,
      bottomNavigationBar: CustomFloatingNavBar.scaffoldBottomBar(
        items: activeNavItems,
        onItemTap: onNavDestinationSelected != null
            ? (item) {
                final idx = activeNavItems.indexOf(item);
                if (idx != -1) {
                  onNavDestinationSelected!(idx);
                }
              }
            : null,
      ),
    );
  }
}
