import 'package:mutasiku/core/errors/failures.dart';
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
import 'package:mutasiku/features/asset/domain/entities/asset.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_category.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_status.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/operator/presentation/providers/operator_verification_provider.dart';
import 'package:mutasiku/features/operator/presentation/screens/operator_dashboard_screen.dart';
import 'package:mutasiku/features/operator/presentation/screens/operator_mutations_screen.dart';
import 'package:mutasiku/features/operator/presentation/screens/operator_verification_detail_screen.dart';
import 'package:mutasiku/features/pemohon/presentation/screens/pemohon_create_mutation_screen.dart';

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

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(User user)
    : super(
        loginUseCase: LoginUseCase(repository: FakeAuthRepository(user: user)),
        logoutUseCase: LogoutUseCase(
          repository: FakeAuthRepository(user: user),
        ),
        authRepository: FakeAuthRepository(user: user),
        checkInitialStatus: false,
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

  Widget createTestWidget(Widget child, {Key? key}) {
    return ProviderScope(
      key: key,
      overrides: [
        authStateProvider.overrideWith((ref) => FakeAuthNotifier(operatorUser)),
        apiMutationRepositoryProvider.overrideWith(
          (ref) => ref.watch(mutationRepositoryProvider),
        ),
      ],
      child: MaterialApp(
        key: key != null ? ValueKey('app_${key.toString()}') : null,
        home: child,
      ),
    );
  }

  testWidgets('OperatorDashboardScreen displays greeting and stat cards', (
    tester,
  ) async {
    await tester.pumpWidget(createTestWidget(const OperatorDashboardScreen()));
    await tester.pumpAndSettle();

    // Verifikasi teks greeting
    expect(find.text('Halo, Siti Operator'), findsOneWidget);

    // Verifikasi stat cards
    expect(find.text('Menunggu Verifikasi'), findsOneWidget);
    expect(find.text('Diteruskan ke Aset'), findsOneWidget);
    expect(find.text('Pengajuan Dikembalikan'), findsNothing);

    // Verifikasi tombol primary action
    expect(find.byKey(const Key('btn_lihat_pengajuan')), findsOneWidget);
  });

  testWidgets('OperatorMutationsScreen renders search bar and sort chips', (
    tester,
  ) async {
    await tester.pumpWidget(createTestWidget(const OperatorMutationsScreen()));
    await tester.pumpAndSettle();

    // Verifikasi appbar
    expect(find.text('Pengajuan Masuk'), findsOneWidget);

    // Verifikasi search input
    expect(find.byKey(const Key('input_search_mutations')), findsOneWidget);

    // Verifikasi compact dropdown filters
    expect(
      find.byKey(const Key('dropdown_filter_operator_status')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('dropdown_filter_operator_sort')),
      findsOneWidget,
    );

    // Verifikasi card pengajuan masuk berstatus Diajukan tampil
    expect(find.text('Diajukan'), findsWidgets);
  });

  testWidgets('OperatorMutationsScreen search filters results correctly', (
    tester,
  ) async {
    await tester.pumpWidget(createTestWidget(const OperatorMutationsScreen()));
    await tester.pumpAndSettle();

    // Pastikan mut_001 (Rina) dan mut_002 (Budi Santoso) ada di list awal
    expect(find.text('Rina'), findsWidgets);
    expect(find.text('Budi Santoso'), findsWidgets);

    // Filter dengan nama "Budi"
    await tester.enterText(
      find.byKey(const Key('input_search_mutations')),
      'Budi',
    );
    await tester.pumpAndSettle();

    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('Rina'), findsNothing);

    // Hapus search
    await tester.enterText(find.byKey(const Key('input_search_mutations')), '');
    await tester.pumpAndSettle();

    expect(find.text('Budi Santoso'), findsWidgets);
    expect(find.text('Rina'), findsWidgets);
  });

  testWidgets(
    'OperatorVerificationDetailScreen displays submission data including Pemakai Lama',
    (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const OperatorVerificationDetailScreen(mutationId: 'mut_001'),
        ),
      );
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
      expect(
        find.text('Perpindahan unit kerja ke Cabang Surabaya.'),
        findsOneWidget,
      );

      // Action buttons: Verifikasi Valid (Operator hanya berwenang memeriksa & meneruskan)
      expect(find.byKey(const Key('btn_kembalikan_pengajuan')), findsNothing);
      expect(find.byKey(const Key('btn_verifikasi_valid')), findsOneWidget);
    },
  );

  testWidgets(
    'Operator verify flow advances status to waitingAssetVerification and invalidates providers',
    (tester) async {
      late WidgetRef containerRef;

      final testWidget = ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => FakeAuthNotifier(operatorUser),
          ),
          apiMutationRepositoryProvider.overrideWith(
            (ref) => ref.watch(mutationRepositoryProvider),
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

      // Tap Verifikasi Valid (memicu modal Verifikasi Pengajuan)
      await tester.tap(find.byKey(const Key('btn_verifikasi_valid')));
      await tester.pumpAndSettle();

      // Modal Verifikasi Pengajuan muncul
      expect(find.text('Verifikasi Pengajuan'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_teruskan_ke_bagian_aset')));
      await tester.pumpAndSettle();

      // Cek status mutasi telah terupdate ke waitingAssetVerification
      final detail = await containerRef.read(
        operatorMutationDetailProvider('mut_001').future,
      );
      expect(detail.status, MutationStatus.waitingAssetVerification);
      expect(detail.verifiedBy, 'Siti Operator');
    },
  );

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
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Verify NotificationScreen renders items
      expect(find.text('Notifikasi'), findsWidgets);

      // Tap first notification item (which has relatedMutationId: mut_004)
      await tester.tap(find.textContaining('FURNITUR-2026-00018').first);
      await tester.pumpAndSettle();

      // Verify navigation reached operator mutation detail route
      expect(navigatedPath, '/operator/mutations/mut_004');
      expect(find.text('Detail Screen: mut_004'), findsOneWidget);
    },
  );

  testWidgets(
    'OperatorVerificationDetailScreen displays Data Aset Master and Snapshot when isUnregisteredAsset is false',
    (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const OperatorVerificationDetailScreen(mutationId: 'mut_001'),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Data Aset Master card appears automatically
      expect(find.byKey(const Key('card_master_asset_data')), findsOneWidget);
      expect(find.text('Data Aset Master'), findsOneWidget);
      expect(find.text('Database SIMAK BMN'), findsOneWidget);

      // 2. Tampilkan semua field master: nama, kode/inventory, serial number, kategori, lokasi, PIC
      expect(find.byKey(const Key('master_asset_name')), findsOneWidget);
      expect(find.text('Laptop Dell Latitude'), findsWidgets);

      expect(find.byKey(const Key('master_asset_code')), findsOneWidget);
      expect(find.text('AST-ELK-2024-0124'), findsOneWidget);

      expect(find.byKey(const Key('master_asset_sn')), findsOneWidget);
      expect(find.text('DL-7490-X1'), findsOneWidget);

      expect(find.byKey(const Key('master_asset_category')), findsOneWidget);
      expect(find.text('Elektronik & IT'), findsOneWidget);

      expect(find.byKey(const Key('master_asset_location')), findsOneWidget);
      expect(find.text('Kantor Pusat (SIMAK BMN)'), findsOneWidget);

      expect(find.byKey(const Key('master_asset_pic')), findsOneWidget);

      // 3. Snapshot Saat Pengajuan card appears
      expect(find.text('Snapshot Saat Pengajuan'), findsOneWidget);

      // 4. Match indicators appear when location and PIC match
      expect(find.byKey(const Key('indicator_match_location')), findsOneWidget);
      expect(find.byKey(const Key('indicator_match_pic')), findsOneWidget);
    },
  );

  testWidgets(
    'OperatorVerificationDetailScreen displays difference indicators when master location and PIC differ from snapshot',
    (tester) async {
      // mut_002 has master location 'Gedung A — Parkir Operasional' vs snapshot 'Kantor Pusat'
      // and master pic 'Driver Operasional General Affair' vs snapshot 'Budi Santoso'
      await tester.pumpWidget(
        createTestWidget(
          const OperatorVerificationDetailScreen(mutationId: 'mut_002'),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi master card ada
      expect(find.byKey(const Key('card_master_asset_data')), findsOneWidget);

      // Verifikasi indikator perbedaan lokasi dan PIC tampil
      expect(find.byKey(const Key('indicator_diff_location')), findsOneWidget);
      expect(
        find.textContaining(
          '⚠️ Berbeda dengan Master (Master: Gedung A — Parkir Operasional)',
        ),
        findsOneWidget,
      );

      expect(find.byKey(const Key('indicator_diff_pic')), findsOneWidget);
      expect(
        find.textContaining(
          '⚠️ Berbeda dengan Master (Master: Driver Operasional General Affair)',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'OperatorVerificationDetailScreen displays Aset Tidak Terdaftar warning and manual data when isUnregisteredAsset is true',
    (tester) async {
      final unregMutation = Mutation(
        id: 'mut_unreg_test',
        ticketNumber: 'OTH-2026-99999',
        asset: const Asset(
          id: '',
          assetCode: 'SN-MANUAL-777',
          name: 'Speaker Meeting Portable',
          category: AssetCategory(id: 'cat_oth', code: 'OTH', name: 'Lainnya'),
          location: 'Ruang Rapat Utama',
          pic: 'Ahmad PIC',
          status: AssetStatus.inMutation,
          condition: 'Baik',
          acquisitionYear: 2026,
        ),
        applicantId: 'u_opr_01',
        applicantName: 'Siti Operator',
        currentLocation: 'Ruang Rapat Utama',
        targetLocation: 'Cabang Solo',
        currentPic: 'Ahmad PIC',
        targetPic: 'Joko Solo',
        reason: 'Pinjam pakai audio meeting.',
        status: MutationStatus.submitted,
        isUnregisteredAsset: true,
        customAssetName: 'Speaker Meeting Portable',
        customSerialNumber: 'SN-MANUAL-777',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => FakeAuthNotifier(operatorUser),
            ),
            apiMutationRepositoryProvider.overrideWith(
              (ref) => ref.watch(mutationRepositoryProvider),
            ),
            operatorMutationDetailProvider('mut_unreg_test')
                .overrideWith((ref) => Future.value(unregMutation)),
            mutationDetailProvider('mut_unreg_test')
                .overrideWith((ref) => Future.value(unregMutation)),
          ],
          child: const MaterialApp(
            home: OperatorVerificationDetailScreen(
              mutationId: 'mut_unreg_test',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Warning Aset Tidak Terdaftar wajib tampil
      expect(
        find.byKey(const Key('banner_unregistered_asset')),
        findsOneWidget,
      );
      expect(find.text('Aset Tidak Terdaftar'), findsOneWidget);

      // Data Aset Master TIDAK boleh tampil
      expect(find.byKey(const Key('card_master_asset_data')), findsNothing);

      // Data manual pengajuan tampil
      expect(find.text('Speaker Meeting Portable'), findsOneWidget);
      expect(find.textContaining('SN-MANUAL-777'), findsOneWidget);
    },
  );

  testWidgets('PemohonCreateMutationScreen renders form fields', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => FakeAuthNotifier(operatorUser),
          ),
        ],
        child: const MaterialApp(home: PemohonCreateMutationScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Informasi Aset Terdaftar'), findsOneWidget);
    expect(find.byType(Form), findsOneWidget);
  });

  testWidgets(
    'OperatorDashboardScreen does not show Lihat Detail or Filter Detail',
    (tester) async {
      await tester.pumpWidget(
        createTestWidget(const OperatorDashboardScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lihat Detail'), findsNothing);
      expect(find.text('Filter Detail'), findsNothing);
    },
  );

  testWidgets(
    'OperatorMutationsScreen initialFilter sets active filter and tab correctly',
    (tester) async {
      // 1. Initial filter TI
      await tester.pumpWidget(
        createTestWidget(const OperatorMutationsScreen(initialFilter: 'ti')),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Aset TI'), findsWidgets);

      // 2. Initial filter Umum
      await tester.pumpWidget(
        createTestWidget(const OperatorMutationsScreen(initialFilter: 'umum')),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Aset Umum'), findsWidgets);

      // 3. Verifikasi tab Dikembalikan tidak lagi ditampilkan
      expect(find.textContaining('Dikembalikan'), findsNothing);

      // 4. Initial filter Submitted
      await tester.pumpWidget(
        createTestWidget(
          const OperatorMutationsScreen(initialFilter: 'submitted'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Menunggu'), findsWidgets);

      // 5. Initial filter Allocated (Dialokasikan)
      await tester.pumpWidget(
        createTestWidget(
          const OperatorMutationsScreen(initialFilter: 'allocated'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Dialokasikan'), findsWidgets);
    },
  );

  testWidgets(
    'OperatorMutationsScreen filter status properly isolates returned and allocated items',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 1. Open screen with 'submitted' filter: returned and allocated items should not appear
      await tester.pumpWidget(
        createTestWidget(
          const OperatorMutationsScreen(initialFilter: 'submitted'),
          key: const ValueKey('opr_screen_sub'),
        ),
      );
      await tester.pumpAndSettle();

      // Rina (submitted) should be visible
      expect(find.text('Rina'), findsWidgets);
      // Andi Wijaya (returned), Meja Kerja Eksekutif (allocated), Server Rack (allocated) should NOT appear
      expect(find.text('Andi Wijaya'), findsNothing);
      expect(find.text('Meja Kerja Eksekutif'), findsNothing);
      expect(find.text('Server Rack Enterprise Dell PowerEdge'), findsNothing);

      // 2. Open screen with 'all' filter: pengajuan riwayat (termasuk yang dikembalikan - Andi Wijaya) dapat dilihat
      await tester.pumpWidget(
        createTestWidget(
          const OperatorMutationsScreen(initialFilter: 'all'),
          key: const ValueKey('opr_screen_all'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Andi Wijaya'), findsOneWidget);
      expect(find.text('Rina'), findsWidgets);
      expect(find.text('Server Rack Enterprise Dell PowerEdge'), findsOneWidget);

      // 3. Open screen with 'allocated' filter (Dialokasikan)
      await tester.pumpWidget(
        createTestWidget(
          const OperatorMutationsScreen(initialFilter: 'allocated'),
          key: const ValueKey('opr_screen_alloc'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Meja Kerja Eksekutif'), findsWidgets);
      expect(
        find.text('Server Rack Enterprise Dell PowerEdge'),
        findsOneWidget,
      );
      expect(find.text('Budi Santoso'), findsNothing);
      expect(find.text('Andi Wijaya'), findsNothing);
    },
  );
}
