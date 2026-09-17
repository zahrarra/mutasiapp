// lib/features/mutation/presentation/providers/mutation_form_provider.dart
//
// State management untuk form pengajuan mutasi.
// Sumber: SCREEN-SPEC.md REQ-004 (Form Mutasi), REQ-005 (Review).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../asset/domain/entities/asset.dart';

/// State form pengajuan mutasi.
class MutationFormState {
  /// Aset yang dipilih.
  final Asset? selectedAsset;

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
    this.selectedAsset,
    this.targetLocation = '',
    this.targetPic = '',
    this.reason = '',
    this.documentName,
    this.fieldErrors = const {},
  });

  MutationFormState copyWith({
    Asset? selectedAsset,
    String? targetLocation,
    String? targetPic,
    String? reason,
    String? documentName,
    Map<String, String?>? fieldErrors,
    bool clearAsset = false,
    bool clearDocument = false,
  }) {
    return MutationFormState(
      selectedAsset: clearAsset ? null : (selectedAsset ?? this.selectedAsset),
      targetLocation: targetLocation ?? this.targetLocation,
      targetPic: targetPic ?? this.targetPic,
      reason: reason ?? this.reason,
      documentName: clearDocument ? null : (documentName ?? this.documentName),
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }

  /// Apakah semua field wajib sudah terisi.
  bool get isComplete =>
      selectedAsset != null &&
      targetLocation.trim().isNotEmpty &&
      targetPic.trim().isNotEmpty &&
      reason.trim().isNotEmpty;

  /// Apakah ada error validasi aktif.
  bool get hasErrors => fieldErrors.values.any((e) => e != null && e.isNotEmpty);
}

/// Notifier untuk mengelola state form mutasi.
class MutationFormNotifier extends StateNotifier<MutationFormState> {
  MutationFormNotifier() : super(const MutationFormState());

  void selectAsset(Asset asset) {
    state = state.copyWith(selectedAsset: asset, fieldErrors: {});
  }

  void setTargetLocation(String value) {
    final errors = Map<String, String?>.from(state.fieldErrors);
    errors.remove('targetLocation');
    state = state.copyWith(targetLocation: value, fieldErrors: errors);
  }

  void setTargetPic(String value) {
    final errors = Map<String, String?>.from(state.fieldErrors);
    errors.remove('targetPic');
    state = state.copyWith(targetPic: value, fieldErrors: errors);
  }

  void setReason(String value) {
    final errors = Map<String, String?>.from(state.fieldErrors);
    errors.remove('reason');
    state = state.copyWith(reason: value, fieldErrors: errors);
  }

  void setDocumentName(String? value) {
    state = state.copyWith(documentName: value);
  }

  /// Validasi semua field. Return true jika valid.
  bool validate() {
    final errors = <String, String?>{};

    if (state.selectedAsset == null) {
      errors['asset'] = 'Aset wajib dipilih.';
    }

    if (state.targetLocation.trim().isEmpty) {
      errors['targetLocation'] = 'Lokasi tujuan wajib dipilih.';
    }

    if (state.targetPic.trim().isEmpty) {
      errors['targetPic'] = 'Penanggung jawab baru wajib dipilih.';
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
