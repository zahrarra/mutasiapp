// test/features/kabag/domain/usecases/kabag_approval_usecases_test.dart
//
// Unit tests untuk Use Cases Approval Kabag Aset.
// Sumber: PRD.md §6.4, §8 Aturan 7, ROLE-FLOW.md §5, SCREEN-SPEC.md KBG-003–004.

import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/core/errors/failures.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/features/asset/domain/entities/asset.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_category.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_status.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/domain/repositories/mutation_repository.dart';
import 'package:mutasiku/features/mutation/domain/usecases/approve_mutation_kabag_usecase.dart';
import 'package:mutasiku/features/mutation/domain/usecases/get_kabag_approvals_usecase.dart';
import 'package:mutasiku/features/mutation/domain/usecases/reject_mutation_kabag_usecase.dart';

class FakeKabagMutationRepository implements MutationRepository {
  final List<Mutation> mutations;

  FakeKabagMutationRepository(this.mutations);

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
  }) async {
    final index = mutations.indexWhere((m) => m.id == mutationId);
    if (index == -1) {
      return const Result.failure(
        NotFoundFailure(message: 'Pengajuan mutasi tidak ditemukan.'),
      );
    }
    final updated = mutations[index].copyWith(
      status: MutationStatus.approved,
      approvedBy: kabagName,
      approvedAt: DateTime.now(),
    );
    mutations[index] = updated;
    return Result.success(updated);
  }

  @override
  Future<Result<Mutation>> rejectMutationKabag({
    required String mutationId,
    required String reason,
    required String kabagName,
  }) async {
    final index = mutations.indexWhere((m) => m.id == mutationId);
    if (index == -1) {
      return const Result.failure(
        NotFoundFailure(message: 'Pengajuan mutasi tidak ditemukan.'),
      );
    }
    final updated = mutations[index].copyWith(
      status: MutationStatus.rejected,
      rejectionReason: reason,
      rejectedBy: kabagName,
      rejectedAt: DateTime.now(),
    );
    mutations[index] = updated;
    return Result.success(updated);
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
}

void main() {
  const dummyAsset = Asset(
    id: 'AST-002',
    assetCode: 'AST-FUR-2024-0002',
    name: 'Meja Kerja Eksekutif',
    category: AssetCategory(
      id: 'cat_2',
      code: 'FUR',
      name: 'Furniture & Mebel',
    ),
    location: 'Kantor Pusat',
    pic: 'Dewi',
    status: AssetStatus.inMutation,
    condition: 'Baik',
    acquisitionYear: 2024,
  );

  Mutation createDummyMutation({
    required String id,
    MutationStatus status = MutationStatus.waitingKabagApproval,
  }) {
    return Mutation(
      id: id,
      ticketNumber: 'FUR-2026-00002',
      asset: dummyAsset,
      applicantName: 'Dewi',
      currentLocation: 'Kantor Pusat',
      targetLocation: 'Cabang Semarang',
      currentPic: 'Dewi',
      targetPic: 'Siti',
      reason: 'Pengadaan cabang',
      status: status,
      createdAt: DateTime.now(),
    );
  }

  group('ApproveMutationKabagUseCase tests', () {
    test('succeeds when mutation status is waitingKabagApproval', () async {
      final fakeRepo = FakeKabagMutationRepository([
        createDummyMutation(
          id: 'mut_kbg_1',
          status: MutationStatus.waitingKabagApproval,
        ),
      ]);
      final useCase = ApproveMutationKabagUseCase(repository: fakeRepo);

      final result = await useCase(
        mutationId: 'mut_kbg_1',
        kabagName: 'Pak Kabag',
      );

      expect(result.isSuccess, true);
      final updated = result.dataOrNull!;
      expect(updated.status, MutationStatus.approved);
      expect(updated.approvedBy, 'Pak Kabag');
      expect(updated.approvedAt, isNotNull);
    });

    test('fails if mutationId is empty', () async {
      final fakeRepo = FakeKabagMutationRepository([]);
      final useCase = ApproveMutationKabagUseCase(repository: fakeRepo);

      final result = await useCase(mutationId: '   ', kabagName: 'Pak Kabag');

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('fails if mutation is not found', () async {
      final fakeRepo = FakeKabagMutationRepository([]);
      final useCase = ApproveMutationKabagUseCase(repository: fakeRepo);

      final result = await useCase(
        mutationId: 'non_existent_id',
        kabagName: 'Pak Kabag',
      );

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test(
      'fails if mutation status is not waitingKabagApproval (e.g. submitted)',
      () async {
        final fakeRepo = FakeKabagMutationRepository([
          createDummyMutation(
            id: 'mut_kbg_1',
            status: MutationStatus.submitted,
          ),
        ]);
        final useCase = ApproveMutationKabagUseCase(repository: fakeRepo);

        final result = await useCase(
          mutationId: 'mut_kbg_1',
          kabagName: 'Pak Kabag',
        );

        expect(result.isFailure, true);
        expect(result.failureOrNull, isA<ValidationFailure>());
        expect(
          result.failureOrNull?.message,
          contains(
            'Hanya pengajuan berstatus Menunggu Approval Kabag yang dapat disetujui',
          ),
        );
      },
    );
  });

  group('RejectMutationKabagUseCase tests', () {
    test(
      'succeeds when status is waitingKabagApproval and reason is provided',
      () async {
        final fakeRepo = FakeKabagMutationRepository([
          createDummyMutation(
            id: 'mut_kbg_1',
            status: MutationStatus.waitingKabagApproval,
          ),
        ]);
        final useCase = RejectMutationKabagUseCase(repository: fakeRepo);

        final result = await useCase(
          mutationId: 'mut_kbg_1',
          reason: 'Aset masih terpakai untuk proyek aktif.',
          kabagName: 'Pak Kabag',
        );

        expect(result.isSuccess, true);
        final updated = result.dataOrNull!;
        expect(updated.status, MutationStatus.rejected);
        expect(
          updated.rejectionReason,
          'Aset masih terpakai untuk proyek aktif.',
        );
        expect(updated.rejectedBy, 'Pak Kabag');
        expect(updated.rejectedAt, isNotNull);
      },
    );

    test('fails when reason is empty (PRD Aturan 7 & KBG-004)', () async {
      final fakeRepo = FakeKabagMutationRepository([
        createDummyMutation(
          id: 'mut_kbg_1',
          status: MutationStatus.waitingKabagApproval,
        ),
      ]);
      final useCase = RejectMutationKabagUseCase(repository: fakeRepo);

      final result = await useCase(
        mutationId: 'mut_kbg_1',
        reason: '   ',
        kabagName: 'Pak Kabag',
      );

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(
        result.failureOrNull?.message,
        contains('Alasan penolakan wajib diisi'),
      );
    });

    test('fails if mutation status is not waitingKabagApproval', () async {
      final fakeRepo = FakeKabagMutationRepository([
        createDummyMutation(id: 'mut_kbg_1', status: MutationStatus.approved),
      ]);
      final useCase = RejectMutationKabagUseCase(repository: fakeRepo);

      final result = await useCase(
        mutationId: 'mut_kbg_1',
        reason: 'Alasan penolakan',
        kabagName: 'Pak Kabag',
      );

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });
  });

  group('GetKabagApprovalsUseCase tests', () {
    test(
      'filters only waitingKabagApproval when onlyWaitingApproval is true',
      () async {
        final fakeRepo = FakeKabagMutationRepository([
          createDummyMutation(
            id: 'm1',
            status: MutationStatus.waitingKabagApproval,
          ),
          createDummyMutation(id: 'm2', status: MutationStatus.submitted),
          createDummyMutation(id: 'm3', status: MutationStatus.approved),
          createDummyMutation(
            id: 'm4',
            status: MutationStatus.waitingKabagApproval,
          ),
        ]);
        final useCase = GetKabagApprovalsUseCase(repository: fakeRepo);

        final result = await useCase(onlyWaitingApproval: true);

        expect(result.isSuccess, true);
        final list = result.dataOrNull!;
        expect(list.length, 2);
        expect(
          list.every((m) => m.status == MutationStatus.waitingKabagApproval),
          true,
        );
      },
    );
  });
}
