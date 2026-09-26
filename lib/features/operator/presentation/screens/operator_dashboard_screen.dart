// lib/features/operator/presentation/screens/operator_dashboard_screen.dart
//
// Dashboard Screen untuk Role: Operator (OPR-001).
// Sumber: ROLE-FLOW.md §4, SCREEN-SPEC.md OPR-001.
// UI: Premium Stitch design — hero 2-col action cards, improved recent list.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/role_dashboard_layout.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../providers/operator_verification_provider.dart';

/// Warna lokal — mengikuti Stitch design tokens.
class _C {
  static const navy = Color(0xFF0F3D56);
  static const teal = Color(0xFF0F766E);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF172B4D);
  static const textSecondary = Color(0xFF52606D);
  static const border = Color(0xFFE2E8F0);
  static const error = Color(0xFFEF4444);
}

class OperatorDashboardScreen extends ConsumerWidget {
  const OperatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userName = authState.user?.name ?? 'Operator';
    final stats = ref.watch(verificationStatsProvider);
    final asyncMutations = ref.watch(operatorAllMutationsProvider);

    return RoleDashboardLayout(
      title: 'Dashboard Operator',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Greeting ──────────────────────────────────────────────────
          Text(
            'Halo, $userName! 👋',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _C.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Verifikasi & Periksa Mutasi Aset',
            style: TextStyle(
              fontSize: 13,
              color: _C.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),

          // ── Hero Action Cards (2-kolom) ────────────────────────────────
          Row(
            children: [
              // Card 1: Pengajuan Masuk (teal)
              Expanded(
                child: _HeroCard(
                  key: const Key('hero_pengajuan_masuk'),
                  icon: Icons.assignment_outlined,
                  title: 'Pengajuan Masuk',
                  subtitle: 'Perlu diverifikasi segera',
                  badgeText: '${stats.pendingCount} Menunggu',
                  badgeColor: Colors.white.withValues(alpha: 0.25),
                  badgeTextColor: Colors.white,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                  ),
                  glowColor: const Color(0xFF0F766E),
                  onTap: () => context.push(RouteNames.operatorMutationsPath),
                ),
              ),
              const SizedBox(width: 12),
              // Card 2: Riwayat Verifikasi (navy)
              Expanded(
                child: _HeroCard(
                  key: const Key('hero_riwayat_verifikasi'),
                  icon: Icons.history_rounded,
                  title: 'Dikembalikan',
                  subtitle: 'Perlu tindak lanjut',
                  badgeText: '${stats.returnedCount} Item',
                  badgeColor: Colors.white.withValues(alpha: 0.15),
                  badgeTextColor: const Color(0xFF6EE7B7),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F3D56), Color(0xFF1A5276)],
                  ),
                  glowColor: const Color(0xFF0F3D56),
                  onTap: () => context.push(RouteNames.operatorMutationsPath),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Primary Action Button ─────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('btn_lihat_pengajuan'),
              onPressed: () => context.push(RouteNames.operatorMutationsPath),
              icon: const Icon(Icons.fact_check_outlined, size: 18),
              label: const Text(
                'Lihat Pengajuan Masuk',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.navy,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Pengajuan Terbaru ─────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pengajuan Terbaru',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => context.push(RouteNames.operatorMutationsPath),
                child: const Text(
                  'Lihat Semua →',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _C.teal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          asyncMutations.when(
            data: (mutations) {
              final incomingList = mutations
                  .where((m) => m.status == MutationStatus.submitted)
                  .take(5)
                  .toList();

              if (incomingList.isEmpty) {
                return _buildEmptyState();
              }

              return Column(
                children: incomingList
                    .map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _RecentCard(
                            mutation: item,
                            onTap: () => context
                                .push('/operator/mutations/${item.id}'),
                          ),
                        ))
                    .toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _C.teal,
                ),
              ),
            ),
            error: (err, _) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: _C.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Gagal memuat pengajuan: $err',
                      style: const TextStyle(
                        color: _C.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_outlined, size: 44, color: _C.border),
          SizedBox(height: 12),
          Text(
            'Belum ada pengajuan masuk',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _C.textSecondary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Pengajuan baru akan muncul di sini',
            style: TextStyle(fontSize: 12, color: _C.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Hero card dengan gradient background (2-kolom).
class _HeroCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeColor;
  final Color badgeTextColor;
  final LinearGradient gradient;
  final Color glowColor;
  final VoidCallback onTap;

  const _HeroCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.gradient,
    required this.glowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: glowColor.withValues(alpha: 0.30),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 12),
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 12),
            // Divider
            Divider(
              height: 1,
              color: Colors.white.withValues(alpha: 0.20),
            ),
            const SizedBox(height: 10),
            // Badge + arrow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: badgeTextColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.60),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Card item mutasi terbaru untuk dashboard Operator.
class _RecentCard extends StatelessWidget {
  final Mutation mutation;
  final VoidCallback? onTap;

  const _RecentCard({required this.mutation, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left accent
            Container(
              width: 3,
              height: 44,
              decoration: BoxDecoration(
                color: _C.teal,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        mutation.ticketNumber,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                          color: _C.navy,
                        ),
                      ),
                      _StatusPill(status: mutation.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mutation.asset.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _C.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pemohon: ${mutation.applicantName}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: _C.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: _C.border,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final MutationStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case MutationStatus.submitted:
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF3B82F6);
        label = 'Masuk';
        break;
      case MutationStatus.returned:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        label = 'Dikembalikan';
        break;
      case MutationStatus.verified:
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF10B981);
        label = 'Terverifikasi';
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF52606D);
        label = status.displayName;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
