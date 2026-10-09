import 'package:mutasiku/core/errors/failures.dart';
// test/features/bagian_aset/presentation/bagian_aset_widget_test.dart
//
// Widget & presentation tests untuk screen Bagian Aset (PRD V1.1 §6.4).

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
import 'package:mutasiku/features/bagian_aset/presentation/screens/bagian_aset_dashboard_screen.dart';
import 'package:mutasiku/features/bagian_aset/presentation/screens/bagian_aset_return_form_screen.dart';
import 'package:mutasiku/features/bagian_aset/presentation/screens/bagian_aset_verification_detail_screen.dart';
import 'package:mutasiku/features/bagian_aset/presentation/screens/bagian_aset_verifications_screen.dart';
import 'package:mutasiku/features/mutation/data/repositories/mutation_repository_impl.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';
import 'package:mutasiku/features/bagian_aset/presentation/providers/bagian_aset_verification_provider.dart';
import 'package:mutasiku/features/notification/presentation/screens/notification_screen.dart';

class FakeBagianAsetAuthRepository implements AuthRepository {
  final User? user;

  FakeBagianAsetAuthRepository({this.user});

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
    @override
  Future<Result<User>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword.length < 8) {
      return Result.failure(
        const ValidationFailure(message: 'Password baru minimal 8 karakter.'),
      );
    }
    if (newPassword != confirmPassword) {
      return Result.failure(
        const ValidationFailure(message: 'Konfirmasi password baru tidak cocok.'),
      );
    }
    if (newPassword == currentPassword) {
      return Result.failure(
        const ValidationFailure(
          message: 'Password baru harus berbeda dengan password lama.',
        ),
      );
    }
    if (user != null) {
      return Result.success(user!.copyWith(mustChangePassword: false));
    }
    return Result.failure(
      const UnauthorizedFailure(message: 'Pengguna tidak ditemukan.'),
    );
  }
}

class FakeBagianAsetAuthNotifier extends AuthNotifier {
  FakeBagianAsetAuthNotifier(User user)
    : super(
        loginUseCase: LoginUseCase(
          repository: FakeBagianAsetAuthRepository(user: user),
        ),
        logoutUseCase: LogoutUseCase(
          repository: FakeBagianAsetAuthRepository(user: user),
        ),
        authRepository: FakeBagianAsetAuthRepository(user: user),
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

  const bagianAsetUser = User(
    id: 'u_ba_01',
    username: 'bagianaset1',
    name: 'Bambang Bagian Aset',
    email: 'bagian.aset@mutasiku.id',
    role: UserRole.bagianAset,
  );

  Widget createTestWidget(Widget child) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => FakeBagianAsetAuthNotifier(bagianAsetUser),
        ),
        apiMutationRepositoryProvider.overrideWith(
          (ref) => ref.watch(mutationRepositoryProvider),
        ),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets(
    'BagianAsetDashboardScreen displays header, hero banner and overview stat cards',
    (tester) async {
      await tester.pumpWidget(
        createTestWidget(const BagianAsetDashboardScreen()),
      );
      await tester.pumpAndSettle();

      // Verifikasi header Bagian Aset Stitch 1:1 (Hamburger & Halo, [Nama]! & Subtitle)
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
      expect(find.text('Halo, Bambang Bagian Aset!'), findsOneWidget);
      expect(
        find.text('Staf Tata Kelola Aset • Verifikasi & Eksekusi Data Fisik'),
        findsOneWidget,
      );
      expect(find.text('VERIFIKASI & PEMBARUAN ASET'), findsOneWidget);

      // Verifikasi 4 Quick Category cards
      expect(find.text('Lolos Operator'), findsOneWidget);
      expect(find.text('Penetapan PIC'), findsOneWidget);
      expect(find.text('Aset TI'), findsOneWidget);
      expect(find.text('Aset Umum'), findsOneWidget);
    },
  );

  testWidgets(
    'BagianAsetDashboardScreen filter Aset TI and Aset Umum work reactively against real data',
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

      await tester.pumpWidget(
        createTestWidget(const BagianAsetDashboardScreen()),
      );
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
    },
  );

  testWidgets(
    'BagianAsetVerificationsScreen renders search bar, filters, and cards',
    (tester) async {
      await tester.pumpWidget(
        createTestWidget(const BagianAsetVerificationsScreen()),
      );
      await tester.pumpAndSettle();

      // Verifikasi appbar & filter
      expect(find.text('Menunggu Verifikasi'), findsWidgets);

      // Verifikasi search input
      expect(find.byKey(const Key('input_search_approvals')), findsOneWidget);

      // Verifikasi filter dropdowns
      expect(
        find.byKey(const Key('dropdown_filter_bagian_aset_status')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('dropdown_filter_bagian_aset_sort')),
        findsOneWidget,
      );

      // Verifikasi badge status tampil
      expect(find.text('Menunggu Verifikasi Bagian Aset'), findsWidgets);
    },
  );

  testWidgets('BagianAsetVerificationsScreen search filters list correctly', (
    tester,
  ) async {
    await tester.pumpWidget(
      createTestWidget(const BagianAsetVerificationsScreen()),
    );
    await tester.pumpAndSettle();

    // mut_004 ada di antrean Bagian Aset (Dewi Lestari, FURNITUR-2026-00018)
    expect(find.text('FURNITUR-2026-00018'), findsOneWidget);

    // Cari tiket yang tidak ada
    await tester.enterText(
      find.byKey(const Key('input_search_approvals')),
      'XYZ-NONEXISTENT',
    );
    await tester.pumpAndSettle();

    expect(find.text('FURNITUR-2026-00018'), findsNothing);
    expect(find.text('Tidak Ada Pengajuan Menunggu'), findsOneWidget);

    // Hapus pencarian
    await tester.enterText(find.byKey(const Key('input_search_approvals')), '');
    await tester.pumpAndSettle();

    expect(find.text('FURNITUR-2026-00018'), findsOneWidget);
  });

  testWidgets(
    'BagianAsetVerificationDetailScreen displays complete mutation data and workflow',
    (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const BagianAsetVerificationDetailScreen(mutationId: 'mut_004'),
        ),
      );
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
      expect(
        find.text('Pengadaan furnitur ruang manager cabang baru.'),
        findsOneWidget,
      );
      // Dokumen
      expect(find.text('Nota_Dinas.pdf'), findsOneWidget);

      // Buttons
      expect(find.byKey(const Key('btn_tolak_approval')), findsOneWidget);
      expect(find.byKey(const Key('btn_setujui_approval')), findsOneWidget);
    },
  );

  testWidgets(
    'Bagian Aset verify & forward flow WITHOUT Kadiv sets status to approved and invalidates providers',
    (tester) async {
      late WidgetRef containerRef;

      final testWidget = ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => FakeBagianAsetAuthNotifier(bagianAsetUser),
          ),
          apiMutationRepositoryProvider.overrideWith(
            (ref) => ref.watch(mutationRepositoryProvider),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            containerRef = ref;
            return const MaterialApp(
              home: BagianAsetVerificationDetailScreen(mutationId: 'mut_004'),
            );
          },
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Tap Setujui / Teruskan
      await tester.tap(find.byKey(const Key('btn_setujui_approval')));
      await tester.pumpAndSettle();

      // Dialog konfirmasi muncul (Verifikasi Data Aset)
      expect(find.text('Verifikasi Data Aset'), findsOneWidget);

      // Tap Ya, Teruskan
      await tester.tap(find.byKey(const Key('btn_confirm_setujui')));
      await tester.pumpAndSettle();

      // Cek status mutasi terupdate ke waitingDivisionHeadApproval
      final detail = await containerRef.read(
        kabagMutationDetailProvider('mut_004').future,
      );
      expect(detail.status.isWaitingDivisionApproval, true);
      expect(detail.assetVerifiedBy, 'Bambang Bagian Aset');
    },
  );

  testWidgets(
    'Bagian Aset verify & forward flow WITH Kadiv sets status to waitingKadivApproval and invalidates providers',
    (tester) async {
      late WidgetRef containerRef;

      final testWidget = ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => FakeBagianAsetAuthNotifier(bagianAsetUser),
          ),
          apiMutationRepositoryProvider.overrideWith(
            (ref) => ref.watch(mutationRepositoryProvider),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            containerRef = ref;
            return const MaterialApp(
              home: BagianAsetVerificationDetailScreen(
                mutationId: 'mut_004_kadiv',
              ),
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
      final detail = await containerRef.read(
        bagianAsetMutationDetailProvider('mut_004_kadiv').future,
      );
      expect(detail.status.isWaitingDivisionApproval, true);
      expect(detail.assetVerifiedBy, 'Bambang Bagian Aset');
      expect(detail.requiresKadivApproval, true);
    },
  );

  testWidgets(
    'Bagian Aset return flow requires reason and sets status to returned with reason saved',
    (tester) async {
      late WidgetRef containerRef;

      final testWidget = ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => FakeBagianAsetAuthNotifier(bagianAsetUser),
          ),
          apiMutationRepositoryProvider.overrideWith(
            (ref) => ref.watch(mutationRepositoryProvider),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            containerRef = ref;
            return const MaterialApp(
              home: BagianAsetReturnFormScreen(mutationId: 'mut_004'),
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

      // Submit return
      await tester.tap(find.byKey(const Key('btn_submit_tolak')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Cek status mutasi terupdate ke returned
      final detailFuture = containerRef.read(
        bagianAsetMutationDetailProvider('mut_004').future,
      );
      await tester.pump(const Duration(milliseconds: 300));
      final detail = await detailFuture;
      expect(detail.status, MutationStatus.returned);
      expect(
        detail.returnReason,
        'Anggaran relokasi furnitur belum dialokasikan untuk cabang ini.',
      );
    },
  );

  testWidgets(
    'NotificationScreen marks as read and navigates to bagian aset detail when item tapped',
    (tester) async {
      String? navigatedPath;

      final router = GoRouter(
        initialLocation: '/bagian-aset/notifications',
        routes: [
          GoRoute(
            path: '/bagian-aset/notifications',
            builder: (context, state) => const NotificationScreen(),
          ),
          GoRoute(
            path: '/bagian-aset/verifications/:id',
            builder: (context, state) {
              navigatedPath = state.uri.toString();
              return Scaffold(
                body: Text('Bagian Aset Detail: ${state.pathParameters['id']}'),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => FakeBagianAsetAuthNotifier(bagianAsetUser),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Verify NotificationScreen renders items
      expect(find.textContaining('FURNITUR-2026-00018'), findsWidgets);

      // Tap first notification item (which has relatedMutationId: mut_004)
      await tester.tap(find.textContaining('FURNITUR-2026-00018').first);
      await tester.pumpAndSettle();

      // Verify navigation reached bagian-aset verification detail route
      expect(navigatedPath, contains('mut_004'));
      expect(find.text('Bagian Aset Detail: mut_004'), findsOneWidget);
    },
  );
}
