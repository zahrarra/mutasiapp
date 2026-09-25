// lib/features/pemohon/presentation/screens/pemohon_confirmation_screen.dart
//
// Screen: MutasiKu — Konfirmasi Mutasi (Interactive & Dynamic)
// Diadaptasi dari desain Stitch MCP.
// Memungkinkan Pemohon memvalidasi hasil update Staff Aset secara interaktif
// dengan checklist verifikasi fisik dinamis sebelum melakukan konfirmasi akhir atau sanggahan.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';
import '../../../notification/domain/entities/notification_item.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../providers/pemohon_confirmation_provider.dart';

class PemohonConfirmationScreen extends ConsumerStatefulWidget {
  final String mutationId;

  const PemohonConfirmationScreen({super.key, required this.mutationId});

  @override
  ConsumerState<PemohonConfirmationScreen> createState() =>
      _PemohonConfirmationScreenState();
}

class _PemohonConfirmationScreenState
    extends ConsumerState<PemohonConfirmationScreen> {
  bool _checkSn = true;
  bool _checkLocation = true;
  bool _checkPic = true;
  bool _copiedSn = false;

  void _safePop(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      try {
        context.go(RouteNames.pemohonMutasiPath);
      } catch (_) {}
    }
  }

  bool _isMutationOwnedBy(Mutation mutation, User? user) {
    if (user == null) return true;
    if (user.role != UserRole.pemohon) return true;

    if (mutation.applicantId != null && mutation.applicantId == user.id) {
      return true;
    }
    if ((user.id == 'usr_pemohon' ||
            user.id == 'usr_101' ||
            user.id == 'user_pemohon') &&
        mutation.applicantId == 'usr_pemohon') {
      return true;
    }
    if (mutation.applicantName.trim().toLowerCase() ==
        user.name.trim().toLowerCase()) {
      return true;
    }
    return false;
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    const months = [
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
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$day ${months[dt.month - 1]} ${dt.year}, $hour:$min WIB';
  }

  @override
  Widget build(BuildContext context) {
    final asyncMutation = ref.watch(mutationDetailProvider(widget.mutationId));
    final actionState = ref.watch(pemohonConfirmationActionProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      // ── Custom Interactive Top App Bar ──────────────────────────────
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
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF172B4D),
                          size: 20,
                        ),
                        tooltip: 'Kembali',
                        onPressed: () => _safePop(context),
                      ),
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Konfirmasi Mutasi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF172B4D),
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            'Verifikasi Fisik & Serah Terima Aset',
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECF4FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD0D5DD)),
                        ),
                        child: Text(
                          'ID: ${widget.mutationId}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF52606D),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF00273A),
                        child: Text(
                          user?.name.isNotEmpty == true
                              ? user!.name[0].toUpperCase()
                              : 'P',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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

      body: asyncMutation.when(
        data: (mutation) {
          if (!_isMutationOwnedBy(mutation, authState.user)) {
            return _buildAccessDenied(context);
          }
          return _buildBody(context, ref, mutation, actionState);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00273A)),
        ),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () =>
              ref.invalidate(mutationDetailProvider(widget.mutationId)),
        ),
      ),
    );
  }

  Widget _buildAccessDenied(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Akses Ditolak',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Anda hanya dapat melihat dan mengonfirmasi pengajuan mutasi milik Anda sendiri.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: () => _safePop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    Mutation mutation,
    PemohonConfirmationActionState actionState,
  ) {
    final effectiveMutation = actionState.result ?? mutation;
    final isPendingConfirmation =
        effectiveMutation.status == MutationStatus.pendingConfirmation;
    final isCompleted = effectiveMutation.status == MutationStatus.completed;

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Success Result Banner ────────────────────────
                    if (actionState.successMessage != null) ...[
                      _buildSuccessBanner(actionState.successMessage!),
                      const SizedBox(height: 12),
                    ],

                    // ── Card 1: Ticket Header & Status Pill ──────────
                    _buildTicketHeaderCard(effectiveMutation),
                    const SizedBox(height: 12),

                    // ── Status Info Banners ──────────────────────────
                    if (isCompleted) ...[
                      _buildCompletedBanner(),
                      const SizedBox(height: 12),
                    ] else if (!isPendingConfirmation) ...[
                      _buildNotPendingBanner(effectiveMutation),
                      const SizedBox(height: 12),
                    ],

                    // ── Error Banner ─────────────────────────────────
                    if (actionState.error != null) ...[
                      _buildErrorBanner(actionState.error!),
                      const SizedBox(height: 12),
                    ],

                    // ── Card 2: Hasil Update Aset ────────────────────
                    _buildAssetUpdateCard(effectiveMutation),
                    const SizedBox(height: 12),

                    // ── Card 3: Perubahan Mutasi (Diff) ──────────────
                    _buildTransferDiffCard(effectiveMutation),
                    const SizedBox(height: 12),

                    // ── Card 4: Verifikasi Fisik & Pernyataan ────────
                    if (isPendingConfirmation) ...[
                      _buildPhysicalChecklistCard(effectiveMutation),
                      const SizedBox(height: 12),
                    ],

                    // ── Card 5: Alasan Mutasi ────────────────────────
                    _buildReasonCard(effectiveMutation),
                  ],
                ),
              ),
            ),

            // ── Sticky Bottom Action Bar ──────────────────────────────
            if (isPendingConfirmation)
              _buildActionBar(context, ref, effectiveMutation, actionState),
          ],
        ),

        // ── Loading Overlay ──────────────────────────────────────────
        if (actionState.isLoading)
          Container(
            color: Colors.black26,
            child: const Center(
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF00273A)),
                      SizedBox(height: 14),
                      Text(
                        'Memproses konfirmasi...',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Card 1: Ticket Header & Status Card ─────────────────────────────
  Widget _buildTicketHeaderCard(Mutation mutation) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD0D5DD)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A101828),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1F0FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.tag,
                      size: 16,
                      color: Color(0xFF00273A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    mutation.ticketNumber,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF172B4D),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: mutation.status == MutationStatus.completed
                      ? const Color(0xFFECFDF3)
                      : (mutation.status == MutationStatus.pendingConfirmation
                          ? const Color(0xFFEFF8FF)
                          : const Color(0xFFFEF3F2)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: mutation.status == MutationStatus.completed
                        ? const Color(0xFFD1FADF)
                        : (mutation.status == MutationStatus.pendingConfirmation
                            ? const Color(0xFFB2DDFF)
                            : const Color(0xFFFECDCA)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: mutation.status == MutationStatus.completed
                            ? const Color(0xFF15803D)
                            : (mutation.status ==
                                    MutationStatus.pendingConfirmation
                                ? const Color(0xFF175CD3)
                                : const Color(0xFFB42318)),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      mutation.status.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: mutation.status == MutationStatus.completed
                            ? const Color(0xFF15803D)
                            : (mutation.status ==
                                    MutationStatus.pendingConfirmation
                                ? const Color(0xFF175CD3)
                                : const Color(0xFFB42318)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFECF4FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDBEAF9)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info,
                  size: 16,
                  color: Color(0xFF175CD3),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Staff Aset telah menyelesaikan pembaruan master data aset pada sistem inventaris korporat. Harap lakukan verifikasi fisik sebelum melakukan konfirmasi final.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF42474D),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Card 2: Hasil Update Aset ───────────────────────────────────────
  Widget _buildAssetUpdateCard(Mutation mutation) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD0D5DD)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A101828),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.devices,
                    size: 18,
                    color: Color(0xFF52606D),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'HASIL UPDATE ASET',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF52606D),
                      letterSpacing: 0.8,
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
                  color: const Color(0xFFECF4FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFD0D5DD)),
                ),
                child: Text(
                  'Diperbarui oleh Staff Aset: ${mutation.staffUpdatedBy ?? 'Ahmad Staff Aset'}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF172B4D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFEAECF0)),
          const SizedBox(height: 12),

          // Asset Item Card Preview
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE4E7EC)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00273A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.laptop_mac,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mutation.asset.assetCode,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Color(0xFF52606D),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        mutation.asset.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF172B4D),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF3),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFFD1FADF),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 11,
                                  color: Color(0xFF15803D),
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'Kondisi Baik & Normal',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF15803D),
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
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Serial Number Row with Copy Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE4E7EC)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nomor Seri (SN)',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF52606D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Builder(
                  builder: (context) {
                    final sn = (mutation.asset.serialNumber != null &&
                            mutation.asset.serialNumber!.isNotEmpty)
                        ? mutation.asset.serialNumber!
                        : '-';
                    return Row(
                      children: [
                        Text(
                          sn,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF172B4D),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: sn),
                            );
                            setState(() => _copiedSn = true);
                            Future.delayed(const Duration(seconds: 2), () {
                              if (mounted) setState(() => _copiedSn = false);
                            });
                          },
                          child: Icon(
                            _copiedSn ? Icons.check : Icons.content_copy,
                            size: 16,
                            color: _copiedSn
                                ? const Color(0xFF15803D)
                                : const Color(0xFF52606D),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Waktu Update Master Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE4E7EC)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Waktu Update Master',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF52606D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDateTime(mutation.staffUpdatedAt ?? mutation.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172B4D),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Mandatory Asset Info Chips for Test Expectations
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildInfoChip(
                Icons.category_outlined,
                mutation.asset.category.name,
              ),
              _buildInfoChip(
                Icons.star_outline,
                mutation.asset.condition,
              ),
              _buildInfoChip(
                Icons.location_on_outlined,
                'Lokasi: ${mutation.asset.location}',
              ),
              _buildInfoChip(
                Icons.person_outline,
                'PIC: ${mutation.asset.pic}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Card 3: Perubahan Mutasi (Diff) ─────────────────────────────────
  Widget _buildTransferDiffCard(Mutation mutation) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD0D5DD)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A101828),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.swap_horiz,
                    size: 18,
                    color: Color(0xFF52606D),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'PERUBAHAN MUTASI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF52606D),
                      letterSpacing: 0.8,
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
                  color: const Color(0xFFECFDF3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD1FADF)),
                ),
                child: const Text(
                  '2 Data Berubah',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFEAECF0)),
          const SizedBox(height: 12),

          // Perubahan 1: Lokasi Penempatan
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE4E7EC)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.corporate_fare,
                      size: 15,
                      color: Color(0xFF00273A),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'LOKASI PENEMPATAN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF172B4D),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        CircleAvatar(
                          radius: 3,
                          backgroundColor: Color(0xFF52606D),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Sebelum',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF52606D),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      mutation.currentLocation,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF52606D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Center(
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00273A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_downward,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        CircleAvatar(
                          radius: 3,
                          backgroundColor: Color(0xFF15803D),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Tujuan Baru',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          mutation.targetLocation,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF172B4D),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.check_circle,
                          size: 15,
                          color: Color(0xFF15803D),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Perubahan 2: Penanggung Jawab (PIC)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE4E7EC)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 15,
                      color: Color(0xFF00273A),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'PENANGGUNG JAWAB (PIC)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF172B4D),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        CircleAvatar(
                          radius: 3,
                          backgroundColor: Color(0xFF52606D),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Lama',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF52606D),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      mutation.currentPic,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF52606D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Center(
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00273A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_downward,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        CircleAvatar(
                          radius: 3,
                          backgroundColor: Color(0xFF15803D),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'PIC Baru',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          mutation.targetPic,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF172B4D),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          size: 15,
                          color: Color(0xFF15803D),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Card 4: Verifikasi Fisik & Pernyataan (Interactive Checklist) ──
  Widget _buildPhysicalChecklistCard(Mutation mutation) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD0D5DD)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A101828),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.checklist,
                size: 20,
                color: Color(0xFF00273A),
              ),
              SizedBox(width: 8),
              Text(
                'Verifikasi Fisik & Pernyataan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172B4D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Pastikan poin berikut divalidasi secara langsung di lapangan:',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF52606D),
            ),
          ),
          const SizedBox(height: 12),

          // Check Item 1: SN Check
          _buildCheckItem(
            value: _checkSn,
            onChanged: (v) => setState(() => _checkSn = v ?? false),
            text:
                'Nomor seri (SN) pada fisik aset sesuai dengan sistem (${(mutation.asset.serialNumber != null && mutation.asset.serialNumber!.isNotEmpty) ? mutation.asset.serialNumber! : '-'})',
          ),
          const SizedBox(height: 8),

          // Check Item 2: Lokasi Check
          _buildCheckItem(
            value: _checkLocation,
            onChanged: (v) => setState(() => _checkLocation = v ?? false),
            text:
                'Unit fisik dan kelengkapan telah diterima di ${mutation.targetLocation}',
          ),
          const SizedBox(height: 8),

          // Check Item 3: PIC Check
          _buildCheckItem(
            value: _checkPic,
            onChanged: (v) => setState(() => _checkPic = v ?? false),
            text:
                'Serah terima fisik dan aksesoris telah divalidasi bersama PIC Baru (${mutation.targetPic})',
          ),
          const SizedBox(height: 12),

          // BAST note
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFECF4FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDBEAF9)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.verified_user,
                  size: 16,
                  color: Color(0xFF00273A),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Setelah dikonfirmasi, Berita Acara Serah Terima (BAST) digital otomatis diterbitkan.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF52606D),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String text,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: value ? Colors.white : const Color(0xFFF7F9FF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value
                ? const Color(0xFF00273A).withValues(alpha: 0.3)
                : const Color(0xFFE4E7EC),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF00273A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF172B4D),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Card 5: Alasan Mutasi ───────────────────────────────────────────
  Widget _buildReasonCard(Mutation mutation) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD0D5DD)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A101828),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alasan Mutasi',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF172B4D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            mutation.reason,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF52606D),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── Info Banners ───────────────────────────────────────────────────
  Widget _buildCompletedBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD1FADF)),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Color(0xFF15803D),
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Konfirmasi telah diberikan. Mutasi aset telah selesai.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF15803D),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotPendingBanner(Mutation mutation) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFEDF89)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFB45309),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pengajuan ini berstatus "${mutation.status.displayName}". Konfirmasi hanya dapat dilakukan ketika pengajuan berstatus "Menunggu Konfirmasi".',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFB45309),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD1FADF)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFF15803D),
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF15803D),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECDCA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFB42318),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFB42318),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFECF4FF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFDBEAF9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF00273A)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF172B4D),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sticky Action Bar ───────────────────────────────────────────────
  Widget _buildActionBar(
    BuildContext context,
    WidgetRef ref,
    Mutation mutation,
    PemohonConfirmationActionState actionState,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE4E7EC), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Primary Confirm Button
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                key: const Key('btn_sesuai_konfirmasi'),
                onPressed: actionState.isLoading
                    ? null
                    : () => _onConfirmTap(context, ref, mutation),
                icon: const Icon(Icons.verified, size: 18),
                label: const Text(
                  '✓ Sesuai',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00273A),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Secondary Report Discrepancy Button
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                key: const Key('btn_tidak_sesuai_konfirmasi'),
                onPressed: actionState.isLoading
                    ? null
                    : () => _onTidakSesuaiTap(context),
                icon: const Icon(Icons.report_problem_outlined, size: 16),
                label: const Text(
                  'Tidak Sesuai',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB45309),
                  side: const BorderSide(color: Color(0xFFFEDF89)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 11, color: Color(0xFF52606D)),
                SizedBox(width: 4),
                Text(
                  'Audit Trail ISO 27001 Terenkripsi MutasiKu Enterprise',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF52606D),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Actions & Dialogs ───────────────────────────────────────────────
  Future<void> _onConfirmTap(
    BuildContext context,
    WidgetRef ref,
    Mutation mutation,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Mutasi'),
        content: Text(
          'Anda akan mengonfirmasi bahwa data mutasi aset "${mutation.asset.name}" '
          'sudah sesuai dengan kondisi fisik.\n\n'
          'Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00273A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Konfirmasi'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final notifier = ref.read(pemohonConfirmationActionProvider.notifier);
    final success = await notifier.confirm(mutationId: widget.mutationId);

    if (!context.mounted) return;

    if (success) {
      final currentMutation =
          ref.read(mutationDetailProvider(widget.mutationId)).valueOrNull;
      ref.read(notificationProvider.notifier).notifyRole(
            targetRole: UserRole.staffAset,
            title: 'Mutasi Selesai',
            message:
                'Pemohon telah mengonfirmasi penerimaan aset untuk pengajuan ${currentMutation?.ticketNumber ?? widget.mutationId}.',
            type: NotificationType.success,
            relatedMutationId: widget.mutationId,
          );
      ref.read(notificationProvider.notifier).notifyUser(
            targetUserId: currentMutation?.applicantId ?? 'usr_pemohon',
            targetRole: UserRole.pemohon,
            title: 'Mutasi Berhasil Diselesaikan',
            message:
                'Mutasi aset ${currentMutation?.ticketNumber ?? widget.mutationId} telah selesai dan terkonfirmasi.',
            type: NotificationType.success,
            relatedMutationId: widget.mutationId,
          );
      ref.invalidate(mutationDetailProvider(widget.mutationId));
      AppFeedback.showSuccess(
        context,
        'Konfirmasi berhasil. Mutasi aset telah selesai.',
      );
    } else {
      final state = ref.read(pemohonConfirmationActionProvider);
      AppFeedback.showError(
        context,
        state.error ?? 'Konfirmasi gagal. Coba lagi.',
      );
    }
  }

  void _onTidakSesuaiTap(BuildContext context) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF0C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.assignment_return_outlined,
                color: Color(0xFFB45309),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Mutasi Tidak Sesuai',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172B4D),
                ),
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Silakan berikan alasan atau catatan ketidaksesuaian aset/lokasi yang diterima agar pengajuan dapat diperbaiki.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF52606D),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Alasan / Keterangan *',
                  hintText: 'Jelaskan ketidaksesuaian...',
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF52606D),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Alasan ketidaksesuaian wajib diisi';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final reason = reasonController.text.trim();
                Navigator.of(ctx).pop();

                final success = await ref
                    .read(pemohonConfirmationActionProvider.notifier)
                    .returnForRevision(
                      mutationId: widget.mutationId,
                      reason: reason,
                    );

                if (!context.mounted) return;

                if (success) {
                  AppFeedback.showSuccess(
                    context,
                    'Pengajuan dikembalikan untuk perbaikan data.',
                  );

                  final currentMutation = ref
                      .read(mutationDetailProvider(widget.mutationId))
                      .valueOrNull;
                  ref.read(notificationProvider.notifier).notifyRole(
                        targetRole: UserRole.staffAset,
                        title: 'Ketidaksesuaian Ditemukan',
                        message:
                            'Pemohon melaporkan ketidaksesuaian untuk pengajuan ${currentMutation?.ticketNumber ?? widget.mutationId}: $reason',
                        type: NotificationType.action,
                        relatedMutationId: widget.mutationId,
                      );
                  ref.read(notificationProvider.notifier).notifyRole(
                        targetRole: UserRole.operator,
                        title: 'Pengajuan Dikembalikan oleh Pemohon',
                        message:
                            'Pengajuan ${currentMutation?.ticketNumber ?? widget.mutationId} dikembalikan untuk penyesuaian: $reason',
                        type: NotificationType.action,
                        relatedMutationId: widget.mutationId,
                      );
                  ref.invalidate(mutationDetailProvider(widget.mutationId));
                  try {
                    context.go(
                      RouteNames.pemohonMutasiEditPath
                          .replaceFirst(':id', widget.mutationId),
                    );
                  } catch (_) {}
                } else {
                  final state =
                      ref.read(pemohonConfirmationActionProvider);
                  AppFeedback.showError(
                    context,
                    state.error ?? 'Gagal melaporkan ketidaksesuaian.',
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB45309),
              foregroundColor: Colors.white,
            ),
            child: const Text('Perbaiki Pengajuan'),
          ),
        ],
      ),
    );
  }
}
