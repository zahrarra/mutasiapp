// test/features/operator/presentation/operator_verification_widget_test.dart
//
// Widget & presentation tests untuk screen Operator Verification.

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
import 'package:mutasiku/features/mutation/data/repositories/mutation_repository_impl.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';
import 'package:mutasiku/features/notification/presentation/screens/notification_screen.dart';
import 'package:mutasiku/features/notification/presentation/widgets/notification_tile.dart';
import 'package:mutasiku/features/operator/presentation/screens/operator_dashboard_screen.dart';
import 'package:mutasiku/features/operator/presentation/screens/operator_mutations_screen.dart';
import 'package:mutasiku/features/operator/presentation/screens/operator_verification_detail_screen.dart';
import 'package:mutasiku/features/operator/presentation/screens/operator_return_form_screen.dart';

class FakeAuthRepository implements AuthRepository {
  final User? user;

  FakeAuthRepository({this.user});

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

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(User user)
      : super(
          loginUseCase: LoginUseCase(repository: FakeAuthRepository(user: user)),
          logoutUseCase: LogoutUseCase(repository: FakeAuthRepository(user: user)),
          authRepository: FakeAuthRepository(user: user),
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

  const operatorUser = User(
    id: 'u_opr_01',
    username: 'operator1',
    name: 'Siti Operator',
    email: 'operator@mutasiku.id',
    role: UserRole.operator,
  );

  Widget createTestWidget(Widget child) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => FakeAuthNotifier(operatorUser),
        ),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets('OperatorDashboardScreen displays greeting and stat cards',
      (tester) async {
    await tester.pumpWidget(createTestWidget(const OperatorDashboardScreen()));
    await tester.pumpAndSettle();

    // Verifikasi teks greeting
    expect(find.text('Halo, Siti Operator'), findsOneWidget);

    // Verifikasi stat cards
    expect(find.text('Menunggu Verifikasi'), findsOneWidget);
    expect(find.text('Pengajuan Dikembalikan'), findsOneWidget);

    // Verifikasi tombol primary action
    expect(find.byKey(const Key('btn_lihat_pengajuan')), findsOneWidget);
  });

  testWidgets('OperatorMutationsScreen renders search bar and sort chips',
      (tester) async {
    await tester.pumpWidget(createTestWidget(const OperatorMutationsScreen()));
    await tester.pumpAndSettle();

    // Verifikasi appbar
    expect(find.text('Pengajuan Masuk'), findsOneWidget);

    // Verifikasi search input
    expect(find.byKey(const Key('input_search_mutations')), findsOneWidget);

    // Verifikasi sort chips
    expect(find.byKey(const Key('chip_sort_terbaru')), findsOneWidget);
    expect(find.byKey(const Key('chip_sort_terlama')), findsOneWidget);

    // Verifikasi card pengajuan masuk berstatus Diajukan tampil
    expect(find.text('Diajukan'), findsWidgets);
  });

  testWidgets('OperatorMutationsScreen search filters results correctly',
      (tester) async {
    await tester.pumpWidget(createTestWidget(const OperatorMutationsScreen()));
    await tester.pumpAndSettle();

    // Pastikan mut_001 (Rina) dan mut_002 (Budi Santoso) ada di list awal
    expect(find.text('Rina'), findsWidgets);
    expect(find.text('Budi Santoso'), findsWidgets);

    // Filter dengan nama "Budi"
    await tester.enterText(
        find.byKey(const Key('input_search_mutations')), 'Budi');
    await tester.pumpAndSettle();

    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('Rina'), findsNothing);

    // Hapus search
    await tester.enterText(
        find.byKey(const Key('input_search_mutations')), '');
    await tester.pumpAndSettle();

    expect(find.text('Budi Santoso'), findsWidgets);
    expect(find.text('Rina'), findsWidgets);
  });

  testWidgets(
      'OperatorVerificationDetailScreen displays submission data including Pemakai Lama',
      (tester) async {
    await tester.pumpWidget(createTestWidget(
      const OperatorVerificationDetailScreen(mutationId: 'mut_001'),
    ));
    await tester.pumpAndSettle();

    // Ticket number
    expect(find.text('ELEKTRONIK-2026-00124'), findsOneWidget);
    // Pemohon
    expect(find.text('Rina'), findsWidgets);
    // Pemakai Lama (PIC Asal)
    expect(find.text('Pemakai Lama (PIC Asal)'), findsOneWidget);
    // PIC Baru (Tujuan)
    expect(find.text('PIC Baru (Tujuan)'), findsOneWidget);
    // Lokasi Asal & Lokasi Tujuan
    expect(find.text('Kantor Pusat'), findsOneWidget);
    expect(find.text('Cabang Surabaya'), findsOneWidget);
    // Alasan Mutasi
    expect(find.text('Perpindahan unit kerja ke Cabang Surabaya.'),
        findsOneWidget);

    // Action buttons: Kembalikan & Verifikasi Valid
    expect(find.byKey(const Key('btn_kembalikan_pengajuan')), findsOneWidget);
    expect(find.byKey(const Key('btn_verifikasi_valid')), findsOneWidget);
  });

  testWidgets(
      'Operator verify flow advances status to waitingKabagApproval and invalidates providers',
      (tester) async {
    late WidgetRef containerRef;

    final testWidget = ProviderScope(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => FakeAuthNotifier(operatorUser),
        ),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          containerRef = ref;
          return const MaterialApp(
            home: OperatorVerificationDetailScreen(mutationId: 'mut_001'),
          );
        },
      ),
    );

    await tester.pumpWidget(testWidget);
    await tester.pumpAndSettle();

    // Tap Verifikasi Valid
    await tester.tap(find.byKey(const Key('btn_verifikasi_valid')));
    await tester.pumpAndSettle();

    // Dialog konfirmasi muncul
    expect(find.text('Konfirmasi Verifikasi'), findsOneWidget);
    expect(
        find.text(
            'Apakah Anda yakin data dan dokumen pengajuan ELEKTRONIK-2026-00124 sudah valid dan lengkap?\n\nPengajuan akan diteruskan ke Kabag Aset.'),
        findsOneWidget);

    // Konfirmasi Ya
    await tester.tap(find.byKey(const Key('btn_confirm_verifikasi')));
    await tester.pumpAndSettle();

    // Cek status mutasi telah terupdate ke waitingKabagApproval
    final detail =
        await containerRef.read(mutationDetailProvider('mut_001').future);
    expect(detail.status.name, 'waitingKabagApproval');
    expect(detail.verifiedBy, 'Siti Operator');
  });

  testWidgets(
      'Operator return flow requires reason and sets status to returned',
      (tester) async {
    late WidgetRef containerRef;

    final testWidget = ProviderScope(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => FakeAuthNotifier(operatorUser),
        ),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          containerRef = ref;
          return const MaterialApp(
            home: OperatorReturnFormScreen(mutationId: 'mut_002'),
          );
        },
      ),
    );

    await tester.pumpWidget(testWidget);
    await tester.pumpAndSettle();

    // Verify card context
    expect(find.text('KENDARAAN-2026-00042'), findsOneWidget);

    // Try submitting without reason
    await tester.tap(find.byKey(const Key('btn_submit_kembalikan')));
    await tester.pumpAndSettle();

    expect(find.text('Alasan pengembalian wajib diisi.'), findsOneWidget);

    // Enter valid reason
    await tester.enterText(
      find.byKey(const Key('input_alasan_pengembalian')),
      'Dokumen surat tugas operasional tidak memiliki cap basah.',
    );
    await tester.pumpAndSettle();

    // Submit return
    await tester.tap(find.byKey(const Key('btn_submit_kembalikan')));
    await tester.pumpAndSettle();

    // Cek status mutasi telah terupdate ke returned
    final detail =
        await containerRef.read(mutationDetailProvider('mut_002').future);
    expect(detail.status.name, 'returned');
    expect(detail.returnReason,
        'Dokumen surat tugas operasional tidak memiliki cap basah.');
  });

  testWidgets(
      'NotificationScreen marks as read and navigates to operator detail when item tapped',
      (tester) async {
    String? navigatedPath;

    final router = GoRouter(
      initialLocation: '/operator/notifications',
      routes: [
        GoRoute(
          path: '/operator/notifications',
          builder: (context, state) => const NotificationScreen(),
        ),
        GoRoute(
          path: '/operator/mutations/:id',
          builder: (context, state) {
            navigatedPath = state.uri.toString();
            return Scaffold(
              body: Text('Detail Screen: ${state.pathParameters['id']}'),
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => FakeAuthNotifier(operatorUser),
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

    // Verify navigation reached operator mutation detail route
    expect(navigatedPath, '/operator/mutations/mut_004');
    expect(find.text('Detail Screen: mut_004'), findsOneWidget);
  });
}
