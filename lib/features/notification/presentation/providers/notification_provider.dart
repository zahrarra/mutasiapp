// lib/features/notification/presentation/providers/notification_provider.dart
//
// Riverpod provider untuk notifikasi berbasis event dan role.
// Sumber: PRD.md §6, ROLE-FLOW.md.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/notification_item.dart';

class NotificationNotifier extends StateNotifier<List<NotificationItem>> {
  NotificationNotifier() : super(_seedData());

  static List<NotificationItem> _seedData() {
    final now = DateTime.now();
    return [
      NotificationItem(
        id: 'notif_1',
        title: 'Pengajuan Diverifikasi',
        message: 'Pengajuan mutasi FURNITUR-2026-00018 telah diverifikasi oleh Operator dan diteruskan ke Kabag.',
        type: NotificationType.info,
        createdAt: now.subtract(const Duration(minutes: 30)),
        relatedMutationId: 'mut_004',
        targetRole: UserRole.pemohon,
        targetUserId: 'usr_pemohon',
      ),
      // ── Operator Notifications ──────────────────────────────────────────
      NotificationItem(
        id: 'notif_opr_1',
        title: 'Pengajuan Baru Masuk',
        message: 'Pengajuan mutasi FURNITUR-2026-00018 (Meja Kerja Eksekutif) diajukan oleh Dewi Lestari dan menunggu verifikasi Anda.',
        type: NotificationType.action,
        createdAt: now.subtract(const Duration(hours: 1)),
        relatedMutationId: 'mut_004',
        targetRole: UserRole.operator,
      ),
      NotificationItem(
        id: 'notif_opr_2',
        title: 'Pengajuan Baru Masuk',
        message: 'Pengajuan mutasi KENDARAAN-2026-00042 (Toyota Avanza) diajukan oleh Budi Santoso dan menunggu verifikasi Anda.',
        type: NotificationType.action,
        createdAt: now.subtract(const Duration(hours: 5)),
        relatedMutationId: 'mut_002',
        targetRole: UserRole.operator,
      ),

      // ── Kabag Aset Notifications ─────────────────────────────────────────
      NotificationItem(
        id: 'notif_kbg_1',
        title: 'Menunggu Approval Kabag',
        message: 'Pengajuan mutasi FURNITUR-2026-00018 (Meja Kerja Eksekutif) telah diverifikasi Operator dan siap ditinjau.',
        type: NotificationType.action,
        createdAt: now.subtract(const Duration(hours: 4)),
        relatedMutationId: 'mut_004',
        targetRole: UserRole.kabagAset,
      ),

      // ── Kadiv Notifications ──────────────────────────────────────────────
      NotificationItem(
        id: 'notif_kdv_1',
        title: 'Menunggu Approval Kadiv',
        message: 'Pengajuan mutasi ELEKTRONIK-2026-00088 (Server Rack Enterprise) telah disetujui Kabag dan memerlukan penetapan akhir Kadiv.',
        type: NotificationType.action,
        createdAt: now.subtract(const Duration(hours: 2)),
        relatedMutationId: 'mut_005',
        targetRole: UserRole.kadiv,
      ),

      // ── Staff Aset Notifications ─────────────────────────────────────────
      NotificationItem(
        id: 'notif_stf_1',
        title: 'Tugas Pembaruan Fisik Aset',
        message: 'Pengajuan mutasi ELEKTRONIK-2026-00077 telah disetujui. Silakan lakukan pemindahan fisik dan perbarui lokasi & PIC aset.',
        type: NotificationType.action,
        createdAt: now.subtract(const Duration(hours: 3)),
        relatedMutationId: 'mut_007',
        targetRole: UserRole.staffAset,
      ),

      // ── Pemohon Notifications ────────────────────────────────────────────
      NotificationItem(
        id: 'notif_pmh_1',
        title: 'Pengajuan Dikembalikan Operator',
        message: 'Pengajuan mutasi ELEKTRONIK-2026-00105 dikembalikan: Dokumen pendukung SK Mutasi belum dilampirkan.',
        type: NotificationType.warning,
        createdAt: now.subtract(const Duration(days: 1)),
        relatedMutationId: 'mut_003',
        targetRole: UserRole.pemohon,
        targetUserId: 'usr_pemohon',
      ),
      NotificationItem(
        id: 'notif_pmh_2',
        title: 'Menunggu Konfirmasi Anda',
        message: 'Data fisik aset kursi ergonomis (FURNITUR-2026-00055) telah diperbarui Staff Aset. Silakan konfirmasi penerimaan fisik.',
        type: NotificationType.action,
        createdAt: now.subtract(const Duration(days: 2)),
        relatedMutationId: 'mut_006',
        targetRole: UserRole.pemohon,
        targetUserId: 'usr_pemohon',
      ),
      NotificationItem(
        id: 'notif_pmh_3',
        title: 'Mutasi Selesai',
        message: 'Mutasi aset Laptop Dell Latitude (ELEKTRONIK-2026-00124) telah dikonfirmasi dan selesai.',
        type: NotificationType.success,
        createdAt: now.subtract(const Duration(days: 3)),
        isRead: true,
        relatedMutationId: 'mut_001',
        targetRole: UserRole.pemohon,
        targetUserId: 'usr_pemohon',
      ),
      // ── Admin Notifications ──────────────────────────────────────────────
      NotificationItem(
        id: 'notif_adm_1',
        title: 'Laporan Master Data & Sistem',
        message: 'Kategori aset dan kriteria approval Kadiv telah aktif dan terkonfigurasi.',
        type: NotificationType.info,
        createdAt: now.subtract(const Duration(hours: 6)),
        targetRole: UserRole.admin,
      ),
    ];
  }

  void markAsRead(String id, {String? userId}) {
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(
            isRead: userId == null || item.targetUserId == userId ? true : item.isRead,
            readByUserIds: userId != null
                ? {...item.readByUserIds, userId}
                : item.readByUserIds,
          )
        else
          item,
    ];
  }

  void markAllAsRead({UserRole? role, String? userId}) {
    state = [
      for (final item in state)
        if (_isTargetedFor(item, role: role, userId: userId))
          item.copyWith(
            isRead: userId == null || item.targetUserId == userId ? true : item.isRead,
            readByUserIds: userId != null
                ? {...item.readByUserIds, userId}
                : item.readByUserIds,
          )
        else
          item,
    ];
  }

  static bool _isTargetedFor(
    NotificationItem item, {
    UserRole? role,
    String? userId,
  }) {
    if (item.targetUserId != null) {
      if (userId != null && item.targetUserId != userId) {
        return false;
      }
      if (role != null && item.targetRole != null && item.targetRole != role) {
        return false;
      }
      return true;
    }
    if (item.targetRole != null) {
      if (role != null && item.targetRole != role) {
        return false;
      }
      return true;
    }
    return false;
  }

  void addNotification(NotificationItem item) {
    state = [item, ...state];
  }

  void notifyRole({
    required UserRole targetRole,
    required String title,
    required String message,
    required NotificationType type,
    String? relatedMutationId,
  }) {
    final item = NotificationItem(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}_${targetRole.name}',
      title: title,
      message: message,
      type: type,
      createdAt: DateTime.now(),
      targetRole: targetRole,
      relatedMutationId: relatedMutationId,
    );
    addNotification(item);
  }

  void notifyUser({
    required String targetUserId,
    UserRole? targetRole,
    required String title,
    required String message,
    required NotificationType type,
    String? relatedMutationId,
  }) {
    final item = NotificationItem(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}_$targetUserId',
      title: title,
      message: message,
      type: type,
      createdAt: DateTime.now(),
      targetUserId: targetUserId,
      targetRole: targetRole,
      relatedMutationId: relatedMutationId,
    );
    addNotification(item);
  }
}

/// Helper fungsi untuk mengecek apakah suatu notifikasi dapat dilihat oleh user tertentu.
bool isNotificationVisibleToUser(NotificationItem item, dynamic user) {
  // Dukungan untuk User entity
  final userId = user.id as String;
  final userRole = user.role as UserRole;

  // 1. Jika notifikasi ditujukan ke user spesifik:
  if (item.targetUserId != null) {
    if (item.targetUserId != userId) {
      return false; // Notifikasi user A tidak pernah tampil untuk user B
    }
    if (item.targetRole != null && item.targetRole != userRole) {
      return false;
    }
    return true;
  }

  // 2. Jika notifikasi ditujukan ke seluruh role:
  if (item.targetRole != null) {
    return item.targetRole == userRole;
  }

  // 3. Notifikasi tanpa target role & user tidak boleh bocor
  return false;
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, List<NotificationItem>>((ref) {
  return NotificationNotifier();
});

/// Provider notifikasi terfilter sesuai role dan user yang sedang login.
final roleNotificationsProvider = Provider<List<NotificationItem>>((ref) {
  final allNotifications = ref.watch(notificationProvider);
  final currentUser = ref.watch(authStateProvider).user;

  if (currentUser == null) return [];

  return allNotifications
      .where((n) => isNotificationVisibleToUser(n, currentUser))
      .map((n) => n.copyWith(isRead: n.isReadBy(currentUser.id)))
      .toList();
});

/// Fallback provider khusus layar Pemohon saat dijalankan tanpa auth mock harness.
final pemohonFallbackNotificationsProvider = Provider<List<NotificationItem>>((ref) {
  final allNotifications = ref.watch(notificationProvider);
  const fallbackUser = User(
    id: 'usr_pemohon',
    username: 'pemohon',
    name: 'Pemohon',
    email: 'pemohon@mutasiku.id',
    role: UserRole.pemohon,
  );

  return allNotifications
      .where((n) => isNotificationVisibleToUser(n, fallbackUser))
      .map((n) => n.copyWith(isRead: n.isReadBy(fallbackUser.id)))
      .toList();
});

/// Menghitung jumlah notifikasi yang belum dibaca khusus untuk user dan role saat ini.
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(roleNotificationsProvider);
  return notifications.where((n) => !n.isRead).length;
});
