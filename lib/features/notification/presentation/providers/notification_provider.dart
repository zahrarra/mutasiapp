// lib/features/notification/presentation/providers/notification_provider.dart
//
// Riverpod provider untuk notifikasi berbasis event dan role.
// Sumber: PRD.md §6, ROLE-FLOW.md.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/notification_item.dart';

class NotificationNotifier extends StateNotifier<List<NotificationItem>> {
  final ApiClient? apiClient;
  final String? currentUserId;
  final UserRole? currentUserRole;

  NotificationNotifier({
    this.apiClient,
    this.currentUserId,
    this.currentUserRole,
  }) : super(_seedData());

  /// Mengambil notifikasi langsung dari backend Laravel API.
  Future<void> fetchNotifications({String? userId, UserRole? role}) async {
    if (apiClient == null) return;
    if (!kIsWeb) {
      try {
        if (SecureStorage.isTestEnvironment &&
            apiClient!.baseUrl == AppConstants.defaultBaseUrl &&
            !apiClient!.isCustomClient) {
          return;
        }
      } catch (_) {}
    }
    try {
      final response = await apiClient!.get('/api/v1/notifications');
      switch (response) {
        case Success(:final data):
          final listData = data['data'] as List<dynamic>?;
          if (listData != null) {
            final items = listData.map((item) {
              final map = item as Map<String, dynamic>;
              final notifData = (map['data'] as Map<String, dynamic>?) ?? {};
              final action = notifData['action'] as String?;
              final notifType = switch (action) {
                'reject' => NotificationType.warning,
                'return' => NotificationType.warning,
                'approve' => NotificationType.success,
                'confirm' => NotificationType.success,
                _ => NotificationType.info,
              };
              final isRead = (map['is_read'] as bool?) ?? (map['read_at'] != null);
              final createdAt =
                  DateTime.tryParse(map['created_at']?.toString() ?? '') ??
                      DateTime.now();

              return NotificationItem(
                id: map['id'].toString(),
                title: notifData['title']?.toString() ?? 'Notifikasi Mutasi',
                message: notifData['message']?.toString() ?? '',
                type: notifType,
                createdAt: createdAt,
                isRead: isRead,
                relatedMutationId: notifData['mutation_id']?.toString(),
                targetUserId: userId ?? currentUserId,
                targetRole: role ?? currentUserRole,
              );
            }).toList();
            state = items;
          }
        case AppFailure():
          // Tetap pertahankan state yang ada jika fetch gagal
          break;
      }
    } catch (_) {}
  }

  static List<NotificationItem> _seedData() {
    final now = DateTime.now();
    return [
      NotificationItem(
        id: 'notif_1',
        title: 'Pengajuan Diverifikasi',
        message: 'Pengajuan mutasi FURNITUR-2026-00018 telah dinyatakan lengkap & diverifikasi oleh Operator dan diteruskan ke Bagian Aset.',
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
        message: 'Pengajuan mutasi FURNITUR-2026-00018 (Meja Kerja Eksekutif) diajukan oleh Dewi Lestari dan menunggu pemeriksaan kelengkapan Anda.',
        type: NotificationType.action,
        createdAt: now.subtract(const Duration(hours: 1)),
        relatedMutationId: 'mut_004',
        targetRole: UserRole.operator,
      ),
      NotificationItem(
        id: 'notif_opr_2',
        title: 'Pengajuan Baru Masuk',
        message: 'Pengajuan mutasi KENDARAAN-2026-00042 (Toyota Avanza) diajukan oleh Budi Santoso dan menunggu pemeriksaan kelengkapan Anda.',
        type: NotificationType.action,
        createdAt: now.subtract(const Duration(hours: 5)),
        relatedMutationId: 'mut_002',
        targetRole: UserRole.operator,
      ),

      // ── Bagian Aset Notifications ────────────────────────────────────────
      NotificationItem(
        id: 'notif_kbg_1',
        title: 'Menunggu Verifikasi Bagian Aset',
        message: 'Pengajuan mutasi FURNITUR-2026-00018 (Meja Kerja Eksekutif) telah dinyatakan lengkap oleh Operator dan menunggu verifikasi keabsahan aset Anda.',
        type: NotificationType.action,
        createdAt: now.subtract(const Duration(hours: 4)),
        relatedMutationId: 'mut_004',
        targetRole: UserRole.bagianAset,
      ),
      NotificationItem(
        id: 'notif_ast_2',
        title: 'Penentuan PIC Baru Diperlukan',
        message: 'Pengajuan mutasi ELEKTRONIK-2026-00077: aset fisik ditinggalkan di unit asal. Bagian Aset menentukan PIC baru melalui sistem saat verifikasi.',
        type: NotificationType.action,
        createdAt: now.subtract(const Duration(hours: 3)),
        relatedMutationId: 'mut_007',
        targetRole: UserRole.bagianAset,
      ),

      // ── Kadiv Notifications ──────────────────────────────────────────────
      NotificationItem(
        id: 'notif_kdv_1',
        title: 'Menunggu Persetujuan Final',
        message: 'Pengajuan mutasi ELEKTRONIK-2026-00088 (Server Rack Enterprise) telah lolos verifikasi Bagian Aset dan memerlukan persetujuan final Pemimpin Divisi.',
        type: NotificationType.action,
        createdAt: now.subtract(const Duration(hours: 2)),
        relatedMutationId: 'mut_005',
        targetRole: UserRole.kadiv,
      ),

      // ── Pemohon Notifications ────────────────────────────────────────────
      NotificationItem(
        id: 'notif_pmh_1',
        title: 'Pengajuan Dikembalikan Operator',
        message: 'Pengajuan mutasi ELEKTRONIK-2026-00105 dikembalikan: Dokumen wajib SK SDM belum dilampirkan.',
        type: NotificationType.warning,
        createdAt: now.subtract(const Duration(days: 1)),
        relatedMutationId: 'mut_003',
        targetRole: UserRole.pemohon,
        targetUserId: 'usr_pemohon',
      ),
      NotificationItem(
        id: 'notif_pmh_2',
        title: 'Menunggu Konfirmasi Anda',
        message: 'Pengajuan mutasi kursi ergonomis (FURNITUR-2026-00055) telah disetujui Pemimpin Divisi. Silakan periksa kondisi fisik aset dan konfirmasi penerimaan.',
        type: NotificationType.action,
        createdAt: now.subtract(const Duration(days: 2)),
        relatedMutationId: 'mut_006',
        targetRole: UserRole.pemohon,
        targetUserId: 'usr_pemohon',
      ),
      NotificationItem(
        id: 'notif_pmh_3',
        title: 'Mutasi Selesai',
        message: 'Mutasi aset Laptop Dell Latitude (ELEKTRONIK-2026-00124) telah dikonfirmasi sesuai dan data inventaris telah diperbarui.',
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
        message: 'Master lokasi dan kategori aset aktif dan terkonfigurasi sesuai alur mutasi.',
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
            isRead: userId == null || item.targetUserId != null ? true : item.isRead,
            readByUserIds: userId != null
                ? {...item.readByUserIds, userId}
                : item.readByUserIds,
          )
        else
          item,
    ];

    if (apiClient != null) {
      apiClient!.post('/api/v1/notifications/$id/read').catchError((_) {
        return Result<Map<String, dynamic>>.failure(const NetworkFailure(message: 'Gagal update read status'));
      });
    }
  }

  void markAllAsRead({UserRole? role, String? userId}) {
    state = [
      for (final item in state)
        if (_isTargetedFor(item, role: role, userId: userId))
          item.copyWith(
            isRead: userId == null || item.targetUserId != null ? true : item.isRead,
            readByUserIds: userId != null
                ? {...item.readByUserIds, userId}
                : item.readByUserIds,
          )
        else
          item,
    ];

    if (apiClient != null) {
      apiClient!.post('/api/v1/notifications/read-all').catchError((_) {
        return Result<Map<String, dynamic>>.failure(const NetworkFailure(message: 'Gagal update read-all'));
      });
    }
  }

  static bool _matchesRole(UserRole? targetRole, UserRole? currentRole) {
    if (targetRole == null || currentRole == null) return true;
    return targetRole == currentRole;
  }

  static bool _isTargetedFor(
    NotificationItem item, {
    UserRole? role,
    String? userId,
  }) {
    if (item.targetUserId != null) {
      if (userId != null && !matchesUserId(item.targetUserId, userId)) {
        return false;
      }
      if (role != null &&
          item.targetRole != null &&
          !_matchesRole(item.targetRole, role)) {
        return false;
      }
      return true;
    }
    if (item.targetRole != null) {
      if (role != null && !_matchesRole(item.targetRole, role)) {
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
    if (!matchesUserId(item.targetUserId, userId)) {
      return false; // Notifikasi user A tidak pernah tampil untuk user B
    }
    if (item.targetRole != null) {
      if (item.targetRole != userRole) {
        return false;
      }
    }
    return true;
  }

  // 2. Jika notifikasi ditujukan ke seluruh role:
  if (item.targetRole != null) {
    return item.targetRole == userRole;
  }

  return false;
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, List<NotificationItem>>((ref) {
      final apiClient = ref.watch(apiClientProvider);
      final notifier = NotificationNotifier(apiClient: apiClient);

      ref.listen<AuthState>(authStateProvider, (prev, next) {
        if (next.isAuthenticated && next.user != null) {
          notifier.fetchNotifications(
            userId: next.user?.id,
            role: next.user?.role,
          );
        }
      });

      return notifier;
    });

/// Provider notifikasi terfilter sesuai role dan user yang sedang login.
final roleNotificationsProvider = Provider<List<NotificationItem>>((ref) {
  final allNotifications = ref.watch(notificationProvider);
  final currentUser = ref.watch(authStateProvider).user;

  if (currentUser == null) return [];

  return allNotifications
      .where((n) => isNotificationVisibleToUser(n, currentUser))
      .map((n) => n.copyWith(isRead: n.isRead || n.isReadBy(currentUser.id)))
      .toList();
});

/// Fallback provider khusus layar Pemohon saat dijalankan tanpa auth mock harness.
final pemohonFallbackNotificationsProvider = Provider<List<NotificationItem>>((
  ref,
) {
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
