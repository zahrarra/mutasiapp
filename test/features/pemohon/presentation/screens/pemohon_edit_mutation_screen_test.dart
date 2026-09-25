// test/features/pemohon/presentation/screens/pemohon_edit_mutation_screen_test.dart
//
// Widget test untuk PemohonEditMutationScreen (REQ-008: Edit & Ajukan Ulang).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mutasiku/app/router/route_names.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/features/asset/domain/entities/asset.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_category.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_status.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/domain/repositories/mutation_repository.dart';
import 'package:mutasiku/features/mutation/domain/usecases/update_mutation_usecase.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';
import 'package:mutasiku/features/pemohon/presentation/screens/pemohon_edit_mutation_screen.dart';

class _FakeMutationRepository implements MutationRepository {
  final Map<String, Mutation> mutations;
  UpdateMutationParams? lastUpdateParams;

  _FakeMutationRepository(List<Mutation> list)
      : mutations = {for (final m in list) m.id: m};

  @override
  Future<Result<Mutation>> submitMutation(SubmitMutationParams params) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<Mutation>> updateMutation({
    required String mutationId,
    required String targetLocation,
    required String targetPic,
    required String reason,
    String? documentName,
  }) async {
    lastUpdateParams = UpdateMutationParams(
      mutationId: mutationId,
      targetLocation: targetLocation,
      targetPic: targetPic,
      reason: reason,
      documentName: documentName,
    );

    final current = mutations[mutationId];
    if (current == null) {
      throw Exception('Not found');
    }

    final updated = current.copyWith(
      targetLocation: targetLocation,
      targetPic: targetPic,
      reason: reason,
      status: MutationStatus.submitted,
    );
    mutations[mutationId] = updated;
    return Result.success(updated);
  }

  @override
  Future<Result<List<Mutation>>> getMutationsByUser(String userId) async {
    return Result.success(mutations.values.toList());
  }

  @override
  Future<Result<Mutation>> getMutationById(String id) async {
    final m = mutations[id];
    if (m == null) {
      throw Exception('Not found');
    }
    return Result.success(m);
  }

  @override
  Future<Result<List<Mutation>>> getAllMutations() async {
    return Result.success(mutations.values.toList());
  }

  @override
  Future<Result<Mutation>> verifyMutation({
    required String mutationId,
    required String operatorName,
    bool requiresKadivApproval = false,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<Mutation>> returnMutation({
    required String mutationId,
    required String reason,
    required String operatorName,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<Mutation>> approveMutationKabag({
    required String mutationId,
    required String kabagName,
    required bool requiresKadivApproval,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<Mutation>> rejectMutationKabag({
    required String mutationId,
    required String reason,
    required String kabagName,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<Mutation>> approveMutationKadiv({
    required String mutationId,
    required String kadivName,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<Mutation>> rejectMutationKadiv({
    required String mutationId,
    required String reason,
    required String kadivName,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<Mutation>> confirmMutation({
    required String mutationId,
    required String confirmedBy,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<Mutation>> processStaffAssetUpdate({
    required String mutationId,
    required String newLocation,
    required String newPic,
    required String staffName,
  }) async {
    throw UnimplementedError();
  }
}

const _testCategory = AssetCategory(
  id: 'cat_01',
  code: 'ELK',
  name: 'Elektronik',
);

const _testAsset = Asset(
  id: 'asset_001',
  assetCode: 'AST-001',
  name: 'Laptop Dell Latitude',
  category: _testCategory,
  location: 'Kantor Pusat',
  pic: 'Budi Santoso',
  status: AssetStatus.available,
  condition: 'Baik',
  acquisitionYear: 2024,
);

Mutation _createMutation({
  String id = 'mut_101',
  MutationStatus status = MutationStatus.returned,
  String? returnReason = 'Dokumen pendukung SK Mutasi belum lengkap.',
}) {
  return Mutation(
    id: id,
    ticketNumber: 'ELK-2026-00101',
    asset: _testAsset,
    applicantName: 'Pemohon Test',
    currentLocation: 'Kantor Pusat',
    targetLocation: 'Cabang Bandung',
    currentPic: 'Budi Santoso',
    targetPic: 'Ahmad PIC',
    reason: 'Kebutuhan tim teknis Bandung',
    status: status,
    returnReason: returnReason,
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  );
}

void main() {
  group('PemohonEditMutationScreen Tests', () {
    testWidgets(
        'renders real operator returnReason and workflow explanation',
        (tester) async {
      final mutation = _createMutation(
        returnReason: 'Dokumen pendukung SK Mutasi belum lengkap.',
      );
      final repo = _FakeMutationRepository([mutation]);

      final router = GoRouter(
        initialLocation: '/pemohon/mutasi/${mutation.id}/edit',
        routes: [
          GoRoute(
            path: RouteNames.pemohonMutasiEditPath,
            builder: (context, state) =>
                PemohonEditMutationScreen(mutationId: mutation.id),
          ),
          GoRoute(
            path: RouteNames.pemohonDashboardPath,
            builder: (context, state) =>
                const Scaffold(body: Text('Dashboard')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mutationRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verifikasi alur perbaikan ditampilkan
      expect(find.text('Alur Perbaikan & Pengajuan Ulang'), findsOneWidget);
      expect(
        find.textContaining('Pengajuan dikembalikan → Perbaiki data'),
        findsOneWidget,
      );

      // 2. Verifikasi catatan operator asli ditampilkan
      expect(find.text('Catatan dari Operator:'), findsOneWidget);
      expect(
        find.text('Dokumen pendukung SK Mutasi belum lengkap.'),
        findsOneWidget,
      );

      // 3. Verifikasi info aset ditampilkan
      expect(find.text('Laptop Dell Latitude'), findsOneWidget);

      // 4. Verifikasi form fields terisi data lama (prefill)
      expect(find.text('Cabang Bandung'), findsOneWidget);
      expect(find.text('Ahmad PIC'), findsOneWidget);
      expect(find.text('Kebutuhan tim teknis Bandung'), findsOneWidget);

      // 5. Verifikasi tombol Ajukan Ulang & Kembali ke Dashboard ada
      expect(find.byKey(const Key('btn_ajukan_ulang')), findsOneWidget);
      expect(find.byKey(const Key('btn_kembali_dashboard')), findsOneWidget);
    });

    testWidgets('does NOT render fake note when returnReason is null or empty',
        (tester) async {
      final mutation = _createMutation(returnReason: null);
      final repo = _FakeMutationRepository([mutation]);

      final router = GoRouter(
        initialLocation: '/pemohon/mutasi/${mutation.id}/edit',
        routes: [
          GoRoute(
            path: RouteNames.pemohonMutasiEditPath,
            builder: (context, state) =>
                PemohonEditMutationScreen(mutationId: mutation.id),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mutationRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Alur tetap ada
      expect(find.text('Alur Perbaikan & Pengajuan Ulang'), findsOneWidget);

      // Catatan operator TIDAK ditampilkan (tidak ada catatan palsu)
      expect(find.text('Catatan dari Operator:'), findsNothing);
    });

    testWidgets('shows guard screen when mutation status is not returned',
        (tester) async {
      final mutation = _createMutation(status: MutationStatus.submitted);
      final repo = _FakeMutationRepository([mutation]);

      final router = GoRouter(
        initialLocation: '/pemohon/mutasi/${mutation.id}/edit',
        routes: [
          GoRoute(
            path: RouteNames.pemohonMutasiEditPath,
            builder: (context, state) =>
                PemohonEditMutationScreen(mutationId: mutation.id),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mutationRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.textContaining('Pengajuan ini berstatus "Diajukan"'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Pengajuan hanya dapat diedit ketika berstatus'),
        findsOneWidget,
      );
      expect(find.text('Lihat Detail Mutasi'), findsOneWidget);
      expect(find.text('Kembali'), findsOneWidget);
      expect(find.byKey(const Key('btn_ajukan_ulang')), findsNothing);
    });

    testWidgets('clicking Kembali navigates to detail route',
        (tester) async {
      final mutation = _createMutation();
      final repo = _FakeMutationRepository([mutation]);

      final router = GoRouter(
        initialLocation: '/pemohon/mutasi/${mutation.id}/edit',
        routes: [
          GoRoute(
            path: RouteNames.pemohonMutasiEditPath,
            builder: (context, state) =>
                PemohonEditMutationScreen(mutationId: mutation.id),
          ),
          GoRoute(
            path: RouteNames.pemohonMutasiDetailPath,
            builder: (context, state) =>
                const Scaffold(body: Text('Detail Screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mutationRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to "Kembali" button
      await tester
          .ensureVisible(find.byKey(const Key('btn_kembali_dashboard')));
      await tester.pumpAndSettle();

      // Tap "Kembali" button
      await tester.tap(find.byKey(const Key('btn_kembali_dashboard')));
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, '/pemohon/mutasi/${mutation.id}');
      expect(find.text('Detail Screen'), findsOneWidget);
    });

    testWidgets('resubmitting updates status to submitted and navigates back',
        (tester) async {
      final mutation = _createMutation();
      final repo = _FakeMutationRepository([mutation]);

      final router = GoRouter(
        initialLocation: '/pemohon/mutasi/${mutation.id}',
        routes: [
          GoRoute(
            path: RouteNames.pemohonMutasiDetailPath,
            builder: (context, state) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => context.push(
                    RouteNames.pemohonMutasiEditPath
                        .replaceFirst(':id', mutation.id),
                  ),
                  child: const Text('Ke Edit'),
                ),
              );
            },
          ),
          GoRoute(
            path: RouteNames.pemohonMutasiEditPath,
            builder: (context, state) {
              return PemohonEditMutationScreen(mutationId: mutation.id);
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mutationRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to Edit
      await tester.tap(find.text('Ke Edit'));
      await tester.pumpAndSettle();

      expect(find.byType(PemohonEditMutationScreen), findsOneWidget);

      // Edit target location
      await tester.enterText(
        find.byKey(const Key('input_edit_target_location')),
        'Cabang Surabaya Baru',
      );

      // Scroll to "Ajukan Ulang" button
      await tester.ensureVisible(find.byKey(const Key('btn_ajukan_ulang')));
      await tester.pumpAndSettle();

      // Tap Ajukan Ulang
      await tester.tap(find.byKey(const Key('btn_ajukan_ulang')));
      await tester.pumpAndSettle();

      // Status in repository is now submitted
      expect(repo.mutations[mutation.id]!.status, MutationStatus.submitted);
      expect(
        repo.mutations[mutation.id]!.targetLocation,
        'Cabang Surabaya Baru',
      );

      // Navigated back to detail
      expect(find.byType(PemohonEditMutationScreen), findsNothing);
      expect(find.text('Ke Edit'), findsOneWidget);
    });
  });
}
