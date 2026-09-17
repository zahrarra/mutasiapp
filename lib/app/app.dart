// lib/app/app.dart
//
// Root Widget MutasiKu.
// Sumber: PROJECT-SETUP.md §5, TECHNICAL-DESIGN.md §3.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Root Widget aplikasi MutasiKu.
class MutasiKuApp extends ConsumerWidget {
  const MutasiKuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
