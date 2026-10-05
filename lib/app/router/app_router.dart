// lib/app/router/app_router.dart
//
// Konfigurasi go_router terpusat dengan Riverpod integration & RBAC route guards.
// Sumber: PROJECT-SETUP.md §8, TECHNICAL-DESIGN.md §3, ROLE-FLOW.md §10.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/landing_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_locations_screen.dart';
import '../../features/admin/presentation/screens/admin_users_screen.dart';
import '../../features/asset/presentation/screens/asset_category_screen.dart';
import '../../features/asset/presentation/screens/asset_detail_screen.dart';
import '../../features/asset/presentation/screens/asset_list_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/unauthorized_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/bagian_aset/presentation/screens/bagian_aset_dashboard_screen.dart';
import '../../features/bagian_aset/presentation/screens/bagian_aset_return_form_screen.dart';
import '../../features/bagian_aset/presentation/screens/bagian_aset_verification_detail_screen.dart';
import '../../features/bagian_aset/presentation/screens/bagian_aset_verifications_screen.dart';
import '../../features/kadiv/presentation/screens/kadiv_approval_detail_screen.dart';
import '../../features/kadiv/presentation/screens/kadiv_approvals_screen.dart';
import '../../features/kadiv/presentation/screens/kadiv_dashboard_screen.dart';
import '../../features/kadiv/presentation/screens/kadiv_reject_form_screen.dart';
import '../../features/notification/presentation/screens/notification_screen.dart';
import '../../features/operator/presentation/screens/operator_dashboard_screen.dart';
import '../../features/operator/presentation/screens/operator_mutations_screen.dart';
import '../../features/operator/presentation/screens/operator_return_form_screen.dart';
import '../../features/operator/presentation/screens/operator_verification_detail_screen.dart';
import '../../features/pemohon/presentation/screens/pemohon_confirmation_screen.dart';
import '../../features/pemohon/presentation/screens/pemohon_create_mutation_screen.dart';
import '../../features/pemohon/presentation/screens/pemohon_dashboard_screen.dart';
import '../../features/pemohon/presentation/screens/pemohon_edit_mutation_screen.dart';
import '../../features/pemohon/presentation/screens/pemohon_mutation_detail_screen.dart';
import '../../features/pemohon/presentation/screens/pemohon_mutation_list_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
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
    initialLocation: RouteNames.landingPath,
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
        path: RouteNames.landingPath,
        name: RouteNames.landingName,
        // Gunakan CustomTransitionPage dengan durasi nol supaya GoRouter
        // tidak menambah animasi bawaan. Semua animasi dikendalikan
        // sepenuhnya oleh LandingScreen (fade-out controller).
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const LandingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              child,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      ),
      GoRoute(
        path: RouteNames.loginPath,
        name: RouteNames.loginName,
        // Fade-in Login selama 500 ms agar melanjutkan fade-out Landing
        // secara mulus tanpa layar kosong/flash.
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        ),
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

      // ─── Asset Routes ─────────────────────────────────────────────────────
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

      // ─── Admin ────────────────────────────────────────────────────────────
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
        path: RouteNames.adminLocationsPath,
        name: RouteNames.adminLocationsName,
        builder: (context, state) => const AdminLocationsScreen(),
      ),
      GoRoute(
        path: RouteNames.adminUsersPath,
        name: RouteNames.adminUsersName,
        builder: (context, state) => const AdminUsersScreen(),
      ),

      // ─── Pemohon ──────────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.pemohonDashboardPath,
        name: RouteNames.pemohonDashboardName,
        builder: (context, state) => const PemohonDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.pemohonMutasiCreatePath,
        name: RouteNames.pemohonMutasiCreateName,
        builder: (context, state) => const PemohonCreateMutationScreen(),
      ),
      GoRoute(
        path: '/pemohon/mutations/create',
        builder: (context, state) => const PemohonCreateMutationScreen(),
      ),
      GoRoute(
        path: RouteNames.pemohonSubmitSuccessPath,
        name: RouteNames.pemohonSubmitSuccessName,
        redirect: (context, state) => RouteNames.pemohonMutasiPath,
      ),
      GoRoute(
        path: RouteNames.pemohonMutasiPath,
        name: RouteNames.pemohonMutasiName,
        builder: (context, state) {
          final filter = state.uri.queryParameters['filter'] ??
              (state.extra is String ? state.extra as String : null);
          return PemohonMutationListScreen(initialFilter: filter);
        },
      ),
      GoRoute(
        path: '/pemohon/mutations',
        builder: (context, state) {
          final filter = state.uri.queryParameters['filter'] ??
              (state.extra is String ? state.extra as String : null);
          return PemohonMutationListScreen(initialFilter: filter);
        },
      ),
      GoRoute(
        path: '/pemohon/history',
        builder: (context, state) {
          final filter = state.uri.queryParameters['filter'] ??
              (state.extra is String ? state.extra as String : null);
          return PemohonMutationListScreen(initialFilter: filter);
        },
      ),
      GoRoute(
        path: '/pemohon/mutation-history',
        builder: (context, state) {
          final filter = state.uri.queryParameters['filter'] ??
              (state.extra is String ? state.extra as String : null);
          return PemohonMutationListScreen(initialFilter: filter);
        },
      ),
      // Path lebih spesifik dulu (confirm & edit), baru detail :id
      GoRoute(
        path: RouteNames.pemohonConfirmationPath,
        name: RouteNames.pemohonConfirmationName,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return PemohonConfirmationScreen(mutationId: id);
        },
      ),
      GoRoute(
        path: '/pemohon/mutations/:id/confirm',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return PemohonConfirmationScreen(mutationId: id);
        },
      ),
      GoRoute(
        path: RouteNames.pemohonMutasiEditPath,
        name: RouteNames.pemohonMutasiEditName,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return PemohonEditMutationScreen(mutationId: id);
        },
      ),
      GoRoute(
        path: RouteNames.pemohonMutasiDetailPath,
        name: RouteNames.pemohonMutasiDetailName,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return PemohonMutationDetailScreen(mutationId: id);
        },
      ),
      GoRoute(
        path: RouteNames.pemohonNotificationsPath,
        name: RouteNames.pemohonNotificationsName,
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: RouteNames.pemohonProfilePath,
        name: RouteNames.pemohonProfileName,
        builder: (context, state) => const ProfileScreen(),
      ),

      // ─── Operator ─────────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.operatorDashboardPath,
        name: RouteNames.operatorDashboardName,
        builder: (context, state) => const OperatorDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.operatorMutationsPath,
        name: RouteNames.operatorMutationsName,
        builder: (context, state) {
          final filter = state.uri.queryParameters['filter'] ??
              (state.extra is String ? state.extra as String : null);
          return OperatorMutationsScreen(initialFilter: filter);
        },
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
        path: RouteNames.operatorNotificationsPath,
        name: RouteNames.operatorNotificationsName,
        builder: (context, state) => const NotificationScreen(),
      ),

      // ─── Bagian Aset (PRD V1.1 §6.4) ──────────────────────────────────────
      GoRoute(
        path: RouteNames.bagianAsetDashboardPath,
        name: RouteNames.bagianAsetDashboardName,
        builder: (context, state) => const BagianAsetDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.bagianAsetVerificationsPath,
        name: RouteNames.bagianAsetVerificationsName,
        builder: (context, state) => const BagianAsetVerificationsScreen(),
      ),
      GoRoute(
        path: RouteNames.bagianAsetVerificationDetailPath,
        name: RouteNames.bagianAsetVerificationDetailName,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return BagianAsetVerificationDetailScreen(mutationId: id);
        },
      ),
      GoRoute(
        path: RouteNames.bagianAsetReturnFormPath,
        name: RouteNames.bagianAsetReturnFormName,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return BagianAsetReturnFormScreen(mutationId: id);
        },
      ),
      GoRoute(
        path: RouteNames.bagianAsetNotificationsPath,
        name: RouteNames.bagianAsetNotificationsName,
        builder: (context, state) => const NotificationScreen(),
      ),
      // ─── Kadiv ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/kadiv',
        redirect: (context, state) => RouteNames.kadivDashboardPath,
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
        path: RouteNames.kadivNotificationsPath,
        name: RouteNames.kadivNotificationsName,
        builder: (context, state) => const NotificationScreen(),
      ),


      // ─── Common Routes ────────────────────────────────────────────────────
      // Dipakai Operator/Bagian Aset/Pemimpin Divisi/Admin. Pemohon punya profil sendiri
      // (pemohonProfilePath) yang menampilkan info lebih kaya.
      GoRoute(
        path: RouteNames.profilePath,
        name: RouteNames.profileName,
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Halaman Tidak Ditemukan')),
      body: Center(
        child: Text(
          'Error: ${state.error?.message ?? 'Halaman tidak ditemukan'}',
        ),
      ),
    ),
  );
});
