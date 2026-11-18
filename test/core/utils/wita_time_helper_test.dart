import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/core/utils/wita_time_helper.dart';

void main() {
  group('WitaTimeHelper Tests', () {
    test('toWita converts UTC to WITA (UTC+8)', () {
      final utc = DateTime.utc(2026, 10, 9, 3, 30); // 03:30 UTC
      final wita = WitaTimeHelper.toWita(utc);

      expect(wita.hour, 11);
      expect(wita.minute, 30);
    });

    test('formatDateTimeWita formats with WITA suffix', () {
      final utc = DateTime.utc(2026, 10, 9, 6, 15); // 14:15 WITA
      final formatted = WitaTimeHelper.formatDateTimeWita(utc);

      expect(formatted, contains('09 Okt 2026'));
      expect(formatted, contains('14:15 WITA'));
    });
  });
}
