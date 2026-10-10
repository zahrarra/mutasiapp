// lib/features/mutation/presentation/providers/mutation_form_provider.dart
//
// State management untuk form pengajuan mutasi.
// Sumber: SCREEN-SPEC.md REQ-004 (Form Mutasi), REQ-005 (Review).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../admin/data/repositories/location_repository_impl.dart';
import '../../../admin/domain/entities/location_item.dart';
import '../../../admin/domain/repositories/location_repository.dart';

/// State form pengajuan mutasi.
class MutationFormState {
  /// Nama aset yang akan dimutasi.
  final String assetName;

  /// Kode / nomor aset.
  final String assetId;

  /// Lokasi asal aset.
  final String sourceLocation;

  /// Lokasi tujuan mutasi.
  final String targetLocation;

  /// PIC / penanggung jawab baru.
  final String targetPic;

  /// Alasan / justifikasi mutasi.
  final String reason;

  /// Nama dokumen pendukung (opsional).
  final String? documentName;

  /// Error per field untuk validasi.
  final Map<String, String?> fieldErrors;

  const MutationFormState({
    this.assetName = '',
    this.assetId = '',
    this.sourceLocation = '',
    this.targetLocation = '',
    this.targetPic = '',
    this.reason = '',
    this.documentName,
    this.fieldErrors = const {},
  });

  /// Apakah semua field wajib sudah terisi.
  bool get isComplete =>
      assetName.trim().isNotEmpty &&
      assetId.trim().isNotEmpty &&
      sourceLocation.trim().isNotEmpty &&
      targetLocation.trim().isNotEmpty &&
      reason.trim().isNotEmpty &&
      (documentName != null && documentName!.trim().isNotEmpty);

  /// Apakah ada error validasi aktif.
  bool get hasErrors =>
      fieldErrors.values.any((e) => e != null && e.isNotEmpty);

  MutationFormState copyWith({
    String? assetName,
    String? assetId,
    String? sourceLocation,
    String? targetLocation,
    String? targetPic,
    String? reason,
    String? documentName,
    Map<String, String?>? fieldErrors,
    bool clearDocument = false,
  }) {
    return MutationFormState(
      assetName: assetName ?? this.assetName,
      assetId: assetId ?? this.assetId,
      sourceLocation: sourceLocation ?? this.sourceLocation,
      targetLocation: targetLocation ?? this.targetLocation,
      targetPic: targetPic ?? this.targetPic,
      reason: reason ?? this.reason,
      documentName: clearDocument ? null : (documentName ?? this.documentName),
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }
}

/// Notifier untuk mengelola state form mutasi.
class MutationFormNotifier extends StateNotifier<MutationFormState> {
  MutationFormNotifier() : super(const MutationFormState());

  /// Mengubah nama aset.
  void setAssetName(String value) {
    final errors = Map<String, String?>.from(state.fieldErrors);
    errors.remove('assetName');

    state = state.copyWith(assetName: value, fieldErrors: errors);
  }

  /// Mengubah kode / nomor aset.
  void setAssetId(String value) {
    final errors = Map<String, String?>.from(state.fieldErrors);
    errors.remove('assetId');

    state = state.copyWith(assetId: value, fieldErrors: errors);
  }

  /// Mengubah lokasi asal aset.
  void setSourceLocation(String value) {
    final errors = Map<String, String?>.from(state.fieldErrors);
    errors.remove('sourceLocation');

    state = state.copyWith(sourceLocation: value, fieldErrors: errors);
  }

  /// Mengubah lokasi tujuan.
  void setTargetLocation(String value) {
    final errors = Map<String, String?>.from(state.fieldErrors);
    errors.remove('targetLocation');

    state = state.copyWith(targetLocation: value, fieldErrors: errors);
  }

  /// Mengubah PIC / penanggung jawab baru.
  void setTargetPic(String value) {
    final errors = Map<String, String?>.from(state.fieldErrors);
    errors.remove('targetPic');

    state = state.copyWith(targetPic: value, fieldErrors: errors);
  }

  /// Mengubah alasan mutasi.
  void setReason(String value) {
    final errors = Map<String, String?>.from(state.fieldErrors);
    errors.remove('reason');

    state = state.copyWith(reason: value, fieldErrors: errors);
  }

  /// Mengubah dokumen pendukung.
  void setDocumentName(String? value) {
    state = state.copyWith(documentName: value);
  }

  /// Validasi semua field.
  ///
  /// Return `true` jika semua field valid.
  bool validate() {
    final errors = <String, String?>{};

    if (state.assetName.trim().isEmpty) {
      errors['assetName'] = 'Nama aset wajib diisi.';
    }

    if (state.assetId.trim().isEmpty) {
      errors['assetId'] = 'Kode / nomor aset wajib diisi.';
    }

    if (state.sourceLocation.trim().isEmpty) {
      errors['sourceLocation'] = 'Lokasi asal wajib diisi.';
    }

    if (state.targetLocation.trim().isEmpty) {
      errors['targetLocation'] = 'Lokasi tujuan wajib diisi.';
    }

    if (state.reason.trim().isEmpty) {
      errors['reason'] = 'Alasan mutasi wajib diisi.';
    }

    if (state.documentName == null || state.documentName!.trim().isEmpty) {
      errors['documentName'] = 'Surat Keputusan (SK) SDM wajib dilampirkan.';
    }

    state = state.copyWith(fieldErrors: errors);

    return errors.isEmpty;
  }

  /// Reset form ke state awal.
  void reset() {
    state = const MutationFormState();
  }
}

/// Provider untuk [MutationFormNotifier].
final mutationFormProvider =
    StateNotifierProvider<MutationFormNotifier, MutationFormState>((ref) {
      return MutationFormNotifier();
    });

// ─── Master Data Lokasi ──────────────────────────────────────────────────────

/// Provider untuk [LocationRepository].
final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LocationRepositoryImpl(apiClient: apiClient);
});

/// Notifier untuk manajemen master lokasi oleh Admin.
class MasterLocationsNotifier
    extends StateNotifier<AsyncValue<List<LocationItem>>> {
  final LocationRepository _repository;

  MasterLocationsNotifier(this._repository)
    : super(_repository.currentLocations.isNotEmpty
          ? AsyncValue.data(_repository.currentLocations)
          : const AsyncValue.loading()) {
    loadLocations();
  }

  Future<void> loadLocations() async {
    state = const AsyncValue.loading();
    var result = await _repository.getAllLocations();
    if (result is AppFailure<List<LocationItem>>) {
      result = await _repository.getActiveLocations();
    }
    if (result is Success<List<LocationItem>>) {
      state = AsyncValue.data(result.data);
    } else if (result is AppFailure<List<LocationItem>>) {
      state = AsyncValue.error(
        result.failure.message ?? 'Terjadi kesalahan',
        StackTrace.current,
      );
    }
  }

  Future<Result<LocationItem>> addLocation(LocationItem item) async {
    final result = await _repository.addLocation(item);
    if (result is Success<LocationItem>) {
      await loadLocations();
    }
    return result;
  }

  Future<Result<LocationItem>> updateLocation(LocationItem item) async {
    final result = await _repository.updateLocation(item);
    if (result is Success<LocationItem>) {
      await loadLocations();
    }
    return result;
  }

  Future<Result<void>> toggleActive(String id, bool isActive) async {
    final result = await _repository.toggleLocationActive(id, isActive);
    if (result is Success<void>) {
      await loadLocations();
    }
    return result;
  }

  Future<Result<void>> deleteLocation(String id) async {
    final result = await _repository.deleteLocation(id);
    if (result is Success<void>) {
      await loadLocations();
    }
    return result;
  }
}

final masterLocationsProvider =
    StateNotifierProvider<
      MasterLocationsNotifier,
      AsyncValue<List<LocationItem>>
    >((ref) {
      final repo = ref.watch(locationRepositoryProvider);
      return MasterLocationsNotifier(repo);
    });

/// Daftar lokasi aktif untuk formulir pengajuan mutasi dan filter
final availableLocationsProvider = Provider<List<String>>((ref) {
  final locationsAsync = ref.watch(masterLocationsProvider);
  return locationsAsync.maybeWhen(
    data: (list) =>
        list.where((loc) => loc.isActive).map((loc) => loc.name).toList(),
    orElse: () => const [],
  );
});

/// Daftar objek LocationItem aktif lengkap dengan ID database untuk formulir mutasi
final availableActiveLocationItemsProvider = Provider<List<LocationItem>>((ref) {
  final locationsAsync = ref.watch(masterLocationsProvider);
  return locationsAsync.maybeWhen(
    data: (list) => list.where((loc) => loc.isActive).toList(),
    orElse: () => const [],
  );
});


/// Provider daftar PIC pengguna aktif dari database (GET /admin/users).
final availablePicUsersProvider = Provider<AsyncValue<List<User>>>((ref) {
  final usersAsync = ref.watch(masterUsersProvider);
  return usersAsync.whenData((users) {
    return users.where((u) => u.isActive).toList();
  });
});

/// Daftar nama PIC yang bersumber dari master data pengguna aktif di database.
/// Menghapus seluruh nama palsu/mock hardcoded.
/// Jika belum termuat atau gagal, mengembalikan list kosong tanpa fallback nama palsu.
final availablePicsProvider = Provider<List<String>>((ref) {
  final usersAsync = ref.watch(masterUsersProvider);
  return usersAsync.maybeWhen(
    data: (users) {
      final activeUsers = users.where((u) => u.isActive).toList();
      return activeUsers.map((u) {
        final roleLabel = u.role.displayName;
        return '${u.name} ($roleLabel)';
      }).toList();
    },
    orElse: () => const <String>[],
  );
});
