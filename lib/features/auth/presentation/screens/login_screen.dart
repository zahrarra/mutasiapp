// lib/features/auth/presentation/screens/login_screen.dart
//
// Screen: Halaman Login (Clean Minimalist).
// Baseline: Stitch “MutasiKu — Halaman Login (Clean Minimalist)”
// UI: Header dengan compact emblem badge, Hello Again heading, input card rounded-2xl,
// elevated brand-navy button, enterprise trust card, dan demo preset pills.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/router/route_names.dart';
import '../../domain/entities/user_role.dart';
import '../providers/auth_provider.dart';

/// Design tokens sesuai baseline Stitch Halaman Login
abstract final class _LoginTheme {
  static const Color navy = Color(0xFF0F3D56);

  static const Color teal = Color(0xFF0F766E);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textHeading = Color(0xFF0F172A);
  static const Color textBody = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textPlaceholder = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color error = Color(0xFFB42318);
  static const Color errorContainer = Color(0xFFFEE2E2);

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

  void _showHelpdeskDialog() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCCFBF1)),
                    ),
                    child: const Icon(
                      Icons.help_outline_rounded,
                      color: _LoginTheme.teal,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bantuan Akses MutasiKu',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _LoginTheme.textHeading,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Akun MutasiKu terintegrasi dengan kredensial Single Sign-On (SSO) pegawai internal.\n\nJika mengalami kendala masuk, pembaruan kata sandi, atau mutasi divisi tugas, silakan hubungi Helpdesk TI di ext. 1404 atau melalui portal dukungan internal.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.5,
                  color: _LoginTheme.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _LoginTheme.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Mengerti',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final loading = auth.isLoading;

    return Scaffold(
      backgroundColor: _LoginTheme.background,
      body: Stack(
        children: [
          // ── Background Ambient Blobs ───────────────────────────────────────
          Positioned(
            top: -40,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE2E8F0).withValues(alpha: 0.45),
              ),
            ),
          ),
          Positioned(
            top: 100,
            right: 16,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0F766E).withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Main Scrollable Canvas ─────────────────────────────────────────
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Top Bar: Back Button & Compact Emblem Badge ──────
                        _buildTopHeader(),

                        const SizedBox(height: 28),

                        // ── Heading Section: Hello Again! ────────────────────
                        _buildHeadingSection(),

                        const SizedBox(height: 28),

                        // ── Error Alert Banner (jika login gagal) ────────────
                        if (auth.failure != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: _LoginTheme.errorContainer,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _LoginTheme.error.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: _LoginTheme.error,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    auth.failure!.userMessage,
                                    style: GoogleFonts.inter(
                                      color: _LoginTheme.error,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ── Field 1: Email Address / NIP Input Card ──────────
                        _buildUsernameField(),

                        const SizedBox(height: 16),

                        // ── Field 2: Password Input Card ─────────────────────
                        _buildPasswordField(),

                        const SizedBox(height: 14),

                        // ── Utility Row: Remember Me & Forgot Password ───────
                        _buildUtilityRow(),

                        const SizedBox(height: 18),

                        // ── Primary CTA: Elevated Login Button ───────────────
                        _buildSubmitButton(loading),

                        const SizedBox(height: 20),

                        // ── Enterprise Trust & Security Card ─────────────────
                        _buildEnterpriseTrustCard(),

                        const SizedBox(height: 14),

                        // ── Helpdesk Link ────────────────────────────────────
                        _buildHelpdeskLink(),

                        const SizedBox(height: 22),

                        // ── Quick Role Presets (Testing & Demo) ──────────────
                        _buildQuickRolePresets(),

                        const SizedBox(height: 24),

                        // ── Bottom Footer ────────────────────────────────────
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Minimalist Back Button
        InkWell(
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.landingPath);
            }
          },
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.6),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: _LoginTheme.textBody,
              size: 20,
            ),
          ),
        ),

        // MutasiKu Compact Emblem Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _LoginTheme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  gradient: const LinearGradient(
                    colors: [_LoginTheme.navy, _LoginTheme.teal],
                  ),
                ),
                child: const Icon(
                  Icons.sync_alt_rounded,
                  size: 11,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'MutasiKu',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _LoginTheme.navy,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Internal',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _LoginTheme.teal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeadingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello Again!',
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: _LoginTheme.textHeading,
            letterSpacing: -0.5,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Welcome back you've\nbeen missed.",
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: _LoginTheme.textMuted,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    return Container(
      decoration: BoxDecoration(
        color: _LoginTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _LoginTheme.border),
        boxShadow: [
          BoxShadow(
            color: _LoginTheme.navy.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        key: const Key('login_username_field'),
        controller: _usernameController,
        textInputAction: TextInputAction.next,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: _LoginTheme.textBody,
        ),
        decoration: InputDecoration(
          hintText: 'Email Address',
          hintStyle: GoogleFonts.inter(
            fontSize: 15,
            color: _LoginTheme.textPlaceholder,
          ),
          prefixIcon: const Icon(
            Icons.person_outline_rounded,
            size: 20,
            color: _LoginTheme.textPlaceholder,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Email / NIP wajib diisi' : null,
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: _LoginTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _LoginTheme.border),
        boxShadow: [
          BoxShadow(
            color: _LoginTheme.navy.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        key: const Key('login_password_field'),
        controller: _passwordController,
        obscureText: _obscure,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _login(),
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: _LoginTheme.textBody,
        ),
        decoration: InputDecoration(
          hintText: 'Password',
          hintStyle: GoogleFonts.inter(
            fontSize: 15,
            color: _LoginTheme.textPlaceholder,
          ),
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            size: 20,
            color: _LoginTheme.textPlaceholder,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
              color: _obscure ? _LoginTheme.textPlaceholder : _LoginTheme.navy,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (v) =>
            (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
      ),
    );
  }

  Widget _buildUtilityRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Remember Me
        InkWell(
          onTap: () => setState(() => _remember = !_remember),
          borderRadius: BorderRadius.circular(6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _remember,
                  activeColor: _LoginTheme.navy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                  onChanged: (v) => setState(() => _remember = v ?? false),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Remember me',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: _LoginTheme.textMuted,
                ),
              ),
            ],
          ),
        ),

        // Forgot Password
        GestureDetector(
          onTap: _showHelpdeskDialog,
          child: Text(
            'Forgot Password?',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _LoginTheme.textHeading,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool loading) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        key: const Key('login_submit_button'),
        onPressed: loading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: _LoginTheme.navy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _LoginTheme.navy.withValues(alpha: 0.7),
          elevation: 6,
          shadowColor: _LoginTheme.navy.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
            : Text(
                'Login',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildEnterpriseTrustCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _LoginTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCCFBF1)),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: _LoginTheme.teal,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sistem Terotentikasi & Terproteksi',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _LoginTheme.textBody,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Akses hanya diperuntukkan bagi pegawai resmi. Setiap aktivitas pencatatan mutasi aset diawasi oleh audit log SIPA.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: _LoginTheme.textMuted,
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

  Widget _buildHelpdeskLink() {
    return Center(
      child: InkWell(
        onTap: _showHelpdeskDialog,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.help_outline_rounded,
                size: 14,
                color: _LoginTheme.textMuted,
              ),
              const SizedBox(width: 6),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Butuh bantuan akses? ',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: _LoginTheme.textMuted,
                      ),
                    ),
                    TextSpan(
                      text: 'Hubungi Helpdesk TI',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _LoginTheme.navy,
                        decoration: TextDecoration.underline,
                      ),
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

  Widget _buildQuickRolePresets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.group_outlined,
              size: 14,
              color: _LoginTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              'Quick Role Switch (Demo & Testing)',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _LoginTheme.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: UserRole.values.map((role) {
            final selected =
                _usernameController.text.toLowerCase() == role.apiValue;
            return GestureDetector(
              onTap: () => _preset(role),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: selected ? _LoginTheme.navy : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected ? _LoginTheme.navy : _LoginTheme.border,
                  ),
                ),
                child: Text(
                  role.displayName,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : _LoginTheme.textBody,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 12,
              color: _LoginTheme.textPlaceholder,
            ),
            const SizedBox(width: 4),
            Text(
              'Sistem Pengelolaan Mutasi & Inventaris Aset',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _LoginTheme.textPlaceholder,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'MutasiKu v2.4.0 • Divisi Operasional TI',
          style: GoogleFonts.inter(
            fontSize: 10,
            color: _LoginTheme.textPlaceholder.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
