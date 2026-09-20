// lib/app/router/route_names.dart
//
// Konstanta nama dan path route MutasiKu.
// Sumber: PROJECT-SETUP.md §8, TECHNICAL-DESIGN.md §3, ROLE-FLOW.md §10.

/// List nama route dan path di MutasiKu untuk 6 Role.
abstract final class RouteNames {
  // ─── General ──────────────────────────────────────────────────────────────
  static const String landingPath = '/';
  static const String landingName = 'landing';

  static const String loginPath = '/login';
  static const String loginName = 'login';

  static const String dashboardPath = '/dashboard';
  static const String dashboardName = 'dashboard';

  static const String unauthorizedPath = '/unauthorized';
  static const String unauthorizedName = 'unauthorized';

  /// Profil bersama (opsional). Pemohon disarankan pakai [pemohonProfilePath].
  static const String profilePath = '/profile';
  static const String profileName = 'profile';

  // ─── Asset ────────────────────────────────────────────────────────────────
  static const String assetsPath = '/assets';
  static const String assetsName = 'assets';

  static const String assetDetailPath = '/assets/:id';
  static const String assetDetailName = 'assetDetail';

  // ─── Pemohon ──────────────────────────────────────────────────────────────
  static const String pemohonDashboardPath = '/pemohon/dashboard';
  static const String pemohonDashboardName = 'pemohonDashboard';

  /// Daftar mutasi (Cek Tiket / Mutasi Saya)
  static const String pemohonMutasiPath = '/pemohon/mutasi';
  static const String pemohonMutasiName = 'pemohonMutasi';

  /// Pilih aset (langkah 1)
  static const String pemohonSelectAssetPath = '/pemohon/assets/select';
  static const String pemohonSelectAssetName = 'pemohonSelectAsset';

  /// Form pengajuan (langkah 2)
  static const String pemohonMutasiCreatePath = '/pemohon/mutasi/create';
  static const String pemohonMutasiCreateName = 'pemohonMutasiCreate';

  /// Sukses setelah submit (satu path saja)
  static const String pemohonSubmitSuccessPath = '/pemohon/mutasi/success';
  static const String pemohonSubmitSuccessName = 'pemohonSubmitSuccess';

  /// Detail tiket — daftarkan SETELAH confirm & edit di app_router
  static const String pemohonMutasiDetailPath = '/pemohon/mutasi/:id';
  static const String pemohonMutasiDetailName = 'pemohonMutasiDetail';

  static const String pemohonMutasiEditPath = '/pemohon/mutasi/:id/edit';
  static const String pemohonMutasiEditName = 'pemohonMutasiEdit';

  static const String pemohonConfirmationPath = '/pemohon/mutasi/:id/confirm';
  static const String pemohonConfirmationName = 'pemohonConfirmation';

  static const String pemohonNotificationsPath = '/pemohon/notifications';
  static const String pemohonNotificationsName = 'pemohonNotifications';

  static const String pemohonProfilePath = '/pemohon/profile';
  static const String pemohonProfileName = 'pemohonProfile';

  // ─── Operator ─────────────────────────────────────────────────────────────
  static const String operatorDashboardPath = '/operator/dashboard';
  static const String operatorDashboardName = 'operatorDashboard';

  static const String operatorMutationsPath = '/operator/mutations';
  static const String operatorMutationsName = 'operatorMutations';

  static const String operatorVerificationDetailPath =
      '/operator/mutations/:id';
  static const String operatorVerificationDetailName =
      'operatorVerificationDetail';

  static const String operatorReturnFormPath = '/operator/mutations/:id/return';
  static const String operatorReturnFormName = 'operatorReturnForm';

  static const String operatorHistoryPath = '/operator/verification-history';
  static const String operatorHistoryName = 'operatorHistory';

  static const String operatorNotificationsPath = '/operator/notifications';
  static const String operatorNotificationsName = 'operatorNotifications';

  // ─── Kabag Aset ───────────────────────────────────────────────────────────
  static const String kabagDashboardPath = '/kabag/dashboard';
  static const String kabagDashboardName = 'kabagDashboard';

  static const String kabagApprovalsPath = '/kabag/approvals';
  static const String kabagApprovalsName = 'kabagApprovals';

  static const String kabagApprovalDetailPath = '/kabag/approvals/:id';
  static const String kabagApprovalDetailName = 'kabagApprovalDetail';

  static const String kabagRejectFormPath = '/kabag/approvals/:id/reject';
  static const String kabagRejectFormName = 'kabagRejectForm';

  static const String kabagHistoryPath = '/kabag/approval-history';
  static const String kabagHistoryName = 'kabagHistory';

  static const String kabagNotificationsPath = '/kabag/notifications';
  static const String kabagNotificationsName = 'kabagNotifications';

  // ─── Kadiv ────────────────────────────────────────────────────────────────
  static const String kadivDashboardPath = '/kadiv/dashboard';
  static const String kadivDashboardName = 'kadivDashboard';

  static const String kadivApprovalsPath = '/kadiv/approvals';
  static const String kadivApprovalsName = 'kadivApprovals';

  static const String kadivApprovalDetailPath = '/kadiv/approvals/:id';
  static const String kadivApprovalDetailName = 'kadivApprovalDetail';

  static const String kadivRejectFormPath = '/kadiv/approvals/:id/reject';
  static const String kadivRejectFormName = 'kadivRejectForm';

  static const String kadivHistoryPath = '/kadiv/approval-history';
  static const String kadivHistoryName = 'kadivHistory';

  static const String kadivNotificationsPath = '/kadiv/notifications';
  static const String kadivNotificationsName = 'kadivNotifications';

  // ─── Staff Aset ───────────────────────────────────────────────────────────
  static const String staffDashboardPath = '/staff-aset/dashboard';
  static const String staffDashboardName = 'staffDashboard';

  static const String staffMutationsPath = '/staff-aset/mutations';
  static const String staffMutationsName = 'staffMutations';

  static const String staffAssetsPath = '/staff-aset/assets';
  static const String staffAssetsName = 'staffAssets';

  // ─── Admin ────────────────────────────────────────────────────────────────
  static const String adminDashboardPath = '/admin/dashboard';
  static const String adminDashboardName = 'adminDashboard';

  static const String adminUsersPath = '/admin/users';
  static const String adminUsersName = 'adminUsers';

  static const String adminRolesPath = '/admin/roles';
  static const String adminRolesName = 'adminRoles';

  static const String adminLocationsPath = '/admin/locations';
  static const String adminLocationsName = 'adminLocations';

  static const String adminCategoriesPath = '/admin/asset-categories';
  static const String adminCategoriesName = 'adminCategories';

  static const String adminCriteriaPath = '/admin/approval-criteria';
  static const String adminCriteriaName = 'adminCriteria';
}
