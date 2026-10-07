// test/features/pemohon/presentation/screens/pemohon_end_to_end_test.dart
//
// End-to-end widget & integration test untuk seluruh flow Pemohon:
// Dashboard → Ajukan Mutasi → Submit → Mutasi Saya → Detail & Tracking →
// Returned → Edit & Ajukan Ulang → Notifikasi → Pending Confirmation → Konfirmasi (Sesuai & Tidak Sesuai)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mutasiku/app/router/route_names.dart';
import 'package:mutasiku/core/errors/failures.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/features/asset/domain/entities/asset.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_category.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_status.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/auth/domain/repositories/auth_repository.dart';
import 'package:mutasiku/features/auth/domain/usecases/login_usecase.dart';
import 'package:mutasiku/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mutasiku/features/auth/presentation/providers/auth_provider.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/core/services/document_picker_service.dart';
import 'package:mutasiku/core/widgets/custom_floating_nav_bar.dart';
import 'package:mutasiku/features/mutation/domain/repositories/mutation_repository.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';
import 'package:mutasiku/core/widgets/searchable_picker_bottom_sheet.dart';
import 'package:mutasiku/features/notification/presentation/providers/notification_provider.dart';
import 'package:mutasiku/features/pemohon/presentation/screens/pemohon_confirmation_screen.dart';
import 'package:mutasiku/features/pemohon/presentation/screens/pemohon_create_mutation_screen.dart';
import 'package:mutasiku/features/pemohon/presentation/screens/pemohon_dashboard_screen.dart';
import 'package:mutasiku/features/pemohon/presentation/screens/pemohon_edit_mutation_screen.dart';
import 'package:mutasiku/features/pemohon/presentation/screens/pemohon_mutation_detail_screen.dart';
import 'package:mutasiku/features/pemohon/presentation/screens/pemohon_mutation_list_screen.dart';
import 'package:mutasiku/features/pemohon/presentation/screens/pemohon_notifications_screen.dart';
import 'package:mutasiku/features/profile/presentation/screens/profile_screen.dart';

class _FakeFullMutationRepository implements MutationRepository {
  final Map<String, Mutation> _mutations = {};
  int _counter = 100;

  _FakeFullMutationRepository(List<Mutation> initial) {
    for (final m in initial) {
      _mutations[m.id] = m;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Result<Mutation>> submitMutation(SubmitMutationParams params) async {
    _counter++;
    final id = 'mut_$_counter';
    final ticketNumber = 'ELK-2026-000$_counter';
    const cat = AssetCategory(id: 'cat_1', code: 'ELK', name: 'Elektronik');
    final resolvedAssetId = params.assetId ?? (params.isUnregisteredAsset ? '' : 'AST-PRN-009');
    final asset = Asset(
      id: resolvedAssetId,
      assetCode: resolvedAssetId,
      name: params.assetName,
      category: cat,
      location: params.sourceLocation,
      pic: 'PIC Lama',
      status: AssetStatus.inMutation,
      condition: 'Baik',
      acquisitionYear: 2024,
    );

    final mutation = Mutation(
      id: id,
      ticketNumber: ticketNumber,
      asset: asset,
      applicantId: params.applicantId,
      applicantName: params.applicantName ?? 'Pemohon',
      currentLocation: params.sourceLocation,
      targetLocation: params.targetLocation,
      currentPic: params.currentPic ?? 'PIC Lama',
      targetPic: params.targetPic,
      reason: params.reason,
      documentName: params.documentName,
      status: MutationStatus.submitted,
      createdAt: DateTime.now(),
    );

    _mutations[id] = mutation;
    return Result.success(mutation);
  }

  @override
  Future<Result<Mutation>> updateMutation({
    required String mutationId,
    required String targetLocation,
    required String targetPic,
    required String reason,
    String? documentName,
  }) async {
    final current = _mutations[mutationId];
    if (current == null) {
      return const Result.failure(NotFoundFailure(message: 'Not found'));
    }
    final updated = current.copyWith(
      targetLocation: targetLocation,
      targetPic: targetPic,
      reason: reason,
      status: MutationStatus.submitted,
    );
    _mutations[mutationId] = updated;
    return Result.success(updated);
  }

  @override
  Future<Result<List<Mutation>>> getMutationsByUser(String userId) async {
    final list = _mutations.values.where((m) => m.applicantId == userId).toList();
    return Result.success(List.unmodifiable(list.reversed.toList()));
  }

  @override
  Future<Result<Mutation>> getMutationById(String id) async {
    final m = _mutations[id];
    if (m == null) {
      return const Result.failure(NotFoundFailure(message: 'Not found'));
    }
    return Result.success(m);
  }

  @override
  Future<Result<List<Mutation>>> getAllMutations() async {
    return Result.success(_mutations.values.toList());
  }

  @override
  Future<Result<Mutation>> verifyMutation({
    required String mutationId,
    required String operatorName,
    bool requiresKadivApproval = false,
  }) async {
    final current = _mutations[mutationId]!;
    final updated = current.copyWith(
      status: MutationStatus.waitingKabagApproval,
      verifiedBy: operatorName,
      verifiedAt: DateTime.now(),
      requiresKadivApproval: requiresKadivApproval,
    );
    _mutations[mutationId] = updated;
    return Result.success(updated);
  }

  @override
  Future<Result<Mutation>> returnMutation({
    required String mutationId,
    required String reason,
    required String operatorName,
  }) async {
    final current = _mutations[mutationId]!;
    final updated = current.copyWith(
      status: MutationStatus.returned,
      returnReason: reason,
      verifiedBy: operatorName,
      verifiedAt: DateTime.now(),
    );
    _mutations[mutationId] = updated;
    return Result.success(updated);
  }

  @override
  Future<Result<Mutation>> approveMutationKabag({
    required String mutationId,
    required String kabagName,
    required bool requiresKadivApproval,
  }) async => throw UnimplementedError();

  @override
  Future<Result<Mutation>> rejectMutationKabag({
    required String mutationId,
    required String reason,
    required String kabagName,
  }) async => throw UnimplementedError();

  @override
  Future<Result<Mutation>> approveMutationKadiv({
    required String mutationId,
    required String kadivName,
  }) async => throw UnimplementedError();

  @override
  Future<Result<Mutation>> rejectMutationKadiv({
    required String mutationId,
    required String reason,
    required String kadivName,
  }) async => throw UnimplementedError();

  @override
  Future<Result<Mutation>> confirmMutationResult({
    required String mutationId,
    required String confirmedBy,
    required bool isSesuai,
    String? reason,
  }) async {
    final current = _mutations[mutationId];
    if (current == null) {
      return const Result.failure(NotFoundFailure(message: 'Not found'));
    }
    if (isSesuai) {
      final updatedAsset = current.asset.copyWith(
        status: AssetStatus.available,
        location: current.targetLocation,
        pic: current.targetPic,
      );
      final updated = current.copyWith(
        asset: updatedAsset,
        status: MutationStatus.completed,
      );
      _mutations[mutationId] = updated;
      return Result.success(updated);
    } else {
      final updated = current.copyWith(
        status: MutationStatus.waitingAssetVerification,
        confirmationReason: reason,
      );
      _mutations[mutationId] = updated;
      return Result.success(updated);
    }
  }

  @override
  Future<Result<Mutation>> confirmMutation({
    required String mutationId,
    required String confirmedBy,
  }) async {
    final current = _mutations[mutationId]!;
    final updated = current.copyWith(status: MutationStatus.completed);
    _mutations[mutationId] = updated;
    return Result.success(updated);
  }

  @override
  Future<Result<Mutation>> processStaffAssetUpdate({
    required String mutationId,
    required String newLocation,
    required String newPic,
    required String staffName,
  }) async => throw UnimplementedError();
}

class _FakePemohonAuthRepository implements AuthRepository {
  final User user;
  _FakePemohonAuthRepository(this.user);

  @override
  Future<Result<User?>> getCurrentUser() async => Result.success(user);

  @override
  Future<Result<User>> login({
    required String username,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<void> logout() async {}
}

class FakePemohonAuthNotifier extends AuthNotifier {
  FakePemohonAuthNotifier(User user)
      : super(
          loginUseCase: LoginUseCase(repository: _FakePemohonAuthRepository(user)),
          logoutUseCase: LogoutUseCase(repository: _FakePemohonAuthRepository(user)),
          authRepository: _FakePemohonAuthRepository(user),
        ) {
    state = AuthState(isLoading: false, user: user);
  }
}

void main() {
  const catElk = AssetCategory(id: 'cat_1', code: 'ELK', name: 'Elektronik');

  const testUser = User(
    id: 'usr_pemohon',
    username: 'pemohon',
    name: 'Pemohon User',
    email: 'pemohon@mutasiku.id',
    role: UserRole.pemohon,
    department: 'IT',
  );

  Mutation createTestMutation({
    required String id,
    required String ticketNumber,
    required MutationStatus status,
    String? returnReason,
    String? applicantId = 'usr_pemohon',
    String assetName = 'Laptop Dell Latitude',
  }) {
    return Mutation(
      id: id,
      ticketNumber: ticketNumber,
      asset: Asset(
        id: 'AST-$id',
        assetCode: 'AST-ELK-$id',
        name: assetName,
        category: catElk,
        location: 'Kantor Pusat',
        pic: 'Pemohon User',
        status: AssetStatus.inMutation,
        condition: 'Baik',
        acquisitionYear: 2024,
      ),
      applicantId: applicantId,
      applicantName: 'Pemohon User',
      currentLocation: 'Kantor Pusat',
      targetLocation: 'Cabang Surabaya',
      currentPic: 'Pemohon User',
      targetPic: 'Budi Santoso',
      reason: 'Mutasi dinas',
      documentName: 'SK.pdf',
      status: status,
      returnReason: returnReason,
      createdAt: DateTime.now(),
    );
  }

  group('Pemohon End-to-End Tests', () {
    testWidgets('Dashboard: search filters data and clearing restores it', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = _FakeFullMutationRepository([
        createTestMutation(
          id: 'mut_1',
          ticketNumber: 'ELK-2026-00001',
          status: MutationStatus.submitted,
          assetName: 'MacBook Pro 16',
        ),
        createTestMutation(
          id: 'mut_2',
          ticketNumber: 'ELK-2026-00002',
          status: MutationStatus.approved,
          assetName: 'ThinkPad X1',
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mutationRepositoryProvider.overrideWithValue(repo),
            apiMutationRepositoryProvider.overrideWithValue(repo),
            authStateProvider.overrideWith(
              (ref) => FakePemohonAuthNotifier(testUser),
            ),
          ],
          child: const MaterialApp(
            home: PemohonDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Stitch header hierarchy and dynamic logged-in user name
      expect(find.text('Halo, Pemohon User!'), findsOneWidget);
      expect(find.text('Pengajuan & Pelacakan Mutasi Aset Kantor'), findsOneWidget);
      expect(find.text('Cari nomor tiket, kode aset, status...'), findsOneWidget);
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
      expect(find.text('Rina'), findsNothing);
      expect(find.text('Zahra Safitri'), findsNothing);

      // Open menu via hamburger button and check dynamic user & role
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Mutasi Saya'), findsWidgets);
      expect(find.text('Pemohon'), findsWidgets);
      // Close menu
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      // Check items exist
      expect(find.text('MacBook Pro 16'), findsWidgets);
      expect(find.text('ThinkPad X1'), findsWidgets);

      // Search for 'ThinkPad'
      await tester.enterText(find.byType(TextField), 'ThinkPad');
      await tester.pumpAndSettle();

      expect(find.text('ThinkPad X1'), findsWidgets);
      expect(find.text('MacBook Pro 16'), findsNothing);

      // Clear search
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      // Both should reappear
      expect(find.text('MacBook Pro 16'), findsWidgets);
      expect(find.text('ThinkPad X1'), findsWidgets);
    });

    testWidgets('Dashboard metric cards navigate to Mutasi Saya with active filters and back navigation works', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = _FakeFullMutationRepository([
        createTestMutation(
          id: 'mut_prog',
          ticketNumber: 'ELK-2026-00001',
          status: MutationStatus.submitted,
          assetName: 'Laptop Dell InProgress',
        ),
        createTestMutation(
          id: 'mut_act',
          ticketNumber: 'ELK-2026-00002',
          status: MutationStatus.returned,
          assetName: 'Monitor LG ActionNeeded',
        ),
        createTestMutation(
          id: 'mut_done',
          ticketNumber: 'ELK-2026-00003',
          status: MutationStatus.completed,
          assetName: 'Printer Epson Completed',
        ),
      ]);

      final router = GoRouter(
        initialLocation: RouteNames.pemohonDashboardPath,
        routes: [
          GoRoute(
            path: RouteNames.pemohonDashboardPath,
            builder: (context, state) => const PemohonDashboardScreen(),
          ),
          GoRoute(
            path: RouteNames.pemohonMutasiPath,
            builder: (context, state) {
              final filter = state.uri.queryParameters['filter'] ??
                  (state.extra is String ? state.extra as String : null);
              return PemohonMutationListScreen(initialFilter: filter);
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mutationRepositoryProvider.overrideWithValue(repo),
            apiMutationRepositoryProvider.overrideWithValue(repo),
            authStateProvider.overrideWith(
              (ref) => FakePemohonAuthNotifier(testUser),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Verify search bar has transparent fill
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.fillColor, Colors.transparent);
      expect(textField.decoration?.filled, false);

      // Tap 'Dalam Proses' metric card
      await tester.tap(find.widgetWithText(InkWell, 'Dalam Proses').first);
      await tester.pumpAndSettle();

      // Mutasi Saya should be visible with only InProgress item
      expect(find.text('Mutasi Saya'), findsWidgets);
      expect(find.text('Laptop Dell InProgress'), findsOneWidget);
      expect(find.text('Monitor LG ActionNeeded'), findsNothing);
      expect(find.text('Printer Epson Completed'), findsNothing);

      // Back to Dashboard
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Halo, Pemohon User!'), findsOneWidget);

      // Tap 'Perlu Tindakan' metric card
      await tester.tap(find.widgetWithText(InkWell, 'Perlu Tindakan').first);
      await tester.pumpAndSettle();

      expect(find.text('Mutasi Saya'), findsWidgets);
      expect(find.text('Monitor LG ActionNeeded'), findsOneWidget);
      expect(find.text('Laptop Dell InProgress'), findsNothing);
      expect(find.text('Printer Epson Completed'), findsNothing);

      // Back to Dashboard
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Tap 'Selesai' metric card
      await tester.tap(find.widgetWithText(InkWell, 'Selesai').first);
      await tester.pumpAndSettle();

      expect(find.text('Mutasi Saya'), findsWidgets);
      expect(find.text('Printer Epson Completed'), findsOneWidget);
      expect(find.text('Laptop Dell InProgress'), findsNothing);
      expect(find.text('Monitor LG ActionNeeded'), findsNothing);

      // Manual switch filter to 'Semua'
      await tester.tap(find.widgetWithText(InkWell, 'Semua').first);
      await tester.pumpAndSettle();

      expect(find.text('Laptop Dell InProgress'), findsOneWidget);
      expect(find.text('Monitor LG ActionNeeded'), findsOneWidget);
      expect(find.text('Printer Epson Completed'), findsOneWidget);
    });

    testWidgets('Ajukan Mutasi: form inputs validate, submits with applicantId, and appears in Mutasi Saya', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = _FakeFullMutationRepository([]);

      final router = GoRouter(
        initialLocation: '/create',
        routes: [
          GoRoute(
            path: '/create',
            builder: (context, state) => const PemohonCreateMutationScreen(),
          ),
          GoRoute(
            path: RouteNames.pemohonSubmitSuccessPath,
            builder: (context, state) {
              return const Scaffold(body: Text('Success Screen'));
            },
          ),
          GoRoute(
            path: RouteNames.pemohonMutasiPath,
            builder: (context, state) {
              return const Scaffold(body: Text('Mutasi Saya Screen'));
            },
          ),
          GoRoute(
            path: RouteNames.pemohonMutasiDetailPath,
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return Scaffold(body: Text('Detail Mutasi Screen $id'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mutationRepositoryProvider.overrideWithValue(repo),
            apiMutationRepositoryProvider.overrideWithValue(repo),
            authStateProvider.overrideWith(
              (ref) => FakePemohonAuthNotifier(testUser),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Tap submit with empty fields -> should fail validation
      final submitBtn = find.text('Kirim Pengajuan Mutasi').evaluate().isNotEmpty
          ? find.text('Kirim Pengajuan Mutasi')
          : find.text('Lanjut ke Konfirmasi');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Wajib diisi'), findsWidgets);

      // Setup document picker hook
      DocumentPickerService.testPicker = () async {
        return const DocumentPickerResult.success(
          PickedDocument(
            name: 'SK_SDM_Mutasi.pdf',
            size: 1024 * 50,
          ),
        );
      };
      addTearDown(() {
        DocumentPickerService.testPicker = null;
      });

      // Fill in all required fields
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Printer Epson L3210');
      await tester.enterText(textFields.at(1), 'AST-PRN-009');
      await tester.enterText(textFields.at(2), 'Pak Joko (Staff IT)');
      await tester.enterText(textFields.at(3), 'Ruang IT Pusat');

      // Select target location from dropdown
      await tester.ensureVisible(find.byKey(const Key('dropdown_target_location')));
      await tester.tap(find.byKey(const Key('dropdown_target_location')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cabang Bandung').last);
      await tester.pumpAndSettle();

      final remainingFields = find.byType(TextFormField);
      await tester.enterText(remainingFields.at(4), 'Lantai 2');
      await tester.enterText(remainingFields.at(5), 'Kebutuhan cetak operasional cabang');
      await tester.pumpAndSettle();

      // Pick document
      await tester.ensureVisible(find.text('Unggah Berkas'));
      await tester.tap(find.text('Unggah Berkas'));
      await tester.pumpAndSettle();

      // Submit
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Modal konfirmasi (Stitch Screen #2 Minimalist)
      expect(find.text('Kirim Pengajuan?'), findsOneWidget);
      expect(
        find.text(
          'Pastikan seluruh data mutasi aset dan dokumen SK SDM sudah sesuai sebelum diteruskan ke pemeriksaan Operator.',
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(ElevatedButton, 'Batal'), findsOneWidget);

      // Tap Kirim Pengajuan inside confirmation dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Kirim Pengajuan'));
      await tester.pumpAndSettle();

      // Modal sukses (Stitch HTML terbaru) di atas Form
      expect(find.text('Pengajuan Berhasil Dikirim'), findsOneWidget);
      expect(find.text('NOMOR TIKET'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Lihat Status Tracking'), findsOneWidget);

      // Tap Lihat Status Tracking -> modal harus ditutup dan membuka Detail Mutasi
      await tester.tap(find.widgetWithText(ElevatedButton, 'Lihat Status Tracking'));
      await tester.pumpAndSettle();

      // Modal tertutup, halaman Detail Mutasi tampil
      expect(find.text('Pengajuan Berhasil Dikirim'), findsNothing);
      expect(find.textContaining('Detail Mutasi Screen mut_'), findsOneWidget);

      // Verify mutation in repo has applicantId == 'usr_pemohon' and currentPic == 'Pak Joko (Staff IT)'
      final userMutationsResult = await repo.getMutationsByUser('usr_pemohon');
      final list = userMutationsResult.dataOrNull!;
      expect(list.length, 1);
      expect(list.first.applicantId, 'usr_pemohon');
      expect(list.first.currentPic, 'Pak Joko (Staff IT)');
      expect(list.first.targetPic, 'Pemohon User');
      expect(list.first.asset.name, 'Printer Epson L3210');
      expect(list.first.status, MutationStatus.submitted);
    });

    testWidgets('Form Pemohon: Aset ikut bawa mengisi PIC Tujuan otomatis; Aset ditinggalkan mengosongkan PIC Tujuan', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = _FakeFullMutationRepository([]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mutationRepositoryProvider.overrideWithValue(repo),
            apiMutationRepositoryProvider.overrideWithValue(repo),
            authStateProvider.overrideWith(
              (ref) => FakePemohonAuthNotifier(testUser),
            ),
          ],
          child: const MaterialApp(
            home: PemohonCreateMutationScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Default: Aset ikut saya bawa (true)
      // PIC Tujuan otomatis terisi dengan nama Pemohon tanpa input manual
      expect(find.byKey(const Key('card_pic_tujuan_otomatis')), findsOneWidget);
      expect(find.text('Pemohon User'), findsWidgets);
      expect(find.text('Otomatis Pemohon'), findsOneWidget);

      // Ubah pilihan ke "Tidak, Aset Ditinggalkan di Unit Asal"
      final tinggalkanOption = find.text('Tidak, Aset Ditinggalkan di Unit Asal');
      await tester.ensureVisible(tinggalkanOption);
      await tester.tap(tinggalkanOption);
      await tester.pumpAndSettle();

      // PIC Tujuan dikosongkan dan info bahwa Bagian Aset yang akan menentukan tampil
      expect(find.byKey(const Key('card_pic_tujuan_ditinggalkan')), findsOneWidget);
      expect(find.text('Akan ditentukan oleh Bagian Aset'), findsOneWidget);
      expect(find.byKey(const Key('card_pic_tujuan_otomatis')), findsNothing);

      // Ubah kembali ke "Ya, Aset Ikut Saya Pindah"
      final bawaOption = find.text('Ya, Aset Ikut Saya Pindah');
      await tester.ensureVisible(bawaOption);
      await tester.tap(bawaOption);
      await tester.pumpAndSettle();

      // PIC Tujuan kembali terisi otomatis dengan nama Pemohon
      expect(find.byKey(const Key('card_pic_tujuan_otomatis')), findsOneWidget);
      expect(find.text('Pemohon User'), findsWidgets);
    });

    testWidgets('Mutasi Saya: filters by applicantId == userId and search query works', (tester) async {
      final repo = _FakeFullMutationRepository([
        createTestMutation(
          id: 'mut_user',
          ticketNumber: 'USR-2026-001',
          status: MutationStatus.submitted,
          applicantId: 'usr_pemohon',
          assetName: 'Laptop Dell Pemohon',
        ),
        createTestMutation(
          id: 'mut_other',
          ticketNumber: 'OTH-2026-002',
          status: MutationStatus.submitted,
          applicantId: 'usr_other_user',
          assetName: 'Server Milik User Lain',
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mutationRepositoryProvider.overrideWithValue(repo),
            apiMutationRepositoryProvider.overrideWithValue(repo),
            authStateProvider.overrideWith(
              (ref) => FakePemohonAuthNotifier(testUser),
            ),
          ],
          child: const MaterialApp(
            home: PemohonMutationListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Pemohon should only see their own mutation
      expect(find.text('Laptop Dell Pemohon'), findsOneWidget);
      expect(find.text('Server Milik User Lain'), findsNothing);

      // Search by ticket or name
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Dell');
      await tester.pumpAndSettle();
      expect(find.text('Laptop Dell Pemohon'), findsOneWidget);

      await tester.enterText(searchField, 'NonExistent');
      await tester.pumpAndSettle();
      expect(find.text('Laptop Dell Pemohon'), findsNothing);
      expect(find.textContaining('Tidak ada pengajuan'), findsOneWidget);
    });

    testWidgets('Detail & Tracking: displays status stepper, returned banner, and Edit button', (tester) async {
      final returnedMutation = createTestMutation(
        id: 'mut_returned',
        ticketNumber: 'RET-2026-001',
        status: MutationStatus.returned,
        returnReason: 'Harap perbaiki lokasi tujuan dan sertakan surat tugas.',
      );
      final repo = _FakeFullMutationRepository([returnedMutation]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mutationRepositoryProvider.overrideWithValue(repo),
            apiMutationRepositoryProvider.overrideWithValue(repo),
            authStateProvider.overrideWith(
              (ref) => FakePemohonAuthNotifier(testUser),
            ),
          ],
          child: const MaterialApp(
            home: PemohonMutationDetailScreen(mutationId: 'mut_returned'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check ticket and status
      expect(find.text('RET-2026-001'), findsOneWidget);
      expect(find.text('Pengajuan Dikembalikan untuk Diperbaiki'), findsOneWidget);
      expect(find.text('Harap perbaiki lokasi tujuan dan sertakan surat tugas.'), findsOneWidget);

      // Stepper should have 'Pengajuan' and 'Verifikasi Aset' (PRD V1.1)
      expect(find.text('Pengajuan'), findsOneWidget);
      expect(find.textContaining('Verifikasi Aset'), findsOneWidget);

      // Edit & Ajukan Ulang button should be visible
      expect(find.text('Edit & Ajukan Ulang'), findsOneWidget);
    });

    testWidgets('Edit & Ajukan Ulang: edits mutation, saves, resets status to submitted', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final returnedMutation = createTestMutation(
        id: 'mut_edit',
        ticketNumber: 'EDT-2026-001',
        status: MutationStatus.returned,
        returnReason: 'Mohon update PIC baru.',
      );
      final repo = _FakeFullMutationRepository([returnedMutation]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mutationRepositoryProvider.overrideWithValue(repo),
            apiMutationRepositoryProvider.overrideWithValue(repo),
            authStateProvider.overrideWith(
              (ref) => FakePemohonAuthNotifier(testUser),
            ),
          ],
          child: const MaterialApp(
            home: PemohonEditMutationScreen(mutationId: 'mut_edit'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Shows original returnReason
      expect(find.text('Mohon update PIC baru.'), findsOneWidget);

      // Edit fields using explicit keys
      await tester.enterText(
        find.byKey(const Key('input_edit_target_location')),
        'Cabang Medan',
      );
      await tester.enterText(
        find.byKey(const Key('input_edit_target_pic')),
        'Rian Hidayat',
      );
      await tester.enterText(
        find.byKey(const Key('input_edit_reason')),
        'Alasan revisi lengkap',
      );
      await tester.pumpAndSettle();

      // Tap Ajukan Ulang
      await tester.ensureVisible(find.byKey(const Key('btn_ajukan_ulang')));
      await tester.tap(find.byKey(const Key('btn_ajukan_ulang')));
      await tester.pumpAndSettle();

      // Verify status in repository became submitted
      final check = await repo.getMutationById('mut_edit');
      expect(check.dataOrNull!.status, MutationStatus.submitted);
      expect(check.dataOrNull!.targetLocation, 'Cabang Medan');
      expect(check.dataOrNull!.targetPic, 'Rian Hidayat');
    });

    testWidgets('Notifications: tapping notification marks read and navigates to detail', (tester) async {
      String? openedDetailId;
      final router = GoRouter(
        initialLocation: '/notifications',
        routes: [
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const PemohonNotificationsScreen(),
          ),
          GoRoute(
            path: '/pemohon/mutasi/:id',
            builder: (context, state) {
              openedDetailId = state.pathParameters['id'];
              return Scaffold(body: Text('Detail $openedDetailId'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Look for notification with mutation id
      expect(find.text('Menunggu Konfirmasi Anda'), findsOneWidget);
      await tester.tap(find.text('Menunggu Konfirmasi Anda'));
      await tester.pumpAndSettle();

      expect(openedDetailId, 'mut_006');
    });

    testWidgets('Konfirmasi: Sesuai completes mutation; Tidak Sesuai returns with reason', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final pendingMutation = createTestMutation(
        id: 'mut_pending',
        ticketNumber: 'CNF-2026-001',
        status: MutationStatus.pendingConfirmation,
      );
      final repo = _FakeFullMutationRepository([pendingMutation]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mutationRepositoryProvider.overrideWithValue(repo),
            apiMutationRepositoryProvider.overrideWithValue(repo),
            authStateProvider.overrideWith(
              (ref) => FakePemohonAuthNotifier(testUser),
            ),
          ],
          child: const MaterialApp(
            home: PemohonConfirmationScreen(mutationId: 'mut_pending'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Sesuai button exists
      expect(find.byKey(const Key('btn_sesuai_konfirmasi')), findsOneWidget);
      expect(find.byKey(const Key('btn_tidak_sesuai_konfirmasi')), findsOneWidget);

      // 1. Test "Sesuai" flow:
      await tester.tap(find.byKey(const Key('btn_sesuai_konfirmasi')));
      await tester.pumpAndSettle();

      // Confirmation dialog shows up
      expect(find.widgetWithText(AlertDialog, 'Konfirmasi Mutasi'), findsOneWidget);
      await tester.tap(find.text('Ya, Konfirmasi'));
      await tester.pumpAndSettle();

      // Verify status became completed
      final completed = await repo.getMutationById('mut_pending');
      expect(completed.dataOrNull!.status, MutationStatus.completed);

      // 2. Test "Tidak Sesuai" flow on another mutation:
      final pending2 = createTestMutation(
        id: 'mut_pending_reject',
        ticketNumber: 'CNF-2026-002',
        status: MutationStatus.pendingConfirmation,
      );
      final repo2 = _FakeFullMutationRepository([pending2]);

      final router2 = GoRouter(
        initialLocation: '/confirm/mut_pending_reject',
        routes: [
          GoRoute(
            path: '/confirm/:id',
            builder: (context, state) => PemohonConfirmationScreen(
              mutationId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/pemohon/mutasi/:id/edit',
            builder: (context, state) => const Scaffold(body: Text('Edit Screen')),
          ),
        ],
      );

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mutationRepositoryProvider.overrideWithValue(repo2),
            apiMutationRepositoryProvider.overrideWithValue(repo2),
            authStateProvider.overrideWith(
              (ref) => FakePemohonAuthNotifier(testUser),
            ),
          ],
          child: MaterialApp.router(routerConfig: router2),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_tidak_sesuai_konfirmasi')));
      await tester.pumpAndSettle();

      // Dialog asks for reason
      expect(find.text('Mutasi Tidak Sesuai'), findsOneWidget);

      // Fill reason
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Alasan / Keterangan *'),
        'Kondisi monitor retak saat tiba di cabang.',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kirim Laporan'));
      await tester.pumpAndSettle();

      // Verify mutation status reverted to waitingAssetVerification with confirmationReason saved (PRD V1.1 §6.6)
      final returned = await repo2.getMutationById('mut_pending_reject');
      expect(returned.dataOrNull!.status, MutationStatus.waitingAssetVerification);
      expect(returned.dataOrNull!.confirmationReason, 'Kondisi monitor retak saat tiba di cabang.');
    });

    testWidgets('Notification Badge: badge appears when unread exists, disappears when marked all read', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = _FakeFullMutationRepository([]);

      late ProviderContainer container;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container = ProviderContainer(
            overrides: [
              mutationRepositoryProvider.overrideWithValue(repo),
            apiMutationRepositoryProvider.overrideWithValue(repo),
              authStateProvider.overrideWith(
                (ref) => FakePemohonAuthNotifier(testUser),
              ),
            ],
          ),
          child: const MaterialApp(
            home: PemohonDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially unread count is > 0
      expect(container.read(unreadNotificationCountProvider), greaterThan(0));

      // Badge exists in floating nav bar near notification icon
      expect(
        find.descendant(
          of: find.byType(CustomFloatingNavBar),
          matching: find.byType(Badge),
        ),
        findsWidgets,
      );

      // Mark all as read
      container.read(notificationProvider.notifier).markAllAsRead();
      await tester.pumpAndSettle();

      // Unread count is now 0
      expect(container.read(unreadNotificationCountProvider), 0);

      // Badge should disappear from floating nav bar
      expect(
        find.descendant(
          of: find.byType(CustomFloatingNavBar),
          matching: find.byType(Badge),
        ),
        findsNothing,
      );
    });

    testWidgets('Profile Screen: displays consistent layout, dynamic role info, and logout dialog', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => FakePemohonAuthNotifier(testUser),
            ),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify user details rendered
      expect(find.text('Pemohon User'), findsWidgets);
      expect(find.text('pemohon@mutasiku.id'), findsWidgets);
      expect(find.text('Pemohon'), findsWidgets);
      expect(find.text('INFORMASI AKUN'), findsOneWidget);

      // Verify no "Kembali ke Dashboard" button
      expect(find.text('Kembali ke Dashboard'), findsNothing);
      expect(find.text('Kembali ke Beranda'), findsNothing);

      // Verify logout button
      final logoutBtn = find.text('Keluar dari Aplikasi');
      expect(logoutBtn, findsOneWidget);

      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.text('Keluar dari Akun?'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Ya, Keluar'), findsOneWidget);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(find.text('Keluar dari Akun?'), findsNothing);
    });

    testWidgets('Searchable Picker: opens bottom sheet, filters, and selects item', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      String? pickedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  pickedValue = await SearchablePickerBottomSheet.show(
                    context: context,
                    title: 'Pilih Lokasi',
                    items: const [
                      'Lantai 1 — Lobby',
                      'Cabang Surabaya',
                      'Cabang Bandung',
                    ],
                  );
                },
                child: const Text('Buka Picker'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Picker'));
      await tester.pumpAndSettle();

      // Picker is open
      expect(find.text('Pilih Lokasi'), findsOneWidget);
      expect(find.text('Lantai 1 — Lobby'), findsOneWidget);
      expect(find.text('Cabang Surabaya'), findsOneWidget);
      expect(find.text('Cabang Bandung'), findsOneWidget);

      // Search for Bandung
      await tester.enterText(find.byType(TextField), 'Bandung');
      await tester.pumpAndSettle();

      expect(find.text('Cabang Bandung'), findsOneWidget);
      expect(find.text('Cabang Surabaya'), findsNothing);
      expect(find.text('Lantai 1 — Lobby'), findsNothing);

      // Tap on item
      await tester.tap(find.text('Cabang Bandung'));
      await tester.pumpAndSettle();

      // Picker dismissed and value returned
      expect(pickedValue, 'Cabang Bandung');
    });
  });
}
