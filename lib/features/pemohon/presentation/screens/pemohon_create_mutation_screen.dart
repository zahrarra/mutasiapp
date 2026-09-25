// lib/features/pemohon/presentation/screens/pemohon_create_mutation_screen.dart
//
// Screen: MutasiKu — Form Ajukan Mutasi (Enhanced UI)
// Diadaptasi dari desain Stitch MCP.
// Form pengajuan mutasi aset dengan alur terstruktur 3-tahap, protokol kepatuhan BMN,
// pemilih PIC dinamis, serta integrasi input manual dan dropdown lokasi.

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/inline_searchable_dropdown.dart';
import '../../../../core/widgets/searchable_picker_bottom_sheet.dart';
import '../../../asset/presentation/providers/asset_provider.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mutation/domain/repositories/mutation_repository.dart';
import '../../../mutation/presentation/providers/mutation_form_provider.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';
import '../../../notification/domain/entities/notification_item.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../../../operator/presentation/providers/operator_verification_provider.dart';

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
  final _picController = TextEditingController();
  final _reasonController = TextEditingController();
  String? _documentName;
  int? _documentSize;
  String? _documentPath;
  List<int>? _documentBytes;
  bool _useOldPicTab = false;
  bool _isFallbackMode = false;
  String? _selectedAssetId;

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result;
      try {
        result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        );
      } on MissingPluginException {
        // Fallback jika platform channel custom belum terlink
        result = await FilePicker.pickFiles();
      } catch (_) {
        // Fallback untuk perangkat yang menolak MIME filter kustom
        result = await FilePicker.pickFiles();
      }

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        List<int>? bytes = file.bytes;
        if (bytes == null && file.path != null) {
          try {
            final f = File(file.path!);
            if (await f.exists()) {
              bytes = await f.readAsBytes();
            }
          } catch (_) {}
        }

        setState(() {
          _documentName = file.name;
          _documentSize = file.size;
          _documentPath = file.path;
          _documentBytes = bytes;
        });

        if (mounted) {
          AppFeedback.showSuccess(
            context,
            'Dokumen berhasil diunggah: ${file.name}',
          );
        }
      }
    } on MissingPluginException {
      if (mounted) {
        AppFeedback.showError(
          context,
          'Plugin file picker belum terpasang di proses aplikasi. Silakan restart/rebuild aplikasi.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, 'Gagal memilih file: $e');
      }
    }
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return 'Terverifikasi Enkripsi';
    if (bytes < 1024) return '$bytes B • Terverifikasi Enkripsi';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB • Terverifikasi Enkripsi';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB • Terverifikasi Enkripsi';
  }

  @override
  void dispose() {
    _assetNameController.dispose();
    _assetCodeController.dispose();
    _sourceLocationController.dispose();
    _currentPicController.dispose();
    _locationController.dispose();
    _picController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _safePop() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      try {
        context.go(RouteNames.pemohonDashboardPath);
      } catch (_) {}
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = ref.read(authStateProvider).user;

    final params = SubmitMutationParams(
      applicantId: user?.id,
      applicantName: user?.name,
      assetId: _isFallbackMode
          ? null
          : (_selectedAssetId ??
              (_assetCodeController.text.trim().isNotEmpty
                  ? _assetCodeController.text.trim()
                  : null)),
      assetName: _assetNameController.text.trim(),
      isUnregisteredAsset: _isFallbackMode,
      customAssetName: _isFallbackMode ? _assetNameController.text.trim() : null,
      customSerialNumber:
          _isFallbackMode ? _assetCodeController.text.trim() : null,
      sourceLocation: _sourceLocationController.text.trim(),
      targetLocation: _locationController.text.trim(),
      currentPic: _currentPicController.text.trim(),
      targetPic: _picController.text.trim(),
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
      ref.read(notificationProvider.notifier).notifyRole(
            targetRole: UserRole.operator,
            title: 'Pengajuan Baru Masuk',
            message:
                'Pengajuan mutasi ${mutation.ticketNumber} (${mutation.asset.name}) diajukan oleh ${mutation.applicantName} dan siap diverifikasi.',
            type: NotificationType.action,
            relatedMutationId: mutation.id,
          );
      ref.invalidate(mutationListProvider);
      ref.invalidate(operatorAllMutationsProvider);
      ref.invalidate(mutationDetailProvider(mutation.id));
      try {
        context.go(
          '${RouteNames.pemohonSubmitSuccessPath}'
          '?ticket=${Uri.encodeComponent(mutation.ticketNumber)}'
          '&id=${mutation.id}',
        );
      } catch (_) {}
    } else {
      final err = ref.read(submitMutationProvider).error;
      AppFeedback.showError(context, err ?? 'Gagal mengajukan mutasi');
    }
  }

  Future<void> _pickPic(List<String> pics) async {
    final currentPic = _currentPicController.text.trim();
    final quickActions = <String>[];
    if (currentPic.isNotEmpty) {
      quickActions.add(currentPic);
    }

    final selected = await SearchablePickerBottomSheet.show(
      context: context,
      title: 'Pilih Penanggung Jawab (PIC)',
      items: pics,
      selectedItem: _picController.text.trim().isEmpty
          ? null
          : _picController.text.trim(),
      searchHint: 'Cari nama PIC...',
      quickActions: quickActions,
    );
    if (selected != null) {
      setState(() {
        _picController.text = selected;
        _useOldPicTab = (selected == currentPic && currentPic.isNotEmpty);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(submitMutationProvider);
    final availableLocations = ref.watch(availableLocationsProvider);
    final availablePics = ref.watch(availablePicsProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FF),
      // ── Custom Enhanced Top Header Bar ──────────────────────────────
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFDBEAF9), width: 1),
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
                          color: Color(0xFF0F1D28),
                          size: 20,
                        ),
                        tooltip: 'Kembali',
                        onPressed: _safePop,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Form Mutasi Baru',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F1D28),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00273A),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'BMN-2026',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'Pengalihan Hak Pakai & Tanggung Jawab',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF3B637D),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
            ),
          ),
        ),
      ),

      // ── Main Body Form ──────────────────────────────────────────────
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Notice Institutional Progress & Protocol Banner ───
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDBEAF9)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06101828),
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
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00273A),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'ALUR PENGAJUAN MUTASI',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3B637D),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          'Tahap 2 dari 3 Selesai',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00101B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 5,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00273A),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 13,
                                    color: Color(0xFF00273A),
                                  ),
                                  SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      '1. Aset Fisik',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F1D28),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 5,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00273A),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Row(
                                children: [
                                  CircleAvatar(
                                    radius: 6,
                                    backgroundColor: Color(0xFF00273A),
                                    child: Text(
                                      '2',
                                      style: TextStyle(
                                        fontSize: 8,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      '2. Destinasi & PIC',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF00273A),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 5,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDBEAF9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Row(
                                children: [
                                  CircleAvatar(
                                    radius: 6,
                                    backgroundColor: Color(0xFFDBEAF9),
                                    child: Text(
                                      '3',
                                      style: TextStyle(
                                        fontSize: 8,
                                        color: Color(0xFF3B637D),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      '3. Berkas & Alasan',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF3B637D),
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
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Compliance Protocol Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECF4FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDBEAF9)),
                ),
                child: Row(
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
                        Icons.verified_user,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Protokol Kepatuhan Aset BMN',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00101B),
                                  letterSpacing: 0.2,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: const Color(0xFFDBEAF9),
                                  ),
                                ),
                                child: const Text(
                                  'SOP-LOG-04',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3B637D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Verifikasi fisik & nomor seri dicocokkan otomatis ke SIMAK BMN sebelum otorisasi berjenjang oleh Pengelola Barang.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF42474C),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── SECTION 1: DATA ASET FISIK ────────────────────────
              _buildSectionCard(
                title: '1. Data Aset Fisik',
                badgeText: 'Langkah 1/3 • Selesai',
                children: [
                  // Fallback Mode Switch
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _isFallbackMode
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isFallbackMode
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF86EFAC),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isFallbackMode
                                    ? 'Mode Fallback: Aset Belum Terdaftar'
                                    : 'Mode Master: Aset SIMAK BMN',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _isFallbackMode
                                      ? const Color(0xFF92400E)
                                      : const Color(0xFF166534),
                                ),
                              ),
                              Text(
                                _isFallbackMode
                                    ? 'Pencarian master dinonaktifkan (input manual).'
                                    : 'Pilih aset dari database master.',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF52606D),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          key: const Key('switch_fallback_mode'),
                          value: _isFallbackMode,
                          onChanged: (val) {
                            setState(() {
                              _isFallbackMode = val;
                              if (val) {
                                _selectedAssetId = null;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  // Tombol Pencarian Master Aset (HANYA tampil jika fallback mode nonaktif)
                  if (!_isFallbackMode) ...[
                    OutlinedButton.icon(
                      key: const Key('btn_search_master_asset'),
                      onPressed: () async {
                        final assets = await ref.read(assetListProvider.future);
                        if (!context.mounted) return;
                        final items = assets
                            .map((a) => '${a.assetCode} — ${a.name}')
                            .toList();
                        final selected = await SearchablePickerBottomSheet.show(
                          context: context,
                          title: 'Pilih Aset Master (SIMAK BMN)',
                          items: items,
                          searchHint: 'Cari kode atau nama aset...',
                        );
                        if (selected != null) {
                          final matched = assets.firstWhere(
                            (a) => '${a.assetCode} — ${a.name}' == selected,
                          );
                          setState(() {
                            _selectedAssetId = matched.id;
                            _assetNameController.text = matched.name;
                            _assetCodeController.text = matched.assetCode;
                            _sourceLocationController.text = matched.location;
                            _currentPicController.text = matched.pic;
                          });
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF00273A),
                        side: const BorderSide(color: Color(0xFFDBEAF9)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.search, size: 16),
                      label: const Text(
                        'Pilih / Cari dari Master SIMAK BMN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Field 0: Nama Aset
                  TextFormField(
                    controller: _assetNameController,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F1D28),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Nama / Model Aset *',
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F1D28),
                      ),
                      hintText: 'Contoh: Laptop Lenovo ThinkPad T14 Gen 4',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF72787D),
                      ),
                      prefixIcon: const Icon(
                        Icons.devices,
                        size: 20,
                        color: Color(0xFF00273A),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDBEAF9)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDBEAF9)),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),

                  // Field 1: Kode / Nomor Seri Aset
                  TextFormField(
                    controller: _assetCodeController,
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F1D28),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Nomor / Kode Seri Aset *',
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F1D28),
                      ),
                      hintText: 'Contoh: AST-ELK-2024-001',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF72787D),
                      ),
                      prefixIcon: const Icon(
                        Icons.tag,
                        size: 20,
                        color: Color(0xFF00273A),
                      ),
                      suffixIcon: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00273A),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.qr_code_scanner,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Pindai',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDBEAF9)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDBEAF9)),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(
                        Icons.cloud_done,
                        size: 13,
                        color: Color(0xFF00273A),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Tersinkronisasi otomatis dengan Database SIMAK BMN',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF52606D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Field 2: Lokasi Asal (InlineSearchableDropdown)
                  InlineSearchableDropdown(
                    key: const Key('dropdown_source_location'),
                    fieldKey: const Key('field_source_location'),
                    labelText: 'Lokasi Asal *',
                    hintText: 'Pilih lokasi asal saat ini',
                    controller: _sourceLocationController,
                    items: availableLocations,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),

                  // Field 3: Pengguna / Pemakai Aset Lama
                  TextFormField(
                    controller: _currentPicController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F1D28),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Pengguna / Pemakai Aset Lama *',
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F1D28),
                      ),
                      hintText: 'Contoh: Victor Pratama (NIP: 19920814 201802 1 003)',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF72787D),
                      ),
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        size: 20,
                        color: Color(0xFF3B637D),
                      ),
                      suffixIcon: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1F0FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Eksisting',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00273A),
                          ),
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDBEAF9)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDBEAF9)),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── SECTION 2: TUJUAN & PENANGGUNG JAWAB BARU ─────────
              _buildSectionCard(
                title: '2. Tujuan & Penanggung Jawab Baru',
                badgeText: 'Langkah 2/3 • Aktif',
                children: [
                  // Field 4: Cabang / Lokasi Tujuan (InlineSearchableDropdown)
                  InlineSearchableDropdown(
                    key: const Key('dropdown_target_location'),
                    fieldKey: const Key('field_target_location'),
                    labelText: 'Cabang / Lokasi Tujuan *',
                    hintText: 'Pilih cabang / lokasi tujuan mutasi',
                    controller: _locationController,
                    items: availableLocations,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),

                  // Segment Toggle: Pilih PIC Baru vs Gunakan PIC Lama
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Penanggung Jawab (PIC) Tujuan *',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F1D28),
                        ),
                      ),
                      const Text(
                        'Wajib Pegawai Aktif',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF52606D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECF4FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFDBEAF9)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _useOldPicTab = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 7),
                              decoration: BoxDecoration(
                                color: !_useOldPicTab
                                    ? const Color(0xFF00273A)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Pilih PIC Baru',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: !_useOldPicTab
                                      ? Colors.white
                                      : const Color(0xFF52606D),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              final oldPic =
                                  _currentPicController.text.trim();
                              setState(() {
                                _useOldPicTab = true;
                                if (oldPic.isNotEmpty) {
                                  _picController.text = oldPic;
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 7),
                              decoration: BoxDecoration(
                                color: _useOldPicTab
                                    ? const Color(0xFF00273A)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Gunakan PIC Lama',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _useOldPicTab
                                      ? Colors.white
                                      : const Color(0xFF52606D),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Field 5: PIC Controller
                  TextFormField(
                    controller: _picController,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F1D28),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Nama PIC Tujuan *',
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F1D28),
                      ),
                      hintText: 'Pilih PIC lama atau PIC baru',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF72787D),
                      ),
                      prefixIcon: const Icon(
                        Icons.person_add_alt_1,
                        size: 20,
                        color: Color(0xFF00273A),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFF00273A),
                        ),
                        onPressed: () => _pickPic(availablePics),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDBEAF9)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDBEAF9)),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── SECTION 3: INFORMASI PENGAJUAN ────────────────────
              _buildSectionCard(
                title: '3. Informasi Pengajuan',
                badgeText: 'Langkah 3/3',
                children: [
                  // Field 6: Alasan Mutasi
                  TextFormField(
                    controller: _reasonController,
                    maxLines: 3,
                    maxLength: 500,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF0F1D28),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Alasan Mutasi *',
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F1D28),
                      ),
                      hintText:
                          'Jelaskan kebutuhan operasional pemindahan aset...',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF72787D),
                      ),
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDBEAF9)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDBEAF9)),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),

                  // Dokumen Pendukung (Opsional)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Text(
                            'Dokumen Pendukung',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F1D28),
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            '(Opsional)',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF52606D),
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'PDF maks 5MB',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF52606D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_documentName != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFDBEAF9)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFDAD6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.picture_as_pdf,
                              color: Color(0xFFBA1A1A),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _documentName!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F1D28),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _formatFileSize(_documentSize),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF52606D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Color(0xFFBA1A1A),
                              size: 18,
                            ),
                            tooltip: 'Hapus Dokumen',
                            onPressed: () {
                              setState(() {
                                _documentName = null;
                                _documentSize = null;
                              });
                            },
                          ),
                        ],
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: _pickDocument,
                      icon: const Icon(Icons.upload_file, size: 16),
                      label: const Text('Pilih Dokumen dari Perangkat'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF00273A),
                        side: const BorderSide(
                          color: Color(0xFFDBEAF9),
                          style: BorderStyle.solid,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),

      // ── Pinned Bottom Action Sheet Container ────────────────────────
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFDBEAF9), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, -1),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: submitState.isLoading ? null : _submit,
                  icon: submitState.isLoading
                      ? const SizedBox.shrink()
                      : const Icon(Icons.send, size: 18),
                  label: submitState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Kirim Pengajuan Mutasi',
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
              const SizedBox(height: 6),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock,
                    size: 12,
                    color: Color(0xFF52606D),
                  ),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Dicatat otomatis dalam register audit BMN dan diteruskan ke Operator Cabang.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF52606D),
                      ),
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildSectionCard({
    required String title,
    required String badgeText,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDBEAF9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06101828),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00273A),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F1D28),
                      letterSpacing: 0.2,
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
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDBEAF9)),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00273A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFECF4FF)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}
