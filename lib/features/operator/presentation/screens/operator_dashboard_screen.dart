// lib/features/operator/presentation/screens/operator_dashboard_screen.dart
//
// Dashboard Operator — UI mengikuti Stitch (greeting, search, hero cards,
// kategori, list verifikasi, floating nav lewat RoleDashboardLayout).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/role_dashboard_layout.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../providers/operator_verification_provider.dart';

class _C {
  static const navy = Color(0xFF0F3D56);
  static const darkCard = Color(0xFF082838);
  static const teal = Color(0xFF0F766E);
  static const textPrimary = Color(0xFF172B4D);
  static const textSecondary = Color(0xFF52606D);
  static const border = Color(0xFFE2E8F0);
  static const surface = Color(0xFFFFFFFF);
}

class OperatorDashboardScreen extends ConsumerStatefulWidget {
  const OperatorDashboardScreen({super.key});

  @override
  ConsumerState<OperatorDashboardScreen> createState() =>
      _OperatorDashboardScreenState();
}

class _OperatorDashboardScreenState
    extends ConsumerState<OperatorDashboardScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Mutation> _filter(List<Mutation> list) {
    final q = _query.trim().toLowerCase();
    var result = list.where((m) => m.status == MutationStatus.submitted);
    if (q.isEmpty) return result.toList();
    return result.where((m) {
      final ticket = m.ticketNumber.toLowerCase();
      final asset = m.asset.name.toLowerCase();
      final code = m.asset.assetCode.toLowerCase();
      final name = m.applicantName.toLowerCase();
      return ticket.contains(q) ||
          asset.contains(q) ||
          code.contains(q) ||
          name.contains(q);
    }).toList();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final userName = user?.name ?? 'Operator';
    final stats = ref.watch(verificationStatsProvider);
    final asyncMutations = ref.watch(operatorAllMutationsProvider);

    return RoleDashboardLayout(
      title: 'Dashboard Operator',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // ── Greeting ─────────────────────────────────────────────
            Text(
              'Halo, $userName!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _C.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Verifikasi & Periksa Mutasi Aset',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _C.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // ── Search (benar-benar filter list di bawah) ─────────────
            TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(fontSize: 13, color: _C.textPrimary),
              decoration: InputDecoration(
                hintText: 'Cari No. Tiket, Kode Aset, Pemohon...',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: _C.textSecondary.withValues(alpha: 0.7),
                ),
                prefixIcon: const Icon(Icons.search, color: _C.textSecondary),
                filled: true,
                fillColor: _C.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _C.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _C.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _C.teal, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Hero cards 2 kolom ───────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _HeroCard(
                    title: 'Pengajuan Masuk',
                    subtitle: 'Perlu diverifikasi segera',
                    badge: '${stats.pendingCount} Menunggu',
                    icon: Icons.fact_check_outlined,
                    background: _C.teal,
                    onTap: () => context.push(RouteNames.operatorMutationsPath),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HeroCard(
                    title: 'Riwayat Verifikasi',
                    subtitle: 'Sudah diproses',
                    badge: '${stats.waitingKabagCount} Menunggu',
                    icon: Icons.history_rounded,
                    background: _C.darkCard,
                    badgeHighlight: true,
                    onTap: () {
                      // Pakai history path jika ada di router; fallback list
                      try {
                        context.push(RouteNames.operatorHistoryPath);
                      } catch (_) {
                        context.push(RouteNames.operatorMutationsPath);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Kategori (opsional / visual; tap → list) ──────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'KATEGORI ASET PRIORITAS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: _C.textSecondary,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push(RouteNames.operatorMutationsPath),
                  child: const Text(
                    'Filter Lengkap',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _C.teal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _CategoryChip(
                    icon: Icons.laptop_mac,
                    iconBg: const Color(0xFFEFF6FF),
                    iconColor: const Color(0xFF1D4ED8),
                    title: 'Laptop & PC',
                    subtitle: 'Antrian verifikasi',
                    onTap: () => context.push(RouteNames.operatorMutationsPath),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CategoryChip(
                    icon: Icons.print_outlined,
                    iconBg: const Color(0xFFECFDF5),
                    iconColor: const Color(0xFF047857),
                    title: 'Printer & Scan',
                    subtitle: 'Antrian verifikasi',
                    onTap: () => context.push(RouteNames.operatorMutationsPath),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── List pengajuan perlu verifikasi ──────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pengajuan Perlu Verifikasi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _C.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push(RouteNames.operatorMutationsPath),
                  child: const Row(
                    children: [
                      Text(
                        'Lihat Semua',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _C.teal,
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 16, color: _C.teal),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            asyncMutations.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _C.teal,
                  ),
                ),
              ),
              error: (e, _) => Text(
                'Gagal memuat: $e',
                style: const TextStyle(color: Colors.red),
              ),
              data: (all) {
                final list = _filter(all).take(10).toList();
                if (list.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    decoration: BoxDecoration(
                      color: _C.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _C.border),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.inbox_outlined, size: 40, color: _C.border),
                        SizedBox(height: 8),
                        Text(
                          'Tidak ada pengajuan menunggu',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _C.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: list
                      .map(
                        (m) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _QueueCard(
                            mutation: m,
                            initials: _initials(m.applicantName),
                            onInspect: () {
                              context.push(
                                RouteNames.operatorVerificationDetailPath
                                    .replaceFirst(':id', m.id),
                              );
                            },
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      );
  }
}

// ─── Widgets ───────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.background,
    required this.onTap,
    this.badgeHighlight = false,
  });

  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Color background;
  final VoidCallback onTap;
  final bool badgeHighlight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: background.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.15)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: badgeHighlight
                            ? const Color(0xFF6EE7B7)
                            : Colors.white,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border),
        ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _C.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _C.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({
    required this.mutation,
    required this.initials,
    required this.onInspect,
  });

  final Mutation mutation;
  final String initials;
  final VoidCallback onInspect;

  @override
  Widget build(BuildContext context) {
    final m = mutation;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: _C.navy.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  m.ticketNumber,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    color: _C.navy,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 6, color: Color(0xFFF59E0B)),
                    SizedBox(width: 4),
                    Text(
                      'Menunggu Verifikasi',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFCCFBF1),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF115E59),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.applicantName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _C.textPrimary,
                      ),
                    ),
                    Text(
                      m.asset.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _C.navy,
                      ),
                    ),
                    Text(
                      'Kode: ${m.asset.assetCode}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: _C.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    m.currentLocation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _C.textSecondary,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward, size: 14, color: _C.teal),
                ),
                Expanded(
                  child: Text(
                    m.targetLocation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _C.navy,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: onInspect,
              style: OutlinedButton.styleFrom(
                foregroundColor: _C.navy,
                side: const BorderSide(color: _C.navy, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Periksa Dokumen',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
