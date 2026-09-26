// lib/features/kadiv/presentation/screens/kadiv_dashboard_screen.dart
//
// Dashboard Screen untuk Role: Kadiv (KDV-001).
// Sumber: ROLE-FLOW.md §6, SCREEN-SPEC.md KDV-001, DESIGN.md.
// UI: Premium Stitch design — stat cards, hero CTA, recent list.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/role_dashboard_layout.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../providers/kadiv_approval_provider.dart';

class _C {
  static const navy = Color(0xFF0F3D56);
  static const teal = Color(0xFF0F766E);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF172B4D);
  static const textSecondary = Color(0xFF52606D);
  static const border = Color(0xFFE2E8F0);
  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFFECFDF5);
  static const warning = Color(0xFFD97706);
  static const warningLight = Color(0xFFFEF3C7);
  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFEF2F2);
}



class KadivDashboardScreen extends ConsumerWidget {
  const KadivDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userName = authState.user?.name ?? 'Kepala Divisi';
    final stats = ref.watch(kadivStatsProvider);
    final asyncMutations = ref.watch(kadivAllMutationsProvider);

    return RoleDashboardLayout(
      title: 'Dashboard Kadiv',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Greeting ────────────────────────────────────────────────
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
            'Otorisasi final mutasi aset tingkat Kepala Divisi',
            style: TextStyle(
              fontSize: 13,
              color: _C.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),

          // ── Stat Cards (3 kolom) ─────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  key: const Key('stat_kadiv_waiting'),
                  icon: Icons.pending_actions_rounded,
                  label: 'Menunggu',
                  count: stats.waitingApprovalCount,
                  iconColor: _C.warning,
                  iconBg: _C.warningLight,
                  countColor: _C.warning,
                  onTap: () {
                    ref.read(kadivStatusFilterProvider.notifier).state =
                        KadivStatusFilter.waiting;
                    context.push(RouteNames.kadivApprovalsPath);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  key: const Key('stat_kadiv_approved'),
                  icon: Icons.verified_outlined,
                  label: 'Disetujui',
                  count: stats.approvedCount,
                  iconColor: _C.success,
                  iconBg: _C.successLight,
                  countColor: _C.success,
                  onTap: () {
                    ref.read(kadivStatusFilterProvider.notifier).state =
                        KadivStatusFilter.approved;
                    context.push(RouteNames.kadivApprovalsPath);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  key: const Key('stat_kadiv_rejected'),
                  icon: Icons.cancel_outlined,
                  label: 'Ditolak',
                  count: stats.rejectedCount,
                  iconColor: _C.error,
                  iconBg: _C.errorLight,
                  countColor: _C.error,
                  onTap: () {
                    ref.read(kadivStatusFilterProvider.notifier).state =
                        KadivStatusFilter.rejected;
                    context.push(RouteNames.kadivApprovalsPath);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Primary Action Button ─────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('btn_lihat_approval_kadiv'),
              onPressed: () {
                ref.read(kadivStatusFilterProvider.notifier).state =
                    KadivStatusFilter.waiting;
                context.push(RouteNames.kadivApprovalsPath);
              },
              icon: const Icon(Icons.verified_user_outlined, size: 18),
              label: const Text(
                'Lihat Antrean Approval Kadiv',
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

          // ── Antrean Terbaru ───────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Antrean Otorisasi',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  ref.read(kadivStatusFilterProvider.notifier).state =
                      KadivStatusFilter.all;
                  context.push(RouteNames.kadivApprovalsPath);
                },
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
              final relevant = mutations
                  .where(isWaitingKadivApproval)
                  .take(5)
                  .toList();


              if (relevant.isEmpty) {
                return _EmptyState();
              }

              return Column(
                children: relevant
                    .map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ApprovalCard(
                            mutation: item,
                            onTap: () =>
                                context.push('/kadiv/approvals/${item.id}'),
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
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _C.errorLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                'Gagal memuat mutasi: $err',
                style: const TextStyle(color: _C.error, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color iconColor;
  final Color iconBg;
  final Color countColor;
  final VoidCallback onTap;

  const _StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.iconColor,
    required this.iconBg,
    required this.countColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: countColor,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: _C.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  final Mutation mutation;
  final VoidCallback? onTap;

  const _ApprovalCard({required this.mutation, this.onTap});

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
            Container(
              width: 3,
              height: 48,
              decoration: BoxDecoration(
                color: _C.navy,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 12),
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
                      if (mutation.approvedBy != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 12,
                              color: _C.success,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Kabag: ${mutation.approvedBy}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: _C.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
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
                    'Tujuan: ${mutation.targetLocation} • ${mutation.applicantName}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: _C.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
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

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle_outline, size: 44, color: _C.success),
          SizedBox(height: 12),
          Text(
            'Tidak Ada Antrean Approval',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _C.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Semua mutasi telah diproses.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: _C.textSecondary),
          ),
        ],
      ),
    );
  }
}
