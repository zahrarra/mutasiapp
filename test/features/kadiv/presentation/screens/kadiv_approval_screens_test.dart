// test/features/kadiv/presentation/screens/kadiv_approval_screens_test.dart
//
// Widget & presentation tests untuk screen Kadiv.
// Sumber: SCREEN-SPEC.md KDV-001–004, ROLE-FLOW.md §6, DESIGN.md.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/features/asset/data/repositories/asset_repository_impl.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/auth/domain/repositories/auth_repository.dart';
import 'package:mutasiku/features/auth/domain/usecases/login_usecase.dart';
import 'package:mutasiku/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mutasiku/features/auth/presentation/providers/auth_provider.dart';
import 'package:mutasiku/features/kadiv/presentation/screens/kadiv_approval_detail_screen.dart';
import 'package:mutasiku/features/kadiv/presentation/screens/kadiv_approvals_screen.dart';
import 'package:mutasiku/features/kadiv/presentation/screens/kadiv_dashboard_screen.dart';
import 'package:mutasiku/features/kadiv/presentation/screens/kadiv_reject_form_screen.dart';
import 'package:mutasiku/features/mutation/data/repositories/mutation_repository_impl.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';
import 'package:mutasiku/features/profile/presentation/screens/profile_screen.dart';

class FakeKadivAuthRepository implements AuthRepository {
  final User? user;

  FakeKadivAuthRepository({this.user});

  @override
  Future<Result<User?>> getCurrentUser() async => Result.success(user);

  @override
  Future<Result<User>> login({
    required String username,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}
}

class FakeKadivAuthNotifier extends AuthNotifier {
  FakeKadivAuthNotifier(User user)
      : super(
          loginUseCase:
              LoginUseCase(repository: FakeKadivAuthRepository(user: user)),
          logoutUseCase:
              LogoutUseCase(repository: FakeKadivAuthRepository(user: user)),
          authRepository: FakeKadivAuthRepository(user: user),
        ) {
    state = AuthState(isLoading: false, user: user);
  }
}

void main() {
  late MutationRepositoryImpl mutationRepository;

  setUp(() {
    MutationRepositoryImpl.resetForTesting();
    final assetRepo = AssetRepositoryImpl();
    mutationRepository = MutationRepositoryImpl(assetRepository: assetRepo);
  });

  const kadivUser = User(
    id: 'u_kdv_01',
    username: 'kadiv1',
    name: 'Drs. Ahmad Dahlan (Kadiv)',
    email: 'kadiv@mutasiku.id',
    role: UserRole.kadiv,
  );

  Widget createTestWidget(Widget child) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => child,
        ),
        GoRoute(
          path: '/kadiv/approvals',
          builder: (context, state) =>
              const Scaffold(body: Text('Approvals List')),
        ),
        GoRoute(
          path: '/kadiv/dashboard',
          builder: (context, state) =>
              const Scaffold(body: Text('Dashboard Kadiv')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => FakeKadivAuthNotifier(kadivUser),
        ),
        mutationRepositoryProvider.overrideWithValue(mutationRepository),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('KadivDashboardScreen displays greeting, stats, and action button',
      (tester) async {
    await tester.pumpWidget(createTestWidget(const KadivDashboardScreen()));
    await tester.pumpAndSettle();

    // Verifikasi teks greeting
    expect(find.text('Halo, Drs. Ahmad Dahlan (Kadiv)'), findsOneWidget);

    // Verifikasi stat cards
    expect(find.text('Menunggu Approval'), findsOneWidget);
    expect(find.text('Disetujui'), findsOneWidget);
    expect(find.text('Ditolak'), findsOneWidget);

    // Verifikasi tombol primary action
    expect(find.byKey(const Key('btn_lihat_approval_kadiv')), findsOneWidget);

    // Verifikasi section pengajuan terbaru
    expect(find.text('Pengajuan Terbaru'), findsOneWidget);
  });

  testWidgets('KadivApprovalsScreen renders search, filter chips, and cards',
      (tester) async {
    await tester.pumpWidget(createTestWidget(const KadivApprovalsScreen()));
    await tester.pumpAndSettle();

    // Verifikasi appbar
    expect(find.text('Approval Kadiv'), findsOneWidget);

    // Verifikasi search input
    expect(find.byKey(const Key('input_search_kadiv_approvals')), findsOneWidget);

    // Verifikasi status filter chips
    expect(find.byKey(const Key('chip_filter_kadiv_menunggu')), findsOneWidget);
    expect(find.byKey(const Key('chip_filter_kadiv_disetujui')), findsOneWidget);
    expect(find.byKey(const Key('chip_filter_kadiv_ditolak')), findsOneWidget);
    expect(find.byKey(const Key('chip_filter_kadiv_semua')), findsOneWidget);

    // Verifikasi sort chips
    expect(find.byKey(const Key('chip_filter_kadiv_terbaru')), findsOneWidget);
    expect(find.byKey(const Key('chip_filter_kadiv_terlama')), findsOneWidget);

    // Verifikasi adanya item mut_005 yang berstatus Menunggu Approval Kadiv
    expect(find.text('Menunggu Approval Kadiv'), findsWidgets);
    expect(find.text('ELEKTRONIK-2026-00088'), findsOneWidget);
  });

  testWidgets(
      'KadivApprovalDetailScreen displays Kabag approval result, timeline, and actions',
      (tester) async {
    await tester.pumpWidget(
      createTestWidget(
        const KadivApprovalDetailScreen(mutationId: 'mut_005'),
      ),
    );
    await tester.pumpAndSettle();

    // Verifikasi App bar
    expect(find.text('Detail Approval Kadiv'), findsOneWidget);

    // Verifikasi Ticket & Status
    expect(find.text('ELEKTRONIK-2026-00088'), findsOneWidget);
    expect(find.text('Menunggu Approval Kadiv'), findsWidgets);

    // Verifikasi HASIL APPROVAL KABAG ditampilkan (Scope PRD & Task)
    expect(find.text('Hasil Approval Kabag Aset'), findsOneWidget);
    expect(find.text('Disetujui Oleh: '), findsOneWidget);
    expect(find.text('H. M. Yusuf (Kabag Aset)'), findsOneWidget);

    // Verifikasi Aset & Alasan
    expect(find.text('Server Rack Enterprise Dell PowerEdge'), findsOneWidget);
    expect(find.text('Alasan Mutasi'), findsOneWidget);

    // Verifikasi Timeline Workflow
    expect(find.text('Timeline Workflow'), findsOneWidget);
    expect(find.text('Approval Kabag Aset'), findsOneWidget);
    expect(find.text('Approval Kadiv'), findsOneWidget);

    // Verifikasi Action Buttons [ Tolak ] dan [ Setujui ]
    expect(find.byKey(const Key('btn_tolak_approval_kadiv')), findsOneWidget);
    expect(find.byKey(const Key('btn_setujui_approval_kadiv')), findsOneWidget);
  });

  testWidgets(
      'KadivRejectFormScreen validates empty reason and submits rejection',
      (tester) async {
    await tester.pumpWidget(
      createTestWidget(
        const KadivRejectFormScreen(mutationId: 'mut_005'),
      ),
    );
    await tester.pumpAndSettle();

    // Verifikasi title & context card
    expect(find.text('Tolak Pengajuan (Kadiv)'), findsOneWidget);
    expect(find.text('ELEKTRONIK-2026-00088'), findsOneWidget);

    // Verifikasi input alasan penolakan
    final inputReason = find.byKey(const Key('input_alasan_penolakan_kadiv'));
    expect(inputReason, findsOneWidget);

    // Coba submit tanpa mengisi alasan -> validasi muncul
    final btnSubmit = find.byKey(const Key('btn_submit_tolak_kadiv'));
    await tester.tap(btnSubmit);
    await tester.pumpAndSettle();

    expect(find.text('Alasan penolakan tidak boleh kosong.'), findsOneWidget);

    // Masukkan alasan kurang dari 5 karakter -> validasi minimal 5 karakter
    await tester.enterText(inputReason, 'abc');
    await tester.tap(btnSubmit);
    await tester.pumpAndSettle();

    expect(find.text('Alasan penolakan minimal 5 karakter.'), findsOneWidget);
  });

  testWidgets(
      'Kadiv approve flow persists MutationStatus.approved and kadivApprovedBy',
      (tester) async {
    await tester.pumpWidget(
      createTestWidget(
        const KadivApprovalDetailScreen(mutationId: 'mut_005'),
      ),
    );
    await tester.pumpAndSettle();

    // Pastikan tombol setujui ada dan klik
    final btnApprove = find.byKey(const Key('btn_setujui_approval_kadiv'));
    expect(btnApprove, findsOneWidget);
    await tester.tap(btnApprove);
    await tester.pumpAndSettle();

    // Dialog konfirmasi muncul
    expect(find.text('Konfirmasi Approval Kadiv'), findsOneWidget);
    final btnConfirm = find.byKey(const Key('btn_confirm_setujui_kadiv'));
    expect(btnConfirm, findsOneWidget);
    await tester.tap(btnConfirm);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Verifikasi pada repository bahwa status mut_005 berubah menjadi approved
    Mutation? updatedMutation;
    await tester.runAsync(() async {
      final updatedResult = await mutationRepository.getMutationById('mut_005');
      updatedMutation = updatedResult.dataOrNull;
    });
    expect(updatedMutation, isNotNull);
    expect(updatedMutation!.status, MutationStatus.approved);
    expect(updatedMutation!.kadivApprovedBy, 'Drs. Ahmad Dahlan (Kadiv)');
    expect(updatedMutation!.kadivApprovedAt, isNotNull);
  });

  testWidgets(
      'Kadiv reject flow persists MutationStatus.rejected with kadivRejectionReason',
      (tester) async {
    await tester.pumpWidget(
      createTestWidget(
        const KadivRejectFormScreen(mutationId: 'mut_005'),
      ),
    );
    await tester.pumpAndSettle();

    final inputReason = find.byKey(const Key('input_alasan_penolakan_kadiv'));
    await tester.enterText(
        inputReason, 'Aset server utama tidak diizinkan mutasi sebelum pengadaan selesai.');
    await tester.pumpAndSettle();

    final btnSubmit = find.byKey(const Key('btn_submit_tolak_kadiv'));
    await tester.tap(btnSubmit);
    await tester.pumpAndSettle();

    // Dialog konfirmasi muncul
    expect(find.text('Konfirmasi Penolakan Kadiv'), findsOneWidget);
    final btnConfirm = find.byKey(const Key('btn_confirm_tolak_kadiv_dialog'));
    expect(btnConfirm, findsOneWidget);
    await tester.tap(btnConfirm);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Verifikasi pada repository bahwa status mut_005 berubah menjadi rejected
    Mutation? updatedRejectMutation;
    await tester.runAsync(() async {
      final updatedResult = await mutationRepository.getMutationById('mut_005');
      updatedRejectMutation = updatedResult.dataOrNull;
    });
    expect(updatedRejectMutation, isNotNull);
    expect(updatedRejectMutation!.status, MutationStatus.rejected);
    expect(updatedRejectMutation!.rejectionReason,
        'Aset server utama tidak diizinkan mutasi sebelum pengadaan selesai.');
    expect(updatedRejectMutation!.kadivRejectionReason,
        'Aset server utama tidak diizinkan mutasi sebelum pengadaan selesai.');
    expect(updatedRejectMutation!.kadivRejectedBy, 'Drs. Ahmad Dahlan (Kadiv)');
    expect(updatedRejectMutation!.kadivRejectedAt, isNotNull);
  });

  testWidgets('KadivApprovalsScreen search filters results correctly',
      (tester) async {
    await tester.pumpWidget(createTestWidget(const KadivApprovalsScreen()));
    await tester.pumpAndSettle();

    // Default item ada
    expect(find.text('ELEKTRONIK-2026-00088'), findsOneWidget);

    // Ketik pencarian yang tidak cocok
    final searchInput = find.byKey(const Key('input_search_kadiv_approvals'));
    await tester.enterText(searchInput, 'XYZ-TIDAK-ADA');
    await tester.pumpAndSettle();

    // Empty state muncul
    expect(find.text('ELEKTRONIK-2026-00088'), findsNothing);
    expect(find.text('Tidak Ada Mutasi Menunggu Approval'), findsOneWidget);

    // Bersihkan pencarian -> item muncul lagi
    await tester.enterText(searchInput, '');
    await tester.pumpAndSettle();
    expect(find.text('ELEKTRONIK-2026-00088'), findsOneWidget);
  });

  testWidgets('ProfileScreen renders Kadiv profile consistently',
      (tester) async {
    await tester.pumpWidget(createTestWidget(const ProfileScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Drs. Ahmad Dahlan (Kadiv)'), findsOneWidget);
    expect(find.text('kadiv@mutasiku.id'), findsOneWidget);
    expect(find.text('Kadiv'), findsWidgets);
    expect(find.text('Informasi Akun'), findsOneWidget);
  });
}
