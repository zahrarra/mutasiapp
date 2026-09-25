// lib/features/staff/presentation/screens/staff_mutation_detail_screen.dart
//
// Screen: Detail Pembaruan Aset oleh Staff Aset (STF-003).
// Sumber: ROLE-FLOW.md §7, SCREEN-SPEC.md STF-003, WIREFRAME.md §2.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';
import '../../../notification/domain/entities/notification_item.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/document_preview_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/staff_mutation_provider.dart';

class StaffMutationDetailScreen extends ConsumerStatefulWidget {
  final String mutationId;

  const StaffMutationDetailScreen({
    super.key,
    required this.mutationId,
  });

  @override
  ConsumerState<StaffMutationDetailScreen> createState() =>
      _StaffMutationDetailScreenState();
}

class _StaffMutationDetailScreenState
    extends ConsumerState<StaffMutationDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _picController = TextEditingController();
  bool _isInitialized = false;

  @override
  void dispose() {
    _locationController.dispose();
    _picController.dispose();
    super.dispose();
  }

  void _initControllers(Mutation mutation) {
    if (!_isInitialized) {
      _locationController.text = mutation.targetLocation;
      _picController.text = mutation.targetPic;
      _isInitialized = true;
    }
  }

  Future<void> _submitUpdate(Mutation mutation) async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Pembaruan Aset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Apakah Anda yakin data perpindahan fisik aset sudah sesuai?',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lokasi Baru: ${_locationController.text.trim()}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'PIC Baru: ${_picController.text.trim()}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Status mutasi akan diperbarui menjadi "Menunggu Konfirmasi" dan siap dikonfirmasi oleh Pemohon.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            key: const Key('btn_confirm_simpan_update_aset'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ya, Simpan'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await ref
        .read(staffAssetUpdateActionProvider.notifier)
        .processUpdate(
          mutationId: mutation.id,
          newLocation: _locationController.text.trim(),
          newPic: _picController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      ref.read(notificationProvider.notifier).notifyUser(
            targetUserId: mutation.applicantId ?? 'usr_pemohon',
            targetRole: UserRole.pemohon,
            title: 'Menunggu Konfirmasi Penerimaan',
            message:
                'Data fisik aset ${mutation.ticketNumber} (${mutation.asset.name}) telah diperbarui oleh Staff Aset. Silakan periksa dan konfirmasi penerimaan fisik.',
            type: NotificationType.action,
            relatedMutationId: mutation.id,
          );
      AppFeedback.showSuccess(
        context,
        'Lokasi & PIC aset ${mutation.asset.name} berhasil diperbarui. Status menjadi Menunggu Konfirmasi.',
      );
      _safePop(context);
    } else {
      final error = ref.read(staffAssetUpdateActionProvider).error;
      AppFeedback.showError(
        context,
        error ?? 'Gagal memperbarui data aset.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncMutation = ref.watch(mutationDetailProvider(widget.mutationId));
    final actionState = ref.watch(staffAssetUpdateActionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pembaruan Aset'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _safePop(context),
        ),
      ),
      body: asyncMutation.when(
        data: (mutation) {
          _initControllers(mutation);
          return _buildContent(context, mutation, actionState);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Gagal memuat detail mutasi: $err',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(mutationDetailProvider(widget.mutationId)),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Mutation mutation,
    StaffAssetUpdateActionState actionState,
  ) {
    final isWaitingUpdate = mutation.status == MutationStatus.approved;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card: No Tiket & Status
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nomor Tiket',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mutation.ticketNumber,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
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
                      color: mutation.status.backgroundColor,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      mutation.status.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: mutation.status.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Section 1: Informasi Aset
          _buildSectionCard(
            title: 'Informasi Aset',
            icon: Icons.inventory_2_outlined,
            children: [
              _buildRow('Nama Aset', mutation.asset.name),
              _buildRow('Kode Aset', mutation.asset.assetCode),
              _buildRow('Kategori', mutation.asset.category.name),
              _buildRow('Kondisi Fisik', mutation.asset.condition),
              _buildRow('Lokasi Sistem Awal', mutation.currentLocation),
              _buildRow('PIC Sistem Awal', mutation.currentPic),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Section 2: Info Pengajuan & Approval
          _buildSectionCard(
            title: 'Detail Pengajuan & Persetujuan',
            icon: Icons.verified_outlined,
            children: [
              _buildRow('Pemohon', mutation.applicantName),
              _buildRow('Alasan Mutasi', mutation.reason),
              if (mutation.documentName != null)
                _buildDocumentRow(mutation),
              if (mutation.approvedBy != null)
                _buildRow('Disetujui Kabag', mutation.approvedBy!),
              if (mutation.kadivApprovedBy != null)
                _buildRow('Disetujui Kadiv', mutation.kadivApprovedBy!),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Section 3: Form Pembaruan Lokasi & PIC
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              side: BorderSide(
                color: isWaitingUpdate ? AppColors.primary : AppColors.border,
                width: isWaitingUpdate ? 1.5 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.edit_location_alt_outlined,
                          color: isWaitingUpdate
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          isWaitingUpdate
                              ? 'Form Pembaruan Lokasi & PIC'
                              : 'Data Pembaruan Lokasi & PIC',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: AppSpacing.lg),

                    if (isWaitingUpdate) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.infoContainer,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: AppColors.info,
                            ),
                            SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                'Pastikan aset fisik telah dipindahkan. Periksa dan sesuaikan lokasi baru serta PIC penerima sebelum menyimpan data.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Input Lokasi Baru
                      CustomTextField(
                        key: const Key('input_lokasi_baru'),
                        label: 'Lokasi Baru',
                        hintText: 'Masukkan lokasi fisik baru aset',
                        controller: _locationController,
                        prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Lokasi baru wajib diisi.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          ActionChip(
                            key: const Key('chip_lokasi_asal'),
                            avatar: const Icon(Icons.history, size: 16),
                            label: Text('Asal: ${mutation.currentLocation}', style: const TextStyle(fontSize: 12)),
                            onPressed: () {
                              _locationController.text = mutation.currentLocation;
                            },
                          ),
                          ActionChip(
                            key: const Key('chip_lokasi_tujuan'),
                            avatar: const Icon(Icons.pin_drop, size: 16),
                            label: Text('Tujuan: ${mutation.targetLocation}', style: const TextStyle(fontSize: 12)),
                            onPressed: () {
                              _locationController.text = mutation.targetLocation;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Input PIC Baru
                      CustomTextField(
                        key: const Key('input_pic_baru'),
                        label: 'PIC (Penanggung Jawab) Baru',
                        hintText: 'Masukkan nama PIC penerima aset',
                        controller: _picController,
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'PIC baru wajib diisi.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          ActionChip(
                            key: const Key('chip_pic_lama'),
                            avatar: const Icon(Icons.person, size: 16),
                            label: Text('PIC Lama: ${mutation.currentPic}', style: const TextStyle(fontSize: 12)),
                            onPressed: () {
                              _picController.text = mutation.currentPic;
                            },
                          ),
                          ActionChip(
                            key: const Key('chip_pic_baru'),
                            avatar: const Icon(Icons.person_add, size: 16),
                            label: Text('PIC Tujuan: ${mutation.targetPic}', style: const TextStyle(fontSize: 12)),
                            onPressed: () {
                              _picController.text = mutation.targetPic;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Submit Button
                      CustomButton(
                        key: const Key('btn_submit_update_aset'),
                        label: 'Simpan Pembaruan Aset',
                        isLoading: actionState.isLoading,
                        icon: const Icon(Icons.check, size: 18, color: Colors.white),
                        onPressed: actionState.isLoading
                            ? null
                            : () => _submitUpdate(mutation),
                      ),
                    ] else ...[
                      // Sudah diupdate / menunggu konfirmasi / selesai
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.successContainer,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 18,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                mutation.status == MutationStatus.pendingConfirmation
                                    ? 'Aset telah diperbarui oleh Staff Aset. Saat ini menunggu konfirmasi Pemohon.'
                                    : 'Mutasi telah selesai.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildRow('Lokasi Baru', mutation.targetLocation),
                      _buildRow('PIC Baru', mutation.targetPic),
                      if (mutation.staffUpdatedBy != null)
                        _buildRow('Diperbarui Oleh', mutation.staffUpdatedBy!),
                      if (mutation.staffUpdatedAt != null)
                        _buildRow(
                          'Waktu Pembaruan',
                          '${mutation.staffUpdatedAt!.day.toString().padLeft(2, '0')}/${mutation.staffUpdatedAt!.month.toString().padLeft(2, '0')}/${mutation.staffUpdatedAt!.year}',
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentRow(Mutation mutation) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 130,
            child: Text(
              'Dokumen',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                DocumentPreviewDialog.show(
                  context,
                  mutation: mutation,
                  currentUser: ref.read(authStateProvider).user,
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.picture_as_pdf_outlined,
                      size: 16, color: AppColors.error),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      mutation.documentName!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.open_in_new,
                      size: 14, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _safePop(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      try {
        context.go(RouteNames.staffMutationsPath);
      } catch (_) {
        // Fallback for tests without GoRouter
      }
    }
  }
}
