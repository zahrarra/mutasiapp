// lib/features/auth/presentation/screens/change_password_screen.dart
//
// Layar Wajib Ganti Password Pertama Kali (First-Login Password Change).
// Menjamin keamanan akun sebelum pengguna dapat mengakses Dashboard.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/errors/result.dart';
import '../providers/auth_provider.dart';

abstract final class _C {
  static const bg = Color(0xFFF8FAFC);
  static const white = Color(0xFFFFFFFF);
  static const darkNavy = Color(0xFF0F3D56);
  static const teal = Color(0xFF0F766E);
  static const tealLight = Color(0xFFE6F4F1);
  static const border = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF1E293B);
  static const textMuted = Color(0xFF64748B);
  static const error = Color(0xFFDC2626);
  static const errorBg = Color(0xFFFEF2F2);
  static const success = Color(0xFF16A34A);
}

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _currentPasswordFocusNode = FocusNode();
  final _newPasswordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordFocusNode.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final currentPass = _currentPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (newPass == currentPass) {
      setState(() {
        _errorMessage = 'Password baru harus berbeda dengan password saat ini.';
      });
      return;
    }

    if (newPass != confirmPass) {
      setState(() {
        _errorMessage = 'Konfirmasi password baru tidak cocok.';
      });
      return;
    }

    setState(() => _isLoading = true);

    final result = await ref.read(authStateProvider.notifier).changePassword(
      currentPassword: currentPass,
      newPassword: newPass,
      confirmPassword: confirmPass,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result is AppFailure) {
      setState(() {
        _errorMessage = (result as AppFailure).failure.message ??
            'Gagal mengubah password. Pastikan password lama benar.';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password berhasil diperbarui. Selamat datang di MutasiKu!'),
          backgroundColor: _C.success,
        ),
      );
    }
  }

  TextStyle _font({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = _C.textPrimary,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final userName = user?.name ?? 'Pengguna MutasiKu';

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icon & Header
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: _C.tealLight,
                          shape: BoxShape.circle,
                          border: Border.all(color: _C.teal.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          color: _C.teal,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Wajib Ganti Password',
                        style: _font(
                          size: 22,
                          weight: FontWeight.w700,
                          color: _C.darkNavy,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Halo, $userName. Demi keamanan akun Anda, silakan ubah password bawaan sebelum melanjutkan ke dashboard.',
                        style: _font(
                          size: 13,
                          weight: FontWeight.w400,
                          color: _C.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error banner
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _C.errorBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _C.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: _C.error, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: _font(
                                  size: 12.5,
                                  color: _C.error,
                                  weight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Card Form Container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _C.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _C.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Password Lama
                          Text(
                            'Password Saat Ini',
                            style: _font(size: 13, weight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            key: const Key('current_password_input'),
                            controller: _currentPasswordController,
                            focusNode: _currentPasswordFocusNode,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) =>
                                _newPasswordFocusNode.requestFocus(),
                            obscureText: _obscureCurrent,
                            decoration: InputDecoration(
                              hintText: 'Masukkan password lama',
                              prefixIcon: const Icon(Icons.lock_outline, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureCurrent
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() => _obscureCurrent = !_obscureCurrent);
                                },
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Password saat ini wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // 2. Password Baru
                          Text(
                            'Password Baru',
                            style: _font(size: 13, weight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            key: const Key('new_password_input'),
                            controller: _newPasswordController,
                            focusNode: _newPasswordFocusNode,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) =>
                                _confirmPasswordFocusNode.requestFocus(),
                            obscureText: _obscureNew,
                            decoration: InputDecoration(
                              hintText: 'Minimal 8 karakter',
                              prefixIcon: const Icon(Icons.key_rounded, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureNew
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() => _obscureNew = !_obscureNew);
                                },
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Password baru wajib diisi';
                              }
                              if (v.length < 8) {
                                return 'Password baru minimal 8 karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // 3. Konfirmasi Password Baru
                          Text(
                            'Konfirmasi Password Baru',
                            style: _font(size: 13, weight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            key: const Key('confirm_password_input'),
                            controller: _confirmPasswordController,
                            focusNode: _confirmPasswordFocusNode,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            obscureText: _obscureConfirm,
                            decoration: InputDecoration(
                              hintText: 'Ulangi password baru',
                              prefixIcon:
                                  const Icon(Icons.lock_clock_outlined, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(
                                      () => _obscureConfirm = !_obscureConfirm);
                                },
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Konfirmasi password wajib diisi';
                              }
                              if (v != _newPasswordController.text) {
                                return 'Konfirmasi password tidak cocok';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton(
                      key: const Key('btn_submit_change_password'),
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.darkNavy,
                        foregroundColor: _C.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Simpan Password & Lanjutkan',
                              style: _font(
                                size: 14,
                                weight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),

                    // Logout Option
                    TextButton.icon(
                      onPressed: () {
                        ref.read(authStateProvider.notifier).logout();
                      },
                      icon: const Icon(Icons.logout_rounded, size: 16, color: _C.textMuted),
                      label: Text(
                        'Keluar dari Akun',
                        style: _font(size: 13, color: _C.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
