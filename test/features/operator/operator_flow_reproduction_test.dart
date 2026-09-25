// test/features/operator/operator_flow_reproduction_test.dart
//
// Regression test: Memastikan pengajuan mutasi baru dari Pemohon (registered maupun unregistered)
// langsung muncul di daftar, pencarian, dan detail Operator dengan status 'submitted'.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/core/providers/core_providers.dart';
import 'package:mutasiku/core/services/connectivity_service.dart';
import 'package:mutasiku/features/asset/data/repositories/asset_repository_impl.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/auth/presentation/providers/auth_provider.dart';
import 'package:mutasiku/features/mutation/data/repositories/mutation_repository_impl.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/domain/repositories/mutation_repository.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';
import 'package:mutasiku/features/operator/presentation/providers/operator_verification_provider.dart';
import 'package:mutasiku/features/operator/presentation/screens/operator_dashboard_screen.dart';
import 'package:mutasiku/features/operator/presentation/screens/operator_mutations_screen.dart';
import 'package:mutasiku/features/operator/presentation/screens/operator_verification_detail_screen.dart';

import 'presentation/operator_verification_widget_test.dart';

void main() {
  setUp(() {
    MutationRepositoryImpl.resetForTesting();
    final assetRepo = AssetRepositoryImpl();
    MutationRepositoryImpl(assetRepository: assetRepo);
  });

  const pemohonUser = User(
    id: 'usr_pemohon',
    username: 'pemohon1',
    name: 'Budi Pemohon',
    email: 'pemohon@mutasiku.id',
    role: UserRole.pemohon,
  );

  const operatorUser = User(
    id: 'usr_operator',
    username: 'operator1',
    name: 'Siti Operator',
    email: 'operator@mutasiku.id',
    role: UserRole.operator,
  );

  test('Trace end-to-end: Registered asset submit -> Operator list -> Operator detail', () async {
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => FakeAuthNotifier(pemohonUser),
        ),
      ],
    );
    addTearDown(container.dispose);

    // 1. Operator accesses all mutations prior to new submission (caches provider)
    final initialOperatorMutations =
        await container.read(operatorAllMutationsProvider.future);
    expect(initialOperatorMutations, isNotEmpty);
    final initialCount = initialOperatorMutations.length;

    // 2. Pemohon submits a registered asset mutation
    final params = SubmitMutationParams(
      applicantId: pemohonUser.id,
      applicantName: pemohonUser.name,
      assetId: 'ast_102', // MacBook Pro
      assetName: 'MacBook Pro M2',
      isUnregisteredAsset: false,
      sourceLocation: 'Lantai 3 - IT Dept',
      targetLocation: 'Lantai 5 - Direksi',
      currentPic: 'Budi Santoso',
      targetPic: 'Direktur Keuangan',
      reason: 'Kebutuhan presentasi direksi.',
    );

    final newMutation =
        await container.read(submitMutationProvider.notifier).submit(params);

    // Verify properties of submitted mutation
    expect(newMutation, isNotNull);
    expect(newMutation!.id, isNotEmpty);
    expect(newMutation.status, equals(MutationStatus.submitted));
    expect(newMutation.applicantId, equals('usr_pemohon'));
    expect(newMutation.assetId, equals('ast_102'));
    expect(newMutation.isUnregisteredAsset, isFalse);

    // 3. Operator checks operatorAllMutationsProvider and filteredIncomingMutationsProvider
    final updatedOperatorMutations =
        await container.read(operatorAllMutationsProvider.future);

    // Check if new mutation is present in Operator list
    final foundInAll =
        updatedOperatorMutations.any((m) => m.id == newMutation.id);
    expect(
      foundInAll,
      isTrue,
      reason: 'New mutation from Pemohon must appear in operatorAllMutationsProvider',
    );
    expect(updatedOperatorMutations.length, equals(initialCount + 1));

    final filteredAsync = container.read(filteredIncomingMutationsProvider);
    final filteredList = filteredAsync.valueOrNull ?? [];
    final foundInFiltered = filteredList.any((m) => m.id == newMutation.id);
    expect(
      foundInFiltered,
      isTrue,
      reason: 'New mutation from Pemohon must appear in filteredIncomingMutationsProvider with default submitted filter',
    );

    // 4. Operator detail access
    final detailMutation =
        await container.read(mutationDetailProvider(newMutation.id).future);
    expect(detailMutation.id, equals(newMutation.id));
    expect(detailMutation.status, equals(MutationStatus.submitted));
    expect(detailMutation.applicantId, equals('usr_pemohon'));
    expect(detailMutation.assetId, equals('ast_102'));
    expect(detailMutation.isUnregisteredAsset, isFalse);
  });

  test('Trace end-to-end: Unregistered asset submit -> Operator list (search & filter) -> Operator detail', () async {
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => FakeAuthNotifier(pemohonUser),
        ),
      ],
    );
    addTearDown(container.dispose);

    // 1. Operator caches mutation list initially
    await container.read(operatorAllMutationsProvider.future);

    // 2. Pemohon submits unregistered asset mutation
    final params = SubmitMutationParams(
      applicantId: pemohonUser.id,
      applicantName: pemohonUser.name,
      assetId: null,
      assetName: 'Proyektor Epson EB-X500',
      isUnregisteredAsset: true,
      customAssetName: 'Proyektor Epson EB-X500',
      customSerialNumber: 'SN-EPSON-9988',
      sourceLocation: 'Gudang Logistik',
      targetLocation: 'Ruang Rapat Direksi',
      currentPic: 'Staff Gudang',
      targetPic: 'Sekretaris Direksi',
      reason: 'Penggantian proyektor ruang rapat yang rusak.',
    );

    final unregMutation =
        await container.read(submitMutationProvider.notifier).submit(params);

    expect(unregMutation, isNotNull);
    expect(unregMutation!.id, isNotEmpty);
    expect(unregMutation.status, equals(MutationStatus.submitted));
    expect(unregMutation.applicantId, equals('usr_pemohon'));
    expect(unregMutation.assetId, isNull);
    expect(unregMutation.isUnregisteredAsset, isTrue);
    expect(unregMutation.customAssetName, equals('Proyektor Epson EB-X500'));
    expect(unregMutation.customSerialNumber, equals('SN-EPSON-9988'));

    // 3. Operator list checks
    final operatorMutations =
        await container.read(operatorAllMutationsProvider.future);
    final found = operatorMutations.any((m) => m.id == unregMutation.id);
    expect(found, isTrue);

    // Search by serial number
    container.read(operatorSearchQueryProvider.notifier).state = 'SN-EPSON-9988';
    final searchBySerialAsync = container.read(filteredIncomingMutationsProvider);
    final searchBySerialList = searchBySerialAsync.valueOrNull ?? [];
    expect(searchBySerialList.any((m) => m.id == unregMutation.id), isTrue);

    // Search by custom asset name
    container.read(operatorSearchQueryProvider.notifier).state = 'Proyektor Epson';
    final searchByNameAsync = container.read(filteredIncomingMutationsProvider);
    final searchByNameList = searchByNameAsync.valueOrNull ?? [];
    expect(searchByNameList.any((m) => m.id == unregMutation.id), isTrue);

    // Reset search
    container.read(operatorSearchQueryProvider.notifier).state = '';

    // 4. Operator detail access for unregistered asset
    final detail =
        await container.read(mutationDetailProvider(unregMutation.id).future);
    expect(detail.id, equals(unregMutation.id));
    expect(detail.status, equals(MutationStatus.submitted));
    expect(detail.isUnregisteredAsset, isTrue);
    expect(detail.assetId, isNull);
    expect(detail.displayAssetName, equals('Proyektor Epson EB-X500'));
    expect(detail.displayAssetCode, equals('SN-EPSON-9988'));
  });

  testWidgets('Widget regression: Operator sees new Pemohon mutation in Dashboard and Mutations screen', (tester) async {
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => FakeAuthNotifier(operatorUser),
        ),
        connectivityStatusProvider.overrideWith(
          (ref) => Stream.value(ConnectivityStatus.online),
        ),
      ],
    );
    addTearDown(container.dispose);

    // Pre-cache operator dashboard
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: OperatorDashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final initialPendingText = find.text('Menunggu Verifikasi');
    expect(initialPendingText, findsOneWidget);
    final initialPendingCount = container.read(verificationStatsProvider).pendingCount;

    // Pemohon submits new mutation
    final params = SubmitMutationParams(
      applicantId: 'usr_pemohon',
      applicantName: 'Budi Pemohon',
      assetId: 'ast_101',
      assetName: 'Laptop Dell Latitude',
      isUnregisteredAsset: false,
      sourceLocation: 'Lantai 2 - Marketing',
      targetLocation: 'Lantai 4 - HRD',
      currentPic: 'Ahmad PIC',
      targetPic: 'Rudi HRD',
      reason: 'Mutasi karyawan baru.',
    );

    // Submit using the same container / repository
    late Mutation? submitted;
    await tester.runAsync(() async {
      submitted =
          await container.read(submitMutationProvider.notifier).submit(params);
      await container.read(operatorAllMutationsProvider.future);
    });
    expect(submitted, isNotNull);

    // Re-pump Dashboard: stats must update reactively
    await tester.pumpAndSettle();
    final updatedPendingCount = container.read(verificationStatsProvider).pendingCount;
    expect(updatedPendingCount, equals(initialPendingCount + 1));

    // Open OperatorMutationsScreen: card must appear
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: OperatorMutationsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(Key('card_mutation_${submitted!.id}')), findsOneWidget);
    expect(find.text(submitted!.ticketNumber), findsOneWidget);

    // Open Operator detail screen directly
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: OperatorVerificationDetailScreen(mutationId: submitted!.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(submitted!.ticketNumber), findsOneWidget);
    expect(find.text('Diajukan'), findsWidgets);
  });
}
