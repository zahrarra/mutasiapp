// lib/features/pemohon/presentation/screens/pemohon_dashboard_screen.dart
//
// Dashboard Pemohon — UI mengikuti mockup.
// Data: authStateProvider + mutationListProvider.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../../../asset/presentation/providers/asset_provider.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../../core/widgets/custom_floating_nav_bar.dart';
import '../widgets/mutation_filter_bottom_sheet.dart';

/// Warna mengikuti mockup dashboard Pemohon.
class _C {
  static const background = Color(0xFFF6F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFF00273A);
  static const primaryContainer = Color(0xFF0F3D56);
  static const secondary = Color(0xFF006A63);
  static const textPrimary = Color(0xFF172B4D);
  static const textSecondary = Color(0xFF52606D);
  static const border = Color(0xFFD0D5DD);
  static const success = Color(0xFF15803D);
  static const warning = Color(0xFFB45309);
  static const info = Color(0xFF175CD3);
  static const error = Color(0xFFB42318);
  static const surfaceLow = Color(0xFFECF4FF);
  static const surfaceContainer = Color(0xFFE1F0FF);
  static const onPrimaryContainer = Color(0xFF80A8C5);
}

class PemohonDashboardScreen extends ConsumerStatefulWidget {
  const PemohonDashboardScreen({super.key});

  @override
  ConsumerState<PemohonDashboardScreen> createState() =>
      _PemohonDashboardScreenState();
}

class _PemohonDashboardScreenState
    extends ConsumerState<PemohonDashboardScreen> {
  final _searchController = TextEditingController();

  MutationStatus? _dashboardFilterStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _goCreateMutation() {
    context.push(RouteNames.pemohonMutasiCreatePath);
  }

  void _goMutasiList() {
    context.push(RouteNames.pemohonMutasiPath);
  }

  void _goNotifications() {
    context.push(RouteNames.pemohonNotificationsPath);
  }

  void _goProfile() {
    context.push(RouteNames.pemohonProfilePath);
  }

  Future<void> _openDashboardFilter(List<Mutation> list) async {
    final Map<MutationStatus?, int> counts = {
      null: list.length,
    };
    for (final s in MutationStatus.values) {
      counts[s] = list.where((m) => m.status == s).length;
    }

    final selected = await showMutationFilterBottomSheet(
      context: context,
      currentStatus: _dashboardFilterStatus,
      counts: counts,
    );

    if (mounted) {
      setState(() {
        _dashboardFilterStatus = selected;
      });
    }
  }

  Color _statusColor(MutationStatus? s) {
    if (s == null) return _C.textSecondary;

    switch (s) {
      case MutationStatus.completed:
        return _C.success;
      case MutationStatus.rejected:
        return _C.error;
      case MutationStatus.pendingConfirmation:
        return _C.warning;
      default:
        return _C.info;
    }
  }

  String _statusLabel(MutationStatus? s) {
    if (s == null) return '-';
    return s.displayName;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final user = auth.user;
    final name = user?.name ?? 'Pemohon';
    final unit = user?.email ?? 'Unit kerja';

    final mutationsAsync = ref.watch(mutationListProvider);
    final responsibleAssetsAsync = ref.watch(userResponsibleAssetsProvider);

    return Scaffold(
      backgroundColor: _C.background,
      extendBody: true,
      body: Column(
            children: [
              // Header
              _Header(onNotif: _goNotifications, onProfile: _goProfile),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  children: [
                    // ── Sapaan ─────────────────────────────────────────
                    Row(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: _C.primaryContainer,
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'P',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _C.success,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _C.surface,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halo, $name',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: _C.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.corporate_fare,
                                    size: 15,
                                    color: _C.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      unit,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: _C.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _C.success.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: _C.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Sinkron',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _C.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Hero card ──────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _C.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _C.primaryContainer.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TOTAL ASET TANGGUNG JAWAB',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.6,
                                        color: _C.onPrimaryContainer,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        responsibleAssetsAsync.when(
                                          data: (assets) => Text(
                                            '${assets.length}',
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                          loading: () => const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                          error: (_, _) => const Text(
                                            '0',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Aset Aktif (PIC)',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _C.onPrimaryContainer,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.inventory_2_outlined,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 44,
                                  child: ElevatedButton.icon(
                                    onPressed: _goCreateMutation,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _C.surface,
                                      foregroundColor: _C.primaryContainer,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.add_circle,
                                      size: 19,
                                    ),
                                    label: const Text(
                                      'Ajukan Mutasi',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SizedBox(
                                  height: 44,
                                  child: OutlinedButton.icon(
                                    onPressed: _goMutasiList,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: 0.25,
                                        ),
                                      ),
                                      backgroundColor: Colors.white.withValues(
                                        alpha: 0.10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.receipt_long,
                                      size: 19,
                                    ),
                                    label: const Text(
                                      'Cek Tiket',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Search ─────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: _C.surface,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(
                                fontSize: 12,
                                color: _C.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Cari nomor tiket atau nama aset...',
                                hintStyle: TextStyle(
                                  fontSize: 12,
                                  color: _C.textSecondary.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  size: 20,
                                  color: _C.textSecondary,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear,
                                          size: 18,
                                          color: _C.textSecondary,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {});
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _C.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: () {
                              mutationsAsync.whenData((list) {
                                _openDashboardFilter(list);
                              });
                            },
                            tooltip: 'Filter Status',
                            icon: Icon(
                              Icons.tune,
                              size: 20,
                              color: _dashboardFilterStatus != null
                                  ? _C.primaryContainer
                                  : _C.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_dashboardFilterStatus != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _dashboardFilterStatus!.color
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _dashboardFilterStatus!.color
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.filter_alt,
                              size: 14,
                              color: _dashboardFilterStatus!.color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Filter: ${_dashboardFilterStatus!.displayName}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _dashboardFilterStatus!.color,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => setState(
                                () => _dashboardFilterStatus = null,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: _dashboardFilterStatus!.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Banner Menunggu Konfirmasi (jika ada) ──────────
                    mutationsAsync.when(
                      data: (list) {
                        final pending = list
                            .where((m) => m.status == MutationStatus.pendingConfirmation)
                            .toList();
                        if (pending.isEmpty) return const SizedBox.shrink();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF0C7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFEDF89)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF79009),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.assignment_turned_in,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${pending.length} Mutasi Menunggu Konfirmasi',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFB45309),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Staff Aset telah selesai update data fisik. Silakan periksa & konfirmasi penerimaan.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF7A2E0E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  if (pending.length == 1) {
                                    context.push(
                                      RouteNames.pemohonConfirmationPath
                                          .replaceFirst(':id', pending.first.id),
                                    );
                                  } else {
                                    context.push(RouteNames.pemohonMutasiPath);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFB45309),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  minimumSize: Size.zero,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Periksa',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),

                    // ── Mutasi dalam proses ────────────────────────────
                    mutationsAsync.when(
                      data: (list) {
                        final query = _searchController.text.trim().toLowerCase();
                        final aktif = list
                            .where(
                              (m) =>
                                  m.status != MutationStatus.completed &&
                                  m.status != MutationStatus.rejected &&
                                  (query.isEmpty ||
                                      m.ticketNumber.toLowerCase().contains(query) ||
                                      m.asset.name.toLowerCase().contains(query) ||
                                      m.targetLocation.toLowerCase().contains(query) ||
                                      m.targetPic.toLowerCase().contains(query)),
                            )
                            .toList();

                        final fokus = aktif.isNotEmpty ? aktif.first : null;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Mutasi Dalam Proses',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _C.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: _C.warning,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${aktif.length} Aktif',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: _C.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (fokus == null)
                              _EmptyCard(
                                text: query.isNotEmpty
                                    ? 'Tidak ada mutasi aktif yang cocok'
                                    : 'Belum ada mutasi aktif',
                                actionLabel: 'Ajukan Mutasi',
                                onAction: _goCreateMutation,
                              )
                            else
                              _ActiveMutationCard(
                                ticket: fokus.ticketNumber,
                                assetName: fokus.asset.name,
                                statusLabel: _statusLabel(fokus.status),
                                statusColor: _statusColor(fokus.status),
                                fromLoc: fokus.targetLocation.isNotEmpty
                                    ? 'Asal terdata'
                                    : '-',
                                toLoc: fokus.targetLocation,
                                onConfirm: fokus.status == MutationStatus.pendingConfirmation
                                    ? () {
                                        context.push(
                                          RouteNames.pemohonConfirmationPath
                                              .replaceFirst(':id', fokus.id),
                                        );
                                      }
                                    : null,
                                onDetail: () {
                                  context.push(
                                    RouteNames.pemohonMutasiDetailPath
                                        .replaceAll(':id', fokus.id),
                                  );
                                },
                              ),
                          ],
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => _EmptyCard(
                        text: 'Gagal memuat mutasi',
                        actionLabel: 'Coba lagi',
                        onAction: () => ref.invalidate(mutationListProvider),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Pengajuan terbaru ──────────────────────────────
                    Row(
                      children: [
                        const Text(
                          'Pengajuan Terbaru',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _C.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _goMutasiList,
                          style: TextButton.styleFrom(
                            foregroundColor: _C.info,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Row(
                            children: [
                              Text(
                                'Lihat Semua',
                                style: TextStyle(fontSize: 11),
                              ),
                              Icon(Icons.chevron_right, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    mutationsAsync.when(
                      data: (list) {
                        final query = _searchController.text.trim().toLowerCase();
                        var filteredList = _dashboardFilterStatus != null
                            ? list
                                .where((m) => m.status == _dashboardFilterStatus)
                                .toList()
                            : list;

                        if (query.isNotEmpty) {
                          filteredList = filteredList
                              .where(
                                (m) =>
                                    m.ticketNumber.toLowerCase().contains(query) ||
                                    m.asset.name.toLowerCase().contains(query) ||
                                    m.targetLocation.toLowerCase().contains(query) ||
                                    m.targetPic.toLowerCase().contains(query),
                              )
                              .toList();
                        }

                        final recent = filteredList.take(5).toList();

                        if (recent.isEmpty) {
                          final emptyMessage = query.isNotEmpty
                              ? 'Tidak ada pengajuan yang cocok dengan "$query"'
                              : (_dashboardFilterStatus != null
                                  ? 'Tidak ada pengajuan dengan status "${_dashboardFilterStatus!.displayName}"'
                                  : 'Belum ada pengajuan');
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              emptyMessage,
                              style: const TextStyle(
                                fontSize: 13,
                                color: _C.textSecondary,
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: recent.map((m) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _RecentTile(
                                ticket: m.ticketNumber,
                                assetName: m.asset.name,
                                statusLabel: _statusLabel(m.status),
                                statusColor: _statusColor(m.status),
                                subtitle:
                                    '${m.targetLocation} • ${m.createdAt}',
                                onTap: () {
                                  context.push(
                                    RouteNames.pemohonMutasiDetailPath
                                        .replaceAll(':id', m.id),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: CustomFloatingNavBar.scaffoldBottomBar(
            items: RoleNavConfig.getNavItemsForRole(UserRole.pemohon),
          ),
        );
  }
}

// ─── Header ────────────────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  const _Header({required this.onNotif, required this.onProfile});

  final VoidCallback onNotif;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Material(
      color: _C.surface.withValues(alpha: 0.92),
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _C.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.sync_alt,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MutasiKu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _C.primary,
                      ),
                    ),
                    Text(
                      'Beranda',
                      style: TextStyle(fontSize: 11, color: _C.textSecondary),
                    ),
                  ],
                ),
                const Spacer(),
                Stack(
                  children: [
                    IconButton(
                      onPressed: onNotif,
                      icon: const Icon(Icons.notifications_outlined),
                      color: _C.textSecondary,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _C.error,
                            shape: BoxShape.circle,
                            border: Border.all(color: _C.surface, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  onPressed: onProfile,
                  icon: const CircleAvatar(
                    radius: 14,
                    backgroundColor: _C.primaryContainer,
                    child: Icon(Icons.person, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Active Mutation Card ──────────────────────────────────────────────────

class _ActiveMutationCard extends StatelessWidget {
  const _ActiveMutationCard({
    required this.ticket,
    required this.assetName,
    required this.statusLabel,
    required this.statusColor,
    required this.fromLoc,
    required this.toLoc,
    required this.onDetail,
    this.onConfirm,
  });

  final String ticket;
  final String assetName;
  final String statusLabel;
  final Color statusColor;
  final String fromLoc;
  final String toLoc;
  final VoidCallback onDetail;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _C.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.alt_route,
                  size: 18,
                  color: _C.primaryContainer,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _C.textPrimary,
                      ),
                    ),
                    Text(
                      assetName,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _C.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Icon(Icons.pending, size: 13, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _C.surfaceLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dari (Asal)',
                        style: TextStyle(fontSize: 11, color: _C.textSecondary),
                      ),
                      Text(
                        fromLoc,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _C.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: _C.surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: _C.primaryContainer,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Ke (Tujuan)',
                        style: TextStyle(fontSize: 11, color: _C.textSecondary),
                      ),
                      Text(
                        toLoc.isEmpty ? '-' : toLoc,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _C.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const _MiniStepper(currentStep: 2),
          if (onConfirm != null) ...[
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00273A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text(
                  'Konfirmasi Penerimaan Aset',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton.icon(
              onPressed: onDetail,
              style: TextButton.styleFrom(
                backgroundColor: _C.surfaceContainer,
                foregroundColor: _C.primaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.visibility, size: 18),
              label: const Text(
                'Lihat Tracking Lengkap',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mini Stepper ──────────────────────────────────────────────────────────

class _MiniStepper extends StatelessWidget {
  const _MiniStepper({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    const labels = ['Diajukan', 'Verifikasi', 'Approval', 'Selesai'];

    return Row(
      children: List.generate(4, (i) {
        final done = i < currentStep;
        final active = i == currentStep;

        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: done || active ? _C.secondary : _C.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: done || active ? _C.secondary : _C.border,
                    width: 2,
                  ),
                ),
                child: done
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : active
                    ? Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: _C.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                labels[i],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.1,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: done || active ? _C.secondary : _C.textSecondary,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Recent Tile ───────────────────────────────────────────────────────────

class _RecentTile extends StatelessWidget {
  const _RecentTile({
    required this.ticket,
    required this.assetName,
    required this.statusLabel,
    required this.statusColor,
    required this.subtitle,
    required this.onTap,
  });

  final String ticket;
  final String assetName;
  final String statusLabel;
  final Color statusColor;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _C.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _C.surfaceLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.laptop_mac, color: _C.primaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ticket,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _C.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      assetName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _C.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _C.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty Card ────────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: const TextStyle(color: _C.textSecondary)),
          const SizedBox(height: 12),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
