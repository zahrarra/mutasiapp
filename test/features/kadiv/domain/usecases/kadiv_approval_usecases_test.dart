// test/features/kadiv/domain/usecases/kadiv_approval_usecases_test.dart
//
// Unit tests untuk Use Cases Approval Kadiv.
// Sumber: PRD.md §6.5, §8 Aturan 7, ROLE-FLOW.md §6, SCREEN-SPEC.md KDV-001–004.

import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/core/errors/failures.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/features/asset/domain/entities/asset.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_category.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_status.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/domain/repositories/mutation_repository.dart';
import 'package:mutasiku/features/mutation/domain/usecases/approve_mutation_kadiv_usecase.dart';
import 'package:mutasiku/features/mutation/domain/usecases/get_kadiv_approvals_usecase.dart';
import 'package:mutasiku/features/mutation/domain/usecases/reject_mutation_kadiv_usecase.dart';

class FakeKadivMutationRepository implements MutationRepository {
  final List<Mutation> mutations;

  FakeKadivMutationRepository(this.mutations);

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
    final index = mutations.indexWhere((m) => m.id == mutationId);

    if (index == -1) {
      return const Result.failure(
        NotFoundFailure(message: 'Pengajuan mutasi tidak ditemukan.'),
      );
    }

    final current = mutations[index];

    final updated = current.copyWith(
      targetLocation: targetLocation,
      targetPic: targetPic,
      reason: reason,
      status: MutationStatus.submitted,
    );

    mutations[index] = updated;

    return Result.success(updated);
  }

  @override
  Future<Result<List<Mutation>>> getMutationsByUser(String userId) async {
    return Result.success(mutations);
  }

  @override
  Future<Result<Mutation>> getMutationById(String id) async {
    try {
      final item = mutations.firstWhere((m) => m.id == id);
      return Result.success(item);
    } catch (_) {
      return const Result.failure(
        NotFoundFailure(message: 'Pengajuan mutasi tidak ditemukan.'),
      );
    }
  }

  @override
  Future<Result<List<Mutation>>> getAllMutations() async {
    return Result.success(mutations);
  }

  @override
  Future<Result<Mutation>> verifyMutation({
    required String mutationId,
    required String operatorName,
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
    final index = mutations.indexWhere((m) => m.id == mutationId);
    if (index == -1) {
      return const Result.failure(
        NotFoundFailure(message: 'Pengajuan mutasi tidak ditemukan.'),
      );
    }
    final updated = mutations[index].copyWith(
      status: MutationStatus.approved,
      kadivApprovedBy: kadivName,
      kadivApprovedAt: DateTime.now(),
    );
    mutations[index] = updated;
    return Result.success(updated);
  }

  @override
  Future<Result<Mutation>> rejectMutationKadiv({
    required String mutationId,
    required String reason,
    required String kadivName,
  }) async {
    final index = mutations.indexWhere((m) => m.id == mutationId);
    if (index == -1) {
      return const Result.failure(
        NotFoundFailure(message: 'Pengajuan mutasi tidak ditemukan.'),
      );
    }
    final updated = mutations[index].copyWith(
      status: MutationStatus.rejected,
      kadivRejectionReason: reason,
      kadivRejectedBy: kadivName,
      kadivRejectedAt: DateTime.now(),
      rejectionReason: reason,
      rejectedBy: kadivName,
      rejectedAt: DateTime.now(),
    );
    mutations[index] = updated;
    return Result.success(updated);
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

void main() {
  const dummyAsset = Asset(
    id: 'AST-00088',
    assetCode: 'AST-ELK-2024-0088',
    name: 'Server Rack Dell',
    category: AssetCategory(id: 'c1', code: 'ELK', name: 'Elektronik'),
    location: 'Kantor Pusat',
    pic: 'Rina',
    status: AssetStatus.inMutation,
    condition: 'Baik',
    acquisitionYear: 2024,
  );

  Mutation createDummyMutation({
    required String id,
    MutationStatus status = MutationStatus.waitingKadivApproval,
  }) {
    return Mutation(
      id: id,
      ticketNumber: 'ELK-2026-00088',
      asset: dummyAsset,
      applicantName: 'Rina',
      currentLocation: 'Kantor Pusat',
      targetLocation: 'Cabang Surabaya',
      currentPic: 'Rina',
      targetPic: 'Bambang',
      reason: 'Relokasi server data center.',
      status: status,
      approvedBy: 'Kabag Aset',
      approvedAt: DateTime(2026, 9, 17, 10, 0),
      createdAt: DateTime(2026, 9, 17, 8, 0),
    );
  }

  group('ApproveMutationKadivUseCase', () {
    test('berhasil menyetujui mutasi berstatus waitingKadivApproval', () async {
      final repo = FakeKadivMutationRepository([
        createDummyMutation(
          id: 'mut_kdv_1',
          status: MutationStatus.waitingKadivApproval,
        ),
      ]);
      final useCase = ApproveMutationKadivUseCase(repository: repo);

      final result = await useCase(
        mutationId: 'mut_kdv_1',
        kadivName: 'Kepala Divisi Aset',
      );

      expect(result.isSuccess, true);
      final updated = result.dataOrNull!;
      expect(updated.status, MutationStatus.approved);
      expect(updated.kadivApprovedBy, 'Kepala Divisi Aset');
    });

    test('gagal jika mutationId kosong', () async {
      final repo = FakeKadivMutationRepository([]);
      final useCase = ApproveMutationKadivUseCase(repository: repo);

      final result = await useCase(
        mutationId: '   ',
        kadivName: 'Kepala Divisi Aset',
      );

      expect(result.isFailure, true);
      expect((result as AppFailure).failure, isA<ValidationFailure>());
    });

    test('gagal jika mutasi tidak ditemukan', () async {
      final repo = FakeKadivMutationRepository([]);
      final useCase = ApproveMutationKadivUseCase(repository: repo);

      final result = await useCase(
        mutationId: 'unknown_id',
        kadivName: 'Kepala Divisi Aset',
      );

      expect(result.isFailure, true);
      expect((result as AppFailure).failure, isA<NotFoundFailure>());
    });

    test('gagal jika status mutasi bukan waitingKadivApproval', () async {
      final repo = FakeKadivMutationRepository([
        createDummyMutation(id: 'mut_kdv_1', status: MutationStatus.submitted),
      ]);
      final useCase = ApproveMutationKadivUseCase(repository: repo);

      final result = await useCase(
        mutationId: 'mut_kdv_1',
        kadivName: 'Kepala Divisi Aset',
      );

      expect(result.isFailure, true);
      expect((result as AppFailure).failure, isA<ValidationFailure>());
    });
  });

  group('RejectMutationKadivUseCase', () {
    test('berhasil menolak mutasi dengan alasan valid', () async {
      final repo = FakeKadivMutationRepository([
        createDummyMutation(
          id: 'mut_kdv_1',
          status: MutationStatus.waitingKadivApproval,
        ),
      ]);
      final useCase = RejectMutationKadivUseCase(repository: repo);

      final result = await useCase(
        mutationId: 'mut_kdv_1',
        reason: 'Perangkat server utama belum boleh dialihkan.',
        kadivName: 'Kepala Divisi Aset',
      );

      expect(result.isSuccess, true);
      final updated = result.dataOrNull!;
      expect(updated.status, MutationStatus.rejected);
      expect(
        updated.rejectionReason,
        'Perangkat server utama belum boleh dialihkan.',
      );
      expect(updated.kadivRejectedBy, 'Kepala Divisi Aset');
    });

    test('gagal jika alasan penolakan kosong', () async {
      final repo = FakeKadivMutationRepository([
        createDummyMutation(
          id: 'mut_kdv_1',
          status: MutationStatus.waitingKadivApproval,
        ),
      ]);
      final useCase = RejectMutationKadivUseCase(repository: repo);

      final result = await useCase(
        mutationId: 'mut_kdv_1',
        reason: '   ',
        kadivName: 'Kepala Divisi Aset',
      );

      expect(result.isFailure, true);
      expect((result as AppFailure).failure, isA<ValidationFailure>());
    });

    test('gagal jika status mutasi bukan waitingKadivApproval', () async {
      final repo = FakeKadivMutationRepository([
        createDummyMutation(id: 'mut_kdv_1', status: MutationStatus.approved),
      ]);
      final useCase = RejectMutationKadivUseCase(repository: repo);

      final result = await useCase(
        mutationId: 'mut_kdv_1',
        reason: 'Alasan penolakan',
        kadivName: 'Kepala Divisi Aset',
      );

      expect(result.isFailure, true);
      expect((result as AppFailure).failure, isA<ValidationFailure>());
    });
  });

  group('GetKadivApprovalsUseCase', () {
    test(
      'mengambil seluruh daftar mutasi untuk keperluan review Kadiv',
      () async {
        final repo = FakeKadivMutationRepository([
          createDummyMutation(
            id: 'm1',
            status: MutationStatus.waitingKadivApproval,
          ),
          createDummyMutation(id: 'm2', status: MutationStatus.submitted),
          createDummyMutation(id: 'm3', status: MutationStatus.approved),
        ]);
        final useCase = GetKadivApprovalsUseCase(repository: repo);

        final result = await useCase();

        expect(result.isSuccess, true);
        expect(result.dataOrNull!.length, 3);
      },
    );
  });
}
