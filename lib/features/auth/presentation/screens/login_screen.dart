// lib/features/auth/presentation/screens/login_screen.dart
// UI mendekati mockup HTML login MutasiKu.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_role.dart';
import '../providers/auth_provider.dart';

/// Token warna mengikuti mockup HTML (bukan layout login lama).
class _C {
  static const background = Color(0xFFF6F8FA);
  static const primary = Color(0xFF00273A);
  static const primaryContainer = Color(0xFF0F3D56);
  static const secondary = Color(0xFF006A63);
  static const secondaryFixed = Color(0xFF9CF2E8);
  static const textPrimary = Color(0xFF172B4D);
  static const textSecondary = Color(0xFF52606D);
  static const surface = Color(0xFFFFFFFF);
  static const success = Color(0xFF15803D);
  static const disabled = Color(0xFF98A2B3);
  static const surfaceLow = Color(0xFFECF4FF);
  static const error = Color(0xFFB42318);
  static const errorContainer = Color(0xFFFFDAD6);
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: 'pemohon');
  final _passwordController = TextEditingController(text: 'password123');
  bool _obscure = true;
  bool _remember = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(authStateProvider.notifier)
        .login(_usernameController.text.trim(), _passwordController.text);
  }

  void _preset(UserRole role) {
    setState(() {
      _usernameController.text = role.apiValue;
      _passwordController.text = 'password123';
    });
  }

  void _ssoHelp() {
    showDialog<void>(
      context: context,
      barrierColor: _C.primary.withValues(alpha: 0.40),
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.help_outline, color: _C.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bantuan Kata Sandi SSO',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _C.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Sandi akun terintegrasi dengan Portal Pusat Pegawai. '
                'Untuk pembaruan atau reset sandi, hubungi Helpdesk TI '
                'atau kunjungi Pusat Dukungan Internal.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: _C.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 40,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: _C.surfaceLow,
                    foregroundColor: _C.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Mengerti'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dec({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: _C.textSecondary.withValues(alpha: 0.50),
        fontSize: 14,
      ),
      filled: true,
      fillColor: _C.surface,
      prefixIcon: Icon(icon, size: 20, color: _C.textSecondary),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _C.primaryContainer, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _C.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _C.error),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final loading = auth.isLoading;

    return Scaffold(
      backgroundColor: _C.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 16,
                  maxWidth: 448,
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ===== TOP: brand + form (seperti HTML) =====
                        const SizedBox(height: 8),

                        // Logo + wordmark
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _C.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: _C.textPrimary.withValues(
                                      alpha: 0.06,
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.sync_alt,
                                color: _C.secondaryFixed,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Mutasi',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: _C.primary,
                                      height: 1.2,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Ku',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: _C.secondary,
                                      height: 1.2,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Masuk ke Akun',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: _C.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Sistem Tata Kelola & Mutasi Aset Internal',
                            style: TextStyle(
                              fontSize: 12,
                              color: _C.textSecondary,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        if (auth.failure != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _C.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              auth.failure!.userMessage,
                              style: const TextStyle(
                                color: _C.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Username
                        const Text(
                          'Username atau NIP',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _C.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _usernameController,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(
                            fontSize: 14,
                            color: _C.textPrimary,
                          ),
                          decoration: _dec(
                            hint: 'Contoh: 1988031201',
                            icon: Icons.badge_outlined,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Wajib diisi'
                              : null,
                        ),

                        const SizedBox(height: 16),

                        // Password header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Kata Sandi',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _C.textPrimary,
                              ),
                            ),
                            GestureDetector(
                              onTap: _ssoHelp,
                              child: const Text(
                                'Lupa Sandi SSO?',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _C.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: _C.textPrimary,
                          ),
                          decoration: _dec(
                            hint: '••••••••',
                            icon: Icons.lock_outline,
                            suffix: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                                color: _C.textSecondary,
                              ),
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                        ),

                        const SizedBox(height: 12),

                        // Remember + LDAP
                        Row(
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: _remember,
                                activeColor: _C.primaryContainer,
                                side: const BorderSide(color: _C.disabled),
                                onChanged: (v) =>
                                    setState(() => _remember = v ?? false),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Ingat workstation ini',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _C.textSecondary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _C.surfaceLow,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 6,
                                    color: _C.success,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'LDAP Aktif',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _C.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // CTA — sama HTML
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: loading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _C.primaryContainer,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: _C.primaryContainer
                                  .withValues(alpha: 0.75),
                              elevation: 1,
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
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Masuk ke Sistem',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.login, size: 20),
                                    ],
                                  ),
                          ),
                        ),

                        // Preset demo — kecil, di bawah tombol (tidak di mockup,
                        // tapi wajib untuk uji 6 role)
                        const SizedBox(height: 20),
                        const Text(
                          'Quick Role (Demo)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _C.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: UserRole.values.map((role) {
                            final selected =
                                _usernameController.text.toLowerCase() ==
                                role.apiValue;
                            return GestureDetector(
                              onTap: () => _preset(role),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? _C.primaryContainer
                                      : _C.surface,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: selected
                                        ? _C.primaryContainer
                                        : const Color(0xFFD0D5DD),
                                  ),
                                ),
                                child: Text(
                                  role.displayName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? Colors.white
                                        : _C.textPrimary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const Spacer(),

                        // ===== BOTTOM: seperti HTML =====
                        const SizedBox(height: 32),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _C.surface,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: _C.textPrimary.withValues(alpha: 0.06),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_user,
                                  size: 15,
                                  color: _C.success,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Koneksi Terenkripsi TLS 1.3 • Akses Internal',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: _C.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Divisi TI & Tata Kelola Aset Perusahaan',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _C.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Akses dibatasi hanya untuk staf inventaris, auditor, dan penanggung jawab unit berwenang.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10, color: _C.disabled),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
