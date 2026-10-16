import 'dart:async';
import 'package:google_fonts/google_fonts.dart';

/// Konfigurasi global pengujian Flutter.
/// Menetapkan allowRuntimeFetching = false agar selama eksekusi test
/// widget dapat dirender dengan font lokal tanpa melakukan request jaringan
/// atau memunculkan warning font saat offline.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
