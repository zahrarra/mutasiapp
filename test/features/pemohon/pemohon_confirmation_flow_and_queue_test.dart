// test/features/pemohon/pemohon_confirmation_flow_and_queue_test.dart
//
// Comprehensive test suite for Pemohon Confirmation Flow:
// 1. Pemohon Queue & Ownership
// 2. Status Guard (only pendingConfirmation can be confirmed)
// 3. NO Double Asset Update (location & PIC preserved from Staff Aset)
// 4. Registered Asset vs Unregistered Asset handling
// 5. Successful Confirmation & Provider Invalidation
// 6. Failed Confirmation & Error Handling
// 7. Permanent History & Ticket Immutability
// 8. Tracking Steps

import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/core/errors/failures.dart';
import 'package:mutasiku/features/asset/data/repositories/asset_repository_impl.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/mutation/data/repositories/mutation_repository_impl.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/domain/repositories/mutation_repository.dart';
import 'package:mutasiku/features/mutation/domain/usecases/confirm_mutation_usecase.dart';
import 'package:mutasiku/features/mutation/presentation/models/mutation_tracking_step.dart';

void main() {
  late AssetRepositoryImpl assetRepository;
  late MutationRepositoryImpl mutationRepository;
  late ConfirmMutationUseCase confirmMutationUseCase;

  const pemohonUser = User(
    id: 'usr_pemohon_andi',
    username: 'pemohon_andi',
    name: 'Andi Pemohon',
    email: 'andi@company.com',
    role: UserRole.pemohon,
  );

  const otherPemohonUser = User(
    id: 'usr_other_pemohon',
    username: 'pemohon_budi',
    name: 'Budi Lain',
    email: 'budi@company.com',
    role: UserRole.pemohon,
  );

  setUp(() {
    AssetRepositoryImpl.resetForTesting();
    MutationRepositoryImpl.resetForTesting();
    assetRepository = AssetRepositoryImpl();
    mutationRepository = MutationRepositoryImpl(assetRepository: assetRepository);
    confirmMutationUseCase = ConfirmMutationUseCase(repository: mutationRepository);
  });

  group('Pemohon Confirmation Flow & Queue Tests', () {
    test('1. Pemohon Queue: only original applicant sees pending confirmation mutations', () async {
      // Create mutation for Andi
      final andiSubmitRes = await mutationRepository.submitMutation(
        SubmitMutationParams(
          assetId: 'ast_1',
          assetName: 'Laptop Dell Latitude 5420',
          applicantId: pemohonUser.id,
          applicantName: pemohonUser.name,
          sourceLocation: 'Lantai 2 — IT Support',
          targetLocation: 'Lantai 5 — Keuangan',
          currentPic: 'Budi Santoso (IT Dept)',
          targetPic: 'Andi Pemohon',
          reason: 'Rotasi unit kerja ke Keuangan',
        ),
      );
      expect(andiSubmitRes.isSuccess, isTrue);
      final andiMutationId = andiSubmitRes.dataOrNull!.id;

      // Create mutation for Budi
      final budiSubmitRes = await mutationRepository.submitMutation(
        SubmitMutationParams(
          assetId: 'ast_2',
          assetName: 'Monitor Dell UltraSharp 27"',
          applicantId: otherPemohonUser.id,
          applicantName: otherPemohonUser.name,
          sourceLocation: 'Lantai 2 — IT Support',
          targetLocation: 'Lantai 3 — Ruang Meeting',
          currentPic: 'Budi Santoso (IT Dept)',
          targetPic: 'Budi Lain',
          reason: 'Display meeting',
        ),
      );
      expect(budiSubmitRes.isSuccess, isTrue);
      final budiMutationId = budiSubmitRes.dataOrNull!.id;

      // Operator verify & Kabag approve both
      await mutationRepository.verifyMutation(mutationId: andiMutationId, operatorName: 'Operator');
      await mutationRepository.approveMutationKabag(
        mutationId: andiMutationId,
        kabagName: 'Kabag Aset',
        requiresKadivApproval: false,
      );

      await mutationRepository.verifyMutation(mutationId: budiMutationId, operatorName: 'Operator');
      await mutationRepository.approveMutationKabag(
        mutationId: budiMutationId,
        kabagName: 'Kabag Aset',
        requiresKadivApproval: false,
      );

      // Staff updates Andi's asset -> pendingConfirmation
      await mutationRepository.processStaffAssetUpdate(
        mutationId: andiMutationId,
        newLocation: 'Lantai 5 — Keuangan',
        newPic: 'Andi Pemohon',
        staffName: 'Staff Hendra',
      );

      // Verify Andi's queue contains his pending confirmation
      final andiListRes = await mutationRepository.getMutationsByUser(pemohonUser.id);
      expect(andiListRes.isSuccess, isTrue);
      final andiPending = andiListRes.dataOrNull!
          .where((m) => m.status == MutationStatus.pendingConfirmation)
          .toList();
      expect(andiPending.length, 1);
      expect(andiPending.first.id, andiMutationId);
      expect(andiPending.first.applicantId, pemohonUser.id);

      // Verify Budi does NOT see Andi's pending confirmation
      final budiListRes = await mutationRepository.getMutationsByUser(otherPemohonUser.id);
      expect(budiListRes.isSuccess, isTrue);
      final budiPending = budiListRes.dataOrNull!
          .where((m) => m.status == MutationStatus.pendingConfirmation)
          .toList();
      expect(budiPending, isEmpty);
    });

    test('2. Status Guard: Confirmation disallowed from non-pendingConfirmation statuses', () async {
      final submitRes = await mutationRepository.submitMutation(
        SubmitMutationParams(
          assetId: 'ast_1',
          assetName: 'Laptop Dell Latitude 5420',
          applicantId: pemohonUser.id,
          applicantName: pemohonUser.name,
          sourceLocation: 'Lantai 2 — IT Support',
          targetLocation: 'Lantai 5 — Keuangan',
          currentPic: 'Budi Santoso',
          targetPic: 'Andi Pemohon',
          reason: 'Rotasi unit kerja',
        ),
      );
      final mutationId = submitRes.dataOrNull!.id;

      // Status: submitted -> Try confirm -> MUST fail
      var confirmRes = await confirmMutationUseCase(
        ConfirmMutationParams(
          mutationId: mutationId,
          confirmedBy: pemohonUser.name,
          userId: pemohonUser.id,
        ),
      );
      expect(confirmRes.isFailure, isTrue);
      expect(confirmRes.failureOrNull, isA<ValidationFailure>());

      // Status: waitingKabagApproval -> Try confirm -> MUST fail
      await mutationRepository.verifyMutation(mutationId: mutationId, operatorName: 'Operator');
      confirmRes = await confirmMutationUseCase(
        ConfirmMutationParams(
          mutationId: mutationId,
          confirmedBy: pemohonUser.name,
          userId: pemohonUser.id,
        ),
      );
      expect(confirmRes.isFailure, isTrue);

      // Status: approved (approvedWaitingAssetUpdate) -> Try confirm -> MUST fail
      await mutationRepository.approveMutationKabag(
        mutationId: mutationId,
        kabagName: 'Kabag Aset',
        requiresKadivApproval: false,
      );
      confirmRes = await confirmMutationUseCase(
        ConfirmMutationParams(
          mutationId: mutationId,
          confirmedBy: pemohonUser.name,
          userId: pemohonUser.id,
        ),
      );
      expect(confirmRes.isFailure, isTrue);

      // Staff asset update moves status to pendingConfirmation
      await mutationRepository.processStaffAssetUpdate(
        mutationId: mutationId,
        newLocation: 'Lantai 5 — Keuangan',
        newPic: 'Andi Pemohon',
        staffName: 'Staff Hendra',
      );

      // Now status is pendingConfirmation -> Confirmation succeeds!
      confirmRes = await confirmMutationUseCase(
        ConfirmMutationParams(
          mutationId: mutationId,
          confirmedBy: pemohonUser.name,
          userId: pemohonUser.id,
        ),
      );
      expect(confirmRes.isSuccess, isTrue);
      expect(confirmRes.dataOrNull!.status, MutationStatus.completed);

      // Status is completed -> Try confirm AGAIN -> MUST fail
      confirmRes = await confirmMutationUseCase(
        ConfirmMutationParams(
          mutationId: mutationId,
          confirmedBy: pemohonUser.name,
          userId: pemohonUser.id,
        ),
      );
      expect(confirmRes.isFailure, isTrue);
      expect(confirmRes.failureOrNull, isA<ValidationFailure>());
    });

    test('3. Ownership Guard: Non-owner cannot confirm mutation', () async {
      final submitRes = await mutationRepository.submitMutation(
        SubmitMutationParams(
          assetId: 'ast_1',
          assetName: 'Laptop Dell Latitude 5420',
          applicantId: pemohonUser.id,
          applicantName: pemohonUser.name,
          sourceLocation: 'Lantai 2 — IT Support',
          targetLocation: 'Lantai 5 — Keuangan',
          currentPic: 'Budi Santoso',
          targetPic: 'Andi Pemohon',
          reason: 'Rotasi unit kerja',
        ),
      );
      final mutationId = submitRes.dataOrNull!.id;

      await mutationRepository.verifyMutation(mutationId: mutationId, operatorName: 'Operator');
      await mutationRepository.approveMutationKabag(
        mutationId: mutationId,
        kabagName: 'Kabag Aset',
        requiresKadivApproval: false,
      );
      await mutationRepository.processStaffAssetUpdate(
        mutationId: mutationId,
        newLocation: 'Lantai 5 — Keuangan',
        newPic: 'Andi Pemohon',
        staffName: 'Staff Hendra',
      );

      // Budi tries to confirm Andi's mutation -> ForbiddenFailure
      final confirmRes = await confirmMutationUseCase(
        ConfirmMutationParams(
          mutationId: mutationId,
          confirmedBy: otherPemohonUser.name,
          userId: otherPemohonUser.id,
        ),
      );
      expect(confirmRes.isFailure, isTrue);
      expect(confirmRes.failureOrNull, isA<ForbiddenFailure>());

      // Mutation remains in pendingConfirmation
      final checkRes = await mutationRepository.getMutationById(mutationId);
      expect(checkRes.dataOrNull!.status, MutationStatus.pendingConfirmation);
    });

    test('4. NO Double Asset Update: Staff Aset updates master asset; Pemohon confirms without overwrite', () async {
      // 1. Initial master asset state
      final initialAssetRes = await assetRepository.getAssetById('ast_1');
      expect(initialAssetRes.isSuccess, isTrue);
      final initialAsset = initialAssetRes.dataOrNull!;
      expect(initialAsset.location, 'Lantai 3 — Ruang IT Developer');
      expect(initialAsset.pic, 'Budi Santoso (IT Dept)');
      final initialHistoryCount = initialAsset.history.length;

      // 2. Submit, verify, and approve
      final submitRes = await mutationRepository.submitMutation(
        SubmitMutationParams(
          assetId: 'ast_1',
          assetName: initialAsset.name,
          applicantId: pemohonUser.id,
          applicantName: pemohonUser.name,
          sourceLocation: initialAsset.location,
          targetLocation: 'Lantai 5 — Ruang Keuangan',
          currentPic: initialAsset.pic,
          targetPic: 'Siti Rahma (Finance)',
          reason: 'Pindah divisi',
        ),
      );
      final mutationId = submitRes.dataOrNull!.id;
      final ticketNumber = submitRes.dataOrNull!.ticketNumber;

      await mutationRepository.verifyMutation(mutationId: mutationId, operatorName: 'Operator');
      await mutationRepository.approveMutationKabag(
        mutationId: mutationId,
        kabagName: 'Kabag Aset',
        requiresKadivApproval: false,
      );

      // 3. Staff Aset updates master asset (location & PIC)
      final staffUpdateRes = await mutationRepository.processStaffAssetUpdate(
        mutationId: mutationId,
        newLocation: 'Lantai 5 — Ruang Keuangan',
        newPic: 'Siti Rahma (Finance)',
        staffName: 'Staff Hendra',
      );
      expect(staffUpdateRes.isSuccess, isTrue);

      // Master asset was updated by Staff Aset
      final afterStaffAssetRes = await assetRepository.getAssetById('ast_1');
      final afterStaffAsset = afterStaffAssetRes.dataOrNull!;
      expect(afterStaffAsset.location, 'Lantai 5 — Ruang Keuangan');
      expect(afterStaffAsset.pic, 'Siti Rahma (Finance)');
      expect(afterStaffAsset.history.length, initialHistoryCount + 1);

      // 4. Pemohon confirms
      final confirmRes = await confirmMutationUseCase(
        ConfirmMutationParams(
          mutationId: mutationId,
          confirmedBy: pemohonUser.name,
          userId: pemohonUser.id,
        ),
      );
      expect(confirmRes.isSuccess, isTrue);
      final completedMutation = confirmRes.dataOrNull!;
      expect(completedMutation.status, MutationStatus.completed);

      // Master asset must NOT have additional updates, history must NOT increase,
      // location and PIC set by Staff Aset must be completely preserved.
      final afterConfirmAssetRes = await assetRepository.getAssetById('ast_1');
      final afterConfirmAsset = afterConfirmAssetRes.dataOrNull!;
      expect(afterConfirmAsset.location, 'Lantai 5 — Ruang Keuangan');
      expect(afterConfirmAsset.pic, 'Siti Rahma (Finance)');
      expect(afterConfirmAsset.history.length, initialHistoryCount + 1); // Exact same count!

      // Mutation ticket remains immutable
      expect(completedMutation.ticketNumber, ticketNumber);
    });

    test('5. Unregistered Asset: preserves manual data without touching master asset', () async {
      // Submit unregistered asset
      final submitRes = await mutationRepository.submitMutation(
        SubmitMutationParams(
          isUnregisteredAsset: true,
          customAssetName: 'Printer Epson L3110 Bekas',
          customSerialNumber: 'EPS-2026-MANUAL',
          applicantId: pemohonUser.id,
          applicantName: pemohonUser.name,
          sourceLocation: 'Gudang Lama',
          targetLocation: 'Lantai 1 — Resepsionis',
          currentPic: 'Pak RT',
          targetPic: 'Mbak Resepsionis',
          reason: 'Peralihan printer non-terdaftar',
        ),
      );
      expect(submitRes.isSuccess, isTrue);
      final mutation = submitRes.dataOrNull!;
      expect(mutation.isUnregisteredAsset, isTrue);
      expect(mutation.assetId, isNull);

      final mutationId = mutation.id;

      await mutationRepository.verifyMutation(mutationId: mutationId, operatorName: 'Operator');
      await mutationRepository.approveMutationKabag(
        mutationId: mutationId,
        kabagName: 'Kabag Aset',
        requiresKadivApproval: false,
      );

      // Staff asset update
      final staffRes = await mutationRepository.processStaffAssetUpdate(
        mutationId: mutationId,
        newLocation: 'Lantai 1 — Resepsionis',
        newPic: 'Mbak Resepsionis',
        staffName: 'Staff Hendra',
      );
      expect(staffRes.isSuccess, isTrue);
      expect(staffRes.dataOrNull!.status, MutationStatus.pendingConfirmation);

      // Pemohon confirms
      final confirmRes = await confirmMutationUseCase(
        ConfirmMutationParams(
          mutationId: mutationId,
          confirmedBy: pemohonUser.name,
          userId: pemohonUser.id,
        ),
      );
      expect(confirmRes.isSuccess, isTrue);
      final completed = confirmRes.dataOrNull!;
      expect(completed.status, MutationStatus.completed);
      expect(completed.isUnregisteredAsset, isTrue);
      expect(completed.displayAssetName, 'Printer Epson L3110 Bekas');
      expect(completed.displayAssetCode, 'EPS-2026-MANUAL');
      expect(completed.assetId, isNull);
    });

    test('6. Tracking: shows completed as final step when mutation is completed', () {
      final steps = MutationTrackingHelper.buildTrackingSteps(
        status: MutationStatus.completed,
        requiresKadivApproval: false,
        applicantName: pemohonUser.name,
        staffUpdatedBy: 'Staff Hendra',
      );

      // Verify step 5 (Konfirmasi) is completed
      final confirmStep = steps.firstWhere((s) => s.key == 'pendingConfirmation');
      expect(confirmStep.state, TrackingStepState.completed);
      expect(confirmStep.badgeText, 'Terkonfirmasi');

      // Verify step 6 (Selesai) is completed
      final completedStep = steps.firstWhere((s) => s.key == 'completed');
      expect(completedStep.state, TrackingStepState.completed);
      expect(completedStep.badgeText, 'Selesai');
    });

    test('7. Tracking: shows pendingConfirmation as current step when awaiting confirmation', () {
      final steps = MutationTrackingHelper.buildTrackingSteps(
        status: MutationStatus.pendingConfirmation,
        requiresKadivApproval: false,
        applicantName: pemohonUser.name,
        staffUpdatedBy: 'Staff Hendra',
      );

      // Verify step 4 (Update Aset) is completed
      final updateStep = steps.firstWhere((s) => s.key == 'approvedWaitingAssetUpdate');
      expect(updateStep.state, TrackingStepState.completed);
      expect(updateStep.badgeText, 'Fisik Terpindah');

      // Verify step 5 (Konfirmasi) is current
      final confirmStep = steps.firstWhere((s) => s.key == 'pendingConfirmation');
      expect(confirmStep.state, TrackingStepState.current);
      expect(confirmStep.badgeText, 'Konfirmasi Diperlukan');

      // Verify step 6 (Selesai) is upcoming
      final completedStep = steps.firstWhere((s) => s.key == 'completed');
      expect(completedStep.state, TrackingStepState.upcoming);
      expect(completedStep.badgeText, 'Menunggu');
    });
  });
}
