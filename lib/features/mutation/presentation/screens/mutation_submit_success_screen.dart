// lib/features/mutation/presentation/screens/mutation_submit_success_screen.dart
//
// Screen: Konfirmasi Sukses Pengajuan Mutasi (REQ-006).
// Sumber: SCREEN-SPEC.md REQ-006, ROLE-FLOW.md §3.
// UI: Stitch "Pengajuan Berhasil" reference 02_pengajuan_berhasil.html.
//
// Langkah terakhir dari alur Pengajuan Mutasi: menampilkan nomor tiket
// hasil generate server dan navigasi kembali ke Mutasi Saya / Dashboard.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../providers/mutation_provider.dart';


/// Screen konfirmasi sukses setelah pengajuan mutasi berhasil dikirim.
class MutationSubmitSuccessScreen extends ConsumerWidget {
  final String? ticketNumber;

  const MutationSubmitSuccessScreen({super.key, this.ticketNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FA),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 420),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── Success icon ──
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF059669).withValues(alpha: 0.15),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF059669),
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Title ──
                          const Text(
                            'Pengajuan Berhasil Dikirim!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F3D56),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),

                          const Text(
                            'Pengajuan mutasi Anda telah diterima dan akan diverifikasi oleh Operator.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: Color(0xFF52606D),
                            ),
                          ),

                          if (ticketNumber != null) ...[
                            const SizedBox(height: 24),

                            // ── Ticket summary card ──
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Nomor Tiket',
                                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              ticketNumber!,
                                              style: const TextStyle(
                                                fontFamily: 'monospace',
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF172B4D),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          _CopyButton(text: ticketNumber!),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Status',
                                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFFBEB),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: const Color(0xFFFDE68A)),
                                        ),
                                        child: const Text(
                                          'Menunggu Verifikasi Operator',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF92400E),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),

                          // ── Info note ──
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 15,
                                  color: Color(0xFF0369A1),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Simpan nomor tiket ini untuk memantau status pengajuan Anda.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      height: 1.4,
                                      color: Color(0xFF0369A1),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ── Primary: Lihat Mutasi Saya ──
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ref.invalidate(mutationListProvider);
                                context.go(RouteNames.pemohonMutasiPath);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F3D56),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.assignment_turned_in_rounded, size: 18),
                              label: const Text(
                                'Lihat Mutasi Saya',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // ── Secondary: Kembali ke Beranda ──
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: () => context.go(RouteNames.pemohonDashboardPath),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF52606D),
                                side: const BorderSide(color: Color(0xFFD0D5DD)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.home_outlined, size: 18),
                              label: const Text(
                                'Kembali ke Beranda',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tombol salin nomor tiket kecil dengan state feedback
class _CopyButton extends StatefulWidget {
  final String text;
  const _CopyButton({required this.text});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _copy,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _copied ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _copied ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          _copied ? 'Tersalin!' : 'Salin',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: _copied ? const Color(0xFF059669) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

