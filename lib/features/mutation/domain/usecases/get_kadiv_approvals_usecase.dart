// lib/features/mutation/domain/usecases/get_kadiv_approvals_usecase.dart
//
// Use case: Mengambil seluruh mutasi untuk keperluan approval Kadiv.
// Sumber: PRD.md §6.5, ROLE-FLOW.md §6, SCREEN-SPEC.md KDV-001 & KDV-002.

import '../../../../core/errors/result.dart';
import '../entities/mutation.dart';
import '../repositories/mutation_repository.dart';

class GetKadivApprovalsUseCase {
  final MutationRepository repository;

  const GetKadivApprovalsUseCase({required this.repository});

  Future<Result<List<Mutation>>> call() async {
    return repository.getAllMutations();
  }
}
