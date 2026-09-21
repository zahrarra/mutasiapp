// lib/features/mutation/domain/usecases/submit_mutation_usecase.dart
//
// Use case: Ajukan Mutasi.
// Sumber: ROLE-FLOW.md §3, TECHNICAL-DESIGN.md §19.
//
// CATATAN FLOW:
// Pemohon memasukkan data aset secara manual pada form pengajuan.
// Aset tidak perlu sudah tersedia di database pada saat pengajuan dibuat.
//
// Use case ini hanya melakukan validasi data pengajuan,
// kemudian meneruskannya ke MutationRepository.

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../entities/mutation.dart';
import '../repositories/mutation_repository.dart';

/// Use case untuk mengajukan pengajuan mutasi baru.
///
/// Data aset dimasukkan manual oleh Pemohon.
///
/// Validasi:
/// 1. Nama aset wajib diisi.
/// 2. Kode / nomor aset / serial wajib diisi.
/// 3. Lokasi aset saat ini wajib diisi.
/// 4. Lokasi tujuan wajib diisi.
/// 5. PIC baru wajib diisi.
/// 6. Alasan mutasi wajib diisi.
///
/// Catatan:
/// Use case TIDAK mencari aset melalui AssetRepository karena
/// aset belum harus tersedia di database pada saat pengajuan.
class SubmitMutationUseCase {
  final MutationRepository mutationRepository;

  const SubmitMutationUseCase({required this.mutationRepository});

  Future<Result<Mutation>> call(SubmitMutationParams params) async {
    // Validasi nama aset.
    if (params.assetName.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Nama aset wajib diisi.'),
      );
    }

    // Validasi kode / nomor aset / serial.
    if (params.assetId.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Kode / Nomor Aset / Serial wajib diisi.'),
      );
    }

    // Validasi lokasi aset saat ini.
    if (params.sourceLocation.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Lokasi aset saat ini wajib diisi.'),
      );
    }

    // Validasi lokasi tujuan.
    if (params.targetLocation.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Lokasi tujuan wajib dipilih.'),
      );
    }

    // Validasi PIC baru.
    if (params.targetPic.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Penanggung jawab baru wajib dipilih.'),
      );
    }

    // Validasi alasan mutasi.
    if (params.reason.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Alasan mutasi wajib diisi.'),
      );
    }

    // Semua validasi berhasil.
    //
    // Tidak ada pencarian AssetRepository di sini.
    // Data aset akan dibuat berdasarkan input manual Pemohon
    // oleh MutationRepository.
    return mutationRepository.submitMutation(params);
  }
}
