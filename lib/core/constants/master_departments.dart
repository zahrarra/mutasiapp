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

  /// Divisi yang sudah ditetapkan untuk role Bagian Aset.
  /// Bagian Aset adalah bagian dari Divisi Umum dan Aset, jadi divisinya
  /// tidak bisa dipilih bebas saat admin membuat/mengubah user.
  static const String bagianAsetDepartment = 'Divisi Umum dan Aset';

  /// Cek apakah suatu nama divisi terdaftar dalam master data
  static bool contains(String? name) {
    if (name == null || name.trim().isEmpty) return false;
    final trimmed = name.trim();
    if (trimmed == 'Umum & Aset' || trimmed == 'Divisi Umum & Aset') {
      return true;
    }
    return all.contains(trimmed);
  }

  /// Normalisasi variasi penamaan divisi testing/UI ke nilai kanonikal
  static String canonical(String? name) {
    if (name == null || name.trim().isEmpty) return defaultDepartment;
    final trimmed = name.trim();
    if (trimmed == 'Umum & Aset' || trimmed == 'Divisi Umum & Aset') {
      return 'Divisi Umum dan Aset';
    }
    return trimmed;
  }
}
