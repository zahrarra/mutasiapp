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
import 'package:mutasiku/features/notification/presentation/screens/notification_screen.dart';
import 'package:mutasiku/features/notification/presentation/widgets/notification_tile.dart';

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
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets('KabagDashboardScreen displays greeting and overview stat cards',
      (tester) async {
    await tester.pumpWidget(createTestWidget(const KabagDashboardScreen()));
    await tester.pumpAndSettle();

    // Verifikasi teks greeting
    expect(find.text('Halo, Bambang Kabag'), findsOneWidget);

    // Verifikasi stat cards
    expect(find.text('Menunggu Approval'), findsOneWidget);
    expect(find.text('Disetujui'), findsOneWidget);
    expect(find.text('Ditolak'), findsOneWidget);

    // Verifikasi tombol primary action
    expect(find.byKey(const Key('btn_lihat_approval')), findsOneWidget);
  });

  testWidgets('KabagApprovalsScreen renders search bar, filters, and cards',
      (tester) async {
    await tester.pumpWidget(createTestWidget(const KabagApprovalsScreen()));
    await tester.pumpAndSettle();

    // Verifikasi appbar
    expect(find.text('Menunggu Approval'), findsOneWidget);

    // Verifikasi search input
    expect(find.byKey(const Key('input_search_approvals')), findsOneWidget);

    // Verifikasi filter chips
    expect(find.byKey(const Key('chip_filter_semua')), findsOneWidget);
    expect(find.byKey(const Key('chip_filter_terbaru')), findsOneWidget);
    expect(find.byKey(const Key('chip_filter_terlama')), findsOneWidget);

    // Verifikasi badge Menunggu Approval Kabag tampil
    expect(find.text('Menunggu Approval Kabag'), findsWidgets);
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
    expect(find.text('Menunggu Approval Kabag'), findsWidgets);
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

    // Dialog konfirmasi muncul (default requiresKadiv = false / 'Tidak perlu')
    expect(find.text('Konfirmasi Persetujuan'), findsOneWidget);
    expect(find.text('Tidak perlu'), findsOneWidget);

    // Tap Ya, Setujui
    await tester.tap(find.byKey(const Key('btn_confirm_setujui')));
    await tester.pumpAndSettle();

    // Cek status mutasi terupdate ke approved
    final detail =
        await containerRef.read(mutationDetailProvider('mut_004').future);
    expect(detail.status, MutationStatus.approved);
    expect(detail.approvedBy, 'Bambang Kabag');
    expect(detail.requiresKadivApproval, false);
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

    // Pilih Radio 'Ya, butuh Kadiv'
    await tester.tap(find.text('Ya, butuh Kadiv'));
    await tester.pumpAndSettle();

    // Tap Ya, Setujui
    await tester.tap(find.byKey(const Key('btn_confirm_setujui')));
    await tester.pumpAndSettle();

    // Cek status mutasi terupdate ke waitingKadivApproval
    final detail =
        await containerRef.read(mutationDetailProvider('mut_004').future);
    expect(detail.status, MutationStatus.waitingKadivApproval);
    expect(detail.approvedBy, 'Bambang Kabag');
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

    // Cek status mutasi terupdate ke rejected
    final detail =
        await containerRef.read(mutationDetailProvider('mut_004').future);
    expect(detail.status, MutationStatus.rejected);
    expect(detail.rejectedBy, 'Bambang Kabag');
    expect(detail.rejectionReason,
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
    expect(find.byType(NotificationTile), findsWidgets);

    // Tap first notification item (which has relatedMutationId: mut_004)
    await tester.tap(find.byType(NotificationTile).first);
    await tester.pumpAndSettle();

    // Verify navigation reached kabag approval detail route
    expect(navigatedPath, '/kabag/approvals/mut_004');
    expect(find.text('Kabag Detail: mut_004'), findsOneWidget);
  });
}
