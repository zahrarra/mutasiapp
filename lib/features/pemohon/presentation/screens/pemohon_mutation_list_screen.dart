// lib/features/pemohon/presentation/screens/pemohon_mutation_list_screen.dart
//
// Screen: MutasiKu — Mutasi Saya (Refined Natural UI)
// Diadaptasi dari desain Stitch MCP.
// Menampilkan daftar mutasi milik Pemohon dengan quick filter tabs, search real-time,
// card status dinamis, dan akses langsung ke detail / konfirmasi / pengajuan ulang.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../../core/widgets/custom_floating_nav_bar.dart';
import '../widgets/mutation_filter_bottom_sheet.dart';
import '../widgets/pemohon_mutation_card.dart';

enum QuickFilterTab {
  all,
  action,
  inProgress,
  completed,
}

class PemohonMutationListScreen extends ConsumerStatefulWidget {
  const PemohonMutationListScreen({super.key});

  @override
  ConsumerState<PemohonMutationListScreen> createState() =>
      _PemohonMutationListScreenState();
}

class _PemohonMutationListScreenState
    extends ConsumerState<PemohonMutationListScreen> {
  final _searchController = TextEditingController();
  QuickFilterTab _selectedTab = QuickFilterTab.all;
  MutationStatus? _selectedStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Mutation> _applyFilter(List<Mutation> list) {
    var result = list;

    // Filter by specific status (if selected from bottom sheet)
    if (_selectedStatus != null) {
      result = result.where((m) => m.status == _selectedStatus).toList();
    } else {
      // Otherwise apply quick filter tab
      switch (_selectedTab) {
        case QuickFilterTab.all:
          break;
        case QuickFilterTab.action:
          result = result
              .where(
                (m) =>
                    m.status == MutationStatus.pendingConfirmation ||
                    m.status == MutationStatus.returned,
              )
              .toList();
          break;
        case QuickFilterTab.inProgress:
          result = result
              .where(
                (m) =>
                    m.status == MutationStatus.submitted ||
                    m.status == MutationStatus.verified ||
                    m.status == MutationStatus.waitingKabagApproval ||
                    m.status == MutationStatus.waitingKadivApproval ||
                    m.status == MutationStatus.approved,
              )
              .toList();
          break;
        case QuickFilterTab.completed:
          result = result
              .where((m) => m.status == MutationStatus.completed)
              .toList();
          break;
      }
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result
          .where(
            (m) =>
                m.ticketNumber.toLowerCase().contains(query) ||
                m.asset.name.toLowerCase().contains(query) ||
                m.asset.assetCode.toLowerCase().contains(query) ||
                m.currentLocation.toLowerCase().contains(query) ||
                m.targetLocation.toLowerCase().contains(query) ||
                m.targetPic.toLowerCase().contains(query),
          )
          .toList();
    }
    return result;
  }

  Future<void> _openFilterBottomSheet(
    BuildContext context,
    List<Mutation> list,
  ) async {
    final Map<MutationStatus?, int> counts = {
      null: list.length,
    };
    for (final s in MutationStatus.values) {
      counts[s] = list.where((m) => m.status == s).length;
    }

    final selected = await showMutationFilterBottomSheet(
      context: context,
      currentStatus: _selectedStatus,
      counts: counts,
    );

    if (mounted) {
      setState(() {
        _selectedStatus = selected;
      });
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Color(0xFF00273A)),
            SizedBox(width: 8),
            Text(
              'Panduan Mutasi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF172B4D),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alur Pengajuan Mutasi Aset:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(height: 6),
            Text(
              '1. Pemohon mengajukan mutasi melalui tombol "+".\n'
              '2. Operator memeriksa fisik dan berkas mutasi.\n'
              '3. Kabag Aset menyetujui (dan Kadiv jika diperlukan).\n'
              '4. Staff Aset memperbarui data fisik & serah terima.\n'
              '5. Pemohon menerima notifikasi dan melakukan konfirmasi serah terima.',
              style: TextStyle(fontSize: 12, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  bool _canPop(BuildContext context) {
    try {
      return Navigator.of(context).canPop();
    } catch (_) {
      return false;
    }
  }

  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      try {
        context.go(RouteNames.pemohonDashboardPath);
      } catch (_) {}
    }
  }

  void _safePush(BuildContext context, String path) {
    try {
      context.push(path);
    } catch (_) {
      // In standalone test environment without GoRouter
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(mutationListProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      // ── Custom Refined Natural Top Bar ──────────────────────────────
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFE4E7EC), width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Back button (if canPop) & MutasiKu Corp Branding
                  Row(
                    children: [
                      if (_canPop(context))
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFF172B4D),
                            size: 20,
                          ),
                          tooltip: 'Kembali',
                          onPressed: () => _handleBack(context),
                        ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00273A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF00273A).withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.sync_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'MutasiKu',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00273A),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE1F0FF),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'CORP',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00273A),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'Manajemen Mutasi Aset',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF52606D),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Right: Help icon & User Profile Avatar
                  Row(
                    children: [
                      InkWell(
                        onTap: () => _showHelpDialog(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFD0D5DD)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.help_outline,
                            size: 19,
                            color: Color(0xFF52606D),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _safePush(context, RouteNames.pemohonProfilePath),
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 17,
                              backgroundColor: const Color(0xFF00273A),
                              child: Text(
                                user?.name.isNotEmpty == true
                                    ? user!.name[0].toUpperCase()
                                    : 'P',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF15803D),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
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
          ),
        ),
      ),

      // ── Floating Action Button (Ajukan Mutasi) ───────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _safePush(context, RouteNames.pemohonMutasiCreatePath),
        backgroundColor: const Color(0xFF00273A),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Ajukan Mutasi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 0.3,
          ),
        ),
      ),

      extendBody: true,
      bottomNavigationBar: CustomFloatingNavBar.scaffoldBottomBar(
        items: RoleNavConfig.getNavItemsForRole(UserRole.pemohon),
      ),

      body: asyncList.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(mutationListProvider),
        ),
        data: (list) {
          final filtered = _applyFilter(list);

          // Counts for quick filter tabs
          final totalCount = list.length;
          final actionCount = list
              .where(
                (m) =>
                    m.status == MutationStatus.pendingConfirmation ||
                    m.status == MutationStatus.returned,
              )
              .length;
          final inProgressCount = list
              .where(
                (m) =>
                    m.status == MutationStatus.submitted ||
                    m.status == MutationStatus.verified ||
                    m.status == MutationStatus.waitingKabagApproval ||
                    m.status == MutationStatus.waitingKadivApproval ||
                    m.status == MutationStatus.approved,
              )
              .length;
          final completedCount = list
              .where((m) => m.status == MutationStatus.completed)
              .length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Overview & Action Summary ──────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mutasi Saya',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF172B4D),
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Daftar pengajuan mutasi aset',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF52606D),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFD0D5DD)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.event_repeat,
                            size: 14,
                            color: Color(0xFF006A63),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'TA 2026',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF52606D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Search & Filter Controls ──────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD0D5DD)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x08101828),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF172B4D),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Cari kode tiket, nama aset, atau unit...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: const Color(0xFF52606D).withValues(alpha: 0.6),
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              size: 18,
                              color: Color(0xFF52606D),
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.cancel,
                                      size: 16,
                                      color: Color(0xFF52606D),
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
                    InkWell(
                      onTap: () => _openFilterBottomSheet(context, list),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedStatus != null
                                ? const Color(0xFF00273A)
                                : const Color(0xFFD0D5DD),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x08101828),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.tune,
                              size: 20,
                              color: Color(0xFF52606D),
                            ),
                            if (_selectedStatus != null)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF00273A),
                                    shape: BoxShape.circle,
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

              // ── Quick Filter Tabs (Refined Natural Chips) ─────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Row(
                  children: [
                    _quickChip(
                      label: 'Semua',
                      count: totalCount,
                      isSelected: _selectedStatus == null &&
                          _selectedTab == QuickFilterTab.all,
                      onTap: () {
                        setState(() {
                          _selectedStatus = null;
                          _selectedTab = QuickFilterTab.all;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _quickChip(
                      label: 'Perlu Tindakan',
                      count: actionCount,
                      showPulseDot: actionCount > 0,
                      isSelected: _selectedStatus == null &&
                          _selectedTab == QuickFilterTab.action,
                      onTap: () {
                        setState(() {
                          _selectedStatus = null;
                          _selectedTab = QuickFilterTab.action;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _quickChip(
                      label: 'Diproses',
                      count: inProgressCount,
                      isSelected: _selectedStatus == null &&
                          _selectedTab == QuickFilterTab.inProgress,
                      onTap: () {
                        setState(() {
                          _selectedStatus = null;
                          _selectedTab = QuickFilterTab.inProgress;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _quickChip(
                      label: 'Selesai',
                      count: completedCount,
                      isSelected: _selectedStatus == null &&
                          _selectedTab == QuickFilterTab.completed,
                      onTap: () {
                        setState(() {
                          _selectedStatus = null;
                          _selectedTab = QuickFilterTab.completed;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // ── Active Specific Status Filter Banner ──────────────
              if (_selectedStatus != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedStatus!.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedStatus!.color.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_alt,
                          size: 15,
                          color: _selectedStatus!.color,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Status: ${_selectedStatus!.displayName} (${filtered.length} data)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _selectedStatus!.color,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => _selectedStatus = null),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: _selectedStatus!.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Records List ──────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFD0D5DD),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.assignment_outlined,
                                  size: 32,
                                  color: Color(0xFF52606D),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _searchController.text.trim().isNotEmpty
                                    ? 'Tidak ada mutasi yang cocok dengan "${_searchController.text.trim()}"'
                                    : (_selectedStatus != null
                                        ? 'Tidak ada mutasi dengan status "${_selectedStatus!.displayName}"'
                                        : 'Belum ada pengajuan mutasi'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF52606D),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_searchController.text.trim().isNotEmpty)
                                OutlinedButton.icon(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.clear, size: 16),
                                  label: const Text('Hapus Pencarian'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF00273A),
                                  ),
                                )
                              else if (_selectedStatus != null ||
                                  _selectedTab != QuickFilterTab.all)
                                OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _selectedStatus = null;
                                      _selectedTab = QuickFilterTab.all;
                                    });
                                  },
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Tampilkan Semua'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF00273A),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final m = filtered[i];
                          return PemohonMutationCard(
                            mutation: m,
                            onTap: () => _safePush(
                              context,
                              RouteNames.pemohonMutasiDetailPath.replaceFirst(
                                ':id',
                                m.id,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _quickChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    bool showPulseDot = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00273A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00273A)
                : const Color(0xFFD0D5DD),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A101828),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showPulseDot) ...[
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFFB45309),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF172B4D),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : (showPulseDot
                        ? const Color(0xFFFEF0C7)
                        : const Color(0xFFE1F0FF)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : (showPulseDot
                          ? const Color(0xFFB45309)
                          : const Color(0xFF00273A)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
