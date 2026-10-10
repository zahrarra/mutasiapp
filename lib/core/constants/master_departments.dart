// lib/core/constants/master_departments.dart
//
// Master Data Resmi Divisi / Unit Kerja MutasiKu.
// Terpisah secara ketat dari lokasi fisik aset.

abstract final class MasterDepartments {
  /// Daftar awal 11 divisi / unit kerja resmi organisasi:
  static const List<String> all = [
    'Divisi TI',
    'UKK Siber',
    'Divisi Treasury',
    'Divisi Umum dan Aset',
    'Divisi SDM',
    'Divisi Operasional',
    'Divisi Kredit',
    'Divisi SKAI',
    'Divisi Pemasaran',
    'Divisi Literasi',
    'Divisi Hukum',
  ];

  /// Nilai default pilihan divisi awal
  static const String defaultDepartment = 'Divisi Operasional';

  /// Cek apakah suatu nama divisi terdaftar dalam master data
  static bool contains(String? name) {
    if (name == null || name.trim().isEmpty) return false;
    return all.contains(name.trim());
  }
}
