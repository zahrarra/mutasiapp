// lib/features/notification/presentation/providers/notification_provider.dart
//
// Riverpod provider untuk notifikasi (mock/in-memory — lihat catatan di
// notification_item.dart mengenai status Open Question backend notifikasi).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/notification_item.dart';

class NotificationNotifier extends StateNotifier<List<NotificationItem>> {
  NotificationNotifier() : super(_seedData());

  static List<NotificationItem> _seedData() {
    final now = DateTime.now();
    return [
      NotificationItem(
        id: 'notif_1',
        title: 'Pengajuan Diverifikasi',
        message: 'Pengajuan mutasi Anda telah diverifikasi oleh Operator dan menunggu approval Kabag Aset.',
        type: NotificationType.info,
        createdAt: now.subtract(const Duration(hours: 2)),
        relatedMutationId: 'mut_004',
      ),
      NotificationItem(
        id: 'notif_2',
        title: 'Menunggu Konfirmasi Anda',
        message: 'Data aset telah diperbarui oleh Staff Aset. Silakan konfirmasi kesesuaian data.',
        type: NotificationType.action,
        createdAt: now.subtract(const Duration(days: 1)),
        relatedMutationId: 'mut_006',
      ),
      NotificationItem(
        id: 'notif_3',
        title: 'Mutasi Selesai',
        message: 'Mutasi aset Anda telah dikonfirmasi dan berstatus Selesai.',
        type: NotificationType.success,
        createdAt: now.subtract(const Duration(days: 3)),
        isRead: true,
        relatedMutationId: 'mut_001',
      ),
    ];
  }

  void markAsRead(String id) {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(isRead: true) else item,
    ];
  }

  void markAllAsRead() {
    state = [for (final item in state) item.copyWith(isRead: true)];
  }

  void addNotification(NotificationItem item) {
    state = [item, ...state];
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, List<NotificationItem>>((ref) {
  return NotificationNotifier();
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationProvider);
  return notifications.where((n) => !n.isRead).length;
});
