// lib/features/mutation/domain/usecases/get_mutations_usecase.dart
//
// Use case: Ambil daftar mutasi milik user.
// Sumber: SCREEN-SPEC.md REQ-002.

import '../../../../core/errors/result.dart';
import '../entities/mutation.dart';
import '../repositories/mutation_repository.dart';

/// Use case untuk mengambil daftar mutasi berdasarkan userId.
class GetMutationsUseCase {
  final MutationRepository repository;

  const GetMutationsUseCase({required this.repository});

  Future<Result<List<Mutation>>> call(String userId) {
    return repository.getMutationsByUser(userId);
  }
}
