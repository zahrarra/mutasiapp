// lib/features/auth/presentation/widgets/role_dashboard_layout.dart
//
// Layout terpusat untuk Dashboard 6 Role MutasiKu.
// Sumber: ROLE-FLOW.md §2–7, WIREFRAME.md §2.
// UI: Premium modern per Stitch design — custom top bar, no Material AppBar.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/widgets/custom_floating_nav_bar.dart';
import '../../domain/entities/user_role.dart';
import '../providers/auth_provider.dart';

/// Item navigasi bottom bar per role (alias untuk [CustomNavItem]).
typedef RoleNavItem = CustomNavItem;

/// Warna lokal layout — mengikuti Stitch design tokens.
class _LC {
  static const navy = Color(0xFF0F3D56);
  static const teal = Color(0xFF0F766E);
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF6F8FA);
  static const textSecondary = Color(0xFF52606D);
  static const border = Color(0xFFE2E8F0);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFD97706);
}

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

    final initials =
        (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'U';
    final roleBadgeLabel = _roleLabel(user?.role);

    return Scaffold(
      backgroundColor: _LC.background,
      extendBody: true,
      body: Column(
        children: [
          // ── Custom Top Bar (no Material AppBar) ────────────────────────
          _TopBar(
            initials: initials,
            roleLabel: roleBadgeLabel,
            onLogout: () => ref.read(authStateProvider.notifier).logout(),
          ),

          // ── Scrollable Body ────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.wifi_off_rounded,
                                color: _LC.warning,
                                size: 16,
                              ),
                              SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  'Anda sedang offline. Menggunakan penyimpanan lokal.',
                                  style: TextStyle(
                                    color: _LC.warning,
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

                  // Role Content Child
                  child,
                ],
              ),
            ),
          ),
        ],
      ),
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

  String _roleLabel(UserRole? role) {
    switch (role) {
      case UserRole.operator:
        return 'Operator Aset';
      case UserRole.kabagAset:
        return 'Kabag Aset';
      case UserRole.kadiv:
        return 'Kepala Divisi';
      case UserRole.staffAset:
        return 'Staff Aset';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.pemohon:
        return 'Pemohon';
      case null:
        return 'MutasiKu';
    }
  }
}

/// Top bar premium pengganti Material AppBar.
/// Layout: Avatar(kiri) | Brand badge(tengah) | Logout(kanan).
class _TopBar extends StatelessWidget {
  final String initials;
  final String roleLabel;
  final VoidCallback onLogout;

  const _TopBar({
    required this.initials,
    required this.roleLabel,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _LC.surface,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _LC.surface,
            border: Border(
              bottom: BorderSide(
                color: _LC.border,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Avatar with online dot
              Stack(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _LC.navy,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -1,
                    right: -1,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: _LC.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: _LC.surface, width: 2),
                      ),
                    ),
                  ),
                ],
              ),

              // Center brand badge
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _LC.navy.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: _LC.navy.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _LC.teal,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          roleLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _LC.navy,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Logout button
              GestureDetector(
                onTap: onLogout,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _LC.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _LC.border),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.logout_rounded,
                    size: 18,
                    color: _LC.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
