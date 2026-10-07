// test/features/kabag/presentation/kabag_approval_widget_test.dart
//
// Widget & presentation tests untuk screen Kabag Aset.

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
import 'package:go_router/go_router.dart';
import 'package:mutasiku/features/kabag/presentation/screens/kabag_approval_detail_screen.dart';
import 'package:mutasiku/features/kabag/presentation/screens/kabag_approvals_screen.dart';
import 'package:mutasiku/features/kabag/presentation/screens/kabag_dashboard_screen.dart';
import 'package:mutasiku/features/kabag/presentation/screens/kabag_reject_form_screen.dart';
import 'package:mutasiku/features/mutation/data/repositories/mutation_repository_impl.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';
import 'package:mutasiku/features/kabag/presentation/providers/kabag_approval_provider.dart';
import 'package:mutasiku/features/notification/presentation/screens/notification_screen.dart';

class FakeKabagAuthRepository implements AuthRepository {
  final User? user;

  FakeKabagAuthRepository({this.user});

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

class FakeKabagAuthNotifier extends AuthNotifier {
  FakeKabagAuthNotifier(User user)
      : super(
          loginUseCase: LoginUseCase(repository: FakeKabagAuthRepository(user: user)),
          logoutUseCase: LogoutUseCase(repository: FakeKabagAuthRepository(user: user)),
          authRepository: FakeKabagAuthRepository(user: user),
        ) {
    state = AuthState(isLoading: false, user: user);
  }
}

void main() {
  setUp(() {
    MutationRepositoryImpl.resetForTesting();
    final assetRepo = AssetRepositoryImpl();
    MutationRepositoryImpl(assetRepository: assetRepo);
  });

  const kabagUser = User(
    id: 'u_kbg_01',
    username: 'kabag1',
    name: 'Bambang Kabag',
    email: 'kabag@mutasiku.id',
    role: UserRole.kabagAset,
  );

  Widget createTestWidget(Widget child) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => FakeKabagAuthNotifier(kabagUser),
        ),
        apiMutationRepositoryProvider.overrideWith(
          (ref) => ref.watch(mutationRepositoryProvider),
        ),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets('KabagDashboardScreen displays header, hero banner and overview stat cards',
      (tester) async {
    await tester.pumpWidget(createTestWidget(const KabagDashboardScreen()));
    await tester.pumpAndSettle();

    // Verifikasi header Bagian Aset Stitch 1:1 (Hamburger & Halo, [Nama]! & Subtitle)
    expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
    expect(find.text('Halo, Bambang Kabag!'), findsOneWidget);
    expect(find.text('Staf Tata Kelola Aset • Verifikasi & Eksekusi Data Fisik'), findsOneWidget);
    expect(find.text('VERIFIKASI & PEMBARUAN ASET'), findsOneWidget);

    // Verifikasi 4 Quick Category cards
    expect(find.text('Lolos Operator'), findsOneWidget);
    expect(find.text('Penetapan PIC'), findsOneWidget);
    expect(find.text('Aset TI'), findsOneWidget);
    expect(find.text('Aset Umum'), findsOneWidget);
  });

  testWidgets('KabagDashboardScreen filter Aset TI and Aset Umum work reactively against real data',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Verifikasi mutasi 1 oleh operator sehingga ada data Aset TI di antrean
    await tester.runAsync(() async {
      final assetRepo = AssetRepositoryImpl();
      final mutRepo = MutationRepositoryImpl(assetRepository: assetRepo);
      await mutRepo.verifyMutation(
        mutationId: 'mut_001',
        operatorName: 'Operator Aset',
        requiresKadivApproval: false,
      );
    });

    await tester.pumpWidget(createTestWidget(const KabagDashboardScreen()));
    await tester.pumpAndSettle();

    // Sebelum filter: tiket Aset TI (ELEKTRONIK-2026-00124) dan Aset Umum (FURNITUR-2026-00018) tampil
    expect(find.text('FURNITUR-2026-00018'), findsOneWidget);
    expect(find.text('ELEKTRONIK-2026-00124'), findsOneWidget);

    // Tap filter "Aset TI"
    await tester.tap(find.byKey(const Key('card_filter_ti')));
    await tester.pumpAndSettle();

    // Hanya Aset TI yang tampil
    expect(find.text('ELEKTRONIK-2026-00124'), findsOneWidget);
    expect(find.text('FURNITUR-2026-00018'), findsNothing);

    // Tap filter "Aset Umum"
    await tester.tap(find.byKey(const Key('card_filter_umum')));
    await tester.pumpAndSettle();

    // Hanya Aset Umum yang tampil
    expect(find.text('FURNITUR-2026-00018'), findsOneWidget);
    expect(find.text('ELEKTRONIK-2026-00124'), findsNothing);
  });

  testWidgets('KabagApprovalsScreen renders search bar, filters, and cards',
      (tester) async {
    await tester.pumpWidget(createTestWidget(const KabagApprovalsScreen()));
    await tester.pumpAndSettle();

    // Verifikasi appbar & filter
    expect(find.text('Menunggu Verifikasi'), findsWidgets);

    // Verifikasi search input
    expect(find.byKey(const Key('input_search_approvals')), findsOneWidget);

    // Verifikasi filter dropdowns
    expect(find.byKey(const Key('dropdown_filter_kabag_status')), findsOneWidget);
    expect(find.byKey(const Key('dropdown_filter_kabag_sort')), findsOneWidget);

    // Verifikasi badge status tampil
    expect(find.text('Menunggu Verifikasi Bagian Aset'), findsWidgets);
  });

  testWidgets('KabagApprovalsScreen search filters list correctly',
      (tester) async {
    await tester.pumpWidget(createTestWidget(const KabagApprovalsScreen()));
    await tester.pumpAndSettle();

    // mut_004 ada di antrean Kabag (Dewi Lestari, FURNITUR-2026-00018)
    expect(find.text('FURNITUR-2026-00018'), findsOneWidget);

    // Cari tiket yang tidak ada
    await tester.enterText(
        find.byKey(const Key('input_search_approvals')), 'XYZ-NONEXISTENT');
    await tester.pumpAndSettle();

    expect(find.text('FURNITUR-2026-00018'), findsNothing);
    expect(find.text('Tidak Ada Pengajuan Menunggu'), findsOneWidget);

    // Hapus pencarian
    await tester.enterText(
        find.byKey(const Key('input_search_approvals')), '');
    await tester.pumpAndSettle();

    expect(find.text('FURNITUR-2026-00018'), findsOneWidget);
  });

  testWidgets(
      'KabagApprovalDetailScreen displays complete mutation data and workflow',
      (tester) async {
    await tester.pumpWidget(createTestWidget(
      const KabagApprovalDetailScreen(mutationId: 'mut_004'),
    ));
    await tester.pumpAndSettle();

    // Ticket Number
    expect(find.text('FURNITUR-2026-00018'), findsOneWidget);
    // Status Badge
    expect(find.text('Menunggu Verifikasi Bagian Aset'), findsWidgets);
    // Pemohon
    expect(find.text('Dewi Lestari'), findsWidgets);
    // Transition Row Lokasi
    expect(find.text('Kantor Pusat'), findsOneWidget);
    expect(find.text('Cabang Semarang'), findsOneWidget);
    // PIC Asal & PIC Baru
    expect(find.text('Siti Rahma'), findsOneWidget);
    // Alasan Mutasi
    expect(find.text('Pengadaan furnitur ruang manager cabang baru.'),
        findsOneWidget);
    // Dokumen
    expect(find.text('Nota_Dinas.pdf'), findsOneWidget);

    // Buttons
    expect(find.byKey(const Key('btn_tolak_approval')), findsOneWidget);
    expect(find.byKey(const Key('btn_setujui_approval')), findsOneWidget);
  });

  testWidgets(
      'Kabag approve flow WITHOUT Kadiv sets status to approved and invalidates providers',
      (tester) async {
    late WidgetRef containerRef;

    final testWidget = ProviderScope(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => FakeKabagAuthNotifier(kabagUser),
        ),
        apiMutationRepositoryProvider.overrideWith(
          (ref) => ref.watch(mutationRepositoryProvider),
        ),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          containerRef = ref;
          return const MaterialApp(
            home: KabagApprovalDetailScreen(mutationId: 'mut_004'),
          );
        },
      ),
    );

    await tester.pumpWidget(testWidget);
    await tester.pumpAndSettle();

    // Tap Setujui
    await tester.tap(find.byKey(const Key('btn_setujui_approval')));
    await tester.pumpAndSettle();

    // Dialog konfirmasi muncul (Verifikasi Data Aset)
    expect(find.text('Verifikasi Data Aset'), findsOneWidget);

    // Tap Ya, Teruskan
    await tester.tap(find.byKey(const Key('btn_confirm_setujui')));
    await tester.pumpAndSettle();

    // Cek status mutasi terupdate ke waitingDivisionHeadApproval
    final detail =
        await containerRef.read(kabagMutationDetailProvider('mut_004').future);
    expect(detail.status.isWaitingDivisionApproval, true);
    expect(detail.assetVerifiedBy, 'Bambang Kabag');
  });

  testWidgets(
      'Kabag approve flow WITH Kadiv sets status to waitingKadivApproval and invalidates providers',
      (tester) async {
    late WidgetRef containerRef;

    final testWidget = ProviderScope(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => FakeKabagAuthNotifier(kabagUser),
        ),
        apiMutationRepositoryProvider.overrideWith(
          (ref) => ref.watch(mutationRepositoryProvider),
        ),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          containerRef = ref;
          return const MaterialApp(
            home: KabagApprovalDetailScreen(mutationId: 'mut_004_kadiv'),
          );
        },
      ),
    );

    await tester.pumpWidget(testWidget);
    await tester.pumpAndSettle();

    // Tap Teruskan / Verifikasi
    await tester.tap(find.byKey(const Key('btn_setujui_approval')));
    await tester.pumpAndSettle();

    // Dialog konfirmasi muncul
    expect(find.text('Verifikasi Data Aset'), findsOneWidget);

    // Tap Ya, Teruskan
    await tester.tap(find.byKey(const Key('btn_confirm_setujui')));
    await tester.pumpAndSettle();

    // Cek status mutasi terupdate ke waitingKadivApproval
    final detail =
        await containerRef.read(kabagMutationDetailProvider('mut_004_kadiv').future);
    expect(detail.status.isWaitingDivisionApproval, true);
    expect(detail.assetVerifiedBy, 'Bambang Kabag');
    expect(detail.requiresKadivApproval, true);
  });

  testWidgets(
      'Kabag reject flow requires reason and sets status to rejected with reason saved',
      (tester) async {
    late WidgetRef containerRef;

    final testWidget = ProviderScope(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => FakeKabagAuthNotifier(kabagUser),
        ),
        apiMutationRepositoryProvider.overrideWith(
          (ref) => ref.watch(mutationRepositoryProvider),
        ),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          containerRef = ref;
          return const MaterialApp(
            home: KabagRejectFormScreen(mutationId: 'mut_004'),
          );
        },
      ),
    );

    await tester.pumpWidget(testWidget);
    await tester.pumpAndSettle();

    // Context Card
    expect(find.text('FURNITUR-2026-00018'), findsOneWidget);

    // Try submitting without reason
    await tester.tap(find.byKey(const Key('btn_submit_tolak')));
    await tester.pumpAndSettle();

    expect(find.text('Alasan penolakan wajib diisi.'), findsOneWidget);

    // Enter valid reason
    await tester.enterText(
      find.byKey(const Key('input_alasan_penolakan')),
      'Anggaran relokasi furnitur belum dialokasikan untuk cabang ini.',
    );
    await tester.pumpAndSettle();

    // Submit rejection
    await tester.tap(find.byKey(const Key('btn_submit_tolak')));
    await tester.pumpAndSettle();

    // Cek status mutasi terupdate ke returned
    final detail =
        await containerRef.read(kabagMutationDetailProvider('mut_004').future);
    expect(detail.status, MutationStatus.returned);
    expect(detail.rejectedBy, 'Bambang Kabag');
    expect(detail.returnReason,
        'Anggaran relokasi furnitur belum dialokasikan untuk cabang ini.');
  });

  testWidgets(
      'NotificationScreen marks as read and navigates to kabag detail when item tapped',
      (tester) async {
    String? navigatedPath;

    final router = GoRouter(
      initialLocation: '/kabag/notifications',
      routes: [
        GoRoute(
          path: '/kabag/notifications',
          builder: (context, state) => const NotificationScreen(),
        ),
        GoRoute(
          path: '/kabag/approvals/:id',
          builder: (context, state) {
            navigatedPath = state.uri.toString();
            return Scaffold(
              body: Text('Kabag Detail: ${state.pathParameters['id']}'),
            );
          },
        ),
        GoRoute(
          path: '/bagian-aset/verifications/:id',
          builder: (context, state) {
            navigatedPath = state.uri.toString();
            return Scaffold(
              body: Text('Kabag Detail: ${state.pathParameters['id']}'),
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => FakeKabagAuthNotifier(kabagUser),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify NotificationScreen renders items
    expect(find.textContaining('FURNITUR-2026-00018'), findsWidgets);

    // Tap first notification item (which has relatedMutationId: mut_004)
    await tester.tap(find.textContaining('FURNITUR-2026-00018').first);
    await tester.pumpAndSettle();

    // Verify navigation reached kabag / bagian-aset approval detail route
    expect(navigatedPath, contains('mut_004'));
    expect(find.text('Kabag Detail: mut_004'), findsOneWidget);
  });
}
