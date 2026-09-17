// lib/features/mutation/domain/usecases/get_mutation_detail_usecase.dart
//
// Use case: Ambil detail mutasi berdasarkan ID.
// Sumber: SCREEN-SPEC.md REQ-007.

import '../../../../core/errors/result.dart';
import '../entities/mutation.dart';
import '../repositories/mutation_repository.dart';

/// Use case untuk mengambil detail satu pengajuan mutasi.
class GetMutationDetailUseCase {
  final MutationRepository repository;

  const GetMutationDetailUseCase({required this.repository});

  Future<Result<Mutation>> call(String id) {
    return repository.getMutationById(id);
  }
}
