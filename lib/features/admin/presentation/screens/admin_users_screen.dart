// lib/features/admin/presentation/screens/admin_users_screen.dart
//
// Screen: Kelola User & Permission oleh Admin (Full Functional CRUD).
// Sumber: Stitch HTML Source of Truth: "MutasiKu — User & Permission (Kelola Pengguna)"
// Screen ID: 6e7839efd09d4717b972b5cdacdae8cd
//
// 100% Visual & Structure matching Stitch HTML.
// Responsive: Mobile (360-430px), Tablet (768-1024px), Desktop/Web (1280px+).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_floating_nav_bar.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/widgets/mutasiku_page_header.dart';

/// Design tokens persis sesuai Stitch HTML (6e7839efd09d4717b972b5cdacdae8cd)
abstract final class _StitchUserColors {
  static const navy = Color(0xFF0F3D56);
  static const darkNavy = Color(0xFF00273A);
  static const heading = Color(0xFF172B4D);
  static const border = Color(0xFFE2E8F0);
  static const bgLight = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFF52606D);
  static const emerald = Color(0xFF10B981);
  static const emeraldBg = Color(0xFFECFDF5);
  static const emeraldBorder = Color(0xFFA7F3D0);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const teal = Color(0xFF0F766E);
}

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  UserRole? _selectedRoleFilter;
  String _selectedUnitFilter = 'Semua Unit';

  final List<String> _unitList = const [
    'Semua Unit',
    'Kantor Pusat',
    'Keuangan',
    'Logistik',
    'Bagian Aset',
    'Divisi TI',
    'Operasional',
    'Cabang',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final text = _searchController.text.trim().toLowerCase();
      if (text != _searchQuery) {
        setState(() => _searchQuery = text);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  TextStyle _font({
    double size = 13,
    FontWeight w = FontWeight.w400,
    Color color = _StitchUserColors.heading,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.montserrat(
      fontSize: size,
      fontWeight: w,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  List<String> _getRolePermissions(UserRole role) {
    switch (role) {
      case UserRole.pemohon:
        return [
          'Ajukan Mutasi Aset Terdaftar',
          'Edit & Kirim Ulang Pengajuan',
          'Konfirmasi Fisik (Sesuai / Tidak Sesuai)',
        ];
      case UserRole.operator:
        return [
          'Pemeriksaan Kelengkapan Data & SK SDM',
          'Kembalikan Pengajuan Belum Lengkap',
          'Teruskan Pengajuan ke Bagian Aset',
        ];
      case UserRole.bagianAset:
        return [
          'Verifikasi Keabsahan Aset & SK SDM',
          'Tentukan PIC Baru bila Kosong',
          'Kembalikan Pengajuan Tidak Valid',
          'Teruskan ke Pemimpin Divisi',
          'Tindak Lanjut Laporan Tidak Sesuai',
        ];
      case UserRole.kabagAset:
        return [
          'Verifikasi Bagian Aset (Legacy)',
          'Teruskan ke Pemimpin Divisi',
        ];
      case UserRole.kadiv:
        return [
          'Approval Final Semua Pengajuan Aset',
          'Tolak Pengajuan dengan Alasan',
        ];
      case UserRole.staffAset:
        return [
          'Pembaruan Otomatis oleh Server (Legacy)',
        ];
      case UserRole.admin:
        return [
          'Kelola Master Pengguna & Role',
          'Kelola Master Lokasi & Unit',
          'Kelola Master Kategori Aset',
        ];
    }
  }

  String _formatInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'AD';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'AD';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    final first = parts[0].isNotEmpty ? parts[0][0] : 'A';
    final second = parts[1].isNotEmpty ? parts[1][0] : 'D';
    return '$first$second'.toUpperCase();
  }

  // ─── Stitch Modal Helpers ──────────────────────────────────────────────────

  Widget _buildStitchFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E293B),
        ),
      ),
    );
  }

  InputDecoration _buildStitchInputDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF94A3B8),
      ),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF00273A), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFB42318), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFB42318), width: 1.5),
      ),
      errorStyle: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFB42318)),
    );
  }

  Widget _buildStitchTwoColumns({
    required Widget left,
    required Widget right,
    required bool isCompact,
  }) {
    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          left,
          const SizedBox(height: 12),
          right,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  Widget _buildAddUserBanner() {
    return Container(
      width: double.infinity,
      height: 106,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const RadialGradient(
          center: Alignment.center,
          radius: 1.15,
          colors: [
            Color(0xFF006A63),
            Color(0xFF0F3D56),
            Color(0xFF00273A),
          ],
          stops: [0.0, 0.48, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00273A).withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: -24,
            left: -16,
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF5EEAD4).withOpacity(0.20),
              ),
            ),
          ),
          Positioned(
            bottom: -24,
            right: -16,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF22D3EE).withOpacity(0.20),
              ),
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1.2,
              ),
            ),
            child: const Icon(
              Icons.person_add_alt_1_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditUserBanner() {
    return Container(
      width: double.infinity,
      height: 98,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F3D56),
            Color(0xFF00273A),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00273A).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.85,
                  colors: [
                    Colors.white.withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
                width: 1.2,
              ),
            ),
            child: const Icon(
              Icons.manage_accounts_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final firstNameCtrl = TextEditingController();
    final lastNameNipCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    String selectedDivision = 'Divisi Operasional';
    UserRole selectedRole = UserRole.operator;
    bool obscurePassword = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.48),
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final screenWidth = MediaQuery.of(dialogCtx).size.width;
          final isCompact = screenWidth < 400;

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isCompact ? 18.0 : 22.0),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAddUserBanner(),
                          const SizedBox(height: 16),
                          Text(
                            'Tambah User Baru',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Registrasi kredensial & otorisasi hak akses staf',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Row: Nama Depan & Nama Belakang / NIP
                          _buildStitchTwoColumns(
                            isCompact: isCompact,
                            left: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStitchFieldLabel('Nama Depan'),
                                TextFormField(
                                  controller: firstNameCtrl,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  decoration: _buildStitchInputDecoration(
                                    hintText: 'Masukkan nama depan',
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Wajib diisi'
                                      : null,
                                ),
                              ],
                            ),
                            right: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStitchFieldLabel('Nama Belakang / NIP'),
                                TextFormField(
                                  controller: lastNameNipCtrl,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  decoration: _buildStitchInputDecoration(
                                    hintText: 'Nama belakang / NIP',
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Wajib diisi'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Email Kantor
                          _buildStitchFieldLabel('Email Kantor'),
                          TextFormField(
                            controller: emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF0F172A),
                            ),
                            decoration: _buildStitchInputDecoration(
                              hintText: 'Masukkan email kantor',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Email kantor wajib diisi';
                              }
                              if (!v.contains('@')) {
                                return 'Format email tidak valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Row: Divisi / Unit Kerja & Role Akun
                          _buildStitchTwoColumns(
                            isCompact: isCompact,
                            left: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStitchFieldLabel('Divisi / Unit Kerja'),
                                DropdownButtonFormField<String>(
                                  value: selectedDivision,
                                  isExpanded: true,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  icon: const Icon(
                                    Icons.expand_more_rounded,
                                    size: 20,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  decoration: _buildStitchInputDecoration(
                                    hintText: 'Pilih Divisi',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Divisi Operasional',
                                      child: Text('Divisi Operasional', overflow: TextOverflow.ellipsis),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Divisi TI',
                                      child: Text('Divisi TI', overflow: TextOverflow.ellipsis),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Divisi Keuangan',
                                      child: Text('Divisi Keuangan', overflow: TextOverflow.ellipsis),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Divisi SDM',
                                      child: Text('Divisi SDM', overflow: TextOverflow.ellipsis),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Divisi Logistik & Aset',
                                      child: Text('Divisi Logistik & Aset', overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setDialogState(() => selectedDivision = val);
                                    }
                                  },
                                ),
                              ],
                            ),
                            right: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStitchFieldLabel('Role Akun'),
                                DropdownButtonFormField<UserRole>(
                                  value: selectedRole,
                                  isExpanded: true,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  icon: const Icon(
                                    Icons.expand_more_rounded,
                                    size: 20,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  decoration: _buildStitchInputDecoration(
                                    hintText: 'Pilih Role',
                                  ),
                                  items: UserRole.activeRoles.map((r) {
                                    return DropdownMenuItem(
                                      value: r,
                                      child: Text(
                                        r.displayName,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setDialogState(() => selectedRole = val);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Row: Kata Sandi & Konfirmasi Kata Sandi
                          _buildStitchTwoColumns(
                            isCompact: isCompact,
                            left: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStitchFieldLabel('Kata Sandi'),
                                TextFormField(
                                  controller: passwordCtrl,
                                  obscureText: obscurePassword,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  decoration: _buildStitchInputDecoration(
                                    hintText: 'Kata sandi',
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 18,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                      onPressed: () => setDialogState(
                                        () => obscurePassword = !obscurePassword,
                                      ),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Wajib diisi';
                                    }
                                    if (v.trim().length < 6) {
                                      return 'Min. 6 karakter';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                            right: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStitchFieldLabel('Konfirmasi Kata Sandi'),
                                TextFormField(
                                  controller: confirmPasswordCtrl,
                                  obscureText: obscureConfirm,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  decoration: _buildStitchInputDecoration(
                                    hintText: 'Ulangi sandi',
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        obscureConfirm
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 18,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                      onPressed: () => setDialogState(
                                        () => obscureConfirm = !obscureConfirm,
                                      ),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v != passwordCtrl.text) {
                                      return 'Sandi tidak sama';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 44,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      side: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                        width: 1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    onPressed: () {
                                      firstNameCtrl.clear();
                                      lastNameNipCtrl.clear();
                                      emailCtrl.clear();
                                      passwordCtrl.clear();
                                      confirmPasswordCtrl.clear();
                                      setDialogState(() {
                                        selectedDivision = 'Divisi Operasional';
                                        selectedRole = UserRole.operator;
                                      });
                                    },
                                    child: Text(
                                      'Reset',
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SizedBox(
                                  height: 44,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00273A),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    onPressed: () async {
                                      if (!formKey.currentState!.validate()) return;
                                      Navigator.of(dialogCtx).pop();

                                      final firstName = firstNameCtrl.text.trim();
                                      final lastNameNip = lastNameNipCtrl.text.trim();
                                      final fullName = '$firstName $lastNameNip'.trim();

                                      String cleanUsername = lastNameNip
                                          .toLowerCase()
                                          .replaceAll(RegExp(r'[^a-z0-9_]'), '');
                                      if (cleanUsername.length < 3) {
                                        cleanUsername = '${firstName}_$lastNameNip'
                                            .toLowerCase()
                                            .replaceAll(RegExp(r'[^a-z0-9_]'), '');
                                      }
                                      if (cleanUsername.length < 3) {
                                        cleanUsername = '${firstName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '')}usr';
                                      }
                                      if (cleanUsername.length < 3) {
                                        cleanUsername = 'usr_${DateTime.now().millisecondsSinceEpoch % 100000}';
                                      }

                                      final newUser = User(
                                        id: 'u_${DateTime.now().millisecondsSinceEpoch}',
                                        name: fullName,
                                        username: cleanUsername,
                                        email: emailCtrl.text.trim(),
                                        department: selectedDivision,
                                        role: selectedRole,
                                        isActive: true,
                                      );

                                      final result = await ref
                                          .read(masterUsersProvider.notifier)
                                          .createUser(newUser);

                                      if (!context.mounted) return;
                                      if (result is Success<User>) {
                                        AppFeedback.showSuccess(
                                          context,
                                          'User "${result.data.name}" (@${result.data.username}) berhasil ditambahkan.',
                                        );
                                      } else if (result is AppFailure<User>) {
                                        AppFeedback.showError(
                                          context,
                                          'Gagal Menambahkan User',
                                          details: result.failure.message,
                                        );
                                      }
                                    },
                                    child: Text(
                                      'Simpan User',
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
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
            ),
          );
        },
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, User user) {
    final formKey = GlobalKey<FormState>();
    final nameParts = user.name.trim().split(RegExp(r'\s+'));
    final initialFirst = nameParts.isNotEmpty ? nameParts.first : '';
    final initialLast = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    final firstNameCtrl = TextEditingController(text: initialFirst);
    final lastNameCtrl = TextEditingController(text: initialLast);
    final emailCtrl = TextEditingController(text: user.email ?? '');
    final deptCtrl = TextEditingController(text: user.department ?? '');
    final nipCtrl = TextEditingController(text: user.username);
    UserRole selectedRole = user.role;
    String selectedStatus = user.isActive ? 'Aktif' : 'Nonaktif';

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.48),
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final screenWidth = MediaQuery.of(dialogCtx).size.width;
          final isCompact = screenWidth < 400;

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isCompact ? 18.0 : 22.0),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildEditUserBanner(),
                          const SizedBox(height: 18),
                          Text(
                            'Edit Data User',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Row: First name & Last name
                          _buildStitchTwoColumns(
                            isCompact: isCompact,
                            left: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStitchFieldLabel('First name'),
                                TextFormField(
                                  controller: firstNameCtrl,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  decoration: _buildStitchInputDecoration(
                                    hintText: 'First name',
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Wajib diisi'
                                      : null,
                                ),
                              ],
                            ),
                            right: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStitchFieldLabel('Last name'),
                                TextFormField(
                                  controller: lastNameCtrl,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  decoration: _buildStitchInputDecoration(
                                    hintText: 'Last name',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Email
                          _buildStitchFieldLabel('Email'),
                          TextFormField(
                            controller: emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF0F172A),
                            ),
                            decoration: _buildStitchInputDecoration(
                              hintText: 'Enter your email address',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Email tidak boleh kosong';
                              }
                              if (!v.contains('@')) {
                                return 'Format email tidak valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Row: Role Akun & Divisi / Unit Kerja
                          _buildStitchTwoColumns(
                            isCompact: isCompact,
                            left: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStitchFieldLabel('Role Akun'),
                                DropdownButtonFormField<UserRole>(
                                  value: selectedRole,
                                  isExpanded: true,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  icon: const Icon(
                                    Icons.expand_more_rounded,
                                    size: 20,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  decoration: _buildStitchInputDecoration(
                                    hintText: 'Pilih Role',
                                  ),
                                  items: UserRole.activeRoles.map((r) {
                                    return DropdownMenuItem(
                                      value: r,
                                      child: Text(
                                        r.displayName,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setDialogState(() => selectedRole = val);
                                    }
                                  },
                                ),
                              ],
                            ),
                            right: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStitchFieldLabel('Divisi / Unit Kerja'),
                                TextFormField(
                                  controller: deptCtrl,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  decoration: _buildStitchInputDecoration(
                                    hintText: 'Divisi / Unit Kerja',
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Wajib diisi'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Row: NIP / ID Karyawan & Status Akun
                          _buildStitchTwoColumns(
                            isCompact: isCompact,
                            left: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStitchFieldLabel('NIP / ID Karyawan'),
                                TextFormField(
                                  controller: nipCtrl,
                                  readOnly: true,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF64748B),
                                  ),
                                  decoration: _buildStitchInputDecoration(
                                    hintText: 'NIP / ID',
                                  ),
                                ),
                              ],
                            ),
                            right: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStitchFieldLabel('Status Akun'),
                                DropdownButtonFormField<String>(
                                  value: selectedStatus,
                                  isExpanded: true,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  icon: const Icon(
                                    Icons.expand_more_rounded,
                                    size: 20,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  decoration: _buildStitchInputDecoration(
                                    hintText: 'Pilih Status',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Aktif',
                                      child: Text('Aktif'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Nonaktif',
                                      child: Text('Nonaktif'),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setDialogState(() => selectedStatus = val);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 46,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF8FAFC),
                                      side: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                        width: 1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    onPressed: () => Navigator.of(dialogCtx).pop(),
                                    child: Text(
                                      'Batal',
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SizedBox(
                                  height: 46,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00273A),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    onPressed: () async {
                                      if (!formKey.currentState!.validate()) return;
                                      Navigator.of(dialogCtx).pop();

                                      final firstName = firstNameCtrl.text.trim();
                                      final lastName = lastNameCtrl.text.trim();
                                      final fullName = lastName.isNotEmpty
                                          ? '$firstName $lastName'
                                          : firstName;

                                      final updatedUser = user.copyWith(
                                        name: fullName,
                                        email: emailCtrl.text.trim(),
                                        department: deptCtrl.text.trim(),
                                        role: selectedRole,
                                        isActive: selectedStatus == 'Aktif',
                                      );

                                      final result = await ref
                                          .read(masterUsersProvider.notifier)
                                          .updateUser(updatedUser);

                                      if (!context.mounted) return;
                                      if (result is Success<User>) {
                                        AppFeedback.showSuccess(
                                          context,
                                          'Data user "${result.data.username}" berhasil diperbarui.',
                                        );
                                      } else if (result is AppFailure<User>) {
                                        AppFeedback.showError(
                                          context,
                                          'Gagal Memperbarui User',
                                          details: result.failure.message,
                                        );
                                      }
                                    },
                                    child: Text(
                                      'Simpan Perubahan',
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
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
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteUser(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Pengguna',
          style: _font(size: 16, w: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus user "${user.name}" (@${user.username})?\n\n'
          'Perhatian: User dengan riwayat aktivitas mutasi tidak dapat dihapus permanen untuk menjaga integritas audit data.',
          style: _font(size: 13, height: 1.4, color: _StitchUserColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final result = await ref
                  .read(masterUsersProvider.notifier)
                  .deleteUser(user.id);

              if (!context.mounted) return;
              if (result is Success<void>) {
                AppFeedback.showSuccess(
                  context,
                  'User "${user.name}" berhasil dihapus.',
                );
              } else if (result is AppFailure<void>) {
                AppFeedback.showError(
                  context,
                  'Penghapusan Ditolak',
                  details: result.failure.message,
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showUserAccessModal(BuildContext context, User user) {
    final permissions = _getRolePermissions(user.role);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _StitchUserColors.slate200,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _StitchUserColors.darkNavy,
                    child: Text(
                      _formatInitials(user.name),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: _font(size: 16, w: FontWeight.bold),
                        ),
                        Text(
                          '${user.role.displayName} • ${user.department ?? "Unit Kerja"}',
                          style: _font(
                            size: 12,
                            color: _StitchUserColors.textSecondary,
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
                      color: user.isActive
                          ? _StitchUserColors.emeraldBg
                          : _StitchUserColors.slate100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: user.isActive
                            ? _StitchUserColors.emeraldBorder
                            : _StitchUserColors.slate200,
                      ),
                    ),
                    child: Text(
                      user.isActive ? 'Aktif' : 'Nonaktif',
                      style: _font(
                        size: 11,
                        w: FontWeight.bold,
                        color: user.isActive
                            ? _StitchUserColors.emerald
                            : _StitchUserColors.slate500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Text(
                'INFORMASI AKUN & OTORISASI',
                style: _font(
                  size: 11,
                  w: FontWeight.w700,
                  color: _StitchUserColors.slate500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow('Username', '@${user.username}'),
              _buildInfoRow('Email', user.email ?? '-'),
              _buildInfoRow('Unit / Divisi', user.department ?? '-'),
              _buildInfoRow('Status SSO', 'Terkoneksi SSO Organisasi'),
              const SizedBox(height: 16),
              Text(
                'HAK AKSES FITUR (RBAC):',
                style: _font(
                  size: 11,
                  w: FontWeight.w700,
                  color: _StitchUserColors.slate500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: permissions.map((p) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _StitchUserColors.slate100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _StitchUserColors.slate200),
                    ),
                    child: Text(
                      p,
                      style: _font(
                        size: 11,
                        w: FontWeight.w500,
                        color: _StitchUserColors.heading,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(
                        user.isActive
                            ? Icons.block
                            : Icons.check_circle_outline,
                        size: 16,
                        color: user.isActive
                            ? AppColors.warning
                            : _StitchUserColors.emerald,
                      ),
                      label: Text(
                        user.isActive ? 'Nonaktifkan' : 'Aktifkan',
                        style: TextStyle(
                          color: user.isActive
                              ? AppColors.warning
                              : _StitchUserColors.emerald,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        final newStatus = !user.isActive;
                        final res = await ref
                            .read(masterUsersProvider.notifier)
                            .toggleActive(user.id, newStatus);
                        if (!context.mounted) return;
                        if (res is Success<void>) {
                          AppFeedback.showSuccess(
                            context,
                            newStatus
                                ? 'User "${user.name}" berhasil diaktifkan.'
                                : 'User "${user.name}" dinonaktifkan.',
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: 'Edit Data',
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _showEditUserDialog(context, user);
                    },
                  ),
                  const SizedBox(width: 4),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: AppColors.error),
                    tooltip: 'Hapus User',
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _confirmDeleteUser(context, user);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: _font(size: 12, color: _StitchUserColors.textSecondary),
          ),
          Text(
            value,
            style: _font(size: 12, w: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(masterUsersProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        // Breakpoints: Mobile (360-430), Tablet (768-1024), Desktop (1280+)
        final bool isDesktop = availableWidth >= 1100;
        final bool isTablet = availableWidth >= 680 && availableWidth < 1100;
        final int gridColumns = isDesktop ? 3 : (isTablet ? 2 : 1);

        final double horizontalPadding;
        if (availableWidth >= 1440) {
          horizontalPadding = 48.0;
        } else if (isDesktop) {
          horizontalPadding = 36.0;
        } else if (isTablet) {
          horizontalPadding = 24.0;
        } else {
          horizontalPadding = 16.0;
        }

        final double bottomNavMaxWidth = isDesktop
            ? 640.0
            : (isTablet ? 520.0 : 440.0);

        return Scaffold(
          backgroundColor: _StitchUserColors.bgLight,
          extendBody: true,
          body: usersAsync.when(
            data: (allUsers) {
              final filtered = allUsers.where((u) {
                final name = u.name.toLowerCase();
                final username = u.username.toLowerCase();
                final dept = (u.department ?? '').toLowerCase();
                final q = _searchQuery.toLowerCase();
                final matchesQuery = q.isEmpty ||
                    name.contains(q) ||
                    username.contains(q) ||
                    dept.contains(q);

                final matchesRole = _selectedRoleFilter == null ||
                    u.role == _selectedRoleFilter;

                final matchesUnit = _selectedUnitFilter == 'Semua Unit' ||
                    dept.contains(_selectedUnitFilter.toLowerCase());

                return matchesQuery && matchesRole && matchesUnit;
              }).toList();

              return RefreshIndicator(
                color: _StitchUserColors.navy,
                onRefresh: () async {
                  ref.invalidate(masterUsersProvider);
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1440),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. TOP HEADER (Stitch 1:1)
                          _buildTopHeader(
                            context,
                            horizontalPadding: horizontalPadding,
                            isDesktop: isDesktop,
                          ),

                          // 2. SEARCH & ROLE FILTERS
                          _buildSearchAndFilters(
                            context,
                            horizontalPadding: horizontalPadding,
                            allUsers: allUsers,
                          ),

                          // 3. LIST HEADER (Daftar Pengguna Aktif)
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              12,
                              horizontalPadding,
                              8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'Daftar Pengguna Aktif',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: _font(
                                            size: isDesktop ? 18 : 15,
                                            w: FontWeight.bold,
                                            color: _StitchUserColors.heading,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _StitchUserColors.slate100,
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          '${filtered.length}',
                                          style: _font(
                                            size: 11,
                                            w: FontWeight.w600,
                                            color: _StitchUserColors.slate500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _StitchUserColors.navy,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    minimumSize: const Size(0, 32),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(Icons.add, size: 14),
                                  label: Text(
                                    'Tambah',
                                    style: _font(
                                      size: 11,
                                      w: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  onPressed: () => _showAddUserDialog(context),
                                ),
                              ],
                            ),
                          ),

                          // 4. RESPONSIVE GRID / CARDS LIST
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              4,
                              horizontalPadding,
                              120, // Extra bottom padding for floating navbar
                            ),
                            child: filtered.isEmpty
                                ? Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(40),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: _StitchUserColors.border,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.person_search_outlined,
                                          size: 48,
                                          color: _StitchUserColors.slate400,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Tidak ada pengguna ditemukan.',
                                          style: _font(
                                            size: 14,
                                            w: FontWeight.w600,
                                            color: _StitchUserColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Coba sesuaikan kata kunci pencarian atau filter role/unit.',
                                          style: _font(
                                            size: 12,
                                            color: _StitchUserColors.slate400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : gridColumns == 1
                                    ? ListView.separated(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: filtered.length,
                                        separatorBuilder: (_, _) =>
                                            const SizedBox(height: 10),
                                        itemBuilder: (ctx, idx) =>
                                            _buildUserCard(filtered[idx]),
                                      )
                                    : GridView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: gridColumns,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                          mainAxisExtent: 116,
                                        ),
                                        itemCount: filtered.length,
                                        itemBuilder: (ctx, idx) =>
                                            _buildUserCard(filtered[idx]),
                                      ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
            loading: () =>
                const LoadingIndicator(message: 'Memuat data user...'),
            error: (err, stack) => ErrorView(
              message: err.toString(),
              onRetry: () =>
                  ref.read(masterUsersProvider.notifier).loadUsers(),
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.bottomCenter,
                heightFactor: 1.0,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: bottomNavMaxWidth),
                  child: CustomFloatingNavBar.scaffoldBottomBar(
                    items: RoleNavConfig.getNavItemsForRole(UserRole.admin),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── TOP HEADER (MutasiKuPageHeader Visual Baseline) ─────────────────────────
  Widget _buildTopHeader(
    BuildContext context, {
    required double horizontalPadding,
    required bool isDesktop,
  }) {
    return MutasiKuPageHeader(
      title: 'User & Permission',
      subtitle: 'Kelola data pengguna, hak akses per role, dan status aktifasi akun',
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(RouteNames.adminDashboardPath);
        }
      },
    );
  }

  // ── SEARCH & FILTERS (Stitch 1:1) ──────────────────────────────────────────
  Widget _buildSearchAndFilters(
    BuildContext context, {
    required double horizontalPadding,
    required List<User> allUsers,
  }) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar + Unit Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _StitchUserColors.slate100,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _StitchUserColors.slate200),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search,
                  size: 18,
                  color: _StitchUserColors.slate400,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari pengguna, NIP, atau divisi...',
                      hintStyle: _font(
                        size: 12,
                        color: _StitchUserColors.slate400,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    style: _font(size: 13, color: _StitchUserColors.heading),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
                // Unit Filter Button
                PopupMenuButton<String>(
                  initialValue: _selectedUnitFilter,
                  onSelected: (val) {
                    setState(() => _selectedUnitFilter = val);
                  },
                  itemBuilder: (ctx) => _unitList.map((unit) {
                    return PopupMenuItem(
                      value: unit,
                      child: Text(
                        unit,
                        style: _font(size: 12),
                      ),
                    );
                  }).toList(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _StitchUserColors.slate200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.apartment,
                          size: 14,
                          color: _StitchUserColors.teal,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _selectedUnitFilter,
                          style: _font(
                            size: 11,
                            w: FontWeight.w600,
                            color: _StitchUserColors.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Role Categories Horizontal Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'KATEGORI ROLE',
                style: _font(
                  size: 11,
                  w: FontWeight.w700,
                  color: _StitchUserColors.slate400,
                  letterSpacing: 0.5,
                ),
              ),
              if (_selectedRoleFilter != null)
                InkWell(
                  onTap: () {
                    setState(() => _selectedRoleFilter = null);
                  },
                  child: Text(
                    'Reset Filter',
                    style: _font(
                      size: 11,
                      w: FontWeight.w600,
                      color: _StitchUserColors.teal,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildRoleCircleItem(
                  label: 'Semua',
                  isSelected: _selectedRoleFilter == null,
                  avatarInitial: 'All',
                  onTap: () => setState(() => _selectedRoleFilter = null),
                ),
                const SizedBox(width: 12),
                _buildRoleCircleItem(
                  label: 'Pemohon',
                  isSelected: _selectedRoleFilter == UserRole.pemohon,
                  avatarInitial: 'PM',
                  onTap: () =>
                      setState(() => _selectedRoleFilter = UserRole.pemohon),
                ),
                const SizedBox(width: 12),
                _buildRoleCircleItem(
                  label: 'Operator',
                  isSelected: _selectedRoleFilter == UserRole.operator,
                  avatarInitial: 'OP',
                  onTap: () =>
                      setState(() => _selectedRoleFilter = UserRole.operator),
                ),
                const SizedBox(width: 12),
                _buildRoleCircleItem(
                  label: 'Bag. Aset',
                  isSelected: _selectedRoleFilter == UserRole.bagianAset,
                  avatarInitial: 'BA',
                  onTap: () =>
                      setState(() => _selectedRoleFilter = UserRole.bagianAset),
                ),
                const SizedBox(width: 12),
                _buildRoleCircleItem(
                  label: 'Kadiv',
                  isSelected: _selectedRoleFilter == UserRole.kadiv,
                  avatarInitial: 'KD',
                  onTap: () =>
                      setState(() => _selectedRoleFilter = UserRole.kadiv),
                ),
                const SizedBox(width: 12),
                _buildRoleCircleItem(
                  label: 'Staff Aset',
                  isSelected: _selectedRoleFilter == UserRole.staffAset,
                  avatarInitial: 'ST',
                  onTap: () =>
                      setState(() => _selectedRoleFilter = UserRole.staffAset),
                ),
                const SizedBox(width: 12),
                _buildRoleCircleItem(
                  label: 'Admin',
                  isSelected: _selectedRoleFilter == UserRole.admin,
                  avatarInitial: 'AD',
                  onTap: () =>
                      setState(() => _selectedRoleFilter = UserRole.admin),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCircleItem({
    required String label,
    required bool isSelected,
    required String avatarInitial,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? _StitchUserColors.darkNavy
                  : _StitchUserColors.slate100,
              border: Border.all(
                color: isSelected
                    ? _StitchUserColors.darkNavy
                    : _StitchUserColors.slate200,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _StitchUserColors.darkNavy.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              avatarInitial,
              style: _font(
                size: 13,
                w: FontWeight.bold,
                color: isSelected ? Colors.white : _StitchUserColors.heading,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: _font(
              size: 11,
              w: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? _StitchUserColors.darkNavy
                  : _StitchUserColors.slate500,
            ),
          ),
        ],
      ),
    );
  }

  // ── USER CARD (Stitch 1:1) ────────────────────────────────────────────────
  Widget _buildUserCard(User user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: user.isActive
              ? _StitchUserColors.slate200
              : AppColors.error.withValues(alpha: 0.25),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _StitchUserColors.slate100,
              border: Border.all(color: _StitchUserColors.slate200),
            ),
            alignment: Alignment.center,
            child: Text(
              _formatInitials(user.name),
              style: _font(
                size: 14,
                w: FontWeight.bold,
                color: _StitchUserColors.darkNavy,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _font(
                    size: 14,
                    w: FontWeight.bold,
                    color: user.isActive
                        ? _StitchUserColors.heading
                        : _StitchUserColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${user.role.displayName} • ${user.department ?? "Kantor"}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _font(
                    size: 12,
                    color: _StitchUserColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    Text(
                      '@${user.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.firaCode(
                        fontSize: 10,
                        color: _StitchUserColors.slate500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: user.isActive
                            ? _StitchUserColors.emeraldBg
                            : _StitchUserColors.slate100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: user.isActive
                              ? _StitchUserColors.emeraldBorder
                              : _StitchUserColors.slate200,
                        ),
                      ),
                      child: Text(
                        user.isActive ? 'Aktif' : 'Nonaktif',
                        style: _font(
                          size: 9,
                          w: FontWeight.w600,
                          color: user.isActive
                              ? _StitchUserColors.emerald
                              : _StitchUserColors.slate500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Kelola Akses Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _StitchUserColors.navy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            onPressed: () => _showUserAccessModal(context, user),
            child: Text(
              'Kelola Akses',
              style: _font(
                size: 11,
                w: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
