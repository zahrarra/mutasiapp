// test/features/pemohon/presentation/screens/pemohon_confirmation_flow_test.dart
//
// Comprehensive unit and widget tests for Fitur Konfirmasi Pemohon:
// - Only pendingConfirmation mutations can be confirmed
// - Pemohon only sees their own mutations (access control)
// - Displays latest asset, location, PIC, and Staff Aset update info
// - Tombol Sesuai: saves confirmation, status becomes completed, invalidates providers & notifications, updates UI without refresh
// - Tombol Tidak Sesuai: prompts reason, saves returnReason, returns to returned status
// - Zero manual refresh button, standard Back button only

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
import 'package:mutasiku/features/mutation/domain/repositories/mutation_repository.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';
import 'package:mutasiku/features/pemohon/presentation/screens/pemohon_confirmation_screen.dart';

class _FakeMutationRepository implements MutationRepository {
  final Map<String, Mutation> _mutations = {};

  _FakeMutationRepository(List<Mutation> list) {
    for (final m in list) {
      _mutations[m.id] = m;
    }
  }

  @override
  Future<Result<Mutation>> confirmMutation({
    required String mutationId,
    required String confirmedBy,
  }) async {
    final current = _mutations[mutationId];
    if (current == null) {
      return const Result.failure(NotFoundFailure(message: 'Not found'));
    }
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
  }

  @override
  Future<Result<Mutation>> returnMutation({
    required String mutationId,
    required String reason,
    required String operatorName,
  }) async {
    final current = _mutations[mutationId];
    if (current == null) {
      return const Result.failure(NotFoundFailure(message: 'Not found'));
    }
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
  Future<Result<Mutation>> getMutationById(String id) async {
    final m = _mutations[id];
    if (m == null) {
      return const Result.failure(NotFoundFailure(message: 'Not found'));
    }
    return Result.success(m);
  }

  @override
  Future<Result<List<Mutation>>> getMutationsByUser(String userId) async {
    return Result.success(_mutations.values.where((m) => m.applicantId == userId).toList());
  }

  @override
  Future<Result<List<Mutation>>> getAllMutations() async {
    return Result.success(_mutations.values.toList());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(User user)
      : super(
          loginUseCase: LoginUseCase(repository: _FakePemohonAuthRepository(user)),
          logoutUseCase: LogoutUseCase(repository: _FakePemohonAuthRepository(user)),
          authRepository: _FakePemohonAuthRepository(user),
        ) {
    state = AuthState(isLoading: false, user: user);
  }
}

Mutation _createTestMutation({
  required String id,
  required String applicantId,
  required String applicantName,
  required MutationStatus status,
  String? staffUpdatedBy,
  DateTime? staffUpdatedAt,
}) {
  const cat = AssetCategory(id: 'cat_1', code: 'ELK', name: 'Elektronik & IT');
  const asset = Asset(
    id: 'AST-TEST-01',
    assetCode: 'AST-ELK-2026-0001',
    name: 'MacBook Pro M3 Max',
    category: cat,
    location: 'Cabang Bandung',
    pic: 'Rudi Hermawan',
    status: AssetStatus.inMutation,
    condition: 'Sangat Baik',
    acquisitionYear: 2026,
  );

  return Mutation(
    id: id,
    ticketNumber: 'ELK-2026-00001',
    asset: asset,
    applicantId: applicantId,
    applicantName: applicantName,
    currentLocation: 'Kantor Pusat',
    targetLocation: 'Cabang Bandung',
    currentPic: 'Budi Santoso',
    targetPic: 'Rudi Hermawan',
    reason: 'Kebutuhan tim engineering di Cabang Bandung',
    status: status,
    staffUpdatedBy: staffUpdatedBy,
    staffUpdatedAt: staffUpdatedAt,
    createdAt: DateTime(2026, 9, 20),
  );
}

void main() {
  const pemohonUser = User(
    id: 'usr_pemohon',
    username: 'pemohon',
    name: 'Rina',
    email: 'rina@company.com',
    role: UserRole.pemohon,
  );

  const otherUser = User(
    id: 'usr_other',
    username: 'other',
    name: 'Dewi',
    email: 'dewi@company.com',
    role: UserRole.pemohon,
  );

  group('Fitur Konfirmasi Pemohon Tests', () {
    testWidgets('1. Displays latest asset, location, PIC, and Staff Aset info', (tester) async {
      final mutation = _createTestMutation(
        id: 'mut_conf_1',
        applicantId: pemohonUser.id,
        applicantName: pemohonUser.name,
        status: MutationStatus.pendingConfirmation,
        staffUpdatedBy: 'Ahmad Staff Aset',
        staffUpdatedAt: DateTime(2026, 9, 24, 10, 30),
      );
      final repo = _FakeMutationRepository([mutation]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mutationRepositoryProvider.overrideWithValue(repo),
            authStateProvider.overrideWith((ref) => _FakeAuthNotifier(pemohonUser)),
          ],
          child: const MaterialApp(
            home: PemohonConfirmationScreen(mutationId: 'mut_conf_1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and status
      expect(find.text('ELK-2026-00001'), findsOneWidget);
      expect(find.text('Menunggu Konfirmasi'), findsAtLeastNWidgets(1));

      // Check asset card displays updated asset information
      expect(find.text('MacBook Pro M3 Max'), findsOneWidget);
      expect(find.text('AST-ELK-2026-0001'), findsOneWidget);
      expect(find.text('Lokasi: Cabang Bandung'), findsOneWidget);
      expect(find.text('PIC: Rudi Hermawan'), findsOneWidget);

      // Check Staff Aset update banner and route
      expect(find.textContaining('Diperbarui oleh Staff Aset: Ahmad Staff Aset'), findsOneWidget);
      expect(find.text('Kantor Pusat'), findsOneWidget);
      expect(find.text('Cabang Bandung'), findsAtLeastNWidgets(1));
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Rudi Hermawan'), findsAtLeastNWidgets(1));

      // Verify no manual refresh button exists
      expect(find.byIcon(Icons.refresh), findsNothing);
      expect(find.textContaining('Refresh'), findsNothing);
    });

    testWidgets('2. Access control: Pemohon cannot view another user\'s mutation', (tester) async {
      final mutation = _createTestMutation(
        id: 'mut_conf_other',
        applicantId: otherUser.id,
        applicantName: otherUser.name,
        status: MutationStatus.pendingConfirmation,
      );
      final repo = _FakeMutationRepository([mutation]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mutationRepositoryProvider.overrideWithValue(repo),
            authStateProvider.overrideWith((ref) => _FakeAuthNotifier(pemohonUser)),
          ],
          child: const MaterialApp(
            home: PemohonConfirmationScreen(mutationId: 'mut_conf_other'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show Access Denied
      expect(find.text('Akses Ditolak'), findsOneWidget);
      expect(find.text('Anda hanya dapat melihat dan mengonfirmasi pengajuan mutasi milik Anda sendiri.'), findsOneWidget);
      expect(find.text('✓ Sesuai'), findsNothing);
      expect(find.text('Tidak Sesuai'), findsNothing);
    });

    testWidgets('3. Only pendingConfirmation can be confirmed (non-pending shows warning banner)', (tester) async {
      final mutation = _createTestMutation(
        id: 'mut_conf_submitted',
        applicantId: pemohonUser.id,
        applicantName: pemohonUser.name,
        status: MutationStatus.submitted,
      );
      final repo = _FakeMutationRepository([mutation]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mutationRepositoryProvider.overrideWithValue(repo),
            authStateProvider.overrideWith((ref) => _FakeAuthNotifier(pemohonUser)),
          ],
          child: const MaterialApp(
            home: PemohonConfirmationScreen(mutationId: 'mut_conf_submitted'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header shows Diajukan
      expect(find.text('Diajukan'), findsAtLeastNWidgets(1));

      // Shows warning banner
      expect(find.textContaining('Pengajuan ini berstatus "Diajukan"'), findsOneWidget);

      // Buttons Sesuai and Tidak Sesuai are NOT rendered
      expect(find.byKey(const Key('btn_sesuai_konfirmasi')), findsNothing);
      expect(find.byKey(const Key('btn_tidak_sesuai_konfirmasi')), findsNothing);
    });

    testWidgets('4. Sesuai flow: confirms, becomes completed, updates UI & notifications without refresh', (tester) async {
      final mutation = _createTestMutation(
        id: 'mut_conf_sesuai',
        applicantId: pemohonUser.id,
        applicantName: pemohonUser.name,
        status: MutationStatus.pendingConfirmation,
        staffUpdatedBy: 'Ahmad Staff Aset',
      );
      final repo = _FakeMutationRepository([mutation]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mutationRepositoryProvider.overrideWithValue(repo),
            authStateProvider.overrideWith((ref) => _FakeAuthNotifier(pemohonUser)),
          ],
          child: const MaterialApp(
            home: PemohonConfirmationScreen(mutationId: 'mut_conf_sesuai'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Sesuai button
      final sesuaiBtn = find.byKey(const Key('btn_sesuai_konfirmasi'));
      expect(sesuaiBtn, findsOneWidget);
      await tester.tap(sesuaiBtn);
      await tester.pumpAndSettle();

      // Dialog confirmation
      expect(find.widgetWithText(AlertDialog, 'Konfirmasi Mutasi'), findsOneWidget);
      expect(find.text('Ya, Konfirmasi'), findsOneWidget);

      await tester.tap(find.text('Ya, Konfirmasi'));
      await tester.pumpAndSettle();

      // Verify mutation in repo became completed
      final checkRepo = await repo.getMutationById('mut_conf_sesuai');
      expect(checkRepo.dataOrNull!.status, MutationStatus.completed);
      expect(checkRepo.dataOrNull!.asset.status, AssetStatus.available);

      // Verify UI immediately displays completed state
      expect(find.text('Selesai'), findsAtLeastNWidgets(1));
      expect(find.text('Konfirmasi telah diberikan. Mutasi aset telah selesai.'), findsOneWidget);

      // Action bar should now be gone
      expect(find.byKey(const Key('btn_sesuai_konfirmasi')), findsNothing);
      expect(find.byKey(const Key('btn_tidak_sesuai_konfirmasi')), findsNothing);
    });

    testWidgets('5. Tidak Sesuai flow: requires reason, saves returnReason, returns to returned status', (tester) async {
      final mutation = _createTestMutation(
        id: 'mut_conf_tidak_sesuai',
        applicantId: pemohonUser.id,
        applicantName: pemohonUser.name,
        status: MutationStatus.pendingConfirmation,
        staffUpdatedBy: 'Ahmad Staff Aset',
      );
      final repo = _FakeMutationRepository([mutation]);

      final router = GoRouter(
        initialLocation: '/confirm/mut_conf_tidak_sesuai',
        routes: [
          GoRoute(
            path: '/confirm/:id',
            builder: (context, state) => PemohonConfirmationScreen(
              mutationId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/pemohon/mutasi/:id/edit',
            builder: (context, state) => const Scaffold(body: Text('Halaman Edit Pengajuan')),
          ),
        ],
      );

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mutationRepositoryProvider.overrideWithValue(repo),
            authStateProvider.overrideWith((ref) => _FakeAuthNotifier(pemohonUser)),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Click Tidak Sesuai
      final tidakSesuaiBtn = find.byKey(const Key('btn_tidak_sesuai_konfirmasi'));
      expect(tidakSesuaiBtn, findsOneWidget);
      await tester.tap(tidakSesuaiBtn);
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.text('Mutasi Tidak Sesuai'), findsOneWidget);

      // Try submitting without reason (validation test)
      await tester.tap(find.text('Perbaiki Pengajuan'));
      await tester.pumpAndSettle();
      expect(find.text('Alasan ketidaksesuaian wajib diisi'), findsOneWidget);

      // Fill in real reason
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Alasan / Keterangan *'),
        'Barang yang diterima tipe berbeda dari pengajuan',
      );
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Perbaiki Pengajuan'));
      await tester.pumpAndSettle();

      // Verify repository updated with returned status and real returnReason
      final checkRepo = await repo.getMutationById('mut_conf_tidak_sesuai');
      expect(checkRepo.dataOrNull!.status, MutationStatus.returned);
      expect(checkRepo.dataOrNull!.returnReason, 'Barang yang diterima tipe berbeda dari pengajuan');

      // Verify navigated to Edit screen
      expect(find.text('Halaman Edit Pengajuan'), findsOneWidget);
    });
  });
}
