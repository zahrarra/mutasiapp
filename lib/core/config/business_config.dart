// lib/core/config/business_config.dart
//
// Konfigurasi aturan bisnis aplikasi MutasiKu.
// Sumber: dosc/SCREEN-SPEC.md §1804 ("Nilai berasal dari konfigurasi Admin/business decision").

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Nilai threshold default untuk mutasi bernilai tinggi yang wajib persetujuan Kadiv.
/// Kriteria approval: Nilai Aset >= Rp 50.000.000.
const double kDefaultKadivApprovalThreshold = 50000000.0;

/// Provider konfigurasi threshold approval Kepala Divisi (Kadiv).
final kadivApprovalThresholdProvider = StateProvider<double>((ref) {
  return kDefaultKadivApprovalThreshold;
});
