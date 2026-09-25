// test/features/staff/domain/usecases/staff_asset_update_usecases_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/core/errors/failures.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/features/asset/domain/entities/asset.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_category.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_status.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/domain/repositories/mutation_repository.dart';
import 'package:mutasiku/features/mutation/domain/usecases/get_staff_mutations_usecase.dart';
import 'package:mutasiku/features/mutation/domain/usecases/process_staff_asset_update_usecase.dart';

class FakeStaffMutationRepository implements MutationRepository {
  final List<Mutation> mutations;

  FakeStaffMutationRepository(this.mutations);

  @override
  Future<Result<Mutation>> submitMutation(SubmitMutationParams params) async =>
      throw UnimplementedError();

  @override
  Future<Result<Mutation>> updateMutation({
    required String mutationId,
    required String targetLocation,
    required String targetPic,
    required String reason,
    String? documentName,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Result<List<Mutation>>> getMutationsByUser(String userId) async =>
      Result.success(mutations);

  @override
  Future<Result<Mutation>> getMutationById(String id) async {
    final mutation = mutations.where((m) => m.id == id).firstOrNull;
    if (mutation == null) {
      return const Result.failure(
        NotFoundFailure(message: 'Pengajuan mutasi tidak ditemukan.'),
      );
    }
    return Result.success(mutation);
  }

  @override
  Future<Result<List<Mutation>>> getAllMutations() async =>
      Result.success(mutations);

  @override
  Future<Result<Mutation>> verifyMutation({
    required String mutationId,
    required String operatorName,
    bool requiresKadivApproval = false,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Result<Mutation>> returnMutation({
    required String mutationId,
    required String reason,
    required String operatorName,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Result<Mutation>> approveMutationKabag({
    required String mutationId,
    required String kabagName,
    required bool requiresKadivApproval,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Result<Mutation>> rejectMutationKabag({
    required String mutationId,
    required String reason,
    required String kabagName,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Result<Mutation>> approveMutationKadiv({
    required String mutationId,
    required String kadivName,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Result<Mutation>> rejectMutationKadiv({
    required String mutationId,
    required String reason,
    required String kadivName,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Result<Mutation>> confirmMutation({
    required String mutationId,
    required String confirmedBy,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Result<Mutation>> processStaffAssetUpdate({
    required String mutationId,
    required String newLocation,
    required String newPic,
    required String staffName,
  }) async {
    final index = mutations.indexWhere((m) => m.id == mutationId);
    if (index == -1) {
      return const Result.failure(
        NotFoundFailure(message: 'Pengajuan mutasi tidak ditemukan.'),
      );
    }

    final current = mutations[index];
    if (current.status != MutationStatus.approved) {
      return const Result.failure(
        ValidationFailure(
          message:
              'Hanya mutasi berstatus Disetujui yang dapat diperbarui oleh Staff Aset.',
        ),
      );
    }

    final updatedAsset = current.asset.copyWith(
      location: newLocation,
      pic: newPic,
    );

    final updated = current.copyWith(
      asset: updatedAsset,
      targetLocation: newLocation,
      targetPic: newPic,
      status: MutationStatus.pendingConfirmation,
      staffUpdatedAt: DateTime.now(),
      staffUpdatedBy: staffName,
    );

    mutations[index] = updated;
    return Result.success(updated);
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

  Mutation createDummyMutation({
    required String id,
    MutationStatus status = MutationStatus.approved,
  }) {
    return Mutation(
      id: id,
      ticketNumber: 'ELK-2026-00001',
      asset: dummyAsset,
      applicantName: 'Rina',
      currentLocation: 'Lantai 1 — IT',
      targetLocation: 'Lantai 4 — Finance',
      currentPic: 'Rina',
      targetPic: 'Budi',
      reason: 'Pindah tugas',
      status: status,
      createdAt: DateTime.now(),
    );
  }

  group('GetStaffMutationsUseCase tests', () {
    test('returns only mutations with approved status by default', () async {
      final fakeRepo = FakeStaffMutationRepository([
        createDummyMutation(id: 'm1', status: MutationStatus.submitted),
        createDummyMutation(id: 'm2', status: MutationStatus.approved),
        createDummyMutation(id: 'm3', status: MutationStatus.waitingKabagApproval),
        createDummyMutation(id: 'm4', status: MutationStatus.approved),
        createDummyMutation(id: 'm5', status: MutationStatus.pendingConfirmation),
      ]);

      final useCase = GetStaffMutationsUseCase(repository: fakeRepo);
      final result = await useCase();

      expect(result.isSuccess, true);
      final list = result.dataOrNull!;
      expect(list.length, 2);
      expect(list.every((m) => m.status == MutationStatus.approved), true);
    });
  });

  group('ProcessStaffAssetUpdateUseCase tests', () {
    test('successfully updates location, pic, and changes status to pendingConfirmation',
        () async {
      final fakeRepo = FakeStaffMutationRepository([
        createDummyMutation(id: 'm_approved', status: MutationStatus.approved),
      ]);

      final useCase = ProcessStaffAssetUpdateUseCase(repository: fakeRepo);
      final result = await useCase(
        mutationId: 'm_approved',
        newLocation: 'Lantai 5 — Executive',
        newPic: 'Ahmad Manager',
        staffName: 'Rizky Staff Aset',
      );

      expect(result.isSuccess, true);
      final updated = result.dataOrNull!;
      expect(updated.status, MutationStatus.pendingConfirmation);
      expect(updated.targetLocation, 'Lantai 5 — Executive');
      expect(updated.targetPic, 'Ahmad Manager');
      expect(updated.asset.location, 'Lantai 5 — Executive');
      expect(updated.asset.pic, 'Ahmad Manager');
      expect(updated.staffUpdatedBy, 'Rizky Staff Aset');
      expect(updated.staffUpdatedAt, isNotNull);
    });

    test('fails if mutationId is empty', () async {
      final fakeRepo = FakeStaffMutationRepository([]);
      final useCase = ProcessStaffAssetUpdateUseCase(repository: fakeRepo);

      final result = await useCase(
        mutationId: '  ',
        newLocation: 'Lokasi Baru',
        newPic: 'PIC Baru',
        staffName: 'Staff',
      );

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('fails if newLocation is empty', () async {
      final fakeRepo = FakeStaffMutationRepository([]);
      final useCase = ProcessStaffAssetUpdateUseCase(repository: fakeRepo);

      final result = await useCase(
        mutationId: 'm1',
        newLocation: '   ',
        newPic: 'PIC Baru',
        staffName: 'Staff',
      );

      expect(result.isFailure, true);
      expect(result.failureOrNull?.message, contains('Lokasi baru wajib diisi'));
    });

    test('fails if newPic is empty', () async {
      final fakeRepo = FakeStaffMutationRepository([]);
      final useCase = ProcessStaffAssetUpdateUseCase(repository: fakeRepo);

      final result = await useCase(
        mutationId: 'm1',
        newLocation: 'Lokasi Baru',
        newPic: '   ',
        staffName: 'Staff',
      );

      expect(result.isFailure, true);
      expect(result.failureOrNull?.message, contains('PIC baru wajib diisi'));
    });

    test('fails if mutation status is not approved', () async {
      final fakeRepo = FakeStaffMutationRepository([
        createDummyMutation(id: 'm_submitted', status: MutationStatus.submitted),
      ]);

      final useCase = ProcessStaffAssetUpdateUseCase(repository: fakeRepo);
      final result = await useCase(
        mutationId: 'm_submitted',
        newLocation: 'Lokasi Baru',
        newPic: 'PIC Baru',
        staffName: 'Staff',
      );

      expect(result.isFailure, true);
      expect(
        result.failureOrNull?.message,
        contains('Hanya mutasi berstatus Disetujui yang dapat diperbarui'),
      );
    });
  });
}
