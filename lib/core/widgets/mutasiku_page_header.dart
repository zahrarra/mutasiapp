// lib/core/widgets/mutasiku_page_header.dart
//
// VISUAL BASELINE HEADER WAJIB MUTASIKU (KECUALI DASHBOARD & PROFILE)
// Karakteristik:
// 1. Back button putih bulat dengan border tipis dan soft shadow di kiri atas
// 2. Pill header putih dengan rounded penuh, border tipis, soft shadow,
//    titik status hijau, dan nama konteks role aplikasi di tengah atas (dinamis).
// 3. Avatar circular deep navy dengan inisial user, border putih, dan titik hijau
//    di kanan atas.
// 4. Page Title besar, bold Montserrat deep navy.
// 5. Subtitle deskripsi fungsi halaman warna slate/abu-abu.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/auth/domain/entities/user_role.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// Reusable Page Header sesuai visual baseline referensi.
class MutasiKuPageHeader extends ConsumerWidget {
  /// Judul halaman besar
  final String title;

  /// Deskripsi singkat fungsi halaman
  final String? subtitle;

  /// Label role / konteks kustom (opsional, default: auto dari authState)
  final String? roleLabel;

  /// Callback back kustom (opsional, default: pop / fallback)
  final VoidCallback? onBack;

  /// Tampilkan tombol back (default: true)
  final bool showBackButton;

  /// Inisial kustom (opsional, default: auto dari nama user)
  final String? userInitials;

  /// Widget aksi tambahan di samping title atau di bawah subtitle
  final Widget? trailing;

  /// Padding keseluruhan header (default: horizontal 16, top 12, bottom 16)
  final EdgeInsetsGeometry padding;

  const MutasiKuPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.roleLabel,
    this.onBack,
    this.showBackButton = true,
    this.userInitials,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 16),
  });

  static String formatRoleLabel(UserRole? role) {
    return 'MUTASIKU';
  }

  static String extractInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'MK';
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'MK';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final displayRole = roleLabel ?? formatRoleLabel(user?.role);
    final initials = userInitials ?? extractInitials(user?.name);

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Top Navigation & Context Bar ─────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Back Button Bulat Putih
              if (showBackButton)
                _buildBackButton(context)
              else
                const SizedBox(width: 42, height: 42),

              const SizedBox(width: 8),

              // 2. Pill Header Putih Tengah (Dynamic Role Label)
              Flexible(child: _buildRolePill(displayRole)),

              const SizedBox(width: 8),

              // 3. Avatar Bulat Deep Navy + Status Hijau
              _buildAvatar(initials),
            ],
          ),

          const SizedBox(height: 20),

          // ── Title & Optional Trailing ──────────────────────────────────
          if (trailing != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildTitle()),
                const SizedBox(width: 12),
                trailing!,
              ],
            )
          else
            _buildTitle(),

          // ── Subtitle ───────────────────────────────────────────────────
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: GoogleFonts.montserrat(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF52606D),
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Tooltip(
      message: 'Kembali',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () {
            if (onBack != null) {
              onBack!();
            } else {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else if (context.canPop()) {
                context.pop();
              }
            }
          },
          customBorder: const CircleBorder(),
          child: Ink(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.arrow_back, size: 20, color: Color(0xFF00273A)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRolePill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Titik status hijau
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF22C55E), // green-500
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          // Nama konteks aplikasi / role
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF00273A),
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String initials) {
    return SizedBox(
      width: 42,
      height: 42,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF00273A), // Deep Navy
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          // Titik status hijau di kanan bawah avatar
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        fontSize: 23,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF00273A),
        height: 1.25,
      ),
    );
  }
}
