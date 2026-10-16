// test/features/pemohon/presentation/screens/pemohon_confirmation_screen_bug_test.dart
//
// Regression test for Pemohon Confirmation Screen:
// 1. Pending confirmation (waitingConfirmation) with null confirmedAt:
//    - Shows "Menunggu Konfirmasi" badge
//    - Does NOT show "Selesai" badge
//    - Does NOT show "Konfirmasi telah diberikan" or "Konfirmasi berhasil" banner
//    - Shows action buttons ("Konfirmasi & Terima Aset", "Lapor Ketidaksesuaian")
//    - Shows blue verification instruction note
// 2. Action state isolation (no leak from other mutations):
//    - Even if pemohonConfirmationActionProvider was populated by another mutation,
//      opening this mutation ignores the mismatched result and keeps buttons visible.
// 3. Completed mutation (status == completed OR confirmedAt != null):
//    - Shows "Selesai" badge
//    - Shows exactly one "Konfirmasi telah diberikan. Mutasi aset telah selesai." banner
//    - Hides action buttons
//    - Hides blue physical verification note
// 4. API Parsing regression:
//    - MutationModel correctly maps 'menunggu_konfirmasi_pemohon', 'disetujui', 'approved'
//    - MutationModel parses confirmed_at safely.

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
import 'package:mutasiku/features/mutation/data/models/mutation_model.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/domain/repositories/mutation_repository.dart';
import 'package:mutasiku/features/mutation/domain/usecases/confirm_mutation_usecase.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';
import 'package:mutasiku/features/pemohon/presentation/providers/pemohon_confirmation_provider.dart';
import 'package:mutasiku/features/pemohon/presentation/screens/pemohon_confirmation_screen.dart';

class _FakeMutationRepository implements MutationRepository {
  final Map<String, Mutation> _mutations = {};

  _FakeMutationRepository(List<Mutation> list) {
    for (final m in list) {
      _mutations[m.id] = m;
    }
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
    return Result.success(
      _mutations.values.where((m) => m.applicantId == userId).toList(),
    );
  }

  @override
  Future<Result<List<Mutation>>> getAllMutations() async {
    return Result.success(_mutations.values.toList());
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
    final updated = current.copyWith(
      status: MutationStatus.completed,
      confirmedAt: DateTime.now(),
    );
    _mutations[mutationId] = updated;
    return Result.success(updated);
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
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(User user)
    : super(
        loginUseCase: LoginUseCase(
          repository: _FakePemohonAuthRepository(user),
        ),
        logoutUseCase: LogoutUseCase(
          repository: _FakePemohonAuthRepository(user),
        ),
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
  DateTime? confirmedAt,
  String ticketNumber = 'UM-2026-0008',
}) {
  const cat = AssetCategory(id: 'cat_um', code: 'UM', name: 'Umum');
  return Mutation(
    id: id,
    ticketNumber: ticketNumber,
    assetId: 'AST-UM-2026-005',
    asset: const Asset(
      id: 'AST-UM-2026-005',
      assetCode: 'AST-UM-2026-005',
      name: 'Rak Dokumen Arsip',
      category: cat,
      status: AssetStatus.inMutation,
      condition: 'Baik',
      acquisitionYear: 2026,
      location: 'Lantai 1 — Arsip',
      pic: 'Atalya Rara',
      serialNumber: 'SN-RAK-001',
    ),
    applicantId: applicantId,
    applicantName: applicantName,
    currentLocation: 'Lantai 1 — Arsip',
    targetLocation: 'Lantai 3 — Ruang Rapat',
    currentPic: 'Atalya Rara',
    targetPic: 'Atalya Rara',
    reason: 'Pemindahan arsip ke ruang rapat',
    status: status,
    confirmedAt: confirmedAt,
    staffUpdatedBy: 'Staf Aset Budi',
    staffUpdatedAt: DateTime(2026, 10, 15, 16, 36),
    createdAt: DateTime(2026, 10, 15, 8, 0),
  );
}

Widget _buildTestApp({
  required String initialLocation,
  required List<Override> overrides,
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/pemohon/mutasi/:id/confirm',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return PemohonConfirmationScreen(mutationId: id);
        },
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const Scaffold(body: Text('Dashboard')),
      ),
    ],
  );

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  const pemohonUser = User(
    id: 'usr_pemohon_atalya',
    username: 'atalya_rara',
    name: 'Atalya Rara',
    email: 'atalya@company.com',
    role: UserRole.pemohon,
  );

  group('Pemohon Confirmation Screen Bug Regression Tests', () {
    testWidgets(
      '1. Mutation in waitingConfirmation shows "Menunggu Konfirmasi" badge, action buttons, and NO success banners',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final mutation = _createTestMutation(
          id: '8',
          applicantId: pemohonUser.id,
          applicantName: pemohonUser.name,
          status: MutationStatus.waitingConfirmation,
          confirmedAt: null,
        );

        final repo = _FakeMutationRepository([mutation]);

        await tester.pumpWidget(
          _buildTestApp(
            initialLocation: '/pemohon/mutasi/8/confirm',
            overrides: [
              apiMutationRepositoryProvider.overrideWithValue(repo),
              authStateProvider.overrideWith((ref) => _FakeAuthNotifier(pemohonUser)),
              confirmMutationUseCaseProvider.overrideWithValue(
                ConfirmMutationUseCase(repository: repo),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Must show Menunggu Konfirmasi badge, NOT Selesai
        expect(find.text('Menunggu Konfirmasi'), findsOneWidget);
        expect(find.text('Selesai'), findsNothing);

        // No success banner
        expect(
          find.text('Konfirmasi telah diberikan. Mutasi aset telah selesai.'),
          findsNothing,
        );
        expect(
          find.text('Konfirmasi berhasil. Mutasi aset telah selesai.'),
          findsNothing,
        );

        // Physical verification info box must be visible
        expect(
          find.textContaining('Harap lakukan verifikasi fisik sebelum melakukan konfirmasi final'),
          findsOneWidget,
        );

        // Action buttons must be visible
        expect(find.byKey(const Key('btn_sesuai_konfirmasi')), findsOneWidget);
        expect(find.byKey(const Key('btn_tidak_sesuai_konfirmasi')), findsOneWidget);
        expect(find.text('Konfirmasi & Terima Aset'), findsOneWidget);
        expect(find.text('Lapor Ketidaksesuaian'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Stale action state from an earlier mutation does not leak into an unconfirmed mutation',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final mutation = _createTestMutation(
          id: '8',
          applicantId: pemohonUser.id,
          applicantName: pemohonUser.name,
          status: MutationStatus.waitingConfirmation,
          confirmedAt: null,
        );

        final anotherMutation = _createTestMutation(
          id: '99',
          applicantId: pemohonUser.id,
          applicantName: pemohonUser.name,
          status: MutationStatus.completed,
          confirmedAt: DateTime.now(),
        );

        final repo = _FakeMutationRepository([mutation, anotherMutation]);

        // We prepare a container where pemohonConfirmationActionProvider already
        // has a successMessage and result from mutation '99'
        final container = ProviderContainer(
          overrides: [
            apiMutationRepositoryProvider.overrideWithValue(repo),
            authStateProvider.overrideWith((ref) => _FakeAuthNotifier(pemohonUser)),
            confirmMutationUseCaseProvider.overrideWithValue(
              ConfirmMutationUseCase(repository: repo),
            ),
          ],
        );

        // Simulate stale state in notifier
        container.read(pemohonConfirmationActionProvider.notifier).state =
            PemohonConfirmationActionState(
              isLoading: false,
              successMessage: 'Konfirmasi berhasil. Mutasi aset telah selesai.',
              result: anotherMutation,
            );

        final router = GoRouter(
          initialLocation: '/pemohon/mutasi/8/confirm',
          routes: [
            GoRoute(
              path: '/pemohon/mutasi/:id/confirm',
              builder: (context, state) {
                final id = state.pathParameters['id'] ?? '';
                return PemohonConfirmationScreen(mutationId: id);
              },
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        // Mutation 8 must NOT be affected by mutation 99's stale completed result:
        expect(find.text('Menunggu Konfirmasi'), findsOneWidget);
        expect(find.text('Selesai'), findsNothing);
        expect(find.byKey(const Key('btn_sesuai_konfirmasi')), findsOneWidget);
        expect(find.byKey(const Key('btn_tidak_sesuai_konfirmasi')), findsOneWidget);
      },
    );

    testWidgets(
      '3. Completed mutation shows "Selesai" badge, single success banner, no action buttons, no physical verification prompt',
      (tester) async {
        final mutation = _createTestMutation(
          id: '8',
          applicantId: pemohonUser.id,
          applicantName: pemohonUser.name,
          status: MutationStatus.completed,
          confirmedAt: DateTime(2026, 10, 16, 12, 0),
        );

        final repo = _FakeMutationRepository([mutation]);

        await tester.pumpWidget(
          _buildTestApp(
            initialLocation: '/pemohon/mutasi/8/confirm',
            overrides: [
              apiMutationRepositoryProvider.overrideWithValue(repo),
              authStateProvider.overrideWith((ref) => _FakeAuthNotifier(pemohonUser)),
              confirmMutationUseCaseProvider.overrideWithValue(
                ConfirmMutationUseCase(repository: repo),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Shows Selesai badge
        expect(find.text('Selesai'), findsOneWidget);

        // Shows exactly one success banner
        expect(
          find.text('Konfirmasi telah diberikan. Mutasi aset telah selesai.'),
          findsOneWidget,
        );

        // Verification instruction note is hidden on completed mutations
        expect(
          find.textContaining('Harap lakukan verifikasi fisik sebelum melakukan konfirmasi final'),
          findsNothing,
        );

        // Action buttons are hidden
        expect(find.byKey(const Key('btn_sesuai_konfirmasi')), findsNothing);
        expect(find.byKey(const Key('btn_tidak_sesuai_konfirmasi')), findsNothing);
      },
    );

    test('4. MutationModel and MutationStatus safely parse API responses', () {
      expect(
        MutationStatus.fromApiValue('menunggu_konfirmasi_pemohon'),
        MutationStatus.waitingConfirmation,
      );
      expect(
        MutationStatus.fromApiValue('disetujui'),
        MutationStatus.waitingConfirmation,
      );
      expect(
        MutationStatus.fromApiValue('approved'),
        MutationStatus.waitingConfirmation,
      );

      final modelPending = MutationModel.fromJson({
        'id': 8,
        'ticket_number': 'UM-2026-0008',
        'status': 'menunggu_konfirmasi_pemohon',
        'applicant_name': 'Atalya Rara',
        'current_location': 'Lantai 1',
        'target_location': 'Lantai 3',
        'current_pic': 'Atalya Rara',
        'target_pic': 'Atalya Rara',
        'reason': 'Pindah meja',
        'confirmed_at': null,
        'created_at': '2026-10-15T08:00:00Z',
      });

      expect(modelPending.status, MutationStatus.waitingConfirmation);
      expect(modelPending.confirmedAt, isNull);

      final modelCompleted = MutationModel.fromJson({
        'id': 8,
        'ticket_number': 'UM-2026-0008',
        'status': 'selesai',
        'applicant_name': 'Atalya Rara',
        'current_location': 'Lantai 1',
        'target_location': 'Lantai 3',
        'current_pic': 'Atalya Rara',
        'target_pic': 'Atalya Rara',
        'reason': 'Pindah meja',
        'confirmed_at': '2026-10-16T12:00:00Z',
        'created_at': '2026-10-15T08:00:00Z',
      });

      expect(modelCompleted.status, MutationStatus.completed);
      expect(modelCompleted.confirmedAt, isNotNull);
    });
  });
}
