// lib/features/staff/presentation/screens/staff_dashboard_screen.dart
//
// Dashboard Screen untuk Role: Staff Aset (STF-001).
// Sumber: ROLE-FLOW.md §7, WIREFRAME.md §2, SCREEN-SPEC.md STF-001.
// UI: Premium Stitch design — hero card antrian, update list cards.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/role_dashboard_layout.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../providers/staff_mutation_provider.dart';

class _C {
  static const navy = Color(0xFF0F3D56);
  static const teal = Color(0xFF0F766E);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF172B4D);
  static const textSecondary = Color(0xFF52606D);
  static const border = Color(0xFFE2E8F0);
  static const success = Color(0xFF10B981);
  static const info = Color(0xFF3B82F6);
  static const infoLight = Color(0xFFEFF6FF);
  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFEF2F2);
}

class StaffAsetDashboardScreen extends ConsumerWidget {
  const StaffAsetDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userName = authState.user?.name ?? 'Staff Aset';
    final stats = ref.watch(staffStatsProvider);
    final asyncMutations = ref.watch(filteredStaffMutationsProvider);

    return RoleDashboardLayout(
      title: 'Dashboard Staff Aset',
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
            'Lakukan pembaruan data lokasi & PIC aset',
            style: TextStyle(
              fontSize: 13,
              color: _C.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),

          // ── Hero Card: Antrian Pembaruan ──────────────────────────────
          GestureDetector(
            key: const Key('card_stat_waiting_update'),
            onTap: () => context.push(RouteNames.staffMutationsPath),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F3D56), Color(0xFF1A5276)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F3D56).withValues(alpha: 0.30),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.published_with_changes_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Antrian Pembaruan Aset',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Disetujui & siap diperbarui',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.70),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${stats.waitingUpdateCount}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'item',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Primary Action Button ─────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('btn_lihat_antrian_staff'),
              onPressed: () => context.push(RouteNames.staffMutationsPath),
              icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
              label: const Text(
                'Lihat Antrian Update Aset',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.teal,
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

          // ── Antrian Terkini ───────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Antrian Pembaruan Terkini',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary,
                ),
              ),
              if (stats.waitingUpdateCount > 0)
                GestureDetector(
                  onTap: () => context.push(RouteNames.staffMutationsPath),
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
              if (mutations.isEmpty) {
                return _buildEmptyState();
              }
              final displayList = mutations.take(5).toList();
              return Column(
                children: displayList
                    .map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _StaffMutationCard(
                            mutation: item,
                            onTap: () => context
                                .push('/staff-aset/mutations/${item.id}'),
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
                'Gagal memuat antrian: $err',
                style: const TextStyle(color: _C.error, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
            'Tidak Ada Antrian Update',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _C.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Semua mutasi yang disetujui telah diperbarui.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: _C.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Card item mutasi untuk antrian Staff Aset.
class _StaffMutationCard extends StatelessWidget {
  final Mutation mutation;
  final VoidCallback? onTap;

  const _StaffMutationCard({required this.mutation, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key('card_staff_mutation_${mutation.id}'),
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _C.infoLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    mutation.status.displayName,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _C.info,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
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
              '${mutation.asset.assetCode} • ${mutation.asset.category.name}',
              style: const TextStyle(fontSize: 11, color: _C.textSecondary),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: _C.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Tujuan: ${mutation.targetLocation}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: _C.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 14,
                        color: _C.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'PIC: ${mutation.targetPic}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: _C.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
