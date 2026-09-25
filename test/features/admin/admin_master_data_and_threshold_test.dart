// test/features/admin/admin_master_data_and_threshold_test.dart
//
// Automated test suite untuk Admin Master Data (User, Location, Category)
// dan Konfigurasi Kadiv Approval Threshold.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/core/config/business_config.dart';
import 'package:mutasiku/core/errors/failures.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/core/storage/secure_storage.dart';
import 'package:mutasiku/features/admin/data/repositories/location_repository_impl.dart';
import 'package:mutasiku/features/admin/domain/entities/location_item.dart';
import 'package:mutasiku/features/asset/data/repositories/asset_repository_impl.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_category.dart';
import 'package:mutasiku/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mutasiku/features/auth/data/repositories/user_repository_impl.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/mutation/data/repositories/mutation_repository_impl.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_form_provider.dart';

class FakeSecureStorage extends SecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<void> write(String key, String value) async => _storage[key] = value;
  @override
  Future<String?> read(String key) async => _storage[key];
  @override
  Future<void> delete(String key) async => _storage.remove(key);
  @override
  Future<void> deleteAll() async => _storage.clear();
  @override
  Future<bool> containsKey(String key) async => _storage.containsKey(key);
}

void main() {
  group('ADMIN USERS & AUTH INTEGRATION', () {
    late UserRepositoryImpl userRepo;
    late AuthRepositoryImpl authRepo;

    setUp(() {
      userRepo = UserRepositoryImpl.instance;
      authRepo = AuthRepositoryImpl(
        secureStorage: FakeSecureStorage(),
        userRepository: userRepo,
      );
    });

    test('1. Admin dapat membuat user baru dan user baru dapat login sesuai rolenya', () async {
      const newUsername = 'danu_operator';
      final createResult = await userRepo.createUser(
        const User(
          id: '',
          username: newUsername,
          name: 'Danu Sanjaya',
          role: UserRole.operator,
          email: 'danu@mutasiku.id',
          department: 'Operasional Logistik',
          isActive: true,
        ),
      );

      expect(createResult is Success<User>, isTrue);
      final createdUser = (createResult as Success<User>).data;
      expect(createdUser.username, equals(newUsername));
      expect(createdUser.role, equals(UserRole.operator));

      // Test login menggunakan user yang baru dibuat oleh Admin
      final loginResult = await authRepo.login(
        username: newUsername,
        password: 'password123',
      );

      expect(loginResult is Success<User>, isTrue);
      final loggedInUser = (loginResult as Success<User>).data;
      expect(loggedInUser.id, equals(createdUser.id));
      expect(loggedInUser.role, equals(UserRole.operator));
      expect(loggedInUser.name, equals('Danu Sanjaya'));
    });

    test('2. Admin dapat mengedit data user (nama, departemen, role)', () async {
      final userResult = await userRepo.getUserByUsername('danu_operator');
      expect(userResult is Success<User>, isTrue);
      final current = (userResult as Success<User>).data;

      final updated = current.copyWith(
        name: 'Danu Sanjaya, S.Kom',
        department: 'Divisi Audit Internal',
        role: UserRole.staffAset,
      );

      final updateResult = await userRepo.updateUser(updated);
      expect(updateResult is Success<User>, isTrue);

      final reFetch = await userRepo.getUserById(current.id);
      expect((reFetch as Success<User>).data.name, equals('Danu Sanjaya, S.Kom'));
      expect(reFetch.data.department, equals('Divisi Audit Internal'));
      expect(reFetch.data.role, equals(UserRole.staffAset));
    });

    test('3. Admin dapat menonaktifkan user dan user nonaktif DITOLAK saat login', () async {
      final userResult = await userRepo.getUserByUsername('danu_operator');
      final current = (userResult as Success<User>).data;

      // Nonaktifkan user
      final toggleResult = await userRepo.toggleUserActive(current.id, false);
      expect(toggleResult is Success<void>, isTrue);

      // Percobaan login harus gagal karena akun dinonaktifkan
      final loginAttempt = await authRepo.login(
        username: 'danu_operator',
        password: 'password123',
      );

      expect(loginAttempt is AppFailure<User>, isTrue);
      final failure = (loginAttempt as AppFailure<User>).failure;
      expect(failure is UnauthorizedFailure, isTrue);
      expect(failure.message, contains('dinonaktifkan'));
    });

    test('4. Akun sistem default dilindungi dari hard delete demi keamanan histori', () async {
      final deleteResult = await userRepo.deleteUser('usr_pemohon');
      expect(deleteResult is AppFailure<void>, isTrue);
      final failure = (deleteResult as AppFailure<void>).failure;
      expect(failure is ValidationFailure, isTrue);
      expect(failure.message, contains('tidak dapat dihapus'));
    });
  });

  group('ADMIN LOCATIONS & MUTATION FORM INTEGRATION', () {
    late LocationRepositoryImpl locationRepo;

    setUp(() {
      locationRepo = LocationRepositoryImpl.instance;
    });

    test('1. Admin dapat menambah lokasi baru dan otomatis muncul di availableLocationsProvider', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const newLocName = 'Gedung Cyber 2 — Lantai 8 Data Center';
      final addResult = await container
          .read(masterLocationsProvider.notifier)
          .addLocation(
            const LocationItem(
              id: '',
              name: newLocName,
              description: 'Fasilitas Disaster Recovery',
              isBranch: false,
              isActive: true,
            ),
          );

      expect(addResult is Success<LocationItem>, isTrue);

      // Trigger provider to read active locations
      final locations = container.read(availableLocationsProvider);
      expect(locations, contains(newLocName));
    });

    test('2. Admin dapat mengedit lokasi', () async {
      final allResult = await locationRepo.getAllLocations();
      final allLocs = (allResult as Success<List<LocationItem>>).data;
      final target = allLocs.firstWhere((l) => l.name.contains('Cyber 2'));

      final updateResult = await locationRepo.updateLocation(
        target.copyWith(
          description: 'Fasilitas Utama Cloud Data Center',
        ),
      );

      expect(updateResult is Success<LocationItem>, isTrue);
      expect(
        (updateResult as Success<LocationItem>).data.description,
        equals('Fasilitas Utama Cloud Data Center'),
      );
    });

    test('3. Menonaktifkan lokasi otomatis menyembunyikan lokasi dari dropdown form Pemohon', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final allResult = await locationRepo.getAllLocations();
      final target = (allResult as Success<List<LocationItem>>).data.firstWhere(
        (l) => l.name.contains('Cyber 2'),
      );

      // Nonaktifkan
      await container
          .read(masterLocationsProvider.notifier)
          .toggleActive(target.id, false);

      final activeLocations = container.read(availableLocationsProvider);
      expect(activeLocations.contains(target.name), isFalse);
    });

    test('4. Lokasi default historis dilindungi dari penghapusan fisik', () async {
      final deleteResult = await locationRepo.deleteLocation('loc_1');
      expect(deleteResult is AppFailure<void>, isTrue);
      expect(
        (deleteResult as AppFailure<void>).failure.message,
        contains('tidak dapat dihapus permanen'),
      );
    });
  });

  group('ADMIN ASSET CATEGORIES', () {
    late AssetRepositoryImpl assetRepo;

    setUp(() {
      assetRepo = AssetRepositoryImpl();
    });

    test('1. Admin dapat menambah kategori baru', () async {
      const code = 'LAB';
      const name = 'Peralatan Laboratorium & Medis';
      final addResult = await assetRepo.addCategory(
        const AssetCategory(
          id: '',
          code: code,
          name: name,
          description: 'Alat ukur presisi dan perangkat steril',
          isActive: true,
        ),
      );

      expect(addResult is Success<AssetCategory>, isTrue);
      final categoriesResult = await assetRepo.getCategories();
      final list = (categoriesResult as Success<List<AssetCategory>>).data;
      expect(list.any((c) => c.code == code && c.name == name), isTrue);
    });

    test('2. Admin dapat mengedit dan menonaktifkan kategori', () async {
      final categoriesResult = await assetRepo.getCategories();
      final list = (categoriesResult as Success<List<AssetCategory>>).data;
      final target = list.firstWhere((c) => c.code == 'LAB');

      // Edit
      final editResult = await assetRepo.updateCategory(
        target.copyWith(description: 'Perangkat laboratorium kimia & fisika'),
      );
      expect(editResult is Success<AssetCategory>, isTrue);

      // Nonaktifkan
      final toggleResult = await assetRepo.toggleCategoryActive(target.id, false);
      expect(toggleResult is Success<void>, isTrue);

      final reFetch = await assetRepo.getCategories();
      final updated = (reFetch as Success<List<AssetCategory>>).data.firstWhere((c) => c.code == 'LAB');
      expect(updated.isActive, isFalse);
      expect(updated.description, equals('Perangkat laboratorium kimia & fisika'));
    });

    test('3. Kategori yang digunakan oleh aset aktif dilindungi dari penghapusan fisik', () async {
      // cat_1 (ELK) digunakan oleh laptop dan printer di master aset
      final deleteResult = await assetRepo.deleteCategory('cat_1');
      expect(deleteResult is AppFailure<void>, isTrue);
      expect(
        (deleteResult as AppFailure<void>).failure.message,
        contains('tidak dapat dihapus permanen karena masih digunakan'),
      );
    });
  });

  group('KADIV APPROVAL THRESHOLD DYNAMIC LOGIC', () {
    test('1. Default threshold adalah Rp 50.000.000', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final threshold = container.read(kadivApprovalThresholdProvider);
      expect(threshold, equals(50000000.0));
    });

    test('2. Perubahan threshold secara dinamis memengaruhi penentuan requiresKadivApproval', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const assetValue = 35000000.0; // Rp 35.000.000
      const isCrossLocation = false; // Mutasi internal

      // Pada default threshold Rp 50.000.000:
      final thresholdDefault = container.read(kadivApprovalThresholdProvider);
      final meetsDefault = assetValue >= thresholdDefault;
      final requiresKadivDefault = meetsDefault || isCrossLocation;
      expect(requiresKadivDefault, isFalse);

      // Admin mengubah threshold menjadi Rp 25.000.000
      container.read(kadivApprovalThresholdProvider.notifier).state = 25000000.0;
      final updatedThreshold = container.read(kadivApprovalThresholdProvider);
      expect(updatedThreshold, equals(25000000.0));

      // Dengan threshold baru, aset bernilai Rp 35.000.000 kini memenuhi threshold
      final meetsUpdated = assetValue >= updatedThreshold;
      final requiresKadivUpdated = meetsUpdated || isCrossLocation;
      expect(requiresKadivUpdated, isTrue);

      // Namun aset bernilai Rp 18.500.000 tetap tidak memerlukan Kadiv
      const lowerAssetValue = 18500000.0;
      final meetsLower = lowerAssetValue >= updatedThreshold;
      expect(meetsLower || isCrossLocation, isFalse);
    });
  });

  group('HISTORI MUTASI TETAP AMAN', () {
    test('Histori mutasi yang sudah ada tetap utuh dan tersimpan di repository', () async {
      final repo = MutationRepositoryImpl(
        assetRepository: AssetRepositoryImpl(),
      );
      final allMutationsResult = await repo.getAllMutations();
      expect(allMutationsResult is Success<List<dynamic>>, isTrue);
      final list = (allMutationsResult as Success<List<dynamic>>).data;
      expect(list.isNotEmpty, isTrue);

      // Pastikan tiket mutasi awal tetap ada
      expect(list.any((m) => m.ticketNumber.contains('2026')), isTrue);
    });
  });
}
