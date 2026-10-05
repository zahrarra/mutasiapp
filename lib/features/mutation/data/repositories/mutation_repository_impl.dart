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
// Setelah pengajuan disetujui Pemimpin Divisi dan dikonfirmasi Pemohon,
// barulah data aset otomatis diperbarui pada database aset.

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

  /// Generator nomor tiket yang dijamin unik dan tidak pernah bertabrakan
  /// dengan mutasi aktif maupun mutasi berstatus completed di histori.
  static String _generateUniqueTicketNumber(String categoryCode, int year) {
    final existingTickets =
        _mutations.map((m) => m.ticketNumber.toUpperCase()).toSet();

    int maxSeq = _ticketCounter;
    final regex = RegExp(r'(\d{3,5})$');
    for (final ticket in existingTickets) {
      final match = regex.firstMatch(ticket);
      if (match != null) {
        final parsed = int.tryParse(match.group(1)!);
        if (parsed != null && parsed > maxSeq) {
          maxSeq = parsed;
        }
      }
    }

    int nextSeq = maxSeq + 1;
    String candidateTicket;
    do {
      candidateTicket =
          '$categoryCode-$year-${nextSeq.toString().padLeft(5, '0')}';
      if (!existingTickets.contains(candidateTicket.toUpperCase())) {
        break;
      }
      nextSeq++;
    } while (true);

    _ticketCounter = nextSeq;
    return candidateTicket;
  }

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
      // Sudah verifikasi valid -> Menunggu Verifikasi Bagian Aset
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
          applicantId: 'usr_pemohon',
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
          applicantId: 'usr_budi',
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
          applicantId: 'usr_pemohon',
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
          applicantId: 'usr_dewi',
          applicantName: 'Dewi Lestari',
          currentLocation: 'Kantor Pusat',
          targetLocation: 'Cabang Semarang',
          currentPic: 'Dewi Lestari',
          targetPic: 'Siti Rahma',
          reason: 'Pengadaan furnitur ruang manager cabang baru.',
          documentName: 'Nota_Dinas.pdf',
          status: MutationStatus.waitingAssetVerification,
          verifiedBy: 'Operator Aset',
          verifiedAt: DateTime.now().subtract(const Duration(hours: 4)),
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),

        Mutation(
          id: 'mut_004_kadiv',
          ticketNumber: 'FURNITUR-2026-00019',
          asset: asset4,
          applicantId: 'usr_dewi',
          applicantName: 'Dewi Lestari',
          currentLocation: 'Kantor Pusat',
          targetLocation: 'Cabang Medan',
          currentPic: 'Dewi Lestari',
          targetPic: 'Siti Rahma',
          reason: 'Pengadaan antar cabang memerlukan approval Kadiv.',
          documentName: 'Nota_Dinas.pdf',
          status: MutationStatus.waitingAssetVerification,
          requiresKadivApproval: true,
          verifiedBy: 'Operator Aset',
          verifiedAt: DateTime.now().subtract(const Duration(hours: 3)),
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
          applicantId: 'usr_hendra',
          applicantName: 'Hendra Setiawan',
          currentLocation: 'Data Center Pusat',
          targetLocation: 'Data Center Surabaya (DRC)',
          currentPic: 'Hendra Setiawan',
          targetPic: 'Bambang Pratama',
          reason: 'Relokasi server inti data center utama ke Disaster Recovery Center Surabaya sesuai kebijakan kepatuhan OJK.',
          documentName: 'SK_Relokasi_Infrastruktur_TI.pdf',
          status: MutationStatus.waitingKadivApproval,
          requiresKadivApproval: true,
          verifiedBy: 'Operator Aset',
          verifiedAt: DateTime.now().subtract(const Duration(hours: 6)),
          approvedBy: 'H. M. Yusuf (Bagian Aset)',
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
          applicantId: 'usr_pemohon',
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
          approvedBy: 'H. M. Yusuf (Bagian Aset)',
          approvedAt: DateTime.now().subtract(const Duration(days: 2)),
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        ),

        // Seed data mut_007:
        // Menunggu verifikasi keabsahan aset oleh Bagian Aset (waitingAssetVerification)
        Mutation(
          id: 'mut_007',
          ticketNumber: 'ELEKTRONIK-2026-00077',
          asset: const Asset(
            id: 'AST-00077',
            assetCode: 'AST-ELK-2024-0077',
            name: 'Laptop Dell Latitude 5430',
            category: catElk,
            location: 'Kantor Pusat — IT Support',
            pic: 'Rizky Pratama',
            status: AssetStatus.inMutation,
            condition: 'Baik',
            acquisitionYear: 2024,
          ),
          applicantId: 'usr_pemohon',
          applicantName: 'Rina Pemohon',
          currentLocation: 'Kantor Pusat — IT Support',
          targetLocation: 'Cabang Solo — Operasional',
          currentPic: 'Rizky Pratama',
          targetPic: 'Agus Santoso',
          reason: 'Dukungan operasional staf baru di Cabang Solo.',
          documentName: 'Surat_Penugasan_Solo.pdf',
          status: MutationStatus.waitingAssetVerification,
          verifiedBy: 'Operator Aset',
          verifiedAt: DateTime.now().subtract(const Duration(days: 1)),
          approvedBy: 'H. M. Yusuf (Bagian Aset)',
          approvedAt: DateTime.now().subtract(const Duration(hours: 3)),
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
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
    final targetLocation = params.targetLocation.trim();
    final reason = params.reason.trim();

    if (targetLocation.isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Lokasi tujuan wajib diisi.'),
      );
    }

    if (reason.isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Alasan mutasi wajib diisi.'),
      );
    }

    // Aturan PIC Baru PRD V1.1 §6.2:
    // - Jawaban Ya -> PIC baru otomatis Pemohon sendiri.
    // - Jawaban Tidak -> PIC baru dikosongkan dan ditentukan Bagian Aset.
    final String targetPic;
    if (params.isAssetMovingWithApplicant) {
      targetPic = params.targetPic.trim().isNotEmpty
          ? params.targetPic.trim()
          : (params.applicantName?.trim().isNotEmpty == true
              ? params.applicantName!.trim()
              : (params.currentPic?.trim().isNotEmpty == true
                  ? params.currentPic!.trim()
                  : 'Pemohon'));
    } else {
      targetPic = '';
    }

    const manualCategory = AssetCategory(
      id: 'cat_ti',
      code: 'TI',
      name: 'Aset TI',
    );

    String categoryCode = 'TI';
    String sourceLocation = params.sourceLocation.trim();
    String currentPic = params.currentPic?.trim().isNotEmpty == true
        ? params.currentPic!.trim()
        : '-';
    Asset? assetEntity;
    String? finalAssetId;
    String? customSerialNumber = params.customSerialNumber?.trim();

    if (params.isUnregisteredAsset) {
      return const Result.failure(
        ValidationFailure(
          message:
              'Aset yang dimutasi harus merupakan aset terdaftar. Input aset bebas/manual tidak didukung.',
        ),
      );
    }

    final rawAssetId = params.assetId?.trim() ?? '';
    if (rawAssetId.isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'ID Aset terdaftar wajib diisi.'),
      );
    }

    // Cegah duplicate active mutation untuk aset yang sama (PRD V1.1 §8 Rule 4).
    final hasActiveMutation = _mutations.any((m) {
      final matchesAsset = (m.assetId != null && m.assetId == rawAssetId) ||
          (m.asset.id.isNotEmpty && m.asset.id == rawAssetId) ||
          (m.asset.assetCode.isNotEmpty && m.asset.assetCode == rawAssetId);
      return matchesAsset &&
          m.status != MutationStatus.completed &&
          m.status != MutationStatus.rejected;
    });

    if (hasActiveMutation) {
      return const Result.failure(
        ValidationFailure(
          message:
              'Aset sedang memiliki pengajuan mutasi aktif yang belum selesai.',
        ),
      );
    }

    // Ambil asset dari AssetRepository
    final assetResult = await assetRepository.getAssetById(rawAssetId);
    if (assetResult is Success<Asset>) {
      assetEntity = assetResult.data;
    } else {
      final assetListResult = await assetRepository.getAssets(query: rawAssetId);
      if (assetListResult is Success<List<Asset>> && assetListResult.data.isNotEmpty) {
        assetEntity = assetListResult.data.firstWhere(
          (a) => a.id == rawAssetId || a.assetCode == rawAssetId,
          orElse: () => assetListResult.data.first,
        );
      } else {
        assetEntity = Asset(
          id: rawAssetId,
          assetCode: rawAssetId,
          name: params.assetName.trim().isNotEmpty ? params.assetName.trim() : 'Aset $rawAssetId',
          category: manualCategory,
          location: sourceLocation.isNotEmpty ? sourceLocation : 'Kantor Pusat',
          pic: currentPic,
          status: AssetStatus.inMutation,
          condition: 'Baik',
          acquisitionYear: DateTime.now().year,
          hasActiveMutation: true,
          serialNumber: customSerialNumber,
        );
      }
    }

    finalAssetId = assetEntity.id;
    categoryCode = assetEntity.category.code.isNotEmpty
        ? assetEntity.category.code
        : 'TI';

    if (sourceLocation.isEmpty) {
      sourceLocation = assetEntity.location;
    }
    if (currentPic == '-' && assetEntity.pic.isNotEmpty) {
      currentPic = assetEntity.pic;
    }

    // Kunci aset saat mutasi dibuat (PRD V1.1 §8 Rule 5)
    await assetRepository.updateAsset(
      assetEntity.copyWith(
        hasActiveMutation: true,
        status: AssetStatus.inMutation,
      ),
    );

    final year = DateTime.now().year;
    final ticketNumber = _generateUniqueTicketNumber(categoryCode, year);
    final mutationId = 'mut_${DateTime.now().millisecondsSinceEpoch}';

    final mutation = Mutation(
      id: mutationId,
      ticketNumber: ticketNumber,
      assetId: finalAssetId,
      asset: assetEntity,
      isUnregisteredAsset: false,
      applicantId: params.applicantId,
      applicantName: params.applicantName ?? 'Pemohon',
      currentLocation: sourceLocation,
      targetLocation: targetLocation,
      currentPic: currentPic,
      targetPic: targetPic,
      isAssetMovingWithApplicant: params.isAssetMovingWithApplicant,
      reason: reason,
      documentName: params.documentName,
      documentPath: params.documentPath,
      documentBytes: params.documentBytes,
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

    final effectiveTargetPic = current.isAssetMovingWithApplicant
        ? (targetPic.trim().isNotEmpty
            ? targetPic.trim()
            : (current.targetPic.trim().isNotEmpty
                ? current.targetPic.trim()
                : current.applicantName))
        : (targetPic.trim().isNotEmpty ? targetPic.trim() : current.targetPic);

    if (current.isAssetMovingWithApplicant && effectiveTargetPic.trim().isEmpty) {
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
      targetPic: effectiveTargetPic,
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

    final userMutations = _mutations.where((m) {
      if (m.applicantId == userId) return true;
      // Mendukung alias ID pemohon standar (usr_pemohon, usr_101, user_pemohon)
      final isUserStdPemohon = (userId == 'usr_pemohon' || userId == 'usr_101' || userId == 'user_pemohon');
      final isMutationStdPemohon = (m.applicantId == 'usr_pemohon' || m.applicantId == 'usr_101' || m.applicantId == 'user_pemohon');
      if (isUserStdPemohon && isMutationStdPemohon) {
        return true;
      }
      return false;
    }).toList();

    return Result.success(List.unmodifiable(userMutations.reversed.toList()));
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
    await Future.delayed(const Duration(milliseconds: 150));
    return Result.success(List.unmodifiable(_mutations.reversed.toList()));
  }

  // ─── PRD V1.1 Workflow Operations ──────────────────────────────────────────

  @override
  Future<Result<Mutation>> operatorForward({
    required String mutationId,
    required String operatorName,
    bool? requiresKadivApproval,
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
      status: MutationStatus.waitingAssetVerification,
      requiresKadivApproval: requiresKadivApproval ?? current.requiresKadivApproval,
      verifiedAt: DateTime.now(),
      verifiedBy: operatorName,
    );

    _mutations[index] = updated;
    return Result.success(updated);
  }

  @override
  Future<Result<Mutation>> operatorReturn({
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
  Future<Result<Mutation>> assetSectionForward({
    required String mutationId,
    required String verifierName,
    String? newPic,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _mutations.indexWhere((m) => m.id == mutationId);
    if (index == -1) {
      return const Result.failure(
        NotFoundFailure(message: 'Pengajuan mutasi tidak ditemukan.'),
      );
    }

    final current = _mutations[index];
    final effectivePic = (newPic != null && newPic.trim().isNotEmpty)
        ? newPic.trim()
        : current.targetPic.trim();

    if (effectivePic.isEmpty) {
      return const Result.failure(
        ValidationFailure(
          message:
              'PIC baru wajib ditentukan oleh Bagian Aset sebelum meneruskan pengajuan.',
        ),
      );
    }

    final updated = current.copyWith(
      targetPic: effectivePic,
      status: MutationStatus.waitingDivisionHeadApproval,
      requiresKadivApproval: true,
      assetVerifiedAt: DateTime.now(),
      assetVerifiedBy: verifierName,
      approvedAt: DateTime.now(),
      approvedBy: verifierName,
    );

    _mutations[index] = updated;
    return Result.success(updated);
  }

  @override
  Future<Result<Mutation>> assetSectionReturn({
    required String mutationId,
    required String reason,
    required String verifierName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (reason.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Alasan pengembalian wajib diisi.'),
      );
    }

    final index = _mutations.indexWhere((m) => m.id == mutationId);
    if (index == -1) {
      return const Result.failure(
        NotFoundFailure(message: 'Pengajuan mutasi tidak ditemukan.'),
      );
    }

    final current = _mutations[index];
    final updated = current.copyWith(
      status: MutationStatus.returned,
      assetReturnReason: reason,
      returnReason: reason,
      assetVerifiedAt: DateTime.now(),
      assetVerifiedBy: verifierName,
      rejectedAt: DateTime.now(),
      rejectedBy: verifierName,
    );

    _mutations[index] = updated;
    return Result.success(updated);
  }

  @override
  Future<Result<Mutation>> divisionApprove({
    required String mutationId,
    required String divisionHeadName,
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
      status: MutationStatus.waitingConfirmation,
      kadivApprovedAt: DateTime.now(),
      kadivApprovedBy: divisionHeadName,
      approvedAt: DateTime.now(),
      approvedBy: divisionHeadName,
    );

    _mutations[index] = updated;
    return Result.success(updated);
  }

  @override
  Future<Result<Mutation>> divisionReject({
    required String mutationId,
    required String reason,
    required String divisionHeadName,
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
      rejectedBy: divisionHeadName,
      kadivRejectedAt: DateTime.now(),
      kadivRejectedBy: divisionHeadName,
      kadivRejectionReason: reason,
    );

    _mutations[index] = updated;

    // Buka lock pada master aset
    if (current.assetId != null && current.assetId!.isNotEmpty) {
      final assetRes = await assetRepository.getAssetById(current.assetId!);
      if (assetRes is Success<Asset>) {
        final a = assetRes.data;
        await assetRepository.updateAsset(
          a.copyWith(hasActiveMutation: false, status: AssetStatus.available),
        );
      }
    }

    return Result.success(updated);
  }

  @override
  Future<Result<Mutation>> confirmMutationResult({
    required String mutationId,
    required String confirmedBy,
    required bool isSesuai,
    String? reason,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _mutations.indexWhere((m) => m.id == mutationId);
    if (index == -1) {
      return const Result.failure(
        NotFoundFailure(message: 'Pengajuan mutasi tidak ditemukan.'),
      );
    }

    final current = _mutations[index];

    if (!current.status.isWaitingConfirmation) {
      return const Result.failure(
        ValidationFailure(
          message:
              'Konfirmasi hanya dapat dilakukan pada mutasi berstatus Menunggu Konfirmasi.',
        ),
      );
    }

    if (!isSesuai) {
      if (reason == null || reason.trim().isEmpty) {
        return const Result.failure(
          ValidationFailure(message: 'Alasan ketidaksesuaian wajib diisi.'),
        );
      }

      final updated = current.copyWith(
        status: MutationStatus.waitingAssetVerification,
        confirmationReason: reason.trim(),
      );

      _mutations[index] = updated;
      return Result.success(updated);
    }

    // Pemohon memilih 'Sesuai':
    // 1. Server otomatis update lokasi & PIC aset master (PRD V1.1 §6.6)
    Asset updatedAsset = current.asset;
    if (current.assetId != null && current.assetId!.isNotEmpty) {
      final assetUpdateResult = await assetRepository.updateAssetLocationAndPic(
        assetId: current.assetId!,
        newLocation: current.targetLocation,
        newPic: current.targetPic,
        ticketNumber: current.ticketNumber,
        updatedBy: confirmedBy,
      );

      if (assetUpdateResult is Success<Asset>) {
        updatedAsset = assetUpdateResult.data;
      } else {
        updatedAsset = current.asset.copyWith(
          location: current.targetLocation,
          pic: current.targetPic,
          hasActiveMutation: false,
          status: AssetStatus.available,
        );
      }
    } else {
      updatedAsset = current.asset.copyWith(
        location: current.targetLocation,
        pic: current.targetPic,
        hasActiveMutation: false,
        status: AssetStatus.available,
      );
    }

    // 2. Status berubah menjadi Selesai & simpan riwayat mutasi
    final updated = current.copyWith(
      asset: updatedAsset,
      status: MutationStatus.completed,
    );

    _mutations[index] = updated;
    return Result.success(updated);
  }

  // ─── Legacy Compatibility Methods ──────────────────────────────────────────

  @override
  Future<Result<Mutation>> verifyMutation({
    required String mutationId,
    required String operatorName,
    bool requiresKadivApproval = false,
  }) async {
    return operatorForward(
      mutationId: mutationId,
      operatorName: operatorName,
      requiresKadivApproval: requiresKadivApproval,
    );
  }

  @override
  Future<Result<Mutation>> returnMutation({
    required String mutationId,
    required String reason,
    required String operatorName,
  }) async {
    return operatorReturn(
      mutationId: mutationId,
      reason: reason,
      operatorName: operatorName,
    );
  }

  @override
  Future<Result<Mutation>> approveMutationKadiv({
    required String mutationId,
    required String kadivName,
  }) async {
    return divisionApprove(
      mutationId: mutationId,
      divisionHeadName: kadivName,
    );
  }

  @override
  Future<Result<Mutation>> rejectMutationKadiv({
    required String mutationId,
    required String reason,
    required String kadivName,
  }) async {
    return divisionReject(
      mutationId: mutationId,
      reason: reason,
      divisionHeadName: kadivName,
    );
  }

  @override
  Future<Result<Mutation>> confirmMutation({
    required String mutationId,
    required String confirmedBy,
  }) async {
    return confirmMutationResult(
      mutationId: mutationId,
      confirmedBy: confirmedBy,
      isSesuai: true,
    );
  }
}
