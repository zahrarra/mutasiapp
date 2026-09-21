// lib/features/mutation/data/repositories/mutation_repository_impl.dart
//
// Mock implementasi MutationRepository.
// Sumber: ROLE-FLOW.md §3 & §4, TECHNICAL-DESIGN.md §19, SCREEN-SPEC.md OPR-001–004.
//
// Ticket format: KATEGORI-TAHUN-NOURUT (server-generated simulation).
// Data disimpan in-memory untuk development/testing.
//
// CATATAN FLOW PENGAJUAN:
// Pemohon memasukkan data aset secara manual pada form pengajuan.
// Aset TIDAK dicari terlebih dahulu dari AssetRepository/database.
// Setelah pengajuan disetujui sampai tahap Staff Aset, barulah data
// aset dapat diproses/diperbarui pada database aset.

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../asset/domain/entities/asset.dart';
import '../../../asset/domain/entities/asset_category.dart';
import '../../../asset/domain/entities/asset_status.dart';
import '../../../asset/domain/repositories/asset_repository.dart';
import '../../domain/entities/mutation.dart';
import '../../domain/entities/mutation_status.dart';
import '../../domain/repositories/mutation_repository.dart';

class MutationRepositoryImpl implements MutationRepository {
  // Dependency ini masih dipertahankan agar tidak memutus konfigurasi
  // dependency injection/provider yang sudah ada.
  //
  // Untuk submitMutation(), dependency ini TIDAK digunakan karena
  // pengajuan mutasi menerima data aset secara manual dari Pemohon.
  final AssetRepository assetRepository;

  MutationRepositoryImpl({required this.assetRepository}) {
    _initInitialSeedData();
  }

  /// In-memory storage untuk mock mutations.
  static final List<Mutation> _mutations = [];

  /// Counter untuk nomor urut tiket.
  static int _ticketCounter = 124;

  /// Flag penanda apakah seed data sudah diinisialisasi.
  static bool _initialized = false;

  /// Inisialisasi seed mock data awal jika storage kosong.
  static void _initInitialSeedData() {
    if (_initialized && _mutations.isNotEmpty) return;
    _initialized = true;

    if (_mutations.isEmpty) {
      const catElk = AssetCategory(
        id: 'cat_1',
        code: 'ELK',
        name: 'Elektronik & IT',
      );

      const catVeh = AssetCategory(
        id: 'cat_3',
        code: 'VEH',
        name: 'Kendaraan Operasional',
      );

      const catFur = AssetCategory(
        id: 'cat_2',
        code: 'FUR',
        name: 'Furniture & Mebel',
      );

      // Mock Aset 1 - Laptop Dell Latitude
      const asset1 = Asset(
        id: 'AST-00124',
        assetCode: 'AST-ELK-2024-0124',
        name: 'Laptop Dell Latitude',
        category: catElk,
        location: 'Kantor Pusat',
        pic: 'Rina',
        status: AssetStatus.inMutation,
        condition: 'Baik',
        acquisitionYear: 2024,
      );

      // Mock Aset 2 - Toyota Avanza
      const asset2 = Asset(
        id: 'AST-00042',
        assetCode: 'AST-VEH-2023-0042',
        name: 'Toyota Avanza 1.3 G',
        category: catVeh,
        location: 'Kantor Pusat',
        pic: 'Budi Santoso',
        status: AssetStatus.inMutation,
        condition: 'Baik',
        acquisitionYear: 2023,
      );

      // Mock Aset 3 - MacBook Pro 16 (Dikembalikan)
      const asset3 = Asset(
        id: 'AST-00105',
        assetCode: 'AST-ELK-2024-0105',
        name: 'MacBook Pro 16" M2',
        category: catElk,
        location: 'Cabang Jakarta',
        pic: 'Andi Wijaya',
        status: AssetStatus.available,
        condition: 'Sangat Baik',
        acquisitionYear: 2024,
      );

      // Mock Aset 4 - Meja Kerja Eksekutif
      // Sudah verifikasi valid -> Menunggu Approval Kabag
      const asset4 = Asset(
        id: 'AST-00018',
        assetCode: 'AST-FUR-2022-0018',
        name: 'Meja Kerja Eksekutif',
        category: catFur,
        location: 'Kantor Pusat',
        pic: 'Dewi Lestari',
        status: AssetStatus.inMutation,
        condition: 'Baik',
        acquisitionYear: 2022,
      );

      _mutations.addAll([
        Mutation(
          id: 'mut_001',
          ticketNumber: 'ELEKTRONIK-2026-00124',
          asset: asset1,
          applicantName: 'Rina',
          currentLocation: 'Kantor Pusat',
          targetLocation: 'Cabang Surabaya',
          currentPic: 'Rina',
          targetPic: 'Rina',
          reason: 'Perpindahan unit kerja ke Cabang Surabaya.',
          documentName: 'SK_Mutasi.pdf',
          status: MutationStatus.submitted,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),

        Mutation(
          id: 'mut_002',
          ticketNumber: 'KENDARAAN-2026-00042',
          asset: asset2,
          applicantName: 'Budi Santoso',
          currentLocation: 'Kantor Pusat',
          targetLocation: 'Cabang Bandung',
          currentPic: 'Budi Santoso',
          targetPic: 'Ahmad Fauzi',
          reason: 'Kebutuhan operasional kendaraan dinas lapangan Bandung.',
          documentName: 'Surat_Tugas_Operasional.pdf',
          status: MutationStatus.submitted,
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),

        Mutation(
          id: 'mut_003',
          ticketNumber: 'ELEKTRONIK-2026-00105',
          asset: asset3,
          applicantName: 'Andi Wijaya',
          currentLocation: 'Cabang Jakarta',
          targetLocation: 'Kantor Pusat',
          currentPic: 'Andi Wijaya',
          targetPic: 'Bambang',
          reason: 'Rotasi divisi IT pusat.',
          documentName: null,
          status: MutationStatus.returned,
          returnReason: 'Dokumen pendukung SK Mutasi belum dilampirkan.',
          verifiedBy: 'Operator Aset',
          verifiedAt: DateTime.now().subtract(const Duration(days: 1)),
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),

        Mutation(
          id: 'mut_004',
          ticketNumber: 'FURNITUR-2026-00018',
          asset: asset4,
          applicantName: 'Dewi Lestari',
          currentLocation: 'Kantor Pusat',
          targetLocation: 'Cabang Semarang',
          currentPic: 'Dewi Lestari',
          targetPic: 'Siti Rahma',
          reason: 'Pengadaan furnitur ruang manager cabang baru.',
          documentName: 'Nota_Dinas.pdf',
          status: MutationStatus.waitingKabagApproval,
          verifiedBy: 'Operator Aset',
          verifiedAt: DateTime.now().subtract(const Duration(hours: 4)),
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),

        Mutation(
          id: 'mut_005',
          ticketNumber: 'ELEKTRONIK-2026-00088',
          asset: const Asset(
            id: 'AST-00088',
            assetCode: 'AST-ELK-2024-0088',
            name: 'Server Rack Enterprise Dell PowerEdge',
            category: catElk,
            location: 'Data Center Pusat',
            pic: 'Hendra Setiawan',
            status: AssetStatus.inMutation,
            condition: 'Sangat Baik',
            acquisitionYear: 2024,
          ),
          applicantName: 'Hendra Setiawan',
          currentLocation: 'Data Center Pusat',
          targetLocation: 'Data Center Surabaya (DRC)',
          currentPic: 'Hendra Setiawan',
          targetPic: 'Bambang Pratama',
          reason: 'Relokasi server inti data center utama ke Disaster Recovery Center Surabaya sesuai kebijakan kepatuhan OJK.',
          documentName: 'SK_Relokasi_Infrastruktur_TI.pdf',
          status: MutationStatus.waitingKadivApproval,
          verifiedBy: 'Operator Aset',
          verifiedAt: DateTime.now().subtract(const Duration(hours: 6)),
          approvedBy: 'H. M. Yusuf (Kabag Aset)',
          approvedAt: DateTime.now().subtract(const Duration(hours: 2)),
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),

        // Seed data mut_006:
        // Menunggu konfirmasi Pemohon (pendingConfirmation)
        Mutation(
          id: 'mut_006',
          ticketNumber: 'FURNITUR-2026-00055',
          asset: const Asset(
            id: 'AST-00055',
            assetCode: 'AST-FUR-2023-0055',
            name: 'Kursi Ergonomis Direktur',
            category: catFur,
            location: 'Cabang Semarang',
            pic: 'Siti Rahma',
            status: AssetStatus.inMutation,
            condition: 'Sangat Baik',
            acquisitionYear: 2023,
          ),
          applicantName: 'Rina',
          currentLocation: 'Kantor Pusat',
          targetLocation: 'Cabang Semarang',
          currentPic: 'Dewi Lestari',
          targetPic: 'Siti Rahma',
          reason: 'Penyesuaian posisi manager baru Cabang Semarang.',
          documentName: 'Nota_Tugas.pdf',
          status: MutationStatus.pendingConfirmation,
          verifiedBy: 'Operator Aset',
          verifiedAt: DateTime.now().subtract(const Duration(days: 3)),
          approvedBy: 'H. M. Yusuf (Kabag Aset)',
          approvedAt: DateTime.now().subtract(const Duration(days: 2)),
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
      ]);
    }
  }

  /// Reset state untuk testing.
  static void resetForTesting() {
    _mutations.clear();
    _ticketCounter = 0;
    _initialized = false;
  }

  @override
  Future<Result<Mutation>> submitMutation(SubmitMutationParams params) async {
    // Simulate network delay.
    await Future.delayed(const Duration(milliseconds: 300));

    // ================================================================
    // DATA ASET DIMASUKKAN MANUAL OLEH PEMOHON
    // ================================================================
    //
    // Tidak ada pencarian ke AssetRepository/database di tahap ini.
    //
    // Pemohon boleh mengajukan mutasi untuk aset yang belum ada
    // di database aset aplikasi. Data yang dimasukkan pada form
    // menjadi dasar data aset pada pengajuan mutasi.
    const manualCategory = AssetCategory(
      id: 'cat_manual',
      code: 'OTH',
      name: 'Lainnya',
    );

    final assetId = params.assetId.trim();
    final assetName = params.assetName.trim();
    final sourceLocation = params.sourceLocation.trim();
    final targetLocation = params.targetLocation.trim();
    final targetPic = params.targetPic.trim();
    final reason = params.reason.trim();

    // Validasi dasar di repository sebagai lapisan pengaman tambahan.
    if (assetId.isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Kode / Nomor Aset / Serial wajib diisi.'),
      );
    }

    if (assetName.isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Nama aset wajib diisi.'),
      );
    }

    if (sourceLocation.isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Lokasi aset saat ini wajib diisi.'),
      );
    }

    if (targetLocation.isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Lokasi tujuan wajib diisi.'),
      );
    }

    if (targetPic.isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Penanggung jawab baru wajib diisi.'),
      );
    }

    if (reason.isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Alasan mutasi wajib diisi.'),
      );
    }

    // Membentuk representasi Asset berdasarkan data manual Pemohon.
    // Ini BUKAN pencarian aset pada database.
    final asset = Asset(
      id: assetId,
      assetCode: assetId,
      name: assetName,
      category: manualCategory,
      location: sourceLocation,
      pic: '-',
      status: AssetStatus.available,
      condition: 'Baik',
      acquisitionYear: DateTime.now().year,
    );

    // Generate ticket number: KATEGORI_CODE-TAHUN-NOURUT.
    _ticketCounter++;

    final year = DateTime.now().year;

    final ticketNumber =
        '${manualCategory.code}-$year-${_ticketCounter.toString().padLeft(5, '0')}';

    final mutationId = 'mut_${DateTime.now().millisecondsSinceEpoch}';

    // Membuat pengajuan mutasi.
    final mutation = Mutation(
      id: mutationId,
      ticketNumber: ticketNumber,
      asset: asset,
      applicantName: 'Pemohon',
      currentLocation: sourceLocation,
      targetLocation: targetLocation,
      currentPic: '-',
      targetPic: targetPic,
      reason: reason,
      documentName: params.documentName,
      status: MutationStatus.submitted,
      createdAt: DateTime.now(),
    );

    _mutations.add(mutation);

    return Result.success(mutation);
  }

  @override
  Future<Result<Mutation>> updateMutation({
    required String mutationId,
    required String targetLocation,
    required String targetPic,
    required String reason,
    String? documentName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _mutations.indexWhere((m) => m.id == mutationId);

    if (index == -1) {
      return const Result.failure(
        NotFoundFailure(message: 'Pengajuan mutasi tidak ditemukan.'),
      );
    }

    final current = _mutations[index];

    if (current.status != MutationStatus.returned) {
      return const Result.failure(
        ConflictFailure(
          message: 'Pengajuan ini tidak dapat diedit karena bukan berstatus "Dikembalikan ke Pemohon".',
        ),
      );
    }

    if (targetLocation.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Lokasi tujuan wajib dipilih.'),
      );
    }

    if (targetPic.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Penanggung jawab baru wajib dipilih.'),
      );
    }

    if (reason.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Alasan mutasi wajib diisi.'),
      );
    }

    // Edit mengembalikan pengajuan ke antrean verifikasi Operator.
    // status -> submitted, sesuai ROLE-FLOW.md §3.
    //
    // CATATAN:
    // Mutation.copyWith saat ini menggunakan pola `x ?? this.x`,
    // sehingga field nullable seperti returnReason tidak bisa
    // dikosongkan lewat copyWith. returnReason lama akan tetap
    // tersimpan sebagai jejak riwayat pengembalian sebelumnya.
    final updated = current.copyWith(
      targetLocation: targetLocation,
      targetPic: targetPic,
      reason: reason,
      documentName: documentName,
      status: MutationStatus.submitted,
    );

    _mutations[index] = updated;

    return Result.success(updated);
  }

  @override
  Future<Result<List<Mutation>>> getMutationsByUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    return Result.success(List.unmodifiable(_mutations.reversed.toList()));
  }

  @override
  Future<Result<Mutation>> getMutationById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));

    try {
      final mutation = _mutations.firstWhere((m) => m.id == id);

      return Result.success(mutation);
    } catch (_) {
      return const Result.failure(
        NotFoundFailure(message: 'Pengajuan mutasi tidak ditemukan.'),
      );
    }
  }

  @override
  Future<Result<List<Mutation>>> getAllMutations() async {
    await Future.delayed(const Duration(milliseconds: 200));

    return Result.success(List.unmodifiable(_mutations.reversed.toList()));
  }

  @override
  Future<Result<Mutation>> verifyMutation({
    required String mutationId,
    required String operatorName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _mutations.indexWhere((m) => m.id == mutationId);

    if (index == -1) {
      return const Result.failure(
        NotFoundFailure(message: 'Pengajuan mutasi tidak ditemukan.'),
      );
    }

    final current = _mutations[index];

    final updated = current.copyWith(
      status: MutationStatus.waitingKabagApproval,
      verifiedAt: DateTime.now(),
      verifiedBy: operatorName,
    );

    _mutations[index] = updated;

    return Result.success(updated);
  }

  @override
  Future<Result<Mutation>> returnMutation({
    required String mutationId,
    required String reason,
    required String operatorName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _mutations.indexWhere((m) => m.id == mutationId);

    if (index == -1) {
      return const Result.failure(
        NotFoundFailure(message: 'Pengajuan mutasi tidak ditemukan.'),
      );
    }

    final current = _mutations[index];

    final updated = current.copyWith(
      status: MutationStatus.returned,
      returnReason: reason,
      verifiedAt: DateTime.now(),
      verifiedBy: operatorName,
    );

    _mutations[index] = updated;

    return Result.success(updated);
  }

  @override
  Future<Result<Mutation>> approveMutationKabag({
    required String mutationId,
    required String kabagName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _mutations.indexWhere((m) => m.id == mutationId);

    if (index == -1) {
      return const Result.failure(
        NotFoundFailure(message: 'Pengajuan mutasi tidak ditemukan.'),
      );
    }

    final current = _mutations[index];

    final updated = current.copyWith(
      status: MutationStatus.approved,
      approvedAt: DateTime.now(),
      approvedBy: kabagName,
    );

    _mutations[index] = updated;

    return Result.success(updated);
  }

  @override
  Future<Result<Mutation>> rejectMutationKabag({
    required String mutationId,
    required String reason,
    required String kabagName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _mutations.indexWhere((m) => m.id == mutationId);

    if (index == -1) {
      return const Result.failure(
        NotFoundFailure(message: 'Pengajuan mutasi tidak ditemukan.'),
      );
    }

    final current = _mutations[index];

    final updated = current.copyWith(
      status: MutationStatus.rejected,
      rejectionReason: reason,
      rejectedAt: DateTime.now(),
      rejectedBy: kabagName,
    );

    _mutations[index] = updated;

    return Result.success(updated);
  }

  @override
  Future<Result<Mutation>> approveMutationKadiv({
    required String mutationId,
    required String kadivName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _mutations.indexWhere((m) => m.id == mutationId);

    if (index == -1) {
      return const Result.failure(
        NotFoundFailure(message: 'Pengajuan mutasi tidak ditemukan.'),
      );
    }

    final current = _mutations[index];

    final updated = current.copyWith(
      status: MutationStatus.approved,
      kadivApprovedAt: DateTime.now(),
      kadivApprovedBy: kadivName,
    );

    _mutations[index] = updated;

    return Result.success(updated);
  }

  @override
  Future<Result<Mutation>> rejectMutationKadiv({
    required String mutationId,
    required String reason,
    required String kadivName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _mutations.indexWhere((m) => m.id == mutationId);

    if (index == -1) {
      return const Result.failure(
        NotFoundFailure(message: 'Pengajuan mutasi tidak ditemukan.'),
      );
    }

    final current = _mutations[index];

    final updated = current.copyWith(
      status: MutationStatus.rejected,
      rejectionReason: reason,
      rejectedAt: DateTime.now(),
      rejectedBy: kadivName,
      kadivRejectedAt: DateTime.now(),
      kadivRejectedBy: kadivName,
      kadivRejectionReason: reason,
    );

    _mutations[index] = updated;

    return Result.success(updated);
  }

  @override
  Future<Result<Mutation>> confirmMutation({
    required String mutationId,
    required String confirmedBy,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _mutations.indexWhere((m) => m.id == mutationId);

    if (index == -1) {
      return const Result.failure(
        NotFoundFailure(message: 'Pengajuan mutasi tidak ditemukan.'),
      );
    }

    final current = _mutations[index];

    final updated = current.copyWith(status: MutationStatus.completed);

    _mutations[index] = updated;

    return Result.success(updated);
  }
}
