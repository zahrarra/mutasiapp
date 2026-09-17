// test/features/kadiv/presentation/screens/kadiv_approval_screens_test.dart
//
// Widget & presentation tests untuk screen Kadiv.
// Sumber: SCREEN-SPEC.md KDV-001–004, ROLE-FLOW.md §6, DESIGN.md.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';

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
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => FakeKadivAuthNotifier(kadivUser),
        ),
        mutationRepositoryProvider.overrideWithValue(mutationRepository),
      ],
      child: MaterialApp(
        home: child,
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
}
