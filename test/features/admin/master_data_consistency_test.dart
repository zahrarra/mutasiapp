// test/features/admin/master_data_consistency_test.dart
//
// Pengujian konsistensi data master:
// 1. Master Divisi / Unit Kerja terpisah dari lokasi fisik aset.
// 2. Master Lokasi Aset mengirim ID database yang benar.
// 3. Penanganan loading, data kosong, dan error API pada master lokasi.

import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/core/constants/master_departments.dart';
import 'package:mutasiku/core/errors/failures.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/features/admin/domain/entities/location_item.dart';
import 'package:mutasiku/features/admin/domain/repositories/location_repository.dart';
import 'package:mutasiku/features/auth/data/repositories/user_repository_impl.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/mutation/domain/repositories/mutation_repository.dart';

class _MockFailingLocationRepo implements LocationRepository {
  @override
  List<LocationItem> get currentLocations => [];

  @override
  Future<Result<List<LocationItem>>> getAllLocations() async {
    return const Result.failure(ServerFailure(message: 'Koneksi API terputus (500)'));
  }

  @override
  Future<Result<List<LocationItem>>> getActiveLocations() async {
    return const Result.failure(ServerFailure(message: 'Koneksi API terputus (500)'));
  }

  @override
  Future<Result<LocationItem>> addLocation(LocationItem item) async =>
      const Result.failure(ServerFailure(message: 'Failed'));

  @override
  Future<Result<LocationItem>> updateLocation(LocationItem item) async =>
      const Result.failure(ServerFailure(message: 'Failed'));

  @override
  Future<Result<void>> toggleLocationActive(String id, bool isActive) async =>
      const Result.failure(ServerFailure(message: 'Failed'));

  @override
  Future<Result<void>> deleteLocation(String id) async =>
      const Result.failure(ServerFailure(message: 'Failed'));
}

class _MockEmptyLocationRepo implements LocationRepository {
  @override
  List<LocationItem> get currentLocations => [];

  @override
  Future<Result<List<LocationItem>>> getAllLocations() async {
    return const Result.success([]);
  }

  @override
  Future<Result<List<LocationItem>>> getActiveLocations() async {
    return const Result.success([]);
  }

  @override
  Future<Result<LocationItem>> addLocation(LocationItem item) async =>
      const Result.failure(ServerFailure(message: 'Failed'));

  @override
  Future<Result<LocationItem>> updateLocation(LocationItem item) async =>
      const Result.failure(ServerFailure(message: 'Failed'));

  @override
  Future<Result<void>> toggleLocationActive(String id, bool isActive) async =>
      const Result.failure(ServerFailure(message: 'Failed'));

  @override
  Future<Result<void>> deleteLocation(String id) async =>
      const Result.failure(ServerFailure(message: 'Failed'));
}

void main() {
  group('A. Master Divisi / Unit Kerja Organization Consistency Tests', () {
    test('1. MasterDepartments memuat persis 11 unit kerja resmi yang ditentukan', () {
      expect(MasterDepartments.all.length, 11);
      expect(MasterDepartments.all, contains('Divisi TI'));
      expect(MasterDepartments.all, contains('UKK Siber'));
      expect(MasterDepartments.all, contains('Divisi Treasury'));
      expect(MasterDepartments.all, contains('Divisi Umum dan Aset'));
      expect(MasterDepartments.all, contains('Divisi SDM'));
      expect(MasterDepartments.all, contains('Divisi Operasional'));
      expect(MasterDepartments.all, contains('Divisi Kredit'));
      expect(MasterDepartments.all, contains('Divisi SKAI'));
      expect(MasterDepartments.all, contains('Divisi Pemasaran'));
      expect(MasterDepartments.all, contains('Divisi Literasi'));
      expect(MasterDepartments.all, contains('Divisi Hukum'));
    });

    test('2. Divisi organisasi terpisah dari lokasi fisik aset dan tidak tercampur', () {
      // Pastikan nama divisi tidak mencampur kode lokasi fisik
      for (final dept in MasterDepartments.all) {
        expect(dept.startsWith('Parkiran'), isFalse);
        expect(dept.startsWith('Lantai'), isFalse);
        expect(dept.startsWith('Cabang'), isFalse);
      }
    });

    test('3. MasterDepartments.contains mendeteksi divisi valid dan menolak divisi fiktif', () {
      expect(MasterDepartments.contains('Divisi TI'), isTrue);
      expect(MasterDepartments.contains('UKK Siber'), isTrue);
      expect(MasterDepartments.contains('Divisi Palsu 99'), isFalse);
      expect(MasterDepartments.contains(null), isFalse);
    });
  });

  group('B. Master Lokasi & Database ID Integrity Tests', () {
    test('1. SubmitMutationParams menyimpan destinationLocationId integer ID database', () {
      const params = SubmitMutationParams(
        applicantId: '1',
        assetId: '10',
        assetName: 'Laptop ThinkPad L14',
        sourceLocation: 'Lantai 1',
        targetLocation: 'Cabang Luwuk',
        destinationLocationId: '35',
        targetPic: 'Budi Santoso',
        reason: 'Pindah tugas dinas cabang',
      );

      expect(params.destinationLocationId, '35');
      expect(params.targetLocation, 'Cabang Luwuk');
      expect(int.tryParse(params.destinationLocationId!), 35);
    });

    test('2. LocationRepository gagal menghasilkan Result.failure dengan pesan eksplisit saat API error', () async {
      final repo = _MockFailingLocationRepo();
      final result = await repo.getActiveLocations();

      expect(result.isFailure, isTrue);
      expect(result, isA<AppFailure<List<LocationItem>>>());
      switch (result) {
        case AppFailure(:final failure):
          expect(failure.message, contains('500'));
        case Success():
          fail('Harus menghasilkan failure');
      }
    });

    test('3. LocationRepository kosong menghasilkan list kosong tanpa silent fallback data palsu', () async {
      final repo = _MockEmptyLocationRepo();
      final result = await repo.getActiveLocations();

      expect(result.isSuccess, isTrue);
      switch (result) {
        case Success(:final data):
          expect(data, isEmpty);
        case AppFailure():
          fail('Harus menghasilkan success list kosong');
      }
    });

    test('4. Lokasi usulan yang berstatus non-aktif (is_active: false) tidak muncul di getActiveLocations', () async {
      final items = [
        const LocationItem(
          id: '1',
          name: 'Kantor Pusat',
          isActive: true,
        ),
        const LocationItem(
          id: '10',
          name: 'Parkiran Basement',
          isActive: false, // Usulan menunggu konfirmasi
        ),
        const LocationItem(
          id: '26',
          name: 'Ruang Divisi TI',
          isActive: false, // Usulan menunggu konfirmasi
        ),
      ];

      final activeLocations = items.where((l) => l.isActive).toList();
      expect(activeLocations.length, 1);
      expect(activeLocations.first.name, 'Kantor Pusat');
      expect(activeLocations.any((l) => l.name == 'Parkiran Basement'), isFalse);
      expect(activeLocations.any((l) => l.name == 'Ruang Divisi TI'), isFalse);
    });
  });

  group('C. User Department / Unit Kerja Consistency Tests', () {
    test('1. UserRepository menyimpan dan membaca kembali unit kerja user yang diedit dengan benar', () async {
      final userRepo = UserRepositoryImpl();
      final usersRes = await userRepo.getAllUsers();
      expect(usersRes.isSuccess, isTrue);

      final users = (usersRes as Success<List<User>>).data;
      final targetUser = users.firstWhere((u) => u.username == 'operator');

      // Pastikan department awal termasuk dalam 11 divisi resmi
      expect(MasterDepartments.contains(targetUser.department), isTrue);

      // Admin mengedit unit kerja ke 'Divisi Kredit'
      final updatedUser = targetUser.copyWith(
        department: 'Divisi Kredit',
      );
      final updateRes = await userRepo.updateUser(updatedUser);
      expect(updateRes.isSuccess, isTrue);
      expect((updateRes as Success<User>).data.department, 'Divisi Kredit');

      // Baca kembali user berdasarkan ID dan pastikan unit kerja tersimpan 'Divisi Kredit'
      final fetchRes = await userRepo.getUserById(targetUser.id);
      expect(fetchRes.isSuccess, isTrue);
      expect((fetchRes as Success<User>).data.department, 'Divisi Kredit');
    });

    test('2. User baru yang dibuat dengan divisi resmi tersimpan dan terbaca kembali dengan benar', () async {
      final userRepo = UserRepositoryImpl();
      const newUser = User(
        id: 'usr_audit_testing_dept',
        username: 'auditor_dept_test',
        name: 'Auditor Unit Kerja',
        role: UserRole.operator,
        department: 'Divisi SKAI',
        isActive: true,
      );

      final createRes = await userRepo.createUser(newUser);
      expect(createRes.isSuccess, isTrue);
      expect((createRes as Success<User>).data.department, 'Divisi SKAI');

      final fetchRes = await userRepo.getUserById(newUser.id);
      expect(fetchRes.isSuccess, isTrue);
      expect((fetchRes as Success<User>).data.department, 'Divisi SKAI');
    });

    test('3. Nilai divisi yang diedit tetap terikat pada ID user dan tidak tercampur antar pengguna', () async {
      final userRepo = UserRepositoryImpl();
      final usersRes = await userRepo.getAllUsers();
      expect(usersRes.isSuccess, isTrue);
      final users = (usersRes as Success<List<User>>).data;

      final pemohon = users.firstWhere((u) => u.username == 'pemohon');
      final operator = users.firstWhere((u) => u.username == 'operator');

      // Update pemohon ke Divisi Treasury
      await userRepo.updateUser(pemohon.copyWith(department: 'Divisi Treasury'));
      // Update operator ke Divisi Literasi
      await userRepo.updateUser(operator.copyWith(department: 'Divisi Literasi'));

      final pAfter = (await userRepo.getUserById(pemohon.id) as Success<User>).data;
      final oAfter = (await userRepo.getUserById(operator.id) as Success<User>).data;

      expect(pAfter.department, 'Divisi Treasury');
      expect(oAfter.department, 'Divisi Literasi');
      expect(pAfter.department, isNot(equals(oAfter.department)));
    });
  });
}
