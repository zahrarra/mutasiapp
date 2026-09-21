// lib/features/mutation/presentation/providers/mutation_form_provider.dart
//
// State management untuk form pengajuan mutasi.
// Sumber: SCREEN-SPEC.md REQ-004 (Form Mutasi), REQ-005 (Review).

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      targetPic.trim().isNotEmpty &&
      reason.trim().isNotEmpty;

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

    if (state.targetPic.trim().isEmpty) {
      errors['targetPic'] = 'Penanggung jawab baru wajib diisi.';
    }

    if (state.reason.trim().isEmpty) {
      errors['reason'] = 'Alasan mutasi wajib diisi.';
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

// ─── Mock Data untuk Dropdown ────────────────────────────────────────────────

/// Daftar lokasi mock (production: dari API/master data).
final availableLocationsProvider = Provider<List<String>>((ref) {
  return [
    'Lantai 1 — Lobby & Reception',
    'Lantai 2 — Ruang Keuangan',
    'Lantai 3 — Ruang IT Developer',
    'Lantai 4 — Ruang Kadiv Aset',
    'Lantai Server — Server Room B',
    'Gedung A — Parkir Operasional',
    'Cabang Surabaya',
    'Cabang Bandung',
    'Cabang Semarang',
  ];
});

/// Daftar PIC mock (production: dari API/master data).
final availablePicsProvider = Provider<List<String>>((ref) {
  return [
    'Budi Santoso (IT Dept)',
    'Siti Aminah (Finance)',
    'Drs. Ahmad Dahlan (Kadiv)',
    'Network Support Team',
    'Driver Operasional General Affair',
    'Staff Aset — Rizky',
    'Rina (HR Dept)',
    'Procurement Team',
  ];
});
