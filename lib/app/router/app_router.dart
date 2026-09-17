// lib/app/router/app_router.dart
//
// Konfigurasi go_router terpusat dengan Riverpod integration & RBAC route guards.
// Sumber: PROJECT-SETUP.md §8, TECHNICAL-DESIGN.md §3, ROLE-FLOW.md §10.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/asset/presentation/screens/asset_category_screen.dart';
import '../../features/asset/presentation/screens/asset_detail_screen.dart';
import '../../features/asset/presentation/screens/asset_list_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/unauthorized_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/kabag/presentation/screens/kabag_approval_detail_screen.dart';
import '../../features/kabag/presentation/screens/kabag_approvals_screen.dart';
import '../../features/kabag/presentation/screens/kabag_dashboard_screen.dart';
import '../../features/kabag/presentation/screens/kabag_reject_form_screen.dart';
import '../../features/kadiv/presentation/screens/kadiv_approval_detail_screen.dart';
import '../../features/kadiv/presentation/screens/kadiv_approvals_screen.dart';
import '../../features/kadiv/presentation/screens/kadiv_dashboard_screen.dart';
import '../../features/kadiv/presentation/screens/kadiv_reject_form_screen.dart';
import '../../features/operator/presentation/screens/operator_dashboard_screen.dart';
import '../../features/operator/presentation/screens/operator_mutations_screen.dart';
import '../../features/operator/presentation/screens/operator_return_form_screen.dart';
import '../../features/operator/presentation/screens/operator_verification_detail_screen.dart';
import '../../features/pemohon/presentation/screens/pemohon_dashboard_screen.dart';
import '../../features/pemohon/presentation/screens/pemohon_confirmation_screen.dart';
import '../../features/staff/presentation/screens/staff_dashboard_screen.dart';
import 'route_guards.dart';
import 'route_names.dart';

/// Notifier sederhana untuk memicu re-evaluation GoRouter ketika status auth berubah.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authStateProvider,
      (previous, next) => notifyListeners(),
    );
  }
}

/// Provider [GoRouter] terpusat.
final appRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: RouteNames.dashboardPath,
    refreshListenable: routerNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authStateProvider);

      if (authState.isLoading) return null;

      final currentLocation = state.matchedLocation;

      return RouteGuards.handleRedirect(
        isAuthenticated: authState.isAuthenticated,
        role: authState.user?.role,
        currentLocation: currentLocation,
      );
    },
    routes: [
      GoRoute(
        path: RouteNames.loginPath,
        name: RouteNames.loginName,
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: RouteNames.dashboardPath,
        name: RouteNames.dashboardName,
        builder: (context, state) => const DashboardScreen(),
      ),

      GoRoute(
        path: RouteNames.unauthorizedPath,
        name: RouteNames.unauthorizedName,
        builder: (context, state) => const UnauthorizedScreen(),
      ),

      // ─── Asset Routes ───────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.assetsPath,
        name: RouteNames.assetsName,
        builder: (context, state) => const AssetListScreen(),
      ),
      GoRoute(
        path: RouteNames.assetDetailPath,
        name: RouteNames.assetDetailName,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return AssetDetailScreen(assetId: id);
        },
      ),

      // ─── Role Dashboards ───────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.adminDashboardPath,
        name: RouteNames.adminDashboardName,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.adminCategoriesPath,
        name: RouteNames.adminCategoriesName,
        builder: (context, state) => const AssetCategoryScreen(),
      ),
      GoRoute(
        path: RouteNames.pemohonDashboardPath,
        name: RouteNames.pemohonDashboardName,
        builder: (context, state) => const PemohonDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.pemohonConfirmationPath,
        name: RouteNames.pemohonConfirmationName,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return PemohonConfirmationScreen(mutationId: id);
        },
      ),
      GoRoute(
        path: RouteNames.operatorDashboardPath,
        name: RouteNames.operatorDashboardName,
        builder: (context, state) => const OperatorDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.operatorMutationsPath,
        name: RouteNames.operatorMutationsName,
        builder: (context, state) => const OperatorMutationsScreen(),
      ),
      GoRoute(
        path: RouteNames.operatorVerificationDetailPath,
        name: RouteNames.operatorVerificationDetailName,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return OperatorVerificationDetailScreen(mutationId: id);
        },
      ),
      GoRoute(
        path: RouteNames.operatorReturnFormPath,
        name: RouteNames.operatorReturnFormName,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return OperatorReturnFormScreen(mutationId: id);
        },
      ),
      GoRoute(
        path: RouteNames.kabagDashboardPath,
        name: RouteNames.kabagDashboardName,
        builder: (context, state) => const KabagDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.kabagApprovalsPath,
        name: RouteNames.kabagApprovalsName,
        builder: (context, state) => const KabagApprovalsScreen(),
      ),
      GoRoute(
        path: RouteNames.kabagApprovalDetailPath,
        name: RouteNames.kabagApprovalDetailName,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return KabagApprovalDetailScreen(mutationId: id);
        },
      ),
      GoRoute(
        path: RouteNames.kabagRejectFormPath,
        name: RouteNames.kabagRejectFormName,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return KabagRejectFormScreen(mutationId: id);
        },
      ),
      GoRoute(
        path: RouteNames.kadivDashboardPath,
        name: RouteNames.kadivDashboardName,
        builder: (context, state) => const KadivDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.kadivApprovalsPath,
        name: RouteNames.kadivApprovalsName,
        builder: (context, state) => const KadivApprovalsScreen(),
      ),
      GoRoute(
        path: RouteNames.kadivApprovalDetailPath,
        name: RouteNames.kadivApprovalDetailName,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return KadivApprovalDetailScreen(mutationId: id);
        },
      ),
      GoRoute(
        path: RouteNames.kadivRejectFormPath,
        name: RouteNames.kadivRejectFormName,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return KadivRejectFormScreen(mutationId: id);
        },
      ),
      GoRoute(
        path: RouteNames.kadivHistoryPath,
        name: RouteNames.kadivHistoryName,
        builder: (context, state) => const KadivApprovalsScreen(),
      ),
      GoRoute(
        path: RouteNames.staffDashboardPath,
        name: RouteNames.staffDashboardName,
        builder: (context, state) => const StaffAsetDashboardScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Halaman Tidak Ditemukan')),
      body: Center(
        child: Text('Error: ${state.error?.message ?? 'Halaman tidak ditemukan'}'),
      ),
    ),
  );
});
