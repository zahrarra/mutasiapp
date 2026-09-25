// lib/features/pemohon/presentation/screens/pemohon_mutation_detail_screen.dart
//
// Screen: Detail Mutasi & Tracking milik Pemohon (Enhanced UI).
// Diadaptasi dari desain Stitch MCP: 'MutasiKu — Detail Mutasi & Tracking (Enhanced UI)'
// Screen ID Stitch: 829242333f1343b685ced750b92f2fd3

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/document_preview_dialog.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';
import '../../../mutation/presentation/models/mutation_tracking_step.dart';
import '../widgets/mutation_status_stepper.dart';

/// Screen detail pengajuan mutasi & pelacakan alur kerja milik Pemohon (Enhanced UI).
class PemohonMutationDetailScreen extends ConsumerWidget {
  final String mutationId;

  const PemohonMutationDetailScreen({super.key, required this.mutationId});

  bool _isMutationOwnedBy(Mutation mutation, User? user) {
    if (user == null) return true;
    if (user.role != UserRole.pemohon) return true;

    if (mutation.applicantId != null && mutation.applicantId == user.id) {
      return true;
    }
    if ((user.id == 'usr_pemohon' ||
            user.id == 'usr_101' ||
            user.id == 'user_pemohon') &&
        (mutation.applicantId == 'usr_pemohon' ||
            mutation.applicantId == 'usr_101' ||
            mutation.applicantId == 'user_pemohon')) {
      return true;
    }
    if (mutation.applicantName.trim().toLowerCase() ==
        user.name.trim().toLowerCase()) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(mutationDetailProvider(mutationId));
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FF),
      appBar: AppBar(
        title: const Text(
          'Detail Mutasi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F1D28),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F1D28)),
          tooltip: 'Kembali',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              try {
                context.go(RouteNames.pemohonMutasiPath);
              } catch (_) {}
            }
          },
        ),
      ),
      body: asyncDetail.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(mutationDetailProvider(mutationId)),
        ),
        data: (m) {
          // Ownership guard
          if (!_isMutationOwnedBy(m, authState.user)) {
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
                      'Anda hanya dapat melihat pengajuan mutasi milik Anda sendiri.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    OutlinedButton.icon(
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          try {
                            context.go(RouteNames.pemohonMutasiPath);
                          } catch (_) {}
                        }
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Kembali'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(mutationDetailProvider(mutationId));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Status & Ticket Hero Card (Navy Gradient)
                  _buildHeroCard(context, m),
                  const SizedBox(height: 16),

                  // 2. Alert Banners (Returned / Rejected)
                  if (m.status == MutationStatus.returned) ...[
                    _buildReturnedAlertBanner(m),
                    const SizedBox(height: 16),
                  ],
                  if (m.status == MutationStatus.rejected) ...[
                    _buildRejectedAlertBanner(m),
                    const SizedBox(height: 16),
                  ],

                  // 3. Pelacakan Alur Kerja (Workflow Timeline)
                  _buildTrackingTimelineCard(m),
                  const SizedBox(height: 16),

                  // 4. Spesifikasi Aset Card
                  _buildAssetSpecificationCard(m),
                  const SizedBox(height: 16),

                  // 5. Rincian Perpindahan Card
                  _buildTransferDetailsCard(m),
                  const SizedBox(height: 16),

                  // 6. Alasan & Dokumen Pendukung
                  _buildJustificationAndDocumentCard(context, m, ref),
                  const SizedBox(height: 16),

                  // 7. Status Info Card
                  _buildStatusInfoBanner(m),
                  const SizedBox(height: 24),

                  // 8. Bottom Action Buttons
                  if (m.status == MutationStatus.returned) ...[
                    ElevatedButton.icon(
                      onPressed: () async {
                        await context.push(
                          RouteNames.pemohonMutasiEditPath.replaceFirst(
                            ':id',
                            m.id,
                          ),
                        );
                        ref.invalidate(mutationDetailProvider(mutationId));
                      },
                      icon: const Icon(Icons.edit_outlined, color: Colors.white),
                      label: const Text(
                        'Edit & Ajukan Ulang',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (m.status == MutationStatus.pendingConfirmation) ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        context.push(
                          RouteNames.pemohonConfirmationPath.replaceFirst(
                            ':id',
                            m.id,
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Konfirmasi Mutasi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. HERO CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeroCard(BuildContext context, Mutation mutation) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00273A),
            Color(0xFF00344D),
            Color(0xFF0A4866),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00273A).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag Pill & Status Badge Row (Responsive Wrap to prevent overflow on mobile)
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'MUTASI ASET',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Color(0xFF67E8F9),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      mutation.ticketNumber,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(
                        Icons.copy_rounded,
                        size: 15,
                        color: Color(0xFFA5F3FC),
                      ),
                      tooltip: 'Salin Nomor Tiket',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: mutation.ticketNumber),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Nomor tiket ${mutation.ticketNumber} berhasil disalin!',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                _buildHeroStatusBadge(mutation.status),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2-Column Info: Tanggal Pengajuan & Target SLA
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TANGGAL PENGAJUAN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFA5F3FC).withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_outlined,
                            size: 13,
                            color: Color(0xFF67E8F9),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _formatDateShort(mutation.createdAt),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TARGET SLA SELESAI',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFA5F3FC).withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 13,
                            color: Color(0xFFFDE047),
                          ),
                          const SizedBox(width: 4),
                          const Expanded(
                            child: Text(
                              '1x24 Jam (Sisa 18 Jam)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: 14),

          // Reviewer card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 17,
                            backgroundColor:
                                const Color(0xFF06B6D4).withValues(alpha: 0.3),
                            child: const Icon(
                              Icons.person,
                              size: 18,
                              color: Color(0xFFA5F3FC),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBBF24),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF00273A),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PETUGAS PENINJAU',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color:
                                    const Color(0xFFA5F3FC).withValues(alpha: 0.8),
                              ),
                            ),
                            Text(
                              _getReviewerName(mutation),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _getReviewerRole(mutation),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.hourglass_top,
                        size: 12,
                        color: Color(0xFFFDE047),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Meninjau',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFDE047),
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

  Widget _buildHeroStatusBadge(MutationStatus status) {
    Color bg;
    Color border;
    Color text;

    switch (status) {
      case MutationStatus.submitted:
      case MutationStatus.waitingKabagApproval:
      case MutationStatus.waitingKadivApproval:
        bg = const Color(0xFFF59E0B).withValues(alpha: 0.2);
        border = const Color(0xFFF59E0B).withValues(alpha: 0.35);
        text = const Color(0xFFFDE68A);
      case MutationStatus.verified:
      case MutationStatus.approved:
      case MutationStatus.completed:
        bg = const Color(0xFF10B981).withValues(alpha: 0.2);
        border = const Color(0xFF10B981).withValues(alpha: 0.35);
        text = const Color(0xFFA7F3D0);
      case MutationStatus.returned:
        bg = const Color(0xFFF97316).withValues(alpha: 0.2);
        border = const Color(0xFFF97316).withValues(alpha: 0.35);
        text = const Color(0xFFFED7AA);
      case MutationStatus.rejected:
        bg = const Color(0xFFEF4444).withValues(alpha: 0.2);
        border = const Color(0xFFEF4444).withValues(alpha: 0.35);
        text = const Color(0xFFFECACA);
      case MutationStatus.pendingConfirmation:
        bg = const Color(0xFF06B6D4).withValues(alpha: 0.2);
        border = const Color(0xFF06B6D4).withValues(alpha: 0.35);
        text = const Color(0xFFA5F3FC);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: text,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. TIMELINE TRACKING
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTrackingTimelineCard(Mutation mutation) {
    final status = mutation.status;
    final steps = MutationTrackingHelper.getStepsForMutation(
      status,
      mutation: mutation,
    );
    final activeStage = MutationTrackingHelper.getActiveStageNumber(steps);
    final totalStages = steps.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00273A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.alt_route,
                      size: 17,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Pelacakan Alur Kerja',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F1D28),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  'Tahap $activeStage dari $totalStages',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Horizontal Status Stepper
          MutationStatusStepper(status: status, mutation: mutation),
          const SizedBox(height: 16),

          // Vertical timeline tiles
          ...List.generate(steps.length, (i) {
            final step = steps[i];
            return _buildTimelineTile(
              title: '${i + 1}. ${step.title}',
              subtitle: step.subtitle,
              isDone: step.isCompleted,
              isCurrent: step.isCurrent,
              isAlert: step.isAlert,
              badgeText: step.badgeText,
              isLast: i == steps.length - 1,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineTile({
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isCurrent,
    required bool isAlert,
    required String badgeText,
    required bool isLast,
  }) {
    Color iconBg;
    Color iconBorder;
    Widget iconChild;

    if (isAlert) {
      iconBg = const Color(0xFFF97316);
      iconBorder = const Color(0xFFFDBA74);
      iconChild = const Icon(Icons.close, size: 14, color: Colors.white);
    } else if (isDone) {
      iconBg = const Color(0xFF059669);
      iconBorder = const Color(0xFF6EE7B7);
      iconChild = const Icon(Icons.check, size: 14, color: Colors.white);
    } else if (isCurrent) {
      iconBg = const Color(0xFFF59E0B);
      iconBorder = const Color(0xFFFDE68A);
      iconChild = Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      );
    } else {
      iconBg = const Color(0xFFE2E8F0);
      iconBorder = const Color(0xFFCBD5E1);
      iconChild = Container(
        width: 4,
        height: 4,
        decoration: const BoxDecoration(
          color: Color(0xFF94A3B8),
          shape: BoxShape.circle,
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicator column
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: iconBorder, width: 2),
                ),
                child: Center(child: iconChild),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDone
                        ? const Color(0xFF10B981)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Content column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? const Color(0xFFFEF3C7).withValues(alpha: 0.35)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCurrent
                        ? const Color(0xFFFCD34D)
                        : const Color(0xFFF1F5F9),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isCurrent
                                  ? const Color(0xFF92400E)
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDone
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isDone
                                  ? const Color(0xFFA7F3D0)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: isDone
                                  ? const Color(0xFF047857)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. ASSET SPECIFICATION CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAssetSpecificationCard(Mutation mutation) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFF00273A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.devices_outlined,
                  size: 17,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Spesifikasi Aset',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F1D28),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Asset banner row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.laptop_chromebook,
                      size: 28,
                      color: Color(0xFF00273A),
                    ),
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
                              color: const Color(0xFFECFEFF),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFFA5F3FC),
                              ),
                            ),
                            child: Text(
                              mutation.isUnregisteredAsset
                                  ? 'ASET MANUAL'
                                  : mutation.asset.category.name.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0E7490),
                              ),
                            ),
                          ),
                          if (mutation.isUnregisteredAsset) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFFFED7AA),
                                ),
                              ),
                              child: const Text(
                                'TIDAK TERDAFTAR',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFC2410C),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mutation.displayAssetName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Kode: ${mutation.displayAssetCode}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Grid 2-column info
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SERIAL NUMBER (SN)',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        mutation.displayAssetCode,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'KONDISI FISIK',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF059669),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            mutation.asset.condition,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. TRANSFER DETAILS CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTransferDetailsCard(Mutation mutation) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFF00273A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.sync_alt,
                  size: 17,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Rincian Perpindahan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F1D28),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Origin location & PIC
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.apartment,
                        size: 18,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'LOKASI ASAL (PENGIRIM)',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            mutation.currentLocation,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'PIC: ${mutation.currentPic}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Dashed connector
                Padding(
                  padding: const EdgeInsets.only(left: 15, top: 4, bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 2,
                        height: 24,
                        color: const Color(0xFF0D9488),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDFA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF99F6E4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_shipping_outlined,
                              size: 12,
                              color: Color(0xFF0F766E),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Mutasi Antar Wilayah',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F766E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Destination location & PIC
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00273A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.pin_drop,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'LOKASI TUJUAN (PENERIMA)',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D9488),
                            ),
                          ),
                          Text(
                            mutation.targetLocation,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'PIC: ${mutation.targetPic}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF475569),
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
          if (mutation.staffUpdatedBy != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_outlined,
                    size: 16,
                    color: Color(0xFF047857),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Fisik diperbarui oleh ${mutation.staffUpdatedBy}'
                      '${mutation.staffUpdatedAt != null ? ' pada ${_formatDateShort(mutation.staffUpdatedAt!)}' : ''}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. JUSTIFICATION & DOCUMENTS CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildJustificationAndDocumentCard(
    BuildContext context,
    Mutation mutation,
    WidgetRef ref,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFF00273A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  size: 17,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Alasan & Dokumen Pendukung',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F1D28),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Justification quote
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.format_quote,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'JUSTIFIKASI KEBUTUHAN',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  mutation.reason,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF334155),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Document attachment tile
          if (mutation.documentName != null && mutation.documentName!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Builder(
                builder: (context) {
                  final docName = mutation.documentName!;
                  final isPdf = docName.toLowerCase().endsWith('.pdf');
                  final isImage = ['png', 'jpg', 'jpeg', 'webp']
                      .any((ext) => docName.toLowerCase().endsWith(ext));

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isPdf
                                    ? const Color(0xFFFEE2E2)
                                    : isImage
                                        ? const Color(0xFFDBEAF9)
                                        : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isPdf
                                      ? const Color(0xFFFECACA)
                                      : isImage
                                          ? const Color(0xFFBFDBFE)
                                          : const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  isPdf
                                      ? Icons.picture_as_pdf
                                      : isImage
                                          ? Icons.image
                                          : Icons.description,
                                  size: 20,
                                  color: isPdf
                                      ? const Color(0xFFB91C1C)
                                      : isImage
                                          ? const Color(0xFF1D4ED8)
                                          : const Color(0xFF475569),
                                ),
                              ),
                            ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mutation.documentName!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Row(
                                children: [
                                  Icon(
                                    Icons.verified,
                                    size: 12,
                                    color: Color(0xFF059669),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Dokumen Terlampir',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF047857),
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
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () =>
                        _showDocumentPreviewDialog(context, mutation, ref),
                    icon: const Icon(Icons.visibility, size: 14),
                    label: const Text('Pratinjau Dokumen'),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF334155),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tidak ada dokumen pendukung yang dilampirkan.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF64748B),
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

  // ─────────────────────────────────────────────────────────────────────────
  // 6. STATUS BANNERS & NOTIFICATIONS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStatusInfoBanner(Mutation mutation) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.notifications_active,
            size: 20,
            color: Color(0xFF2563EB),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Pengajuan Aktif',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Pengajuan sedang diproses sesuai alur kerja. Anda akan menerima notifikasi otomatis begitu status disetujui atau memerlukan konfirmasi.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF3B82F6),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnedAlertBanner(Mutation mutation) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.assignment_return_outlined,
            size: 22,
            color: Color(0xFFEA580C),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pengajuan Dikembalikan untuk Diperbaiki',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9A3412),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (mutation.returnReason != null &&
                          mutation.returnReason!.trim().isNotEmpty)
                      ? mutation.returnReason!.trim()
                      : 'Harap perbaiki lokasi tujuan dan sertakan surat tugas.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFC2410C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedAlertBanner(Mutation mutation) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.cancel_outlined,
            size: 22,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pengajuan Ditolak',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF991B1B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mutation.kadivRejectionReason ??
                      (mutation.rejectionReason ??
                          'Pengajuan mutasi ini tidak disetujui.'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB91C1C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPER METHODS
  // ─────────────────────────────────────────────────────────────────────────
  String _getReviewerName(Mutation mutation) {
    return switch (mutation.status) {
      MutationStatus.submitted ||
      MutationStatus.returned =>
        mutation.verifiedBy ?? 'Siti Rahma',
      MutationStatus.verified ||
      MutationStatus.waitingKabagApproval =>
        mutation.approvedBy ?? 'Bpk. Budi Santoso',
      MutationStatus.waitingKadivApproval => 'Drs. Hendra',
      MutationStatus.approved => mutation.staffUpdatedBy ?? 'Agus Pratama',
      MutationStatus.pendingConfirmation => mutation.applicantName,
      MutationStatus.completed => 'Sistem Terverifikasi',
      MutationStatus.rejected =>
        mutation.kadivRejectionReason != null ? 'Drs. Hendra' : 'Bpk. Budi Santoso',
    };
  }

  String _getReviewerRole(Mutation mutation) {
    return switch (mutation.status) {
      MutationStatus.submitted ||
      MutationStatus.returned =>
        'Operator Aset & Logistik',
      MutationStatus.verified ||
      MutationStatus.waitingKabagApproval =>
        'Kabag Aset & Logistik',
      MutationStatus.waitingKadivApproval => 'Kepala Divisi (Kadiv)',
      MutationStatus.approved => 'Staff Aset (Fisik & Inventaris)',
      MutationStatus.pendingConfirmation => 'Pemohon (Konfirmasi Akhir)',
      MutationStatus.completed => 'Siklus Mutasi Selesai',
      MutationStatus.rejected => 'Peninjau Mutasi',
    };
  }

  String _formatDateShort(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:$minute';
  }

  void _showDocumentPreviewDialog(
      BuildContext context, Mutation mutation, WidgetRef ref) {
    DocumentPreviewDialog.show(
      context,
      mutation: mutation,
      currentUser: ref.read(authStateProvider).user,
    );
  }
}
