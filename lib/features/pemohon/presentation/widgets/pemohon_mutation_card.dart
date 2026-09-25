import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';

class PemohonMutationCard extends StatelessWidget {
  final Mutation mutation;
  final VoidCallback? onTap;
  final Widget? trailingAction;
  final VoidCallback? onConfirmTap;
  final VoidCallback? onEditTap;

  const PemohonMutationCard({
    super.key,
    required this.mutation,
    this.onTap,
    this.trailingAction,
    this.onConfirmTap,
    this.onEditTap,
  });

  String _formatDate(DateTime dt) {
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
    return '$day ${months[dt.month - 1]} ${dt.year}';
  }

  String _getStageText(MutationStatus status) {
    switch (status) {
      case MutationStatus.submitted:
        return 'Tahap 1/6: Diajukan';
      case MutationStatus.verified:
        return 'Tahap 2/6: Terverifikasi Operator';
      case MutationStatus.waitingKabagApproval:
        return 'Tahap 3/6: Kabag Review';
      case MutationStatus.waitingKadivApproval:
        return 'Tahap 4/6: Kadiv Review';
      case MutationStatus.approved:
        return 'Tahap 5/6: Eksekusi Staff';
      case MutationStatus.pendingConfirmation:
        return 'Tahap 6/6: Konfirmasi Pemohon';
      case MutationStatus.completed:
        return 'Selesai';
      case MutationStatus.returned:
        return 'Perlu Perbaikan';
      case MutationStatus.rejected:
        return 'Ditolak';
    }
  }

  void _safePush(BuildContext context, String path) {
    try {
      context.push(path);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final status = mutation.status;

    // Card border color based on status
    Color borderColor = const Color(0xFFD0D5DD);
    Color statusBgColor = const Color(0xFFEFF8FF);
    Color statusTextColor = const Color(0xFF175CD3);
    Color statusBorderColor = const Color(0xFFB2DDFF);
    String statusBadgeLabel = status.displayName;

    switch (status) {
      case MutationStatus.pendingConfirmation:
        borderColor = const Color(0xFFB2DDFF);
        statusBgColor = const Color(0xFF175CD3);
        statusTextColor = Colors.white;
        statusBorderColor = const Color(0xFF175CD3);
        statusBadgeLabel = 'Perlu Tindakan';
        break;
      case MutationStatus.returned:
        borderColor = const Color(0xFFFEDF89);
        statusBgColor = const Color(0xFFFEF0C7);
        statusTextColor = const Color(0xFFB45309);
        statusBorderColor = const Color(0xFFFEDF89);
        statusBadgeLabel = 'Perlu Perbaikan';
        break;
      case MutationStatus.completed:
        borderColor = const Color(0xFFD1FADF);
        statusBgColor = const Color(0xFFECFDF3);
        statusTextColor = const Color(0xFF15803D);
        statusBorderColor = const Color(0xFFD1FADF);
        statusBadgeLabel = 'Selesai';
        break;
      case MutationStatus.rejected:
        borderColor = const Color(0xFFFECDCA);
        statusBgColor = const Color(0xFFFEF3F2);
        statusTextColor = const Color(0xFFB42318);
        statusBorderColor = const Color(0xFFFECDCA);
        statusBadgeLabel = 'Ditolak';
        break;
      case MutationStatus.waitingKabagApproval:
        statusBgColor = const Color(0xFFFEF0C7);
        statusTextColor = const Color(0xFFB45309);
        statusBorderColor = const Color(0xFFFEDF89);
        statusBadgeLabel = 'Approval Kabag';
        break;
      case MutationStatus.waitingKadivApproval:
        statusBgColor = const Color(0xFFFEF0C7);
        statusTextColor = const Color(0xFFB45309);
        statusBorderColor = const Color(0xFFFEDF89);
        statusBadgeLabel = 'Approval Kadiv';
        break;
      case MutationStatus.verified:
        statusBgColor = const Color(0xFFEFF8FF);
        statusTextColor = const Color(0xFF175CD3);
        statusBorderColor = const Color(0xFFB2DDFF);
        statusBadgeLabel = 'Terverifikasi';
        break;
      case MutationStatus.approved:
        statusBgColor = const Color(0xFFE0F2FE);
        statusTextColor = const Color(0xFF0369A1);
        statusBorderColor = const Color(0xFFBAE6FD);
        statusBadgeLabel = 'Eksekusi Staff';
        break;
      case MutationStatus.submitted:
        statusBgColor = const Color(0xFFEFF8FF);
        statusTextColor = const Color(0xFF175CD3);
        statusBorderColor = const Color(0xFFB2DDFF);
        statusBadgeLabel = 'Diajukan';
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A101828),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Card Header (Ticket & Status Badge) ─────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            mutation.ticketNumber,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: status == MutationStatus.pendingConfirmation
                                  ? const Color(0xFF175CD3)
                                  : (status == MutationStatus.returned
                                      ? const Color(0xFFB45309)
                                      : const Color(0xFF00273A)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '•',
                            style: TextStyle(
                              color: Color(0xFF52606D),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(mutation.createdAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF52606D),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusBorderColor, width: 1),
                      ),
                      child: Text(
                        statusBadgeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Asset Name & Code ───────────────────────────────
                Text(
                  mutation.asset.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172B4D),
                  ),
                ),
                if (mutation.asset.assetCode.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    mutation.asset.assetCode,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: Color(0xFF52606D),
                    ),
                  ),
                ],
                const SizedBox(height: 8),

                // ── Movement Route (Current → Target) ───────────────
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        mutation.currentLocation,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF172B4D),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 13,
                        color: Color(0xFF52606D),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        mutation.targetLocation,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF172B4D),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // ── Returned Reason Notice (if returned) ────────────
                if (status == MutationStatus.returned) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 14,
                          color: Color(0xFFB45309),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            mutation.returnReason?.isNotEmpty == true
                                ? mutation.returnReason!
                                : 'Foto serial number buram atau data perlu diperbaiki.',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFB45309),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Trailing Action Override or Refined Footer ───────
                if (trailingAction != null) ...[
                  const SizedBox(height: 12),
                  trailingAction!,
                ] else ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFEAECF0)),
                  const SizedBox(height: 8),

                  if (status == MutationStatus.pendingConfirmation)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          mutation.asset.assetCode.isNotEmpty
                              ? mutation.asset.assetCode
                              : mutation.ticketNumber,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Color(0xFF52606D),
                          ),
                        ),
                        InkWell(
                          onTap: onConfirmTap ??
                              () => _safePush(
                                    context,
                                    RouteNames.pemohonConfirmationPath
                                        .replaceFirst(':id', mutation.id),
                                  ),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF175CD3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Konfirmasi Diterima',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward,
                                  size: 13,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (status == MutationStatus.returned)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          mutation.asset.assetCode.isNotEmpty
                              ? mutation.asset.assetCode
                              : mutation.ticketNumber,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Color(0xFF52606D),
                          ),
                        ),
                        InkWell(
                          onTap: onEditTap ??
                              () => _safePush(
                                    context,
                                    RouteNames.pemohonMutasiEditPath
                                        .replaceFirst(':id', mutation.id),
                                  ),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF0C7),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFFEDF89),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Perbaiki Berkas',
                                  style: TextStyle(
                                    color: Color(0xFFB45309),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward,
                                  size: 13,
                                  color: Color(0xFFB45309),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (status == MutationStatus.completed)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.verified,
                              size: 14,
                              color: Color(0xFF15803D),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'BAST Terbit',
                              style: TextStyle(
                                color: Color(0xFF15803D),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: onTap,
                          child: const Text(
                            'Unduh BAST',
                            style: TextStyle(
                              color: Color(0xFF00273A),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text.rich(
                          TextSpan(
                            text: '${_getStageText(status).split(':')[0]}: ',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF52606D),
                            ),
                            children: [
                              TextSpan(
                                text: _getStageText(status).contains(':')
                                    ? _getStageText(status)
                                        .split(':')[1]
                                        .trim()
                                    : _getStageText(status),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF172B4D),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            text: 'PIC: ',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF52606D),
                            ),
                            children: [
                              TextSpan(
                                text: mutation.targetPic,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF172B4D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
