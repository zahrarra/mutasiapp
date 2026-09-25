// lib/features/pemohon/presentation/screens/pemohon_shell_screen.dart
//
// Shell navigasi bottom bar Pemohon.
// Sumber: ROLE-FLOW.md §3, desain Stitch Pemohon.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../../core/widgets/custom_floating_nav_bar.dart';

class PemohonShellScreen extends ConsumerWidget {
  final Widget child;
  final int currentIndex;

  const PemohonShellScreen({
    super.key,
    required this.child,
    this.currentIndex = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: CustomFloatingNavBar.scaffoldBottomBar(
        items: RoleNavConfig.getNavItemsForRole(UserRole.pemohon),
      ),
    );
  }
}
