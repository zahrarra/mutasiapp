// lib/features/pemohon/presentation/screens/pemohon_create_mutation_screen.dart
//
// Form Pengajuan Mutasi — visual Stitch “Executive Clean Form”.
// Font: Montserrat.
// Functionality: submit, dokumen, validasi, provider.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/services/document_picker_service.dart';
import '../../../../core/services/mutation_draft_service.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/document_preview_dialog.dart';
import '../../../../core/widgets/inline_searchable_dropdown.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mutation/domain/repositories/mutation_repository.dart';
import '../../../mutation/presentation/providers/mutation_form_provider.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';
import '../../../notification/domain/entities/notification_item.dart';
import '../../../notification/presentation/providers/notification_provider.dart';

abstract final class _C {
  static const bg = Color(0xFFF6F8FA);
  static const white = Color(0xFFFFFFFF);
  static const navy = Color(0xFF0F3D56);
  static const text = Color(0xFF172B4D);
  static const muted = Color(0xFF52606D);
  static const border = Color(0xFFD0D5DD);
  static const teal = Color(0xFF006A63);
  static const warning = Color(0xFFB45309);
  static const warningBg = Color(0xFFFEF3C7);
  static const warningBorder = Color(0xFFFDE68A);
  static const success = Color(0xFF15803D);
}

class PemohonCreateMutationScreen extends ConsumerStatefulWidget {
  const PemohonCreateMutationScreen({super.key});

  @override
  ConsumerState<PemohonCreateMutationScreen> createState() =>
      _PemohonCreateMutationScreenState();
}

class _PemohonCreateMutationScreenState
    extends ConsumerState<PemohonCreateMutationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _assetNameController = TextEditingController();
  final _assetCodeController = TextEditingController();
  final _sourceLocationController = TextEditingController();
  final _currentPicController = TextEditingController();
  final _locationController = TextEditingController();
  final _roomController = TextEditingController();
  final _picController = TextEditingController();
  final _reasonController = TextEditingController();

  String? _documentName;
  int? _documentSize;
  String? _documentPath;
  List<int>? _documentBytes;

  /// true = dibawa sendiri, false = ditinggalkan
  bool _bringAsset = true;

  String? _selectedAssetId;

  static const _maxReason = 250;

  @override
  void initState() {
    super.initState();

    _reasonController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    // Agar tampilan lokasi read-only ikut berubah
    // ketika lokasi asal diketik.
    _sourceLocationController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedDraft();
    });
  }

  @override
  void dispose() {
    _assetNameController.dispose();
    _assetCodeController.dispose();
    _sourceLocationController.dispose();
    _currentPicController.dispose();
    _locationController.dispose();
    _roomController.dispose();
    _picController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // TYPOGRAPHY
  // ---------------------------------------------------------------------------

  /// Style untuk teks yang diketik user.
  /// Sengaja dibuat kecil dan regular agar tidak terlalu besar/bold.
  TextStyle _inputTextStyle({Color color = _C.text, double size = 13}) {
    return GoogleFonts.montserrat(
      fontSize: size,
      fontWeight: FontWeight.w400,
      color: color,
      height: 1.35,
    );
  }

  TextStyle _m({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = _C.text,
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

  // ---------------------------------------------------------------------------
  // NAVIGATION
  // ---------------------------------------------------------------------------

  void _safePop() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.pemohonDashboardPath);
    }
  }

  // ---------------------------------------------------------------------------
  // DRAFT
  // ---------------------------------------------------------------------------

  Future<void> _loadSavedDraft() async {
    final user = ref.read(authStateProvider).user;
    final draft = await MutationDraftService.loadDraft(userId: user?.id);
    if (draft != null && mounted) {
      setState(() {
        _selectedAssetId = draft.assetId;
        _assetNameController.text = draft.assetName;
        _assetCodeController.text = draft.assetCode;
        _sourceLocationController.text = draft.sourceLocation;
        _currentPicController.text = draft.currentPic;
        _locationController.text = draft.targetLocation;
        _roomController.text = draft.room;
        _bringAsset = draft.bringAsset;
        _picController.text = draft.targetPic;
        _reasonController.text = draft.reason;
        _documentName = draft.documentName;
        _documentSize = draft.documentSize;
        _documentPath = draft.documentPath;
        _documentBytes = draft.documentBytes;
      });
      AppFeedback.showInfo(context, 'Draf pengajuan mutasi dimuat.');
    }
  }

  Future<void> _saveDraft() async {
    final user = ref.read(authStateProvider).user;
    final draft = MutationDraft(
      assetId: _selectedAssetId,
      assetName: _assetNameController.text.trim(),
      assetCode: _assetCodeController.text.trim(),
      sourceLocation: _sourceLocationController.text.trim(),
      currentPic: _currentPicController.text.trim(),
      targetLocation: _locationController.text.trim(),
      room: _roomController.text.trim(),
      bringAsset: _bringAsset,
      targetPic: _picController.text.trim(),
      reason: _reasonController.text.trim(),
      documentName: _documentName,
      documentSize: _documentSize,
      documentPath: _documentPath,
      documentBytes: _documentBytes,
      savedAt: DateTime.now(),
    );
    await MutationDraftService.saveDraft(draft, userId: user?.id);
    if (mounted) {
      AppFeedback.showSuccess(context, 'Draf pengajuan berhasil disimpan.');
      _safePop();
    }
  }

  // ---------------------------------------------------------------------------
  // DOCUMENT
  // ---------------------------------------------------------------------------

  void _previewDocument() {
    if (_documentName == null) return;
    DocumentPreviewDialog.showFile(
      context,
      fileName: _documentName!,
      bytes: _documentBytes != null ? Uint8List.fromList(_documentBytes!) : null,
      filePath: _documentPath,
    );
  }

  Future<void> _pickDocument() async {
    try {
      final result = await DocumentPickerService.pickDocument(
        allowedExtensions: const ['pdf'],
      );

      if (!mounted) return;

      if (result.isCanceled) return;

      if (result.isFailure) {
        AppFeedback.showError(
          context,
          result.errorMessage ?? 'Upload gagal. Ukuran file maksimal 30 MB.',
        );
        return;
      }

      final doc = result.document;

      if (doc != null) {
        setState(() {
          _documentName = doc.name;
          _documentSize = doc.size;
          _documentPath = doc.path;
          _documentBytes = doc.bytes;
        });

        AppFeedback.showSuccess(context, 'Dokumen diunggah: ${doc.name}');
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
          context,
          'Gagal mengunggah dokumen: $e',
        );
      }
    }
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '—';

    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }



  // ---------------------------------------------------------------------------
  // SUBMIT
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final user = ref.read(authStateProvider).user;

    final sourceLocation = _sourceLocationController.text.trim();
    final targetLoc = _locationController.text.trim();
    final room = _roomController.text.trim();

    // Lokasi tujuan lengkap.
    final fullTarget = room.isEmpty ? targetLoc : '$targetLoc — $room';

    // Pastikan lokasi asal benar-benar tersedia.
    if (sourceLocation.isEmpty) {
      AppFeedback.showError(context, 'Lokasi aset saat ini wajib diisi.');
      return;
    }

    if (targetLoc.isEmpty) {
      AppFeedback.showError(context, 'Lokasi tujuan wajib diisi.');
      return;
    }

    if (_documentName == null || _documentName!.trim().isEmpty) {
      AppFeedback.showError(
        context,
        'Surat Keputusan (SK) SDM wajib diunggah untuk pengajuan mutasi.',
      );
      return;
    }

    final targetPic = _bringAsset
        ? (_picController.text.trim().isNotEmpty
            ? _picController.text.trim()
            : (user?.name ?? ''))
        : '';

    final params = SubmitMutationParams(
      applicantId: user?.id,
      applicantName: user?.name,
      assetId: _selectedAssetId ??
          (_assetCodeController.text.trim().isNotEmpty
              ? _assetCodeController.text.trim()
              : 'AST-001'),
      assetName: _assetNameController.text.trim(),
      isAssetMovingWithApplicant: _bringAsset,
      isUnregisteredAsset: false,
      sourceLocation: sourceLocation,
      targetLocation: fullTarget,
      currentPic: _currentPicController.text.trim().isNotEmpty
          ? _currentPicController.text.trim()
          : (user?.name ?? ''),
      targetPic: targetPic,
      reason: _reasonController.text.trim(),
      documentName: _documentName,
      documentPath: _documentPath,
      documentBytes: _documentBytes,
    );

    final mutation = await ref
        .read(submitMutationProvider.notifier)
        .submit(params);

    if (!mounted) return;

    if (mutation != null) {
      await MutationDraftService.clearDraft(userId: user?.id);
      if (!mounted) return;

      ref
          .read(notificationProvider.notifier)
          .notifyRole(
            targetRole: UserRole.operator,
            title: 'Pengajuan Baru Masuk',
            message:
                'Pengajuan ${mutation.ticketNumber} diajukan oleh ${mutation.applicantName}.',
            type: NotificationType.action,
            relatedMutationId: mutation.id,
          );

      ref.invalidate(mutationListProvider);

      context.go(
        '${RouteNames.pemohonSubmitSuccessPath}'
        '?ticket=${Uri.encodeComponent(mutation.ticketNumber)}'
        '&id=${mutation.id}',
      );
    } else {
      final err = ref.read(submitMutationProvider).error;

      AppFeedback.showError(context, err ?? 'Gagal mengajukan mutasi');
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(submitMutationProvider);
    final locations = ref.watch(availableLocationsProvider);
    final user = ref.watch(authStateProvider).user;
    final initials = _initials(user?.name ?? 'P');

    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          _buildHeader(initials),

          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Form Pengajuan Mutasi',
                      style: _m(size: 20, weight: FontWeight.w700),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      'Pengalihan lokasi fisik dan penanggung jawab (PIC) aset dinas',
                      style: _m(size: 13, color: _C.muted),
                    ),

                    const SizedBox(height: 20),

                    _sectionAsset(locations),

                    const SizedBox(height: 16),

                    _sectionRoute(locations),

                    const SizedBox(height: 16),

                    _sectionReasonDoc(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomBar(submitState.isLoading),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _buildHeader(String initials) {
    return Material(
      color: _C.white.withValues(alpha: 0.95),
      elevation: 0.5,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Material(
                  color: _C.white,
                  shape: const CircleBorder(side: BorderSide(color: _C.border)),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _safePop,
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.arrow_back, size: 20, color: _C.text),
                    ),
                  ),
                ),

                const Spacer(),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFF99EFE5).withValues(alpha: 0.7),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: _C.teal,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'MUTASIKU',
                        style: _m(
                          size: 11,
                          weight: FontWeight.w700,
                          color: _C.navy,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _C.navy,
                        shape: BoxShape.circle,
                        border: Border.all(color: _C.border),
                      ),
                      child: Text(
                        initials,
                        style: _m(
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
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
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
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION ASET
  // ---------------------------------------------------------------------------

  Widget _sectionAsset(List<String> locations) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(Icons.inventory_2_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Informasi Aset Terdaftar',
                  style: _m(size: 14, weight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _C.warningBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _C.warningBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, size: 13, color: _C.warning),
                    const SizedBox(width: 4),
                    Text(
                      'Terkunci saat proses',
                      style: _m(
                        size: 11,
                        weight: FontWeight.w600,
                        color: _C.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          const Divider(height: 1, color: Color(0x99D0D5DD)),

          const SizedBox(height: 14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _C.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.border),
                ),
                child: const Icon(Icons.laptop_mac, size: 26, color: _C.text),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _assetNameController,
                      style: _inputTextStyle(),
                      decoration: _inputDeco('Nama aset *'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Wajib diisi'
                          : null,
                    ),

                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _assetCodeController,
                      style: _inputTextStyle(color: _C.muted),
                      decoration: _inputDeco('Kode / SN aset'),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _C.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.border),
            ),
            child: Column(
              children: [
                TextFormField(
                  controller: _currentPicController,
                  style: _inputTextStyle(),
                  decoration: _inputDeco('Pemegang / PIC saat ini'),
                ),

                const SizedBox(height: 8),

                InlineSearchableDropdown(
                  fieldKey: const Key('dropdown_source_location'),
                  controller: _sourceLocationController,
                  labelText: 'Unit kerja & lokasi asal *',
                  hintText: 'Pilih unit kerja & lokasi asal',
                  items: locations,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Lokasi aset saat ini wajib diisi'
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION RUTE
  // ---------------------------------------------------------------------------

  Widget _sectionRoute(List<String> locations) {
    final sourceLocation = _sourceLocationController.text.trim();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                child: const Icon(Icons.alt_route, size: 18, color: _C.navy),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  'Rute & Status Pengelolaan Fisik',
                  style: _m(size: 14, weight: FontWeight.w700),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Text(
                  'SOP-AST-2025',
                  style: _m(size: 10, weight: FontWeight.w600, color: _C.teal),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          const Divider(height: 1, color: Color(0x99D0D5DD)),

          const SizedBox(height: 14),

          Text(
            'LOKASI ASAL (READ-ONLY)',
            style: _m(
              size: 11,
              weight: FontWeight.w700,
              color: _C.muted,
              letterSpacing: 0.6,
            ),
          ),

          const SizedBox(height: 6),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _C.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _C.border.withValues(alpha: 0.7)),
            ),
            child: Row(
              children: [
                const Icon(Icons.apartment, size: 18, color: _C.muted),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    sourceLocation.isEmpty
                        ? 'Isi lokasi asal di bagian aset'
                        : sourceLocation,
                    style: _inputTextStyle(
                      color: sourceLocation.isEmpty ? _C.muted : _C.text,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'UNIT / CABANG PENUGASAN BARU',
            style: _m(
              size: 11,
              weight: FontWeight.w700,
              color: _C.muted,
              letterSpacing: 0.6,
            ),
          ),

          const SizedBox(height: 6),

          DropdownButtonFormField<String>(
            key: const Key('dropdown_target_location'),
            initialValue: locations.contains(_locationController.text.trim())
                ? _locationController.text.trim()
                : null,
            style: _inputTextStyle(),
            decoration: _inputDeco('Pilih unit / cabang tujuan *').copyWith(
              prefixIcon: const Icon(Icons.business, size: 20, color: _C.navy),
            ),
            icon: const Icon(Icons.expand_more, color: _C.muted),
            items: locations.map((loc) {
              return DropdownMenuItem<String>(
                value: loc,
                child: Text(loc, style: _inputTextStyle()),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _locationController.text = val;
                });
              }
            },
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Lokasi tujuan wajib dipilih'
                : null,
          ),

          const SizedBox(height: 14),

          Text(
            'RUANGAN / AREA PENEMPATAN',
            style: _m(
              size: 11,
              weight: FontWeight.w700,
              color: _C.muted,
              letterSpacing: 0.6,
            ),
          ),

          const SizedBox(height: 6),

          TextFormField(
            controller: _roomController,
            style: _inputTextStyle(),
            decoration: _inputDeco('Contoh: Lantai 1 — Ruang Operasional')
                .copyWith(
                  prefixIcon: const Icon(
                    Icons.meeting_room,
                    size: 18,
                    color: _C.muted,
                  ),
                ),
          ),

          const SizedBox(height: 14),

          Text(
            'ASET IKUT SAYA PINDAH? *',
            style: _m(
              size: 11,
              weight: FontWeight.w700,
              color: _C.muted,
              letterSpacing: 0.6,
            ),
          ),

          const SizedBox(height: 8),

          _radioHandling(
            selected: _bringAsset,
            title: 'Ya, Aset Ikut Saya Pindah',
            badge: 'Bawa Sendiri',
            badgeGreen: true,
            body: 'Perangkat tetap digunakan & dibawa pemohon ke unit penugasan baru.',
            icon: Icons.work_outline,
            onTap: () => setState(() => _bringAsset = true),
          ),

          const SizedBox(height: 10),

          _radioHandling(
            selected: !_bringAsset,
            title: 'Tidak, Aset Ditinggalkan di Unit Asal',
            badge: 'Tinggalkan',
            badgeGreen: false,
            body: 'Aset fisik ditinggalkan di unit kerja saat ini. PIC baru akan ditentukan oleh Bagian Aset melalui sistem.',
            icon: Icons.warehouse_outlined,
            onTap: () => setState(() => _bringAsset = false),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(12),
              border: const Border(left: BorderSide(color: _C.teal, width: 4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.policy_outlined, size: 18, color: _C.teal),

                const SizedBox(width: 10),

                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: _m(size: 12, color: _C.muted, height: 1.4),
                      children: [
                        TextSpan(
                          text: 'Ketentuan Tata Kelola Inventaris:\n',
                          style: _m(size: 12, weight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: _bringAsset
                              ? 'Aset dibawa ke unit baru dan PIC tetap Pemohon. Master inventaris akan diperbarui setelah konfirmasi serah terima.'
                              : 'Aset ditinggalkan di lokasi asal. PIC baru akan ditentukan oleh Bagian Aset melalui sistem saat verifikasi.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_bringAsset) ...[
            const SizedBox(height: 12),

            InlineSearchableDropdown(
              controller: _picController,
              labelText: 'PIC tujuan (otomatis Pemohon, atau nama PIC baru) *',
              hintText: 'Pilih atau cari PIC tujuan',
              items: ref.watch(availablePicsProvider),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // RADIO
  // ---------------------------------------------------------------------------

  Widget _radioHandling({
    required bool selected,
    required String title,
    required String badge,
    required bool badgeGreen,
    required String body,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? const Color(0xFFF7F9FF) : _C.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _C.navy : _C.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 20,
                color: selected ? _C.navy : _C.muted,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          icon,
                          size: 16,
                          color: selected ? _C.navy : _C.muted,
                        ),

                        const SizedBox(width: 6),

                        Expanded(
                          child: Text(
                            title,
                            style: _m(size: 13, weight: FontWeight.w700),
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeGreen ? const Color(0xFFECFDF5) : _C.bg,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: badgeGreen
                                  ? const Color(0xFFA7F3D0)
                                  : _C.border,
                            ),
                          ),
                          child: Text(
                            badge,
                            style: _m(
                              size: 10,
                              weight: FontWeight.w700,
                              color: badgeGreen ? _C.success : _C.muted,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      body,
                      style: _m(size: 12, color: _C.muted, height: 1.35),
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

  // ---------------------------------------------------------------------------
  // SECTION ALASAN & DOKUMEN
  // ---------------------------------------------------------------------------

  Widget _sectionReasonDoc() {
    final len = _reasonController.text.length;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, size: 20, color: _C.navy),

              const SizedBox(width: 8),

              Text(
                'Alasan & Dokumen Otorisasi',
                style: _m(size: 14, weight: FontWeight.w700),
              ),
            ],
          ),

          const SizedBox(height: 12),

          const Divider(height: 1, color: Color(0x99D0D5DD)),

          const SizedBox(height: 14),

          Row(
            children: [
              Text(
                'ALASAN KEBUTUHAN MUTASI *',
                style: _m(
                  size: 11,
                  weight: FontWeight.w600,
                  color: _C.muted,
                  letterSpacing: 0.5,
                ),
              ),

              const Spacer(),

              Text(
                '$len / $_maxReason',
                style: _m(size: 11, weight: FontWeight.w500, color: _C.muted),
              ),
            ],
          ),

          const SizedBox(height: 6),

          TextFormField(
            controller: _reasonController,
            maxLength: _maxReason,
            maxLines: 3,
            style: _inputTextStyle(size: 13),
            decoration: _inputDeco('Jelaskan alasan mutasi...')
                .copyWith(counterText: ''),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Alasan wajib diisi' : null,
          ),

          const SizedBox(height: 14),

          Text(
            'SURAT KEPUTUSAN (SK) SDM *',
            style: _m(
              size: 11,
              weight: FontWeight.w700,
              color: _C.muted,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            'PDF wajib, maksimal 30 MB',
            style: _m(
              size: 11,
              weight: FontWeight.w500,
              color: _C.muted,
            ),
          ),

          const SizedBox(height: 8),

          if (_documentName != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _C.bg.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _C.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf,
                      size: 20,
                      color: Color(0xFFDC2626),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _documentName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _m(size: 13, weight: FontWeight.w500),
                        ),
                        Text(
                          _formatFileSize(_documentSize),
                          style: _m(size: 11, color: _C.muted),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    tooltip: 'Lihat dokumen',
                    icon: const Icon(Icons.visibility_outlined, size: 20, color: _C.navy),
                    onPressed: _previewDocument,
                  ),

                  TextButton(
                    onPressed: () {
                      setState(() {
                        _documentName = null;
                        _documentSize = null;
                        _documentPath = null;
                        _documentBytes = null;
                      });
                    },
                    child: Text(
                      'Hapus',
                      style: _m(
                        size: 12,
                        weight: FontWeight.w600,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
          ],

          OutlinedButton.icon(
            onPressed: _pickDocument,
            style: OutlinedButton.styleFrom(
              foregroundColor: _C.navy,
              side: const BorderSide(color: _C.border),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.upload_file, size: 18),
            label: Text(
              _documentName == null
                  ? 'Unggah Berkas'
                  : 'Unggah Berkas Tambahan',
              style: _m(size: 12, weight: FontWeight.w600, color: _C.navy),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM BAR
  // ---------------------------------------------------------------------------

  Widget _bottomBar(bool loading) {
    return Container(
      decoration: BoxDecoration(
        color: _C.white.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: Color(0xCCD0D5DD))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: loading ? null : _saveDraft,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _C.text,
                      side: const BorderSide(color: _C.border),
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.bookmark_border, size: 18),
                    label: Text(
                      'Simpan Draf',
                      style: _m(size: 13, weight: FontWeight.w700),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.navy,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Lanjut ke Konfirmasi',
                                  style: _m(
                                    size: 13,
                                    weight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_forward, size: 18),
                              ],
                            ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_user, size: 12, color: _C.teal),

                  const SizedBox(width: 4),

                  Flexible(
                    child: Text(
                      'Sesuai PRD MutasiKu • Tiket diterbitkan otomatis',
                      textAlign: TextAlign.center,
                      style: _m(
                        size: 10,
                        weight: FontWeight.w500,
                        color: _C.muted,
                      ),
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

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: _C.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _C.border),
      ),
      child: Icon(icon, size: 18, color: _C.text),
    );
  }

  // ---------------------------------------------------------------------------
  // INPUT DECORATION
  // ---------------------------------------------------------------------------

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,

      // Hint juga tidak bold.
      hintStyle: _inputTextStyle(color: _C.muted, size: 12.5),

      filled: true,
      fillColor: _C.white,

      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _C.border),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _C.border),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _C.navy, width: 1.5),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFB42318)),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFB42318), width: 1.5),
      ),
    );
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
}
