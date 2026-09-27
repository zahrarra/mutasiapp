// lib/features/pemohon/presentation/screens/pemohon_dashboard_screen.dart
//
// Dashboard Pemohon — visual Stitch.
// Font: Montserrat. Navigasi: context.go (URL ikut berubah).
// Logic/provider sesuai PRD.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/router/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';
import '../../../notification/presentation/providers/notification_provider.dart';

abstract final class _S {
  static const navy = Color(0xFF0F2E42);
  static const navyCard = Color(0xFF0F3D56);
  static const surface = Color(0xFFF6F8FA);
  static const white = Color(0xFFFFFFFF);
  static const text900 = Color(0xFF0F172A);
  static const text800 = Color(0xFF1E293B);
  static const text700 = Color(0xFF334155);
  static const text600 = Color(0xFF475569);
  static const text500 = Color(0xFF64748B);
  static const text400 = Color(0xFF94A3B8);
  static const border = Color(0xFFE2E8F0);
  static const border100 = Color(0xFFF1F5F9);
  static const link = Color(0xFF18538A);
  static const emerald50 = Color(0xFFECFDF5);
  static const emerald200 = Color(0xFFA7F3D0);
  static const emerald600 = Color(0xFF059669);
  static const emerald700 = Color(0xFF047857);
  static const emerald500 = Color(0xFF10B981);
  static const sky100 = Color(0xFFE0F2FE);
  static const sky800 = Color(0xFF075985);
  static const confirmBg = Color(0xFFFFF4E5);
  static const confirmBorder = Color(0xFFFDE3B6);
  static const confirmIconBg = Color(0xFFE88625);
  static const confirmTitle = Color(0xFF8C4600);
  static const confirmBody = Color(0xFFA66115);
  static const confirmBtn = Color(0xFF8B4513);
  static const approvedBg = Color(0xFFEBF3FF);
  static const approvedText = Color(0xFF2B66CC);
  static const pendingBg = Color(0xFFFFF3E0);
  static const pendingText = Color(0xFFB76E00);
  static const slate100 = Color(0xFFF1F5F9);
}

class PemohonDashboardScreen extends ConsumerStatefulWidget {
  const PemohonDashboardScreen({super.key});

  @override
  ConsumerState<PemohonDashboardScreen> createState() =>
      _PemohonDashboardScreenState();
}

class _PemohonDashboardScreenState
    extends ConsumerState<PemohonDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  MutationStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final v = _searchController.text.trim().toLowerCase();
    if (v == _searchQuery) return;
    setState(() => _searchQuery = v);
  }

  TextStyle _montserrat({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = _S.text800,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.montserrat(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  String _detailPath(String id) =>
      RouteNames.pemohonMutasiDetailPath.replaceFirst(':id', id);

  String _confirmPath(String id) =>
      RouteNames.pemohonConfirmationPath.replaceFirst(':id', id);

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final mutationsAsync = ref.watch(mutationListProvider);
    ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      backgroundColor: _S.surface,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: _S.navyCard,
          onRefresh: () async {
            ref.invalidate(mutationListProvider);
            ref.invalidate(unreadNotificationCountProvider);
            await ref.read(mutationListProvider.future);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildHeader(user?.name ?? 'Pemohon'),
                    const SizedBox(height: 12),
                    _buildGreeting(user?.name ?? 'Pemohon'),
                    const SizedBox(height: 12),
                    _buildSummaryCard(mutationsAsync),
                    const SizedBox(height: 12),
                    _buildSearchFilter(),
                    const SizedBox(height: 12),
                    _buildConfirmationBanner(mutationsAsync),
                    const SizedBox(height: 16),
                    _buildActiveSection(mutationsAsync),
                    const SizedBox(height: 20),
                    _buildRecentSection(mutationsAsync),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader(String userName) {
    return Row(
      children: [
        _squareIconBtn(Icons.menu_rounded, () => _showMenu(context)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _S.emerald50,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _S.emerald200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: _S.emerald600,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'MUTASIKU PEMOHON',
                style: _montserrat(
                  size: 11,
                  weight: FontWeight.w600,
                  color: _S.emerald700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => context.go(RouteNames.pemohonProfilePath),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _S.navy,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  _initials(userName),
                  style: _montserrat(
                    size: 12,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _S.emerald500,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting(String userName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Divisi Operasional & Umum',
                style: _montserrat(
                  size: 12,
                  weight: FontWeight.w500,
                  color: _S.text500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: _S.emerald50,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _S.emerald200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: _S.emerald600,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Online',
                    style: _montserrat(
                      size: 11,
                      weight: FontWeight.w500,
                      color: _S.emerald700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Halo, ${_displayFirstName(userName)}!',
          style: _montserrat(
            size: 24,
            weight: FontWeight.w800,
            color: _S.text900,
            height: 1.15,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Kelola & Pantau Pengajuan Mutasi Aset',
          style: _montserrat(size: 12, color: _S.text500),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(AsyncValue<List<Mutation>> mutationsAsync) {
    final list = mutationsAsync.valueOrNull ?? const <Mutation>[];
    final active = list.where(_isActive).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _S.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: _S.navyCard.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 20,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL ASET TANGGUNG JAWAB',
                style: _montserrat(
                  size: 11,
                  weight: FontWeight.w600,
                  color: const Color(0xFFCBD5E1),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$active',
                    style: _montserrat(
                      size: 30,
                      weight: FontWeight.w800,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Aset Aktif (PIC)',
                    style: _montserrat(
                      size: 14,
                      weight: FontWeight.w500,
                      color: const Color(0xFFCBD5E1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () =>
                            context.go(RouteNames.pemohonMutasiCreatePath),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_rounded,
                                size: 18,
                                color: _S.navyCard,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Ajukan Mutasi',
                                style: _montserrat(
                                  size: 12,
                                  weight: FontWeight.w600,
                                  color: _S.navyCard,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => context.go(RouteNames.pemohonMutasiPath),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.confirmation_number_outlined,
                                size: 18,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Cek Tiket',
                                style: _montserrat(
                                  size: 12,
                                  weight: FontWeight.w500,
                                  color: Colors.white,
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilter() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: _S.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _S.border),
            ),
            child: TextField(
              controller: _searchController,
              style: _montserrat(size: 12, color: _S.text700),
              decoration: InputDecoration(
                hintText: 'Cari nomor tiket atau nama aset...',
                hintStyle: _montserrat(size: 12, color: _S.text400),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: _S.text400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _squareIconBtn(Icons.tune_rounded, () => _showFilter(context)),
      ],
    );
  }

  Widget _buildConfirmationBanner(AsyncValue<List<Mutation>> mutationsAsync) {
    final list = mutationsAsync.valueOrNull ?? const <Mutation>[];
    final pending = list
        .where((m) => m.status == MutationStatus.pendingConfirmation)
        .toList();
    if (pending.isEmpty) return const SizedBox.shrink();

    final first = pending.first;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _S.confirmBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _S.confirmBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _S.confirmIconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.fact_check_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${pending.length} Mutasi Menunggu Konfirmasi',
                  style: _montserrat(
                    size: 12,
                    weight: FontWeight.w700,
                    color: _S.confirmTitle,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Staff Aset telah selesai update data fisik. Silakan periksa & konfirmasi penerimaan.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _montserrat(
                    size: 11,
                    color: _S.confirmBody,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: _S.confirmBtn,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: () => context.go(_confirmPath(first.id)),
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text(
                  'Periksa',
                  style: _montserrat(
                    size: 11,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSection(AsyncValue<List<Mutation>> mutationsAsync) {
    final list = mutationsAsync.valueOrNull ?? const <Mutation>[];
    final active =
        list
            .where(_isActive)
            .where(_matchesSearch)
            .where(_matchesStatus)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Mutasi Dalam Proses',
              style: _montserrat(
                size: 14,
                weight: FontWeight.w700,
                color: _S.text900,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _S.sky100,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${active.length} Berjalan',
                style: _montserrat(
                  size: 11,
                  weight: FontWeight.w600,
                  color: _S.sky800,
                ),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.go(RouteNames.pemohonMutasiPath),
              child: Row(
                children: [
                  Text(
                    'Lihat Semua',
                    style: _montserrat(
                      size: 12,
                      weight: FontWeight.w600,
                      color: _S.link,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: _S.link,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (active.isEmpty)
          _emptyActiveCard()
        else
          _mutationProcessCard(active.first),
      ],
    );
  }

  Widget _emptyActiveCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _S.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _S.border100),
      ),
      child: Column(
        children: [
          Text(
            'Belum ada mutasi aktif',
            style: _montserrat(size: 13, weight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Pengajuan yang sedang berjalan akan tampil di sini.',
            textAlign: TextAlign.center,
            style: _montserrat(size: 11, color: _S.text500),
          ),
          TextButton(
            onPressed: () => context.go(RouteNames.pemohonMutasiCreatePath),
            child: Text(
              'Ajukan Mutasi',
              style: _montserrat(
                size: 12,
                weight: FontWeight.w600,
                color: _S.navyCard,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mutationProcessCard(Mutation m) {
    final step = _stitchStepIndex(m);
    const labels = [
      'Diajukan',
      'Verifikasi',
      'Disetujui',
      'Update Aset',
      'Konfirmasi',
      'Selesai',
    ];

    return Material(
      color: _S.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.go(_detailPath(m.id)),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _S.border100),
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
                children: [
                  const Icon(
                    Icons.devices_rounded,
                    size: 18,
                    color: _S.text500,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      m.displayAssetCode.isNotEmpty
                          ? m.displayAssetCode
                          : m.ticketNumber,
                      style: _montserrat(
                        size: 12,
                        weight: FontWeight.w700,
                        color: _S.text900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _statusPill(m.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                m.displayAssetName,
                style: _montserrat(
                  size: 16,
                  weight: FontWeight.w700,
                  color: _S.text800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'SN: ${m.displayAssetCode}',
                style: _montserrat(size: 12, color: _S.text500),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _S.slate100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.apartment_rounded,
                      size: 16,
                      color: _S.text400,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        m.currentLocation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _montserrat(
                          size: 12,
                          weight: FontWeight.w500,
                          color: _S.text700,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: _S.text400,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        m.targetLocation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: _montserrat(
                          size: 12,
                          weight: FontWeight.w500,
                          color: _S.text700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.apartment_rounded,
                      size: 16,
                      color: _S.text400,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 52,
                child: LayoutBuilder(
                  builder: (context, c) {
                    final w = c.maxWidth / labels.length;
                    final progress =
                        (step.clamp(0, labels.length - 1)) /
                        (labels.length - 1);
                    return Stack(
                      children: [
                        Positioned(
                          top: 10,
                          left: w / 2,
                          right: w / 2,
                          child: Container(height: 2, color: _S.border),
                        ),
                        Positioned(
                          top: 10,
                          left: w / 2,
                          width: (c.maxWidth - w) * progress,
                          child: Container(height: 2, color: _S.emerald500),
                        ),
                        Row(
                          children: [
                            for (var i = 0; i < labels.length; i++)
                              SizedBox(
                                width: w,
                                child: Column(
                                  children: [
                                    _stepDot(i, step),
                                    const SizedBox(height: 4),
                                    Text(
                                      labels[i],
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: _montserrat(
                                        size: 10,
                                        weight: i == step
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: i < step
                                            ? _S.emerald700
                                            : i == step
                                            ? _S.text900
                                            : _S.text400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, color: _S.border100),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Lihat Detail Pelacakan',
                      style: _montserrat(
                        size: 14,
                        weight: FontWeight.w600,
                        color: _S.text800,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: _S.text400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepDot(int i, int active) {
    if (i < active) {
      return Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: _S.emerald500,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
      );
    }
    if (i == active) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: _S.navyCard,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
              blurRadius: 0,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: _S.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
      ),
    );
  }

  int _stitchStepIndex(Mutation m) {
    switch (m.status) {
      case MutationStatus.submitted:
      case MutationStatus.returned:
        return 0;
      case MutationStatus.verified:
        return 1;
      case MutationStatus.waitingKabagApproval:
      case MutationStatus.waitingKadivApproval:
        return 2;
      case MutationStatus.approved:
        return 3;
      case MutationStatus.pendingConfirmation:
        return 4;
      case MutationStatus.completed:
        return 5;
      case MutationStatus.rejected:
        return 0;
    }
  }

  Widget _buildRecentSection(AsyncValue<List<Mutation>> mutationsAsync) {
    final list = mutationsAsync.valueOrNull ?? const <Mutation>[];
    final recent = list.where(_matchesSearch).where(_matchesStatus).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final items = recent.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Pengajuan Terbaru',
              style: _montserrat(
                size: 14,
                weight: FontWeight.w700,
                color: _S.text900,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.go(RouteNames.pemohonMutasiPath),
              child: Row(
                children: [
                  Text(
                    'Lihat Semua',
                    style: _montserrat(
                      size: 12,
                      weight: FontWeight.w600,
                      color: _S.link,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 14,
                    color: _S.link,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Text(
            'Belum ada pengajuan mutasi.',
            style: _montserrat(size: 12, color: _S.text500),
          )
        else
          ...items.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _recentCard(m),
            ),
          ),
      ],
    );
  }

  Widget _recentCard(Mutation m) {
    return Material(
      color: _S.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.go(_detailPath(m.id)),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _S.border100),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _S.slate100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFCBD5E1).withValues(alpha: 0.6),
                  ),
                ),
                child: Icon(_statusIcon(m.status), size: 20, color: _S.text700),
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
                            m.ticketNumber,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _montserrat(
                              size: 12,
                              weight: FontWeight.w700,
                              color: _S.text900,
                            ),
                          ),
                        ),
                        _statusPill(m.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      m.displayAssetName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _montserrat(
                        size: 11,
                        weight: FontWeight.w500,
                        color: _S.text600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${m.targetLocation}  •  ${_fmtDate(m.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _montserrat(size: 10, color: _S.text400),
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

  Widget _statusPill(MutationStatus status) {
    final bg = _pillBg(status);
    final fg = _pillFg(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == MutationStatus.approved ||
              status == MutationStatus.submitted ||
              status == MutationStatus.verified)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
          Text(
            _shortStatus(status),
            style: _montserrat(size: 10, weight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: _S.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _S.border.withValues(alpha: 0.8)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_rounded, 'Beranda', true, () {
                context.go(RouteNames.pemohonDashboardPath);
              }),
              _navItem(Icons.sync_alt_rounded, 'Mutasi', false, () {
                context.go(RouteNames.pemohonMutasiPath);
              }),
              _navItem(Icons.notifications_outlined, 'Notifikasi', false, () {
                context.go(RouteNames.pemohonNotificationsPath);
              }),
              _navItem(Icons.person_outline_rounded, 'Profil', false, () {
                context.go(RouteNames.pemohonProfilePath);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: active
                ? BoxDecoration(
                    color: _S.navyCard.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  )
                : null,
            child: Icon(
              icon,
              size: 20,
              color: active ? _S.navyCard : _S.text400,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: _montserrat(
              size: 10,
              weight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? _S.navyCard : _S.text400,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilter(BuildContext context) async {
    final selected = await showModalBottomSheet<MutationStatus?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(selectedStatus: _selectedStatus),
    );
    if (!mounted) return;
    setState(() => _selectedStatus = selected);
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _S.border,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.sync_alt_rounded),
                title: Text('Mutasi Saya', style: _montserrat(size: 14)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go(RouteNames.pemohonMutasiPath);
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_none_rounded),
                title: Text('Notifikasi', style: _montserrat(size: 14)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go(RouteNames.pemohonNotificationsPath);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: Text('Profil', style: _montserrat(size: 14)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go(RouteNames.pemohonProfilePath);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _squareIconBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: _S.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _S.border),
          ),
          child: Icon(icon, size: 20, color: _S.text700),
        ),
      ),
    );
  }

  bool _isActive(Mutation m) =>
      m.status != MutationStatus.completed &&
      m.status != MutationStatus.rejected;

  bool _matchesStatus(Mutation m) =>
      _selectedStatus == null || m.status == _selectedStatus;

  bool _matchesSearch(Mutation m) {
    if (_searchQuery.isEmpty) return true;
    final values = [
      m.ticketNumber,
      m.displayAssetName,
      m.displayAssetCode,
      m.currentLocation,
      m.targetLocation,
    ];
    return values.any((v) => v.toLowerCase().contains(_searchQuery));
  }

  String _initials(String name) {
    final p = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (p.isEmpty) return 'P';
    if (p.length == 1) {
      return p.first.length >= 2
          ? p.first.substring(0, 2).toUpperCase()
          : p.first.toUpperCase();
    }
    return '${p.first[0]}${p.last[0]}'.toUpperCase();
  }

  String _displayFirstName(String name) {
    final p = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    return p.isEmpty ? 'Pemohon' : p.first;
  }

  String _fmtDate(DateTime d) {
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

  Color _pillBg(MutationStatus s) {
    switch (s) {
      case MutationStatus.pendingConfirmation:
        return _S.pendingBg;
      case MutationStatus.returned:
        return const Color(0xFFEDF2F7);
      case MutationStatus.approved:
      case MutationStatus.completed:
      case MutationStatus.submitted:
      case MutationStatus.verified:
        return _S.approvedBg;
      case MutationStatus.waitingKabagApproval:
      case MutationStatus.waitingKadivApproval:
        return _S.pendingBg;
      case MutationStatus.rejected:
        return const Color(0xFFFEE2E2);
    }
  }

  Color _pillFg(MutationStatus s) {
    switch (s) {
      case MutationStatus.pendingConfirmation:
        return _S.pendingText;
      case MutationStatus.returned:
        return const Color(0xFF4A5568);
      case MutationStatus.approved:
      case MutationStatus.completed:
      case MutationStatus.submitted:
      case MutationStatus.verified:
        return _S.approvedText;
      case MutationStatus.waitingKabagApproval:
      case MutationStatus.waitingKadivApproval:
        return _S.pendingText;
      case MutationStatus.rejected:
        return const Color(0xFFB42318);
    }
  }

  String _shortStatus(MutationStatus s) {
    switch (s) {
      case MutationStatus.submitted:
        return 'Diajukan';
      case MutationStatus.returned:
        return 'Dikembalikan';
      case MutationStatus.waitingKabagApproval:
        return 'Menunggu Kabag';
      case MutationStatus.waitingKadivApproval:
        return 'Menunggu Kadiv';
      case MutationStatus.verified:
        return 'Terverifikasi';
      case MutationStatus.approved:
        return 'Disetujui';
      case MutationStatus.pendingConfirmation:
        return 'Menunggu Konfirmasi';
      case MutationStatus.completed:
        return 'Selesai';
      case MutationStatus.rejected:
        return 'Ditolak';
    }
  }

  IconData _statusIcon(MutationStatus s) {
    switch (s) {
      case MutationStatus.submitted:
        return Icons.send_outlined;
      case MutationStatus.returned:
        return Icons.reply_rounded;
      case MutationStatus.pendingConfirmation:
        return Icons.fact_check_outlined;
      case MutationStatus.approved:
      case MutationStatus.completed:
        return Icons.check_circle_outline;
      default:
        return Icons.devices_rounded;
    }
  }
}

class _FilterSheet extends StatelessWidget {
  final MutationStatus? selectedStatus;

  const _FilterSheet({required this.selectedStatus});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                  color: _S.border,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Text(
              'Filter Pengajuan',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _S.text900,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(context, 'Semua', null),
                for (final s in MutationStatus.values)
                  _chip(context, _label(s), s),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label, MutationStatus? value) {
    final selected = selectedStatus == value;
    return GestureDetector(
      onTap: () => Navigator.pop(context, value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _S.navyCard : _S.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _S.navyCard : _S.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _S.text500,
          ),
        ),
      ),
    );
  }

  static String _label(MutationStatus s) {
    switch (s) {
      case MutationStatus.submitted:
        return 'Diajukan';
      case MutationStatus.returned:
        return 'Dikembalikan';
      case MutationStatus.waitingKabagApproval:
        return 'Menunggu Kabag';
      case MutationStatus.waitingKadivApproval:
        return 'Menunggu Kadiv';
      case MutationStatus.verified:
        return 'Terverifikasi';
      case MutationStatus.approved:
        return 'Disetujui';
      case MutationStatus.rejected:
        return 'Ditolak';
      case MutationStatus.pendingConfirmation:
        return 'Konfirmasi';
      case MutationStatus.completed:
        return 'Selesai';
    }
  }
}
