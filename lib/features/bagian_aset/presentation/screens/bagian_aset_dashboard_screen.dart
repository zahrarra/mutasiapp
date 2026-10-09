// lib/features/bagian_aset/presentation/screens/bagian_aset_dashboard_screen.dart
//
// Dashboard Bagian Aset — UI Baseline Stitch 1:1 Pixel-Accurate
// Screen Reference: 771bf0516fe94eed81fee36dbcb8cc09 (MutasiKu — Dashboard Bagian Aset - Modern Style).
// Fitur & PRD V1.1 §6.4:
// - Verifikasi keabsahan data aset yang lolos dari Operator.
// - Menentukan/menunjuk PIC baru jika aset ditinggalkan (isAssetMovingWithApplicant == false).
// - Pemohon tidak memilih PIC; Bagian Aset bertugas menentukan PIC baru.
// - Action dialog pilih PIC baru berfungsi stabil tanpa error/white screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/widgets/custom_floating_nav_bar.dart';
import '../../../../core/widgets/inline_searchable_dropdown.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/presentation/providers/mutation_form_provider.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../providers/bagian_aset_verification_provider.dart';

/// Design tokens persis sesuai Stitch screen 771bf0516fe94eed81fee36dbcb8cc09
abstract final class _C {
  static const navy = Color(0xFF0F3D56);
  static const teal = Color(0xFF0F766E);
  static const bg = Color(0xFFF6F8FA);
  static const textPrimary = Color(0xFF172B4D);
  static const textSecondary = Color(0xFF52606D);
  static const border = Color(0xFFE2E8F0);
  static const borderLight = Color(0xFFF1F5F9);
}

class BagianAsetDashboardScreen extends ConsumerStatefulWidget {
  const BagianAsetDashboardScreen({super.key});

  @override
  ConsumerState<BagianAsetDashboardScreen> createState() =>
      _BagianAsetDashboardScreenState();
}

class _BagianAsetDashboardScreenState
    extends ConsumerState<BagianAsetDashboardScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedCategoryFilter; // null, 'lolos', 'pic', 'ti', 'umum'

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
    final val = _searchController.text.trim().toLowerCase();
    if (val != _query) {
      setState(() => _query = val);
    }
  }

  TextStyle _font({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = _C.textPrimary,
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

  bool _isITAsset(Mutation m) {
    final catCode = m.asset.category.code.trim().toUpperCase();
    final catName = m.asset.category.name.trim().toLowerCase();
    final name = m.asset.name.toLowerCase();

    // Prioritas 1: Kategori resmi TI / IT / Elektronik
    if (catCode == 'TI' || catCode == 'IT' || catCode == 'ELK') {
      return true;
    }
    // Jika kode kategori umum (FUR, VEH, dsb.)
    if (catCode == 'FUR' || catCode == 'VEH' || catCode == 'UMUM') {
      return false;
    }

    // Prioritas 2: nama kategori atau nama aset
    return catName.contains('it') ||
        catName.contains('ti') ||
        catName.contains('elektronik') ||
        catName.contains('komputer') ||
        catName.contains('hardware') ||
        catName.contains('perangkat') ||
        name.contains('thinkpad') ||
        name.contains('macbook') ||
        name.contains('laptop') ||
        name.contains('server') ||
        name.contains('pc') ||
        name.contains('monitor') ||
        name.contains('printer') ||
        name.contains('scanner');
  }

  List<Mutation> _filterMutations(List<Mutation> all) {
    // Filter antrean khusus Bagian Aset (status menunggu verifikasi aset)
    var list = all.where((m) => m.status.isWaitingAssetVerification);

    // Filter kategori cepat dari 4 stat cards
    if (_selectedCategoryFilter != null) {
      switch (_selectedCategoryFilter) {
        case 'pic':
          list = list.where(
            (m) =>
                !m.isAssetMovingWithApplicant ||
                m.targetPic.trim().isEmpty ||
                m.targetPic.trim() == '-',
          );
          break;
        case 'ti':
          list = list.where(_isITAsset);
          break;
        case 'umum':
          list = list.where((m) => !_isITAsset(m));
          break;
        case 'lolos':
        default:
          break;
      }
    }

    // Filter search text di header
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((m) {
        final ticket = m.ticketNumber.toLowerCase();
        final asset = m.asset.name.toLowerCase();
        final code = m.asset.assetCode.toLowerCase();
        final sn = m.displaySerialNumber.toLowerCase();
        final name = m.applicantName.toLowerCase();
        final loc =
            '${m.currentLocation} ${m.targetLocation} ${m.asset.location}'
                .toLowerCase();
        return ticket.contains(q) ||
            asset.contains(q) ||
            code.contains(q) ||
            sn.contains(q) ||
            name.contains(q) ||
            loc.contains(q);
      });
    }

    return list.toList();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'BA';
    if (parts.length == 1) {
      return parts.first.length >= 2
          ? parts.first.substring(0, 2).toUpperCase()
          : parts.first.toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  void _showProfileMenu(BuildContext context, dynamic user) {
    final userName = user?.name ?? 'Bagian Aset';
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _C.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: _C.teal,
                      child: Text(
                        _initials(userName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: _font(size: 15, weight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Bagian Pengelolaan Aset',
                            style: _font(size: 12, color: _C.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.person_outline_rounded,
                    color: _C.navy,
                  ),
                  title: Text(
                    'Profil Akun',
                    style: _font(size: 14, weight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push(RouteNames.profilePath);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.assignment_turned_in_outlined,
                    color: _C.navy,
                  ),
                  title: Text(
                    'Antrean Verifikasi Aset',
                    style: _font(size: 14, weight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push(RouteNames.bagianAsetVerificationsPath);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.notifications_none_rounded,
                    color: _C.navy,
                  ),
                  title: Text(
                    'Notifikasi',
                    style: _font(size: 14, weight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push(RouteNames.bagianAsetNotificationsPath);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DIALOG: PENETAPAN PIC BARU & VERIFIKASI (PRD V1.1 §6.4)
  // ──────────────────────────────────────────────────────────────────────────
  void _openPicAssignmentDialog(BuildContext context, Mutation mutation) {
    final availablePics = ref.read(availablePicsProvider);
    final picController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            final bottomInset = MediaQuery.of(dialogCtx).viewInsets.bottom;

            return Material(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: _C.border,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.person_add_rounded,
                                color: Color(0xFFB45309),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Penetapan PIC Baru',
                                    style: _font(
                                      size: 16,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Tiket: ${mutation.ticketNumber}',
                                    style: _font(
                                      size: 11,
                                      color: _C.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () =>
                                  Navigator.pop(bottomSheetContext),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Asset Brief Card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _C.bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _C.borderLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mutation.asset.name,
                                style: _font(
                                  size: 13,
                                  weight: FontWeight.w700,
                                  color: _C.navy,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'SN: ${mutation.displaySerialNumber} • Pemohon: ${mutation.applicantName}',
                                style: _font(size: 11, color: _C.textSecondary),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFFDE68A),
                                  ),
                                ),
                                child: Text(
                                  'Aset fisik ditinggalkan / masuk pool unit asal. Tentukan penanggung jawab baru sebelum diteruskan ke Pemimpin Divisi.',
                                  style: _font(
                                    size: 10.5,
                                    color: const Color(0xFF92400E),
                                    weight: FontWeight.w500,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Searchable Dropdown PIC
                        Text(
                          'Pilih PIC Baru dari Master Data *',
                          style: _font(
                            size: 12,
                            weight: FontWeight.w700,
                            color: _C.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InlineSearchableDropdown(
                          fieldKey: const Key('input_pic_baru_dashboard'),
                          labelText: 'Nama PIC Baru',
                          hintText: 'Cari atau pilih nama PIC baru...',
                          controller: picController,
                          items: availablePics,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Wajib memilih nama PIC baru';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton.icon(
                            key: const Key('btn_submit_pic_verifikasi'),
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }
                                    final selectedPic = picController.text
                                        .trim();
                                    if (selectedPic.isEmpty) return;

                                    setModalState(() => isSubmitting = true);
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    final nav = Navigator.of(
                                      bottomSheetContext,
                                    );

                                    final success = await ref
                                        .read(
                                          bagianAsetVerificationActionProvider
                                              .notifier,
                                        )
                                        .verifyAndForward(
                                          mutationId: mutation.id,
                                          newPic: selectedPic,
                                        );

                                    if (!mounted) return;
                                    nav.pop();

                                    if (success) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          backgroundColor: _C.teal,
                                          content: Text(
                                            'PIC Baru ($selectedPic) berhasil ditetapkan & diteruskan ke Pemimpin Divisi.',
                                            style: _font(
                                              size: 13,
                                              color: Colors.white,
                                              weight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      );
                                    } else {
                                      final err = ref
                                          .read(
                                            bagianAsetVerificationActionProvider,
                                          )
                                          .error;
                                      messenger.showSnackBar(
                                        SnackBar(
                                          backgroundColor: const Color(
                                            0xFFEF4444,
                                          ),
                                          content: Text(
                                            err ??
                                                'Gagal memverifikasi pengajuan.',
                                            style: _font(
                                              size: 13,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            icon: isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.check_circle_outline,
                                    size: 18,
                                  ),
                            label: Text(
                              isSubmitting
                                  ? 'Memproses...'
                                  : 'Tetapkan PIC & Teruskan ke Kadiv',
                              style: _font(
                                size: 13,
                                weight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _C.navy,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DIALOG: KONFIRMASI VERIFIKASI LANGSUNG (BAWA SENDIRI)
  // ──────────────────────────────────────────────────────────────────────────
  void _openDirectVerificationDialog(BuildContext context, Mutation mutation) {
    bool isSubmitting = false;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCFBF1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.verified_outlined,
                      color: _C.teal,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Verifikasi Data Aset',
                      style: _font(size: 16, weight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Apakah Anda yakin keabsahan data aset pada tiket ${mutation.ticketNumber} (${mutation.asset.name}) telah sesuai dan siap diteruskan ke Pemimpin Divisi?',
                    style: _font(size: 13, height: 1.4, color: _C.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _C.bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _C.borderLight),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.badge_outlined,
                          size: 16,
                          color: _C.teal,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Status PIC: Bawa Sendiri (${mutation.applicantName})',
                            style: _font(
                              size: 11,
                              weight: FontWeight.w600,
                              color: _C.navy,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text(
                    'Batal',
                    style: _font(size: 13, color: _C.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(dialogContext);

                          final success = await ref
                              .read(
                                bagianAsetVerificationActionProvider.notifier,
                              )
                              .verifyAndForward(mutationId: mutation.id);

                          if (!mounted) return;
                          nav.pop();

                          if (success) {
                            messenger.showSnackBar(
                              SnackBar(
                                backgroundColor: _C.teal,
                                content: Text(
                                  'Aset ${mutation.ticketNumber} diverifikasi dan diteruskan ke Pemimpin Divisi.',
                                  style: _font(
                                    size: 13,
                                    color: Colors.white,
                                    weight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          } else {
                            final err = ref
                                .read(
                                  bagianAsetVerificationActionProvider,
                                )
                                .error;
                            messenger.showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFFEF4444),
                                content: Text(
                                  err ?? 'Gagal memverifikasi pengajuan.',
                                  style: _font(size: 13, color: Colors.white),
                                ),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.navy,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(100, 38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Verifikasi & Teruskan',
                          style: _font(
                            size: 13,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BUILD METHOD
  // ──────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final userName = user?.name ?? 'Bagian Aset';
    final asyncMutations = ref.watch(bagianAsetAllMutationsProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      backgroundColor: _C.bg,
      body: RefreshIndicator(
        color: _C.teal,
        onRefresh: () async {
          ref.invalidate(bagianAsetAllMutationsProvider);
          await ref.read(bagianAsetAllMutationsProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // ── 1. Curved Deep Navy Header Container (Stitch 1:1) ─────────────
            SliverToBoxAdapter(
              child: _buildCurvedHeader(
                user: user,
                userName: userName,
                unreadCount: unreadCount,
                asyncMutations: asyncMutations,
              ),
            ),

            // ── 2. Body Content ──────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Quick Category Cards (Grid 2x2 — Stitch 1:1)
                  _buildQuickCategoryGrid(asyncMutations),
                  const SizedBox(height: 20),

                  // Section: Pengajuan Perlu Verifikasi Bagian Aset
                  _buildSectionHeader(asyncMutations),
                  const SizedBox(height: 12),

                  // Ticket Cards List
                  _buildTicketCardsList(asyncMutations),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomFloatingNavBar.scaffoldBottomBar(
        items: RoleNavConfig.getNavItemsForRole(UserRole.bagianAset),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 1. CURVED DEEP NAVY HEADER CONTAINER (Stitch 1:1)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildCurvedHeader({
    required dynamic user,
    required String userName,
    required int unreadCount,
    required AsyncValue<List<Mutation>> asyncMutations,
  }) {
    final topPadding = MediaQuery.of(context).padding.top;
    final waitingCount = asyncMutations.maybeWhen(
      data: (list) =>
          list.where((m) => m.status.isWaitingAssetVerification).length,
      orElse: () => 0,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _C.navy,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative background glow (HTML Stitch 1:1)
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 176,
              height: 176,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: -40,
            child: Container(
              width: 144,
              height: 144,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0F766E).withValues(alpha: 0.20),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding + 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Hamburger (kiri) & Actions (kanan) - Stitch 1:1
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Kiri: Hamburger Menu Icon (☰)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showProfileMenu(context, user),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.10),
                              width: 1.0,
                            ),
                          ),
                          child: const Icon(
                            Icons.menu_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // Kanan: Notifications & Avatar Circle
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Notifikasi Button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => context.push(
                              RouteNames.bagianAsetNotificationsPath,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.10),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 1.0,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Icon(
                                    Icons.notifications_none_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  if (unreadCount > 0)
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEF4444),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: _C.navy,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Avatar Profile Circle (solid #006a63, border 2)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showProfileMenu(context, user),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF006A63),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.30),
                                  width: 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Text(
                                    _initials(userName),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF34D399),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _C.navy,
                                          width: 2.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Title & Subtitle Row (HTML Stitch 1:1)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, $userName!',
                      style: _font(
                        size: 20,
                        weight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Staf Tata Kelola Aset • Verifikasi & Eksekusi Data Fisik',
                      style: _font(
                        size: 11,
                        weight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Search Bar Pill (Transparan Glass, TANPA putih solid - HTML Stitch 1:1)
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.20),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        size: 20,
                        color: Colors.white.withValues(alpha: 0.70),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            inputDecorationTheme: const InputDecorationTheme(
                              filled: false,
                              fillColor: Colors.transparent,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            cursorColor: Colors.white,
                            style: _font(
                              size: 13,
                              color: Colors.white,
                              weight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              filled: false,
                              fillColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              hintText:
                                  'Cari nomor tiket, kode aset, lokasi...',
                              hintStyle: _font(
                                size: 13,
                                color: Colors.white.withValues(alpha: 0.65),
                                weight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_query.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Colors.white.withValues(alpha: 0.70),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Hero Banner Card: VERIFIKASI & PEMBARUAN ASET (HTML Stitch 1:1)
                _buildHeroBannerCard(waitingCount),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HERO BANNER CARD (Curved & Deep — HTML Stitch 1:1)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildHeroBannerCard(int waitingCount) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF134E6F), Color(0xFF0B2F42)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kiri: Tag, Judul, Deskripsi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.40),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(0xFF00E5C9)
                              .withValues(alpha: 0.30),
                        ),
                      ),
                      child: Text(
                        'VERIFIKASI & PEMBARUAN ASET',
                        style: _font(
                          size: 10,
                          weight: FontWeight.w700,
                          color: const Color(0xFF99EFE5),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Antrean Verifikasi Fisik & Pembaruan Sistem',
                      style: _font(
                        size: 13,
                        weight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Verifikasi keabsahan data aset, penunjukan PIC baru dari pool, dan pembaruan master data setelah otorisasi.',
                      style: _font(
                        size: 11,
                        color: Colors.white.withValues(alpha: 0.75),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Kanan: Icon assignment_turned_in Box
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_turned_in_outlined,
                  size: 24,
                  color: Color(0xFF99EFE5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tombol Kelola Antrean Aset
                ElevatedButton(
                  key: const Key('btn_hero_review_pengajuan'),
                  onPressed: () {
                    ref.read(bagianAsetStatusFilterProvider.notifier).state =
                        BagianAsetStatusFilter.waiting;
                    context.push(RouteNames.bagianAsetVerificationsPath);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 1,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Kelola Antrean Aset',
                        style: _font(
                          size: 12,
                          weight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),

                // Counter Perlu Tindakan
                GestureDetector(
                  key: const Key('btn_hero_perlu_tindakan'),
                  onTap: () {
                    ref.read(bagianAsetStatusFilterProvider.notifier).state =
                        BagianAsetStatusFilter.waiting;
                    context.push(RouteNames.bagianAsetVerificationsPath);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00E5C9),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$waitingCount',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F3D56),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Perlu Tindakan',
                        style: _font(
                          size: 11,
                          weight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.90),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 2. QUICK CATEGORY CARDS (Grid 2x2 — HTML Stitch 1:1)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildQuickCategoryGrid(AsyncValue<List<Mutation>> asyncMutations) {
    final list = asyncMutations.maybeWhen(
      data: (items) =>
          items.where((m) => m.status.isWaitingAssetVerification).toList(),
      orElse: () => <Mutation>[],
    );

    final countLolos = list.length;
    final countNeedsPic = list
        .where(
          (m) =>
              !m.isAssetMovingWithApplicant ||
              m.targetPic.trim().isEmpty ||
              m.targetPic.trim() == '-',
        )
        .length;
    final countTI = list.where(_isITAsset).length;
    final countUmum = list.where((m) => !_isITAsset(m)).length;

    return Column(
      children: [
        Row(
          children: [
            // Card 1: Lolos Operator (Segera, Tiket)
            Expanded(
              child: _buildCategoryCard(
                key: const Key('card_filter_lolos'),
                icon: Icons.verified_outlined,
                iconColor: const Color(0xFF047857),
                iconBg: const Color(0xFFECFDF5),
                badgeText: 'Segera',
                badgeBg: const Color(0xFFFFFBEB),
                badgeTextColor: const Color(0xFFB45309),
                badgeBorderColor: const Color(0xFFFDE68A),
                count: countLolos,
                unit: 'Tiket',
                title: 'Lolos Operator',
                subtitle: 'Menunggu verifikasi aset',
                countColor: const Color(0xFF0F3D56),
                isSelected: _selectedCategoryFilter == 'lolos',
                onTap: () {
                  setState(() {
                    _selectedCategoryFilter = _selectedCategoryFilter == 'lolos'
                        ? null
                        : 'lolos';
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            // Card 2: Penetapan PIC (Pool, Tiket)
            Expanded(
              child: _buildCategoryCard(
                key: const Key('card_filter_pic'),
                icon: Icons.person_add_outlined,
                iconColor: const Color(0xFF0F766E),
                iconBg: const Color(0xFF0F766E).withValues(alpha: 0.10),
                badgeText: 'Pool',
                badgeBg: const Color(0xFFF0FDFA),
                badgeTextColor: const Color(0xFF0F766E),
                badgeBorderColor: const Color(0xFF99F6E4),
                count: countNeedsPic,
                unit: 'Tiket',
                title: 'Penetapan PIC',
                subtitle: 'Aset ditinggal / masuk pool',
                countColor: const Color(0xFF0F766E),
                isSelected: _selectedCategoryFilter == 'pic',
                onTap: () {
                  setState(() {
                    _selectedCategoryFilter = _selectedCategoryFilter == 'pic'
                        ? null
                        : 'pic';
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Card 3: Aset TI (TI, Unit)
            Expanded(
              child: _buildCategoryCard(
                key: const Key('card_filter_ti'),
                icon: Icons.devices_outlined,
                iconColor: const Color(0xFF1D4ED8),
                iconBg: const Color(0xFFEFF6FF),
                badgeText: 'TI',
                badgeBg: const Color(0xFFEFF6FF),
                badgeTextColor: const Color(0xFF1D4ED8),
                badgeBorderColor: const Color(0xFFBFDBFE),
                count: countTI,
                unit: 'Unit',
                title: 'Aset TI',
                subtitle: 'Infrastruktur & komputer',
                countColor: const Color(0xFF172B4D),
                isSelected: _selectedCategoryFilter == 'ti',
                onTap: () {
                  setState(() {
                    _selectedCategoryFilter = _selectedCategoryFilter == 'ti'
                        ? null
                        : 'ti';
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            // Card 4: Aset Umum (Umum, Unit)
            Expanded(
              child: _buildCategoryCard(
                key: const Key('card_filter_umum'),
                icon: Icons.chair_outlined,
                iconColor: const Color(0xFFB45309),
                iconBg: const Color(0xFFFFFBEB),
                badgeText: 'Umum',
                badgeBg: const Color(0xFFF1F5F9),
                badgeTextColor: const Color(0xFF64748B),
                badgeBorderColor: const Color(0xFFE2E8F0),
                count: countUmum,
                unit: 'Unit',
                title: 'Aset Umum',
                subtitle: 'Furnitur & fasilitas kantor',
                countColor: const Color(0xFF0F3D56),
                isSelected: _selectedCategoryFilter == 'umum',
                onTap: () {
                  setState(() {
                    _selectedCategoryFilter = _selectedCategoryFilter == 'umum'
                        ? null
                        : 'umum';
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    Key? key,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String badgeText,
    required Color badgeBg,
    required Color badgeTextColor,
    required Color badgeBorderColor,
    required int count,
    required String unit,
    required String title,
    required String subtitle,
    Color? countColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      key: key,
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? _C.teal : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? _C.teal.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris atas: Icon Box & Badge Pill (HTML Stitch 1:1)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: badgeBorderColor, width: 1.0),
                    ),
                    child: Text(
                      badgeText,
                      style: _font(
                        size: 10,
                        weight: FontWeight.w600,
                        color: badgeTextColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Angka & Unit
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$count',
                    style: _font(
                      size: 20,
                      weight: FontWeight.w800,
                      color: countColor ?? const Color(0xFF0F3D56),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: _font(
                      size: 11,
                      weight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),

              // Title & Subtitle
              Text(
                title,
                style: _font(
                  size: 12,
                  weight: FontWeight.w700,
                  color: const Color(0xFF172B4D),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: _font(size: 10, color: const Color(0xFF52606D)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 3. SECTION HEADER: Pengajuan Perlu Verifikasi Bagian Aset
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildSectionHeader(AsyncValue<List<Mutation>> asyncMutations) {
    final count = asyncMutations.maybeWhen(
      data: (items) =>
          items.where((m) => m.status.isWaitingAssetVerification).length,
      orElse: () => 0,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pengajuan Perlu Verifikasi Bagian Aset',
              style: _font(
                size: 13,
                weight: FontWeight.w700,
                color: _C.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFFF59E0B),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        InkWell(
          key: const Key('btn_dashboard_lihat_semua'),
          onTap: () {
            ref.read(bagianAsetStatusFilterProvider.notifier).state =
                BagianAsetStatusFilter.waiting;
            context.push(RouteNames.bagianAsetVerificationsPath);
          },
          borderRadius: BorderRadius.circular(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Lihat Semua ($count)',
                style: _font(size: 11, weight: FontWeight.w600, color: _C.teal),
              ),
              const Icon(Icons.chevron_right_rounded, size: 14, color: _C.teal),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 4. TICKET CARDS LIST (Stitch 1:1 Pixel-Accurate)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildTicketCardsList(AsyncValue<List<Mutation>> asyncMutations) {
    return asyncMutations.when(
      data: (mutations) {
        final filteredList = _filterMutations(mutations);

        if (filteredList.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredList.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final mutation = filteredList[index];
            return _buildTicketCard(mutation);
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(strokeWidth: 2, color: _C.teal),
        ),
      ),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Column(
          children: [
            Text(
              'Gagal memuat antrean mutasi: $err',
              style: _font(size: 13, color: const Color(0xFFEF4444)),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => ref.invalidate(kabagAllMutationsProvider),
              icon: const Icon(
                Icons.refresh,
                size: 16,
                color: Color(0xFFEF4444),
              ),
              label: const Text(
                'Coba Lagi',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(Mutation mutation) {
    final isMovingWithApplicant = mutation.isAssetMovingWithApplicant;
    final isIT = _isITAsset(mutation);
    final needsPic =
        !isMovingWithApplicant ||
        mutation.targetPic.trim().isEmpty ||
        mutation.targetPic.trim() == '-';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.push(
              RouteNames.bagianAsetVerificationDetailPath.replaceFirst(
                ':id',
                mutation.id,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Row: Ticket ID & Status Badge (Stitch 1:1) ──────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.confirmation_number_outlined,
                          size: 15,
                          color: _C.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          mutation.ticketNumber,
                          style: _font(
                            size: 12,
                            weight: FontWeight.w700,
                            color: _C.navy,
                          ),
                        ),
                      ],
                    ),
                    // Status Badge
                    if (mutation.returnReason != null &&
                        mutation.returnReason!.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0xFFFDE68A),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '⚠️ Konfirmasi Fisik Tidak Sesuai',
                          style: _font(
                            size: 9.5,
                            weight: FontWeight.w600,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                      )
                    else if (isMovingWithApplicant)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDFA),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0xFF99F6E4),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Lolos Operator — Verifikasi Aset',
                          style: _font(
                            size: 9.5,
                            weight: FontWeight.w600,
                            color: const Color(0xFF115E59),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0xFFFDE68A),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF59E0B),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Perlu Tentukan PIC Baru',
                              style: _font(
                                size: 9.5,
                                weight: FontWeight.w600,
                                color: const Color(0xFF92400E),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: _C.borderLight),
                const SizedBox(height: 12),

                // ── Asset Info Row (Stitch 1:1) ──────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Box
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isIT
                            ? const Color(0xFFEFF6FF)
                            : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isIT ? Icons.laptop_mac_rounded : Icons.chair_rounded,
                        size: 22,
                        color: isIT
                            ? const Color(0xFF1D4ED8)
                            : const Color(0xFFB45309),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isIT
                                      ? const Color(0xFFEFF6FF)
                                      : const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isIT ? 'LAPTOP / IT' : 'FURNITUR / UMUM',
                                  style: _font(
                                    size: 9,
                                    weight: FontWeight.w700,
                                    color: isIT
                                        ? const Color(0xFF1D4ED8)
                                        : const Color(0xFFB45309),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'SN: ${mutation.displaySerialNumber}',
                                style: _font(size: 11, color: _C.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            mutation.asset.name,
                            style: _font(
                              size: 13.5,
                              weight: FontWeight.w700,
                              color: _C.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isMovingWithApplicant
                                ? '${mutation.applicantName} • ${mutation.currentLocation} → ${mutation.targetLocation}'
                                : '${mutation.applicantName} • Eks ${mutation.currentLocation}',
                            style: _font(size: 11, color: _C.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Status PIC Box (Stitch 1:1) ──────────────────────────────
                if (isMovingWithApplicant)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.borderLight),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.badge_outlined,
                              size: 16,
                              color: _C.teal,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Status PIC: ',
                              style: _font(size: 11, color: _C.textSecondary),
                            ),
                            Text(
                              'Bawa Sendiri',
                              style: _font(
                                size: 11,
                                weight: FontWeight.w600,
                                color: _C.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDFA),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Otomatis: ${mutation.applicantName}',
                            style: _font(
                              size: 10,
                              weight: FontWeight.w600,
                              color: _C.teal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB).withValues(alpha: 0.60),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFDE68A).withValues(alpha: 0.60),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.person_add_outlined,
                              size: 16,
                              color: Color(0xFFB45309),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Status PIC: ',
                              style: _font(size: 11, color: _C.textSecondary),
                            ),
                            Text(
                              'Ditinggal / Masuk Pool',
                              style: _font(
                                size: 11,
                                weight: FontWeight.w600,
                                color: const Color(0xFF78350F),
                              ),
                            ),
                          ],
                        ),
                        if (needsPic)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFFDE68A),
                              ),
                            ),
                            child: Text(
                              'PIC Baru Kosong',
                              style: _font(
                                size: 10,
                                weight: FontWeight.w700,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDFA),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF99F6E4),
                              ),
                            ),
                            child: Text(
                              'PIC: ${mutation.targetPic}',
                              style: _font(
                                size: 10,
                                weight: FontWeight.w600,
                                color: _C.teal,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),

                // ── Action Button (Stitch 1:1) ───────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    key: Key('btn_action_${mutation.id}'),
                    onPressed: () {
                      if (needsPic) {
                        _openPicAssignmentDialog(context, mutation);
                      } else {
                        _openDirectVerificationDialog(context, mutation);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.navy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          needsPic
                              ? 'Tentukan PIC & Verifikasi'
                              : 'Verifikasi & Teruskan ke Kadiv',
                          style: _font(
                            size: 13,
                            weight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 15,
                          color: Colors.white,
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
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.borderLight),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF99F6E4)),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 28,
              color: _C.teal,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Semua Aset Telah Diverifikasi',
            style: _font(size: 14, weight: FontWeight.w700, color: _C.navy),
          ),
          const SizedBox(height: 4),
          Text(
            _query.isNotEmpty || _selectedCategoryFilter != null
                ? 'Tidak ada pengajuan mutasi yang cocok dengan filter aktif.'
                : 'Tidak ada pengajuan yang memerlukan verifikasi Bagian Aset saat ini.',
            textAlign: TextAlign.center,
            style: _font(size: 12, color: _C.textSecondary, height: 1.35),
          ),
          if (_query.isNotEmpty || _selectedCategoryFilter != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _query = '';
                  _selectedCategoryFilter = null;
                });
              },
              icon: const Icon(Icons.refresh, size: 16, color: _C.teal),
              label: Text(
                'Reset Filter',
                style: _font(size: 12, weight: FontWeight.w600, color: _C.teal),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
