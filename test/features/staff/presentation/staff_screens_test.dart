// test/features/staff/presentation/staff_screens_test.dart
//
// Widget & presentation tests untuk screen dan flow Staff Aset.
// Sumber: SCREEN-SPEC.md STF-001–003, ROLE-FLOW.md §7.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mutasiku/app/router/route_names.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/features/asset/data/repositories/asset_repository_impl.dart';
import 'package:mutasiku/features/asset/domain/entities/asset.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_category.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_status.dart';
import 'package:mutasiku/features/asset/presentation/providers/asset_provider.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/auth/domain/repositories/auth_repository.dart';
import 'package:mutasiku/features/auth/domain/usecases/login_usecase.dart';
import 'package:mutasiku/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mutasiku/features/auth/presentation/providers/auth_provider.dart';
import 'package:mutasiku/features/mutation/data/repositories/mutation_repository_impl.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';
import 'package:mutasiku/features/profile/presentation/screens/profile_screen.dart';
import 'package:mutasiku/features/staff/presentation/providers/staff_mutation_provider.dart';
import 'package:mutasiku/features/staff/presentation/screens/staff_dashboard_screen.dart';
import 'package:mutasiku/features/staff/presentation/screens/staff_mutation_detail_screen.dart';
import 'package:mutasiku/features/staff/presentation/screens/staff_mutation_list_screen.dart';

class FakeStaffAuthRepository implements AuthRepository {
  final User? user;

  FakeStaffAuthRepository({this.user});

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

class FakeStaffAuthNotifier extends AuthNotifier {
  FakeStaffAuthNotifier(User user)
      : super(
          loginUseCase: LoginUseCase(repository: FakeStaffAuthRepository(user: user)),
          logoutUseCase: LogoutUseCase(repository: FakeStaffAuthRepository(user: user)),
          authRepository: FakeStaffAuthRepository(user: user),
        ) {
    state = AuthState(isLoading: false, user: user);
  }
}

void main() {
  const dummyAsset = Asset(
    id: 'AST-STF-001',
    assetCode: 'AST-ELK-2024-0001',
    name: 'ThinkPad X1 Carbon',
    category: AssetCategory(
      id: 'cat_1',
      code: 'ELK',
      name: 'Elektronik',
    ),
    location: 'Lantai 1 — IT',
    pic: 'Rina',
    status: AssetStatus.inMutation,
    condition: 'Baik',
    acquisitionYear: 2024,
  );

  final testMutation = Mutation(
    id: 'mut_stf_01',
    ticketNumber: 'ELK-2026-00099',
    asset: dummyAsset,
    applicantName: 'Rina Pemohon',
    currentLocation: 'Lantai 1 — IT',
    targetLocation: 'Lantai 4 — Finance',
    currentPic: 'Rina Pemohon',
    targetPic: 'Budi Finance',
    reason: 'Rotasi divisi',
    status: MutationStatus.approved,
    approvedBy: 'Pak Kabag',
    approvedAt: DateTime.now().subtract(const Duration(days: 1)),
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  );

  const testUser = User(
    id: 'usr_staff_01',
    username: 'staff1',
    name: 'Rizky Staff Aset',
    email: 'rizky.staff@bankjateng.co.id',
    role: UserRole.staffAset,
  );

  late AssetRepositoryImpl assetRepository;
  late MutationRepositoryImpl mutationRepository;

  setUp(() {
    MutationRepositoryImpl.resetForTesting();
    assetRepository = AssetRepositoryImpl();
    mutationRepository = MutationRepositoryImpl(assetRepository: assetRepository);
  });

  Widget createWidget(Widget child, {List<Override> overrides = const []}) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => child,
        ),
        GoRoute(
          path: RouteNames.staffDashboardPath,
          builder: (context, state) => const StaffAsetDashboardScreen(),
        ),
        GoRoute(
          path: RouteNames.staffMutationsPath,
          builder: (context, state) => const StaffMutationListScreen(),
        ),
        GoRoute(
          path: '/staff-aset/mutations/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return StaffMutationDetailScreen(mutationId: id);
          },
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => FakeStaffAuthNotifier(testUser),
        ),
        staffAllMutationsProvider.overrideWith((ref) => [testMutation]),
        mutationDetailProvider('mut_stf_01').overrideWith((ref) => testMutation),
        ...overrides,
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('StaffAsetDashboardScreen displays greeting and waiting update stat card',
      (tester) async {
    await tester.pumpWidget(createWidget(const StaffAsetDashboardScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Halo, Rizky Staff Aset'), findsOneWidget);
    expect(find.text('Menunggu Pembaruan Aset'), findsOneWidget);
    expect(find.text('Antrian Pembaruan Terkini'), findsOneWidget);
    expect(find.text('ThinkPad X1 Carbon'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('StaffMutationListScreen displays search, sort chips, and mutation card',
      (tester) async {
    await tester.pumpWidget(createWidget(const StaffMutationListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Antrian Pembaruan Aset'), findsOneWidget);
    expect(find.byKey(const Key('input_search_staff_mutations')), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Terbaru'), findsOneWidget);
    expect(find.text('Terlama'), findsOneWidget);
    expect(find.text('ELK-2026-00099'), findsOneWidget);
    expect(find.text('ThinkPad X1 Carbon'), findsOneWidget);
    expect(find.text('Lantai 1 — IT → Lantai 4 — Finance'), findsOneWidget);
  });

  testWidgets('StaffMutationDetailScreen displays info and form with pre-filled target data',
      (tester) async {
    await tester.pumpWidget(
      createWidget(
        const StaffMutationDetailScreen(mutationId: 'mut_stf_01'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Detail Pembaruan Aset'), findsOneWidget);
    expect(find.text('ELK-2026-00099'), findsOneWidget);
    expect(find.text('Informasi Aset'), findsOneWidget);
    expect(find.text('Detail Pengajuan & Persetujuan'), findsOneWidget);
    expect(find.text('Form Pembaruan Lokasi & PIC'), findsOneWidget);
    expect(find.byKey(const Key('btn_submit_update_aset')), findsOneWidget);

    expect(find.widgetWithText(TextFormField, 'Lantai 4 — Finance'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Budi Finance'), findsOneWidget);
  });

  testWidgets('StaffMutationDetailScreen chips update location and PIC input fields',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      createWidget(
        const StaffMutationDetailScreen(mutationId: 'mut_stf_01'),
      ),
    );
    await tester.pumpAndSettle();

    // Verify chips exist
    expect(find.byKey(const Key('chip_lokasi_asal')), findsOneWidget);
    expect(find.byKey(const Key('chip_lokasi_tujuan')), findsOneWidget);
    expect(find.byKey(const Key('chip_pic_lama')), findsOneWidget);
    expect(find.byKey(const Key('chip_pic_baru')), findsOneWidget);

    // Tap chip PIC Lama (currentPic: 'Rina Pemohon')
    await tester.ensureVisible(find.byKey(const Key('chip_pic_lama')));
    await tester.tap(find.byKey(const Key('chip_pic_lama')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Rina Pemohon'), findsOneWidget);

    // Tap chip PIC Tujuan (targetPic: 'Budi Finance')
    await tester.ensureVisible(find.byKey(const Key('chip_pic_baru')));
    await tester.tap(find.byKey(const Key('chip_pic_baru')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Budi Finance'), findsOneWidget);

    // Tap chip Lokasi Asal (currentLocation: 'Lantai 1 — IT')
    await tester.ensureVisible(find.byKey(const Key('chip_lokasi_asal')));
    await tester.tap(find.byKey(const Key('chip_lokasi_asal')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Lantai 1 — IT'), findsOneWidget);

    // Tap chip Lokasi Tujuan (targetLocation: 'Lantai 4 — Finance')
    await tester.ensureVisible(find.byKey(const Key('chip_lokasi_tujuan')));
    await tester.tap(find.byKey(const Key('chip_lokasi_tujuan')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Lantai 4 — Finance'), findsOneWidget);
  });

  testWidgets('StaffMutationDetailScreen validates empty inputs before submitting',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      createWidget(
        const StaffMutationDetailScreen(mutationId: 'mut_stf_01'),
      ),
    );
    await tester.pumpAndSettle();

    // Clear location field
    await tester.enterText(find.byKey(const Key('input_lokasi_baru')), '');
    await tester.ensureVisible(find.byKey(const Key('btn_submit_update_aset')));
    await tester.tap(find.byKey(const Key('btn_submit_update_aset')));
    await tester.pumpAndSettle();

    expect(find.text('Lokasi baru wajib diisi.'), findsOneWidget);
  });

  testWidgets(
      'Full End-to-End Staff Update Flow: update location and pick old PIC persists to mutation and asset history, status becomes pendingConfirmation',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Gunakan repository sesungguhnya dengan seed mut_007 (status approved)
    final router = GoRouter(
      initialLocation: '/staff-aset/mutations/mut_007',
      routes: [
        GoRoute(
          path: RouteNames.staffDashboardPath,
          builder: (context, state) => const StaffAsetDashboardScreen(),
        ),
        GoRoute(
          path: RouteNames.staffMutationsPath,
          builder: (context, state) => const StaffMutationListScreen(),
        ),
        GoRoute(
          path: '/staff-aset/mutations/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return StaffMutationDetailScreen(mutationId: id);
          },
        ),
      ],
    );

    final container = ProviderScope(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => FakeStaffAuthNotifier(testUser),
        ),
        mutationRepositoryProvider.overrideWithValue(mutationRepository),
        assetRepositoryProvider.overrideWithValue(assetRepository),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );

    await tester.pumpWidget(container);
    await tester.pumpAndSettle();

    // Verify detail is opened for mut_007
    expect(find.text('Detail Pembaruan Aset'), findsOneWidget);
    expect(find.text('ELEKTRONIK-2026-00077'), findsOneWidget);
    expect(find.text('Laptop Dell Latitude 5430'), findsOneWidget);

    // Edit lokasi baru & gunakan PIC lama
    final inputLocation = find.byKey(const Key('input_lokasi_baru'));
    await tester.ensureVisible(inputLocation);
    await tester.enterText(inputLocation, 'Cabang Solo — Ruang CS Lantai 1');
    await tester.ensureVisible(find.byKey(const Key('chip_pic_lama')));
    await tester.tap(find.byKey(const Key('chip_pic_lama')));
    await tester.pumpAndSettle();

    // Pastikan PIC menjadi 'Rizky Pratama' (PIC lama)
    expect(find.widgetWithText(TextFormField, 'Rizky Pratama'), findsOneWidget);

    // Tap submit button
    final btnSubmit = find.byKey(const Key('btn_submit_update_aset'));
    await tester.ensureVisible(btnSubmit);
    await tester.tap(btnSubmit);
    await tester.pumpAndSettle();

    // Dialog konfirmasi muncul
    expect(find.text('Konfirmasi Pembaruan Aset'), findsOneWidget);
    expect(find.text('Cabang Solo — Ruang CS Lantai 1'), findsWidgets);
    expect(find.text('Rizky Pratama'), findsWidgets);

    // Konfirmasi dialog
    final btnConfirm = find.byKey(const Key('btn_confirm_simpan_update_aset'));
    await tester.tap(btnConfirm);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Verifikasi pada mutationRepository bahwa status mut_007 berubah menjadi pendingConfirmation
    Mutation? updatedMutation;
    await tester.runAsync(() async {
      final res = await mutationRepository.getMutationById('mut_007');
      updatedMutation = res.dataOrNull;
    });

    expect(updatedMutation, isNotNull);
    expect(updatedMutation!.status, MutationStatus.pendingConfirmation);
    expect(updatedMutation!.targetLocation, 'Cabang Solo — Ruang CS Lantai 1');
    expect(updatedMutation!.targetPic, 'Rizky Pratama');
    expect(updatedMutation!.staffUpdatedBy, 'Rizky Staff Aset');
    expect(updatedMutation!.staffUpdatedAt, isNotNull);

    // Verifikasi pada assetRepository bahwa lokasi dan PIC terupdate & ada asset history
    Asset? updatedAsset;
    await tester.runAsync(() async {
      final res = await assetRepository.getAssetById('AST-00077');
      updatedAsset = res.dataOrNull;
    });

    expect(updatedAsset, isNotNull);
    expect(updatedAsset!.location, 'Cabang Solo — Ruang CS Lantai 1');
    expect(updatedAsset!.pic, 'Rizky Pratama');
    expect(updatedAsset!.history, isNotEmpty);
    final historyItem = updatedAsset!.history.last;
    expect(historyItem.ticketNumber, 'ELEKTRONIK-2026-00077');
    expect(historyItem.newLocation, 'Cabang Solo — Ruang CS Lantai 1');
    expect(historyItem.newPic, 'Rizky Pratama');
    expect(historyItem.updatedBy, 'Rizky Staff Aset');
  });

  testWidgets('StaffMutationListScreen search filters correctly',
      (tester) async {
    final router = GoRouter(
      initialLocation: RouteNames.staffMutationsPath,
      routes: [
        GoRoute(
          path: RouteNames.staffMutationsPath,
          builder: (context, state) => const StaffMutationListScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => FakeStaffAuthNotifier(testUser),
          ),
          mutationRepositoryProvider.overrideWithValue(mutationRepository),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Default item mut_007 ada
    expect(find.text('ELEKTRONIK-2026-00077'), findsOneWidget);

    // Search dengan keyword tidak cocok
    final searchInput = find.byKey(const Key('input_search_staff_mutations'));
    await tester.enterText(searchInput, 'KATA_KUNCI_TIDAK_ADA');
    await tester.pumpAndSettle();

    expect(find.text('ELEKTRONIK-2026-00077'), findsNothing);
    expect(find.text('Tidak ada hasil untuk "KATA_KUNCI_TIDAK_ADA"'), findsOneWidget);

    // Bersihkan keyword -> item mut_007 muncul kembali
    await tester.enterText(searchInput, '');
    await tester.pumpAndSettle();
    expect(find.text('ELEKTRONIK-2026-00077'), findsOneWidget);
  });

  testWidgets('ProfileScreen renders Staff Aset profile consistently',
      (tester) async {
    final router = GoRouter(
      initialLocation: RouteNames.profilePath,
      routes: [
        GoRoute(
          path: RouteNames.profilePath,
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => FakeStaffAuthNotifier(testUser),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Rizky Staff Aset'), findsOneWidget);
    expect(find.text('rizky.staff@bankjateng.co.id'), findsOneWidget);
    expect(find.text('Staff Aset'), findsWidgets);
    expect(find.text('Informasi Akun'), findsOneWidget);
  });
}
