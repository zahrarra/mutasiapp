// lib/features/mutation/presentation/screens/mutation_detail_screen.dart
//
// Screen: Detail Pengajuan Mutasi milik Pemohon (REQ-007).
// Sumber: SCREEN-SPEC.md REQ-007, ROLE-FLOW.md §3.
//
// Menampilkan detail lengkap satu pengajuan mutasi beserta aksi
// kontekstual sesuai status:
// - returned              -> tombol "Edit Pengajuan" (REQ-008)
// - pendingConfirmation   -> tombol "Konfirmasi Sekarang" (REQ-009)
// - status lain           -> read-only (tanpa aksi)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../domain/entities/mutation.dart';
import '../../domain/entities/mutation_status.dart';
import '../providers/mutation_provider.dart';

/// Screen detail pengajuan mutasi milik Pemohon.
class MutationDetailScreen extends ConsumerWidget {
  final String mutationId;

  const MutationDetailScreen({super.key, required this.mutationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMutation = ref.watch(mutationDetailProvider(mutationId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detail Pengajuan')),
      body: asyncMutation.when(
        data: (mutation) => _buildBody(context, ref, mutation),
        loading: () => const LoadingIndicator(),
        error: (err, _) => ErrorView(
          message: 'Gagal memuat detail pengajuan.\n${err.toString()}',
          onRetry: () => ref.invalidate(mutationDetailProvider(mutationId)),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, Mutation mutation) {
    final showEdit = mutation.status == MutationStatus.returned;
    final showConfirm = mutation.status == MutationStatus.pendingConfirmation;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(mutation),
                const SizedBox(height: AppSpacing.md),

                if (mutation.status == MutationStatus.returned && mutation.returnReason != null)
                  _buildBanner(
                    icon: Icons.info_outline,
                    color: AppColors.warning,
                    background: AppColors.warningContainer,
                    text: 'Dikembalikan Operator: ${mutation.returnReason}',
                  ),
                if (mutation.status == MutationStatus.rejected && mutation.rejectionReason != null)
                  _buildBanner(
                    icon: Icons.cancel_outlined,
                    color: AppColors.error,
                    background: AppColors.errorContainer,
                    text: 'Ditolak Kabag Aset: ${mutation.rejectionReason}',
                  ),
                if (mutation.status == MutationStatus.rejected && mutation.kadivRejectionReason != null)
                  _buildBanner(
                    icon: Icons.cancel_outlined,
                    color: AppColors.error,
                    background: AppColors.errorContainer,
                    text: 'Ditolak Kadiv: ${mutation.kadivRejectionReason}',
                  ),
                if (showConfirm)
                  _buildBanner(
                    icon: Icons.touch_app_outlined,
                    color: AppColors.info,
                    background: AppColors.infoContainer,
                    text: 'Data aset telah diperbarui. Silakan konfirmasi kesesuaiannya.',
                  ),
                const SizedBox(height: AppSpacing.md),

                _sectionTitle('Detail Aset'),
                const SizedBox(height: AppSpacing.sm),
                _infoCard([
                  _infoRow('Nama Aset', mutation.asset.name),
                  _infoRow('Kode Aset', mutation.asset.assetCode),
                  _infoRow('Kategori', mutation.asset.category.name, isLast: true),
                ]),
                const SizedBox(height: AppSpacing.md),

                _sectionTitle('Perpindahan'),
                const SizedBox(height: AppSpacing.sm),
                _infoCard([
                  _transferRow('Lokasi', mutation.currentLocation, mutation.targetLocation),
                  const SizedBox(height: AppSpacing.md),
                  _transferRow('PIC', mutation.currentPic, mutation.targetPic),
                ]),
                const SizedBox(height: AppSpacing.md),

                _sectionTitle('Alasan Mutasi'),
                const SizedBox(height: AppSpacing.sm),
                _infoCard([
                  Text(
                    mutation.reason,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5),
                  ),
                ]),
                const SizedBox(height: AppSpacing.md),

                _sectionTitle('Tanggal Diajukan'),
                const SizedBox(height: AppSpacing.sm),
                _infoCard([
                  Text(
                    _formatDate(mutation.createdAt),
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                ]),
                const SizedBox(height: AppSpacing.giant),
              ],
            ),
          ),
        ),
        if (showEdit || showConfirm) _buildActionBar(context, mutation, showEdit, showConfirm),
      ],
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader(Mutation mutation) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nomor Tiket', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  mutation.ticketNumber,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
            decoration: BoxDecoration(
              color: mutation.status.backgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              mutation.status.displayName,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: mutation.status.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner({
    required IconData icon,
    required Color color,
    required Color background,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.card)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: color, height: 1.4))),
          ],
        ),
      ),
    );
  }

  // ─── Sections ───────────────────────────────────────────────────────────

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      );

  Widget _infoCard(List<Widget> children) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _infoRow(String label, String value, {bool isLast = false}) => Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
        child: Row(
          children: [
            SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          ],
        ),
      );

  Widget _transferRow(String label, String from, String to) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppRadius.small)),
                  child: Text(from, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Icon(Icons.arrow_forward, size: 14, color: AppColors.secondary),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(color: AppColors.successContainer, borderRadius: BorderRadius.circular(AppRadius.small)),
                  child: Text(to, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondary), overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
        ],
      );

  // ─── Action Bar ─────────────────────────────────────────────────────────

  Widget _buildActionBar(BuildContext context, Mutation mutation, bool showEdit, bool showConfirm) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: CustomButton(
        label: showEdit ? 'Edit Pengajuan' : 'Konfirmasi Sekarang',
        width: double.infinity,
        icon: Icon(showEdit ? Icons.edit_outlined : Icons.check_circle_outline, size: 18, color: Colors.white),
        onPressed: () {
          if (showEdit) {
            context.push(RouteNames.pemohonMutasiEditPath.replaceFirst(':id', mutation.id));
          } else {
            context.push(RouteNames.pemohonConfirmationPath.replaceFirst(':id', mutation.id));
          }
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
