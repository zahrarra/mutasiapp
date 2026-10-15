// lib/features/operator/presentation/screens/operator_return_form_screen.dart
//
// Screen: Form Pengembalian Pengajuan Mutasi oleh Operator (OPR-004).
// Catatan: Operator berwenang memeriksa kelengkapan data & SK SDM lalu meneruskan ke Bagian Aset.
// Aksi pengembalian/penolakan bukan wewenang Operator (wewenang Bagian Aset & Pimpinan).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/mutasiku_page_header.dart';

class OperatorReturnFormScreen extends ConsumerWidget {
  final String mutationId;

  const OperatorReturnFormScreen({super.key, required this.mutationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SafeArea(
            bottom: false,
            child: MutasiKuPageHeader(
              title: 'Pengembalian Berkas',
              subtitle: 'Informasi wewenang verifikasi operator',
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(RouteNames.operatorMutationsPath);
                }
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 48,
                        color: AppColors.warning,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Aksi Tidak Diizinkan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Operator tidak memiliki kewenangan untuk mengembalikan atau menolak pengajuan mutasi. Operator hanya berwenang memeriksa kelengkapan berkas fisik & SK SDM lalu meneruskannya ke Bagian Aset.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(RouteNames.operatorMutationsPath);
                          }
                        },
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('Kembali ke Detail Pengajuan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
