// lib/features/profile/presentation/screens/profile_screen.dart
//
// Profil bersama semua role — visual Stitch.
// Bottom bar: CustomFloatingNavBar + RoleNavConfig (beda per role).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/widgets/custom_floating_nav_bar.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

abstract final class _C {
  static const bg = Color(0xFFF1F5F9);
  static const white = Color(0xFFFFFFFF);
  static const navy = Color(0xFF0F3D56);
  static const teal = Color(0xFF0F766E);
  static const tealSoft = Color(0xFFE6F4F1);
  static const grayMuted = Color(0xFF52606D);
  static const grayLight = Color(0xFF94A3B8);
  static const border = Color(0xFFE2E8F0);
  static const danger = Color(0xFFB42318);
  static const dangerLight = Color(0xFFFEF3F2);
  static const slate800 = Color(0xFF1E293B);
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  TextStyle _t({
    double size = 14,
    FontWeight w = FontWeight.w400,
    Color color = _C.slate800,
    double? h,
    double? ls,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: w,
      color: color,
      height: h,
      letterSpacing: ls,
    );
  }

  String _roleLabel(UserRole? role) {
    switch (role) {
      case UserRole.pemohon:
        return 'Pemohon';
      case UserRole.operator:
        return 'Operator';
      case UserRole.bagianAset:
        return 'Bagian Aset';
      case UserRole.kadiv:
        return 'Pemimpin Divisi';
      case UserRole.admin:
        return 'Admin';
      case null:
        return '-';
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xFF0F172A).withValues(alpha: 0.6),
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF2F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: _C.danger,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Keluar dari Akun?',
                  style: _t(size: 16, w: FontWeight.w700, color: _C.slate800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Apakah Anda yakin ingin keluar dari aplikasi MutasiKu?',
                  textAlign: TextAlign.center,
                  style: _t(size: 12, color: _C.grayMuted, h: 1.4),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _C.grayMuted,
                          side: const BorderSide(color: _C.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Batal',
                          style: _t(size: 12, w: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: _C.danger,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Ya, Keluar',
                          style: _t(
                            size: 12,
                            w: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (ok == true && context.mounted) {
      await ref.read(authStateProvider.notifier).logout();
      if (context.mounted) {
        context.go(RouteNames.loginPath);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final role = user?.role;
    final name = user?.name ?? '-';
    final email = user?.email ?? user?.username ?? '-';
    final unit = user?.department ?? '-';

    // Sesuaikan field entity user Anda jika nama beda:
    // unitName / division / department

    return Scaffold(
      backgroundColor: _C.bg,
      extendBody: true,
      body: Stack(
        children: [
          // Ambient glow
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 280,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFFF7ED).withValues(alpha: 0.6),
                    const Color(0xFFF8FAFC).withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                  child: Row(
                    children: [
                      Material(
                        color: _C.white.withValues(alpha: 0.8),
                        shape: const CircleBorder(
                          side: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(
                                role?.defaultRoute ?? RouteNames.dashboardPath,
                              );
                            }
                          },
                          child: const SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.arrow_back,
                              size: 20,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Profil',
                          textAlign: TextAlign.center,
                          style: _t(
                            size: 20,
                            w: FontWeight.w700,
                            color: _C.navy,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  children: [
                    // Card identitas
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _C.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _C.border.withValues(alpha: 0.8),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _C.navy.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _C.navy.withValues(alpha: 0.1),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              size: 48,
                              color: _C.navy,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            name,
                            style: _t(
                              size: 20,
                              w: FontWeight.w700,
                              color: _C.navy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: _t(
                              size: 12,
                              w: FontWeight.w500,
                              color: _C.grayMuted,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _C.tealSoft,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: const Color(0xFF99F6E4)
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                child: Text(
                                  _roleLabel(role),
                                  style: _t(
                                    size: 12,
                                    w: FontWeight.w600,
                                    color: _C.teal,
                                  ),
                                ),
                              ),
                              if (unit != '-' && unit.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: _C.border),
                                  ),
                                  child: Text(
                                    unit,
                                    style: _t(
                                      size: 12,
                                      w: FontWeight.w500,
                                      color: const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFE2E8F0), height: 1),
                    const SizedBox(height: 16),
                    // Informasi Akun
                    Text(
                      'INFORMASI AKUN',
                      style: _t(
                        size: 12,
                        w: FontWeight.w700,
                        color: _C.grayLight,
                        ls: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _C.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _C.border.withValues(alpha: 0.8),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _C.navy.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _row('Nama', name),
                          _divider(),
                          _row('Username', email),
                          _divider(),
                          _row('Role', _roleLabel(role), valueColor: _C.teal),
                          _divider(),
                          _row('Unit', unit, showBorder: false),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Logout
                    Material(
                      color: _C.dangerLight,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () => _confirmLogout(context, ref),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFFECACA)
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.logout_rounded,
                                size: 16,
                                color: _C.danger,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Keluar dari Aplikasi',
                                style: _t(
                                  size: 12,
                                  w: FontWeight.w600,
                                  color: _C.danger,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: role != null
          ? CustomFloatingNavBar.scaffoldBottomBar(
              items: RoleNavConfig.getNavItemsForRole(role),
            )
          : null,
    );
  }

  Widget _row(
    String label,
    String value, {
    Color valueColor = _C.navy,
    bool showBorder = true,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: showBorder ? 12 : 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: _t(size: 12, color: _C.grayMuted)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: _t(size: 12, w: FontWeight.w600, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Divider(height: 1, color: Color(0xFFF1F5F9)),
    );
  }
}
