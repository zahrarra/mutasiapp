// lib/main.dart
//
// Entry point utama aplikasi MutasiKu.
// Sumber: PROJECT-SETUP.md §4, TECHNICAL-DESIGN.md §3.
//
// ATURAN:
// - main.dart harus tetap tipis.
// - Inisialisasi storage/services dilakukan di sini sebelum runApp().
// - Tidak menaruh business logic/role logic di main.dart.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/providers/core_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MutasiKuApp(),
    ),
  );
}
