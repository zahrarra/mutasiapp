// lib/features/notification/presentation/screens/notification_screen.dart
//
// Notifikasi bersama semua role — visual Stitch.
// Data: roleNotificationsProvider (hanya notif role yang login).
// Bottom bar: gaya _buildBottomNav() per role (tanpa Riwayat).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mutasiku/core/widgets/custom_floating_nav_bar.dart';
import '../../../../core/widgets/mutasiku_page_header.dart';

import '../../../../app/router/route_names.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/notification_item.dart';
import '../providers/notification_provider.dart';

enum _Filter { all, tugas, pembaruan }

abstract final class _S {
  static const bg = Color(0xFFF6F8FA);
  static const white = Color(0xFFFFFFFF);
  static const navy = Color(0xFF0F3D56);
  static const primaryContainer = Color(0xFF0F3D56);
  static const secondary = Color(0xFF006A63);
  static const textPrimary = Color(0xFF172B4D);
  static const textSecondary = Color(0xFF52606D);
  static const info = Color(0xFF175CD3);
  static const success = Color(0xFF15803D);
  static const warning = Color(0xFFB45309);
  static const surfaceLow = Color(0xFFECF4FF);
  static const surfaceHigh = Color(0xFFDBEAF9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate400 = Color(0xFF94A3B8);
}

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  _Filter _filter = _Filter.all;

  TextStyle _t({
    double size = 14,
    FontWeight w = FontWeight.w400,
    Color color = _S.textPrimary,
    double? h,
    double? ls,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: w,
      color: color,
      height: h,
      letterSpacing: ls,
    );
  }

  void _handleTap(NotificationItem item) {
    final currentUser = ref.read(authStateProvider).user;
    ref
        .read(notificationProvider.notifier)
        .markAsRead(item.id, userId: currentUser?.id);

    final mutationId = item.relatedMutationId;
    if (mutationId == null || mutationId.isEmpty) return;

    final role = currentUser?.role ?? item.targetRole;
    final targetPath = switch (role) {
      UserRole.operator =>
        RouteNames.operatorVerificationDetailPath.replaceFirst(
          ':id',
          mutationId,
        ),
      UserRole.bagianAset =>
        RouteNames.bagianAsetVerificationDetailPath.replaceFirst(
          ':id',
          mutationId,
        ),
      UserRole.kabagAset => RouteNames.kabagApprovalDetailPath.replaceFirst(
        ':id',
        mutationId,
      ),
      UserRole.kadiv => RouteNames.kadivApprovalDetailPath.replaceFirst(
        ':id',
        mutationId,
      ),
      UserRole.staffAset => RouteNames.staffMutationDetailPath.replaceFirst(
        ':id',
        mutationId,
      ),
      UserRole.pemohon => RouteNames.pemohonMutasiDetailPath.replaceFirst(
        ':id',
        mutationId,
      ),
      _ => null,
    };
    if (targetPath != null) {
      context.push(targetPath);
    }
  }

  void _markAllRead() {
    final u = ref.read(authStateProvider).user;
    ref
        .read(notificationProvider.notifier)
        .markAllAsRead(role: u?.role, userId: u?.id);
  }

  bool _isTugas(NotificationItem n) {
    final t = '${n.type} ${n.title}'.toLowerCase();
    return t.contains('action') ||
        t.contains('pengajuan') ||
        t.contains('verifikasi') ||
        t.contains('perbaikan') ||
        t.contains('sla') ||
        t.contains('tugas') ||
        t.contains('konfirmasi') ||
        t.contains('revisi');
  }

  List<NotificationItem> _filtered(List<NotificationItem> list) {
    switch (_filter) {
      case _Filter.all:
        return list;
      case _Filter.tugas:
        return list.where(_isTugas).toList();
      case _Filter.pembaruan:
        return list.where((n) => !_isTugas(n)).toList();
    }
  }

  Map<String, List<NotificationItem>> _groups(List<NotificationItem> list) {
    final map = <String, List<NotificationItem>>{};
    final now = DateTime.now();
    for (final n in list) {
      final key = _dayLabel(n.createdAt, now);
      map.putIfAbsent(key, () => []).add(n);
    }
    return map;
  }

  String _dayLabel(DateTime d, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hari Ini';
    if (diff == 1) return 'Kemarin';
    if (diff < 7) return 'Minggu Lalu';
    return 'Lebih Lama';
  }

  String _fmtDate(DateTime d) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  String _relative(DateTime d) {
    final diff = DateTime.now().difference(d);
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes.clamp(0, 59)} menit yang lalu • $h:$min WIB';
    }
    if (diff.inHours < 24 && diff.inDays == 0) {
      return '${diff.inHours} jam yang lalu • $h:$min WIB';
    }
    if (diff.inDays == 1) return 'Kemarin, $h:$min WIB';
    return '${_fmtDate(d)}, $h:$min WIB';
  }



  (IconData, Color, Color) _iconStyle(NotificationItem n) {
    final t = '${n.type} ${n.title}'.toLowerCase();
    if (t.contains('selesai') ||
        t.contains('setuju') ||
        t.contains('persetujuan')) {
      return (
        Icons.check_circle_outline,
        _S.success.withValues(alpha: 0.1),
        _S.success,
      );
    }
    if (t.contains('sla') ||
        t.contains('peringatan') ||
        t.contains('warning')) {
      return (
        Icons.warning_amber_rounded,
        _S.warning.withValues(alpha: 0.1),
        _S.warning,
      );
    }
    if (t.contains('perbaikan') ||
        t.contains('revisi') ||
        t.contains('dokumen')) {
      return (
        Icons.published_with_changes,
        _S.surfaceHigh,
        _S.primaryContainer,
      );
    }
    if (t.contains('arsip') || t.contains('sinkron') || t.contains('serah')) {
      return (Icons.task_alt, _S.surfaceLow, _S.secondary);
    }
    return (Icons.assignment_outlined, _S.surfaceLow, _S.secondary);
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(roleNotificationsProvider);
    final user = ref.watch(authStateProvider).user;
    final role = user?.role;

    final sorted = List<NotificationItem>.from(notifications)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final list = _filtered(sorted);
    final groups = _groups(list);
    final unread = sorted.where((n) => !n.isRead).length;
    final tugasN = sorted.where(_isTugas).length;
    final pembN = sorted.length - tugasN;

    return Scaffold(
      backgroundColor: _S.bg,
      extendBody: true,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: sorted.isEmpty
                ? Center(
                    child: Text(
                      'Belum ada notifikasi.',
                      style: _t(size: 14, color: _S.textSecondary),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _chip('Semua', sorted.length, _Filter.all),
                                  const SizedBox(width: 8),
                                  _chip('Tugas Verifikasi', tugasN, _Filter.tugas),
                                  const SizedBox(width: 8),
                                  _chip('Pembaruan', pembN, _Filter.pembaruan),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: unread == 0 ? null : _markAllRead,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _S.surfaceLow.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                unread == 0
                                    ? 'Semua Terbaca'
                                    : 'Tandai Semua Dibaca',
                                style: _t(
                                  size: 11,
                                  w: FontWeight.w600,
                                  color: unread == 0
                                      ? _S.slate400
                                      : _S.secondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (list.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'Tidak ada notifikasi di filter ini.',
                            textAlign: TextAlign.center,
                            style: _t(size: 13, color: _S.textSecondary),
                          ),
                        )
                      else
                        ...groups.entries.expand((e) {
                          final gUnread = e.value
                              .where((n) => !n.isRead)
                              .length;
                          return [
                            Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 6),
                              child: Row(
                                children: [
                                  Text(
                                    e.key.toUpperCase(),
                                    style: _t(
                                      size: 12,
                                      w: FontWeight.w700,
                                      ls: 0.6,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (e.value.isNotEmpty)
                                    Text(
                                      _fmtDate(e.value.first.createdAt),
                                      style: _t(
                                        size: 11,
                                        color: _S.textSecondary,
                                      ),
                                    ),
                                  const Spacer(),
                                  if (gUnread > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _S.surfaceHigh,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        '$gUnread Baru',
                                        style: _t(
                                          size: 11,
                                          w: FontWeight.w600,
                                          color: _S.navy,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            ...e.value.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _notifCard(item),
                              ),
                            ),
                          ];
                        }),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: role != null
          ? CustomFloatingNavBar.scaffoldBottomBar(
              items: RoleNavConfig.getNavItemsForRole(role),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: MutasiKuPageHeader(
        title: 'Notifikasi',
        subtitle: 'Pusat informasi dan status pembaruan mutasi aset',
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            final r = ref.read(authStateProvider).user?.role;
            context.go(r?.defaultRoute ?? RouteNames.dashboardPath);
          }
        },
      ),
    );
  }

  Widget _chip(String label, int count, _Filter f) {
    final active = _filter == f;
    return GestureDetector(
      onTap: () => setState(() => _filter = f),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? _S.primaryContainer : _S.surfaceLow,
          borderRadius: BorderRadius.circular(999),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: label,
                style: _t(
                  size: 12,
                  w: active ? FontWeight.w600 : FontWeight.w500,
                  color: active ? Colors.white : _S.textSecondary,
                ),
              ),
              TextSpan(
                text: ' ($count)',
                style: _t(
                  size: 11,
                  w: FontWeight.w500,
                  color: active
                      ? Colors.white.withValues(alpha: 0.9)
                      : _S.textSecondary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notifCard(NotificationItem item) {
    final unread = !item.isRead;
    final style = _iconStyle(item);
    final icon = style.$1;
    final bg = style.$2;
    final fg = style.$3;

    return Material(
      color: _S.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _handleTap(item),
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: unread ? 1.0 : 0.9,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _S.slate200.withValues(alpha: 0.8)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Stack(
              children: [
                if (unread)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: _S.info,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 18, color: fg),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: unread ? 12 : 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: _t(size: 14, w: FontWeight.w600, h: 1.3),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.message,
                              style: _t(
                                size: 12,
                                color: _S.textSecondary,
                                h: 1.45,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _relative(item.createdAt),
                              style: _t(size: 11, color: _S.slate400),
                            ),
                          ],
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
}
