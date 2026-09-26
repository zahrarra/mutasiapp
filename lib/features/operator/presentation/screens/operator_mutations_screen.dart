// lib/features/operator/presentation/screens/operator_mutations_screen.dart
//
// Screen: Pengajuan Masuk Operator (OPR-002).
// Sumber: SCREEN-SPEC.md OPR-002, ROLE-FLOW.md §4, WIREFRAME.md §2.
// UI: Premium Stitch design — custom top bar, filter chips, improved list cards.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../../core/widgets/custom_floating_nav_bar.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../providers/operator_verification_provider.dart';

class _C {
  static const navy = Color(0xFF0F3D56);
  static const teal = Color(0xFF0F766E);
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF6F8FA);
  static const textPrimary = Color(0xFF172B4D);
  static const textSecondary = Color(0xFF52606D);
  static const border = Color(0xFFE2E8F0);
  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFFECFDF5);
  static const warning = Color(0xFFD97706);
  static const warningLight = Color(0xFFFEF3C7);
  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFEF2F2);
  static const info = Color(0xFF3B82F6);
  static const infoLight = Color(0xFFEFF6FF);
}

class OperatorMutationsScreen extends ConsumerStatefulWidget {
  const OperatorMutationsScreen({super.key});

  @override
  ConsumerState<OperatorMutationsScreen> createState() =>
      _OperatorMutationsScreenState();
}

class _OperatorMutationsScreenState
    extends ConsumerState<OperatorMutationsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(operatorAllMutationsProvider);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncIncoming = ref.watch(filteredIncomingMutationsProvider);
    final sortOrder = ref.watch(operatorSortOrderProvider);
    final statusFilter = ref.watch(operatorStatusFilterProvider);

    return Scaffold(
      backgroundColor: _C.background,
      extendBody: true,
      body: Column(
        children: [
          // ── Custom Top Bar ──────────────────────────────────────────
          Container(
            color: _C.surface,
            child: SafeArea(
              bottom: false,
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: _C.surface,
                  border: Border(
                    bottom: BorderSide(color: _C.border, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(RouteNames.operatorDashboardPath);
                        }
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _C.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _C.border),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          size: 18,
                          color: _C.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pengajuan Masuk',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _C.textPrimary,
                            ),
                          ),
                          Text(
                            'Antrean Verifikasi Operator',
                            style: TextStyle(
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
            ),
          ),

          // ── Search & Filter Header ──────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            color: _C.surface,
            child: Column(
              children: [
                // Search Field
                Container(
                  decoration: BoxDecoration(
                    color: _C.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.border),
                  ),
                  child: TextField(
                    key: const Key('input_search_mutations'),
                    controller: _searchController,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _C.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari no. tiket, aset, pemohon...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: _C.textSecondary,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: _C.textSecondary,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                ref
                                    .read(operatorSearchQueryProvider.notifier)
                                    .state = '';
                              },
                              child: const Icon(
                                Icons.clear_rounded,
                                size: 16,
                                color: _C.textSecondary,
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      ref.read(operatorSearchQueryProvider.notifier).state =
                          value;
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Filter & Sort Row
                Row(
                  children: [
                    // Status Filter
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: _C.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _C.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<OperatorStatusFilter>(
                            key: const Key('dropdown_filter_operator_status'),
                            value: statusFilter,
                            isDense: true,
                            isExpanded: true,
                            icon: const Icon(
                              Icons.filter_list_rounded,
                              size: 16,
                              color: _C.teal,
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _C.textPrimary,
                            ),
                            items: OperatorStatusFilter.values.map((s) {
                              return DropdownMenuItem(
                                value: s,
                                child: Text(s.displayName),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                ref
                                    .read(
                                      operatorStatusFilterProvider.notifier,
                                    )
                                    .state = val;
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Sort Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: _C.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _C.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<MutationSortOrder>(
                          key: const Key('dropdown_filter_operator_sort'),
                          value: sortOrder,
                          isDense: true,
                          icon: const Icon(
                            Icons.sort_rounded,
                            size: 16,
                            color: _C.textSecondary,
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _C.textPrimary,
                          ),
                          items: MutationSortOrder.values.map((order) {
                            return DropdownMenuItem(
                              value: order,
                              child: Text(order.displayName),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              ref
                                  .read(operatorSortOrderProvider.notifier)
                                  .state = val;
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _C.border),

          // ── Content List ────────────────────────────────────────────
          Expanded(
            child: asyncIncoming.when(
              data: (mutations) {
                if (mutations.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  color: _C.teal,
                  onRefresh: () async {
                    ref.invalidate(operatorAllMutationsProvider);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: mutations.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = mutations[index];
                      return _MutationCard(
                        mutation: item,
                        onTap: () =>
                            context.push('/operator/mutations/${item.id}'),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _C.teal,
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: _C.errorLight,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          size: 32,
                          color: _C.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Gagal Memuat Data',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _C.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$err',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _C.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () =>
                            ref.invalidate(operatorAllMutationsProvider),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Coba Lagi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
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
      bottomNavigationBar: CustomFloatingNavBar.scaffoldBottomBar(
        items: RoleNavConfig.getNavItemsForRole(UserRole.operator),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _C.successLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 36,
                color: _C.success,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tidak Ada Pengajuan Masuk',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _C.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Semua pengajuan mutasi telah\ndiproses dan diverifikasi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _C.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card item mutasi untuk list antrean verifikasi.
class _MutationCard extends StatelessWidget {
  final Mutation mutation;
  final VoidCallback? onTap;

  const _MutationCard({required this.mutation, this.onTap});

  static String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(mutation.status.name);

    return GestureDetector(
      key: Key('card_mutation_${mutation.id}'),
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
            // ── Row 1: Ticket + Status ─────────────────────────
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
                    color: statusColor.$2,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    mutation.status.displayName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor.$1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // ── Row 2: Asset Name ──────────────────────────────
            Text(
              mutation.asset.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _C.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: _C.border),
            const SizedBox(height: 8),

            // ── Row 3: Pemohon + Tanggal ───────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 13,
                      color: _C.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      mutation.applicantName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _C.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: _C.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(mutation.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: _C.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Returns (foreground, background) color pair based on status name.
  (Color, Color) _statusColor(String statusName) {
    switch (statusName) {
      case 'submitted':
        return (_C.info, _C.infoLight);
      case 'returned':
        return (_C.warning, _C.warningLight);
      case 'verified':
      case 'approved':
      case 'completed':
        return (_C.success, _C.successLight);
      case 'rejected':
        return (_C.error, _C.errorLight);
      default:
        return (_C.textSecondary, _C.border);
    }
  }
}
