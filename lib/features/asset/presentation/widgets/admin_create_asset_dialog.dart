// lib/features/asset/presentation/widgets/admin_create_asset_dialog.dart
//
// Dialog Form Create Asset untuk Admin.
// Terintegrasi dengan POST /api/v1/admin/assets.
// Mengikuti typography dan visual standard Stitch Admin.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mutation/presentation/providers/mutation_form_provider.dart';
import '../../domain/repositories/asset_repository.dart';
import '../providers/asset_provider.dart';

class AdminCreateAssetDialog extends ConsumerStatefulWidget {
  const AdminCreateAssetDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AdminCreateAssetDialog(),
    );
  }

  @override
  ConsumerState<AdminCreateAssetDialog> createState() =>
      _AdminCreateAssetDialogState();
}

class _AdminCreateAssetDialogState
    extends ConsumerState<AdminCreateAssetDialog> {
  final _formKey = GlobalKey<FormState>();

  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _acquisitionYearController = TextEditingController();
  final _usageYearController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedLocationId;
  String? _selectedPicId;
  String _selectedCondition = 'Baik';

  bool _isSubmitting = false;
  String? _errorMessage;

  final List<String> _conditions = [
    'Baik',
    'Rusak Ringan',
    'Rusak Berat',
  ];

  @override
  void initState() {
    super.initState();
    _acquisitionYearController.text = DateTime.now().year.toString();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _serialNumberController.dispose();
    _acquisitionYearController.dispose();
    _usageYearController.dispose();
    super.dispose();
  }

  /// Label di atas setiap input field (weight medium/normal, tidak bold).
  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF334155),
        ),
      ),
    );
  }

  /// Dekorasi input box dengan hint normal dan border bersih.
  InputDecoration _inputDecoration({
    required String hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      isDense: true,
      hintText: hintText,
      hintStyle: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF94A3B8),
      ),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 18, color: const Color(0xFF64748B))
          : null,
      prefixIconConstraints: const BoxConstraints(
        minWidth: 40,
        minHeight: 40,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF0F3D56), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      errorStyle: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: const Color(0xFFEF4444),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    debugPrint('[AdminCreateAssetDialog] _handleSubmit dipanggil');
    if (_isSubmitting) return;

    setState(() => _errorMessage = null);

    // 1. Validasi form input
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      debugPrint('[AdminCreateAssetDialog] Validasi form gagal');
      setState(() {
        _errorMessage = 'Harap lengkapi semua field formulir wajib dengan benar.';
      });
      AppFeedback.showError(
        context,
        'Harap lengkapi semua field formulir wajib dengan benar.',
      );
      return;
    }

    // 2. Validasi field dropdown
    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      setState(() => _errorMessage = 'Kategori aset wajib dipilih.');
      AppFeedback.showError(context, 'Kategori aset wajib dipilih');
      return;
    }
    if (_selectedLocationId == null || _selectedLocationId!.isEmpty) {
      setState(() => _errorMessage = 'Lokasi aset wajib dipilih.');
      AppFeedback.showError(context, 'Lokasi aset wajib dipilih');
      return;
    }
    if (_selectedPicId == null || _selectedPicId!.isEmpty) {
      setState(() => _errorMessage = 'Penanggung Jawab (PIC) wajib dipilih.');
      AppFeedback.showError(context, 'Penanggung Jawab (PIC) wajib dipilih');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final acqYear = int.tryParse(_acquisitionYearController.text.trim()) ??
          DateTime.now().year;
      final usageYearText = _usageYearController.text.trim();
      final usageYear =
          usageYearText.isNotEmpty ? int.tryParse(usageYearText) : null;

      final params = CreateAssetParams(
        assetCode: _codeController.text.trim(),
        name: _nameController.text.trim(),
        assetCategoryId: _selectedCategoryId!,
        locationId: _selectedLocationId!,
        picId: _selectedPicId!,
        condition: _selectedCondition,
        serialNumber: _serialNumberController.text.trim(),
        acquisitionYear: acqYear,
        usageYear: usageYear,
        isActive: true,
      );

      debugPrint(
        '[AdminCreateAssetDialog] Mengirim createAsset: ${params.assetCode}, ${params.name}',
      );

      final createdAsset = await ref
          .read(createAssetNotifierProvider.notifier)
          .createAsset(params);

      if (!mounted) return;

      setState(() => _isSubmitting = false);

      if (createdAsset != null) {
        debugPrint(
          '[AdminCreateAssetDialog] Aset berhasil dibuat: id=${createdAsset.id}, code=${createdAsset.assetCode}',
        );
        AppFeedback.showSuccess(
          context,
          'Aset baru berhasil dibuat: ${createdAsset.name} (${createdAsset.assetCode})',
        );
        Navigator.of(context).pop(true);
      } else {
        final errorState = ref.read(createAssetNotifierProvider).error;
        final errorMsg =
            errorState ?? 'Gagal menambahkan aset. Terjadi kesalahan sistem.';
        debugPrint('[AdminCreateAssetDialog] Gagal create: $errorMsg');
        setState(() => _errorMessage = errorMsg);
        AppFeedback.showError(
          context,
          'Gagal menambahkan aset',
          details: errorMsg,
        );
      }
    } catch (e, stack) {
      debugPrint('[AdminCreateAssetDialog] Exception saat submit: $e\n$stack');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Terjadi kesalahan sistem: $e';
        });
        AppFeedback.showError(
          context,
          'Terjadi kesalahan saat memproses formulir',
          details: e.toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(assetCategoriesProvider);
    final locationsAsync = ref.watch(masterLocationsProvider);
    final usersAsync = ref.watch(masterUsersProvider);

    final currentMaxYear = DateTime.now().year + 1;

    final inputTextStyle = GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF0F172A),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Dialog Header ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF0F3D56),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
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
                          'Tambah Aset Baru',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Daftarkan inventaris baru ke Master Aset MutasiKu',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // ── Form Content ───────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Inline Error Banner jika terjadi kegagalan validasi / API submit
                      if (_errorMessage != null) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFFCA5A5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Color(0xFFDC2626),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF991B1B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Kode Aset & Nomor Seri (2 Kolom)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Kode Aset *'),
                                TextFormField(
                                  controller: _codeController,
                                  style: inputTextStyle,
                                  decoration: _inputDecoration(
                                    hintText: 'Misal: AST-IT-2026-001',
                                    prefixIcon: Icons.qr_code,
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Kode aset wajib diisi';
                                    }
                                    if (val.trim().length > 50) {
                                      return 'Maksimal 50 karakter';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Nomor Seri (SN) *'),
                                TextFormField(
                                  controller: _serialNumberController,
                                  style: inputTextStyle,
                                  decoration: _inputDecoration(
                                    hintText: 'Misal: SN82914029',
                                    prefixIcon: Icons.tag,
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Nomor seri wajib diisi';
                                    }
                                    if (val.trim().length > 100) {
                                      return 'Maksimal 100 karakter';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Nama Aset
                      _buildFieldLabel('Nama Aset *'),
                      TextFormField(
                        controller: _nameController,
                        style: inputTextStyle,
                        decoration: _inputDecoration(
                          hintText: 'Misal: Laptop Dell Latitude 5420 Core i7',
                          prefixIcon: Icons.devices,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nama aset wajib diisi';
                          }
                          if (val.trim().length > 255) {
                            return 'Maksimal 255 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Kategori Aset Dropdown
                      _buildFieldLabel('Kategori Aset *'),
                      categoriesAsync.when(
                        data: (categories) {
                          final activeCats =
                              categories.where((c) => c.isActive).toList();
                          return DropdownButtonFormField<String>(
                            initialValue: _selectedCategoryId,
                            isExpanded: true,
                            style: inputTextStyle,
                            hint: Text(
                              'Pilih Kategori Aset',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                            decoration: _inputDecoration(
                              hintText: 'Pilih Kategori Aset',
                              prefixIcon: Icons.category_outlined,
                            ),
                            items: activeCats.map((cat) {
                              return DropdownMenuItem<String>(
                                value: cat.id,
                                child: Text(
                                  '${cat.name} (${cat.code})',
                                  style: inputTextStyle,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedCategoryId = val;
                                _errorMessage = null;
                              });
                            },
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Kategori aset wajib dipilih';
                              }
                              return null;
                            },
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (error, stack) => Text(
                          'Gagal memuat kategori aset',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Lokasi / Unit Kerja Dropdown
                      _buildFieldLabel('Lokasi / Unit Kerja *'),
                      locationsAsync.when(
                        data: (locations) {
                          final activeLocations =
                              locations.where((l) => l.isActive).toList();
                          return DropdownButtonFormField<String>(
                            initialValue: _selectedLocationId,
                            isExpanded: true,
                            style: inputTextStyle,
                            hint: Text(
                              'Pilih Lokasi Penempatan',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                            decoration: _inputDecoration(
                              hintText: 'Pilih Lokasi Penempatan',
                              prefixIcon: Icons.location_on_outlined,
                            ),
                            items: activeLocations.map((loc) {
                              final desc = loc.description?.trim();
                              final label = desc != null && desc.isNotEmpty
                                  ? '${loc.name} ($desc)'
                                  : loc.name;
                              return DropdownMenuItem<String>(
                                value: loc.id,
                                child: Text(
                                  label,
                                  style: inputTextStyle,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedLocationId = val;
                                _errorMessage = null;
                              });
                            },
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Lokasi aset wajib dipilih';
                              }
                              return null;
                            },
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (error, stack) => Text(
                          'Gagal memuat lokasi aset',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // PIC Dropdown
                      _buildFieldLabel('Penanggung Jawab (PIC) *'),
                      usersAsync.when(
                        data: (users) {
                          final activeUsers =
                              users.where((u) => u.isActive).toList();
                          return DropdownButtonFormField<String>(
                            initialValue: _selectedPicId,
                            isExpanded: true,
                            style: inputTextStyle,
                            hint: Text(
                              'Pilih User PIC',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                            decoration: _inputDecoration(
                              hintText: 'Pilih User PIC',
                              prefixIcon: Icons.person_outline,
                            ),
                            items: activeUsers.map((u) {
                              return DropdownMenuItem<String>(
                                value: u.id,
                                child: Text(
                                  '${u.name} - ${u.role.displayName}',
                                  style: inputTextStyle,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedPicId = val;
                                _errorMessage = null;
                              });
                            },
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'PIC aset wajib dipilih';
                              }
                              return null;
                            },
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (error, stack) => Text(
                          'Gagal memuat daftar PIC',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Kondisi Dropdown
                      _buildFieldLabel('Kondisi Aset *'),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCondition,
                        isExpanded: true,
                        style: inputTextStyle,
                        decoration: _inputDecoration(
                          hintText: 'Pilih Kondisi Fisik',
                          prefixIcon: Icons.health_and_safety_outlined,
                        ),
                        items: _conditions.map((cond) {
                          return DropdownMenuItem<String>(
                            value: cond,
                            child: Text(
                              cond,
                              style: inputTextStyle,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCondition = val;
                              _errorMessage = null;
                            });
                          }
                        },
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Kondisi aset wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Tahun Perolehan & Tahun Mulai Penggunaan (2 Kolom)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Tahun Perolehan *'),
                                TextFormField(
                                  controller: _acquisitionYearController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                  ],
                                  style: inputTextStyle,
                                  decoration: _inputDecoration(
                                    hintText: 'Misal: 2026',
                                    prefixIcon: Icons.calendar_today_outlined,
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Tahun perolehan wajib diisi';
                                    }
                                    final year = int.tryParse(val.trim());
                                    if (year == null ||
                                        year < 1900 ||
                                        year > currentMaxYear) {
                                      return '1900 - $currentMaxYear';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Tahun Mulai Penggunaan'),
                                TextFormField(
                                  controller: _usageYearController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                  ],
                                  style: inputTextStyle,
                                  decoration: _inputDecoration(
                                    hintText: 'Misal: 2026',
                                    prefixIcon: Icons.event_available_outlined,
                                  ),
                                  validator: (val) {
                                    if (val != null && val.trim().isNotEmpty) {
                                      final year = int.tryParse(val.trim());
                                      if (year == null ||
                                          year < 1900 ||
                                          year > currentMaxYear) {
                                        return '1900 - $currentMaxYear';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Dialog Actions ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F3D56),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          const Color(0xFF0F3D56).withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Simpan Aset',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
