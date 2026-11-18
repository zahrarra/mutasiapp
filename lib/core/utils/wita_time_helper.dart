// lib/core/utils/wita_time_helper.dart
//
// Helper sentral untuk penanganan zona waktu WITA (Asia/Makassar, UTC+8):
// konversi dan pemformatan tanggal. (Dulu bernama SlaWitaHelper dan memuat
// kalkulasi SLA; SLA sudah ditiadakan dari MutasiKu, jadi yang tersisa
// di sini hanya utilitas tanggal WITA.)

abstract final class WitaTimeHelper {
  /// Offset WITA terhadap UTC (+8 jam)
  static const Duration witaOffset = Duration(hours: 8);

  /// Konversi sembarang [DateTime] ke waktu WITA (UTC+8) secara deterministik.
  static DateTime toWita(DateTime dt) {
    final utc = dt.toUtc();
    return utc.add(witaOffset);
  }

  /// Format tanggal singkat dalam WITA: "09 Okt 2026, 14:30 WITA"
  static String formatDateTimeWita(DateTime? dt) {
    if (dt == null) return '-';
    final wita = toWita(dt);

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    final day = wita.day.toString().padLeft(2, '0');
    final month = months[wita.month - 1];
    final year = wita.year;
    final hour = wita.hour.toString().padLeft(2, '0');
    final minute = wita.minute.toString().padLeft(2, '0');

    return '$day $month $year, $hour:$minute WITA';
  }

  /// Format tanggal saja dalam WITA: "09 Okt 2026"
  static String formatDateWita(DateTime? dt) {
    if (dt == null) return '-';
    final wita = toWita(dt);

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    final day = wita.day.toString().padLeft(2, '0');
    final month = months[wita.month - 1];
    final year = wita.year;

    return '$day $month $year';
  }
}
