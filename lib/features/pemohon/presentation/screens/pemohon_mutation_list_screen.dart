// lib/features/pemohon/presentation/screens/pemohon_mutation_list_screen.dart
//
// Mutasi Saya — visual Stitch (HTML yang dikirim).
// Font: Inter. Logic: search, filter chip, status, navigasi, FAB.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mutasiku/core/widgets/custom_floating_nav_bar.dart';
import 'package:mutasiku/core/widgets/error_view.dart';
import 'package:mutasiku/core/widgets/mutasiku_page_header.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';

import '../../../../app/router/route_names.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';

enum _QuickFilter { all, progress, done, action }

abstract final class _C {
  static const background = Color(0xFFF6F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFF00273A);
  static const primaryContainer = Color(0xFF0F3D56);
  static const secondary = Color(0xFF006A63);
  static const textPrimary = Color(0xFF172B4D);
  static const textSecondary = Color(0xFF52606D);
  static const border = Color(0xFFD0D5DD);
  static const warning = Color(0xFFB45309);
  static const success = Color(0xFF15803D);
  static const surfaceContainer = Color(0xFFE1F0FF);
}

class PemohonMutationListScreen extends ConsumerStatefulWidget {
  final String? initialFilter;

  const PemohonMutationListScreen({
    super.key,
    this.initialFilter,
  });

  @override
  ConsumerState<PemohonMutationListScreen> createState() =>
      _PemohonMutationListScreenState();
}

class _PemohonMutationListScreenState
    extends ConsumerState<PemohonMutationListScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  _QuickFilter _filter = _QuickFilter.all;

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null) {
      _filter = _parseFilter(widget.initialFilter);
    }
    _searchController.addListener(() {
      final q = _searchController.text.trim().toLowerCase();
      if (q != _query) setState(() => _query = q);
    });
  }

  @override
  void didUpdateWidget(covariant PemohonMutationListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFilter != oldWidget.initialFilter &&
        widget.initialFilter != null) {
      setState(() {
        _filter = _parseFilter(widget.initialFilter);
      });
    }
  }

  static _QuickFilter _parseFilter(String? value) {
    if (value == null) return _QuickFilter.all;
    final v = value.toLowerCase().trim();
    if (v == 'progress' || v == 'dalam proses' || v == 'dalamproses') {
      return _QuickFilter.progress;
    }
    if (v == 'action' || v == 'perlu tindakan' || v == 'perlutindakan') {
      return _QuickFilter.action;
    }
    if (v == 'done' || v == 'selesai' || v == 'completed') {
      return _QuickFilter.done;
    }
    return _QuickFilter.all;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  TextStyle _inter({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = _C.textPrimary,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  List<Mutation> _filterList(List<Mutation> list) {
    var result = list;
    switch (_filter) {
      case _QuickFilter.all:
        break;
      case _QuickFilter.progress:
        result = result
            .where(
              (m) =>
                  m.status == MutationStatus.submitted ||
                  m.status == MutationStatus.waitingAssetVerification ||
                  m.status == MutationStatus.verified ||
                  m.status == MutationStatus.waitingDivisionHeadApproval ||
                  m.status == MutationStatus.waitingKadivApproval ||
                  m.status == MutationStatus.approved ||
                  m.status == MutationStatus.waitingSync,
            )
            .toList();
        break;
      case _QuickFilter.done:
        result = result
            .where((m) => m.status == MutationStatus.completed)
            .toList();
        break;
      case _QuickFilter.action:
        result = result
            .where(
              (m) =>
                  m.status == MutationStatus.waitingConfirmation ||
                  m.status == MutationStatus.pendingConfirmation ||
                  m.status == MutationStatus.returned,
            )
            .toList();
        break;
    }
    if (_query.isNotEmpty) {
      result = result.where((m) {
        final hay = [
          m.ticketNumber,
          m.displayAssetName,
          m.displayAssetCode,
          m.displaySerialNumber,
          m.currentLocation,
          m.targetLocation,
          m.targetPic,
        ].join(' ').toLowerCase();
        return hay.contains(_query);
      }).toList();
    }
    result = [...result]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  int _count(List<Mutation> list, _QuickFilter f) {
    switch (f) {
      case _QuickFilter.all:
        return list.length;
      case _QuickFilter.progress:
        return list
            .where(
              (m) =>
                  m.status == MutationStatus.submitted ||
                  m.status == MutationStatus.waitingAssetVerification ||
                  m.status == MutationStatus.verified ||
                  m.status == MutationStatus.waitingDivisionHeadApproval ||
                  m.status == MutationStatus.waitingKadivApproval ||
                  m.status == MutationStatus.approved ||
                  m.status == MutationStatus.waitingSync,
            )
            .length;
      case _QuickFilter.done:
        return list.where((m) => m.status == MutationStatus.completed).length;
      case _QuickFilter.action:
        return list
            .where(
              (m) =>
                  m.status == MutationStatus.waitingConfirmation ||
                  m.status == MutationStatus.pendingConfirmation ||
                  m.status == MutationStatus.returned,
            )
            .length;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(mutationListProvider);
    final all = asyncList.valueOrNull ?? const <Mutation>[];
    final filtered = _filterList(all);

    return Scaffold(
      backgroundColor: _C.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              color: _C.primaryContainer,
              onRefresh: () async {
                ref.invalidate(mutationListProvider);
                await ref.read(mutationListProvider.future);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildTitle(all.length),
                        const SizedBox(height: 12),
                        _buildSearch(),
                        const SizedBox(height: 12),
                        _buildChips(all),
                        const SizedBox(height: 12),
                        if (asyncList.isLoading && all.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (asyncList.hasError && all.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: ErrorView(
                              message: asyncList.error
                                  .toString()
                                  .replaceFirst('Exception: ', ''),
                              onRetry: () =>
                                  ref.invalidate(mutationListProvider),
                            ),
                          )
                        else if (filtered.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Tidak ada pengajuan.',
                              textAlign: TextAlign.center,
                              style: _inter(size: 13, color: _C.textSecondary),
                            ),
                          )
                        else
                          ...filtered.map(
                            (m) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _MutationCard(mutation: m, style: _inter),
                            ),
                          ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: const _SnugEndFloatFabLocation(gap: 10.0),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.pushNamed(RouteNames.pemohonMutasiCreateName),
        backgroundColor: _C.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
        label: Text(
          'Ajukan Mutasi',
          style: _inter(
            size: 14,
            weight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      bottomNavigationBar: CustomFloatingNavBar.scaffoldBottomBar(
        items: RoleNavConfig.getNavItemsForRole(UserRole.pemohon),
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: MutasiKuPageHeader(
        title: 'Mutasi Saya',
        subtitle: 'Daftar pengajuan mutasi aset internal',
        roleLabel: 'PEMOHON',
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(RouteNames.pemohonDashboardPath);
          }
        },
      ),
    );
  }

  Widget _buildTitle(int total) {
    return const SizedBox.shrink();
  }

  Widget _buildSearch() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.border.withValues(alpha: 0.7)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: _inter(size: 13, weight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Cari no. tiket, aset, tujuan...',
                hintStyle: _inter(
                  size: 13,
                  color: _C.textSecondary.withValues(alpha: 0.6),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: _C.textSecondary,
                ),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: _searchController.clear,
                        icon: const Icon(Icons.cancel, size: 16),
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: _C.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => _showFilterSheet(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.border.withValues(alpha: 0.7)),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: _C.textSecondary,
                    ),
                  ),
                  if (_filter != _QuickFilter.all)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: _C.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            child: SafeArea(
              top: false,
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: _C.border,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Text(
                  'Filter Mutasi Saya',
                  style: _inter(
                    size: 16,
                    weight: FontWeight.w800,
                    color: _C.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.apps_rounded, color: _C.primaryContainer),
                  title: Text('Semua Pengajuan', style: _inter(size: 14, weight: FontWeight.w600)),
                  trailing: _filter == _QuickFilter.all
                      ? const Icon(Icons.check_circle_rounded, color: _C.secondary)
                      : null,
                  onTap: () {
                    setState(() => _filter = _QuickFilter.all);
                    Navigator.pop(sheetContext);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.sync_rounded, color: Color(0xFF175CD3)),
                  title: Text('Dalam Proses', style: _inter(size: 14, weight: FontWeight.w600)),
                  trailing: _filter == _QuickFilter.progress
                      ? const Icon(Icons.check_circle_rounded, color: _C.secondary)
                      : null,
                  onTap: () {
                    setState(() => _filter = _QuickFilter.progress);
                    Navigator.pop(sheetContext);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.assignment_turned_in_rounded, color: _C.warning),
                  title: Text('Perlu Tindakan (Konfirmasi & Revisi)', style: _inter(size: 14, weight: FontWeight.w600)),
                  trailing: _filter == _QuickFilter.action
                      ? const Icon(Icons.check_circle_rounded, color: _C.secondary)
                      : null,
                  onTap: () {
                    setState(() => _filter = _QuickFilter.action);
                    Navigator.pop(sheetContext);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.verified_rounded, color: _C.success),
                  title: Text('Selesai', style: _inter(size: 14, weight: FontWeight.w600)),
                  trailing: _filter == _QuickFilter.done
                      ? const Icon(Icons.check_circle_rounded, color: _C.secondary)
                      : null,
                  onTap: () {
                    setState(() => _filter = _QuickFilter.done);
                    Navigator.pop(sheetContext);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  }

  Widget _buildChips(List<Mutation> all) {
    Widget chip(String label, _QuickFilter f) {
      final active = _filter == f;
      final n = _count(all, f);
      return Material(
        color: active ? _C.primary : _C.surface,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: () => setState(() => _filter = f),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: active ? null : Border.all(color: _C.border),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: _inter(
                    size: 12,
                    weight: FontWeight.w600,
                    color: active ? Colors.white : _C.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white.withValues(alpha: 0.25)
                        : _C.surfaceContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$n',
                    style: _inter(
                      size: 10,
                      weight: FontWeight.w700,
                      color: active ? Colors.white : _C.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('Semua', _QuickFilter.all),
          const SizedBox(width: 8),
          chip('Dalam Proses', _QuickFilter.progress),
          const SizedBox(width: 8),
          chip('Perlu Tindakan', _QuickFilter.action),
          const SizedBox(width: 8),
          chip('Selesai', _QuickFilter.done),
        ],
      ),
    );
  }

}

class _MutationCard extends StatelessWidget {
  final Mutation mutation;
  final TextStyle Function({
    double size,
    FontWeight weight,
    Color color,
    double? height,
    double? letterSpacing,
  })
  style;

  const _MutationCard({required this.mutation, required this.style});

  @override
  Widget build(BuildContext context) {
    final m = mutation;
    final status = m.status;

    return Material(
      color: _C.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => context.pushNamed(
          RouteNames.pemohonMutasiDetailName,
          pathParameters: {'id': m.id},
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.border.withValues(alpha: 0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${m.ticketNumber}  •  ${_fmt(m.createdAt)}',
                      style: style(
                        size: 11,
                        weight: FontWeight.w600,
                        color: _C.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _badge(m),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                m.displayAssetName,
                style: style(size: 14, weight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      m.currentLocation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: style(
                        size: 12,
                        weight: FontWeight.w500,
                        color: _C.textPrimary,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 13,
                      color: _C.textSecondary,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      m.targetLocation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: style(
                        size: 12,
                        weight: FontWeight.w500,
                        color: _C.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              if (status == MutationStatus.returned &&
                  (m.returnReason?.isNotEmpty ?? false)) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      m.staffUpdatedAt != null
                          ? Icons.hourglass_top
                          : Icons.info_outline,
                      size: 13,
                      color: m.staffUpdatedAt != null
                          ? const Color(0xFF175CD3)
                          : _C.warning,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        m.returnReason!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: style(
                          size: 11,
                          color: m.staffUpdatedAt != null
                              ? const Color(0xFF175CD3)
                              : _C.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0x33D0D5DD)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _footerLeft(m),
                      style: style(size: 11, color: _C.textSecondary),
                    ),
                  ),
                  if (status == MutationStatus.waitingConfirmation ||
                      status == MutationStatus.pendingConfirmation)
                    _actionBtn(
                      context,
                      'Konfirmasi Diterima',
                      filled: true,
                      onTap: () => context.pushNamed(
                        RouteNames.pemohonConfirmationName,
                        pathParameters: {'id': m.id},
                      ),
                    )
                  else if (status == MutationStatus.returned &&
                      m.staffUpdatedAt == null)
                    // Operator mengembalikan pengajuan di tahap awal
                    // (sebelum verifikasi Bagian Aset) → pemohon memang perlu
                    // memperbaiki data pengajuannya.
                    _actionBtn(
                      context,
                      'Perbaiki Berkas',
                      filled: false,
                      onTap: () => context.pushNamed(
                        RouteNames.pemohonMutasiEditName,
                        pathParameters: {'id': m.id},
                      ),
                    )
                  else if (status == MutationStatus.returned &&
                      m.staffUpdatedAt != null)
                    // Pemohon sudah melaporkan ketidaksesuaian; tidak ada
                    // tindakan lain yang perlu ia lakukan — tinggal menunggu
                    // Bagian Aset memperbaiki data.
                    Text(
                      'Menunggu perbaikan Bagian Aset',
                      style: style(
                        size: 11,
                        weight: FontWeight.w500,
                        color: const Color(0xFF175CD3),
                      ),
                    )
                  else if (status == MutationStatus.completed)
                    Text(
                      'BAST Terbit',
                      style: style(
                        size: 11,
                        weight: FontWeight.w500,
                        color: _C.success,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(Mutation m) {
    final s = m.status;
    // Heuristik yang sama dengan pemohon_confirmation_screen.dart: jika
    // status returned TAPI staffUpdatedAt sudah terisi, ini adalah laporan
    // ketidaksesuaian yang dikirim Pemohon setelah Bagian Aset update data —
    // bukan pengembalian pengajuan oleh Operator. Pemohon tidak perlu
    // "memperbaiki" apa pun di sini, sehingga label & warna dibedakan.
    final isDisputedByApplicant =
        s == MutationStatus.returned && m.staffUpdatedAt != null;

    final (bg, fg, label) = switch (s) {
      MutationStatus.waitingConfirmation ||
      MutationStatus.pendingConfirmation => (
        _C.primary,
        Colors.white,
        'Perlu Tindakan',
      ),
      MutationStatus.returned when isDisputedByApplicant => (
        const Color(0xFFEFF6FF),
        const Color(0xFF175CD3),
        'Menunggu Bagian Aset',
      ),
      MutationStatus.returned => (
        _C.warning.withValues(alpha: 0.15),
        _C.warning,
        'Perlu Perbaikan',
      ),
      MutationStatus.completed => (
        _C.success.withValues(alpha: 0.15),
        _C.success,
        'Selesai',
      ),
      MutationStatus.waitingAssetVerification => (
        _C.warning.withValues(alpha: 0.1),
        _C.warning,
        'Verifikasi Aset',
      ),
      MutationStatus.waitingDivisionHeadApproval ||
      MutationStatus.waitingKadivApproval => (
        _C.warning.withValues(alpha: 0.1),
        _C.warning,
        'Approval Kadiv',
      ),
      MutationStatus.approved => (
        _C.warning.withValues(alpha: 0.1),
        _C.warning,
        'Disetujui',
      ),
      MutationStatus.submitted => (_C.surfaceContainer, _C.primary, 'Diajukan'),
      MutationStatus.verified => (
        _C.surfaceContainer,
        _C.primary,
        'Terverifikasi',
      ),
      MutationStatus.rejected => (
        const Color(0xFFFEE2E2),
        const Color(0xFFB42318),
        'Ditolak',
      ),
      MutationStatus.waitingSync => (
        _C.surfaceContainer,
        _C.primary,
        'Offline',
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: isDisputedByApplicant
            ? Border.all(color: const Color(0xFF175CD3).withValues(alpha: 0.3))
            : (s == MutationStatus.returned)
            ? Border.all(color: _C.warning.withValues(alpha: 0.3))
            : null,
      ),
      child: Text(
        label,
        style: style(size: 10, weight: FontWeight.w600, color: fg),
      ),
    );
  }

  Widget _actionBtn(
    BuildContext context,
    String label, {
    required bool filled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: filled ? _C.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: filled ? null : Border.all(color: _C.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: style(
                  size: 11,
                  weight: FontWeight.w700,
                  color: filled ? Colors.white : _C.primary,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.arrow_forward,
                size: 13,
                color: filled ? Colors.white : _C.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _footerLeft(Mutation m) {
    if (m.status == MutationStatus.completed) return '';
    if (m.status == MutationStatus.returned ||
        m.status == MutationStatus.waitingConfirmation ||
        m.status == MutationStatus.pendingConfirmation) {
      return m.displayAssetCode;
    }
    return 'Tahap: ${_stage(m.status)}';
  }

  String _stage(MutationStatus s) {
    switch (s) {
      case MutationStatus.submitted:
        return 'Diajukan';
      case MutationStatus.returned:
        return 'Perlu Perbaikan';
      case MutationStatus.verified:
        return 'Verifikasi';
      case MutationStatus.waitingAssetVerification:
        return 'Verifikasi Aset';
      case MutationStatus.waitingKadivApproval:
        return 'Kadiv Review';
      case MutationStatus.approved:
        return 'Disetujui';
      default:
        return s.displayName;
    }
  }

  String _fmt(DateTime d) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}

/// Floating action button location that positions the FAB snugly above the
/// bottom navigation bar with a custom gap (default 10dp) anchored to the end.
class _SnugEndFloatFabLocation extends StandardFabLocation
    with FabEndOffsetX, FabFloatOffsetY {
  final double gap;
  const _SnugEndFloatFabLocation({this.gap = 10.0});

  @override
  double getOffsetY(
    ScaffoldPrelayoutGeometry scaffoldGeometry,
    double adjustment,
  ) {
    // In FabFloatOffsetY, safeMargin is max(16.0, ...).
    // Adding (16.0 - gap) moves the FAB down so the gap between the FAB bottom
    // and contentBottom (top edge of bottomNavigationBar) is precisely `gap` dp (e.g., 10 dp).
    return super.getOffsetY(scaffoldGeometry, 16.0 - gap + adjustment);
  }
}
