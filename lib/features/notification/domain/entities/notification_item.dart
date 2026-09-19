// lib/features/notification/domain/entities/notification_item.dart
//
// Domain Entity: NotificationItem.
//
// CATATAN PENTING:
// Mekanisme notifikasi (push vs in-app, sumber data, retensi) belum
// diputuskan — lihat Open Questions di TECHNICAL-DESIGN.md & PRD.md.
// Implementasi ini adalah placeholder MVP berbasis mock/in-memory data
// agar tab "Notifikasi" di tiap role dashboard tidak dead-end, dan agar
// struktur domain sudah siap saat backend notifikasi final ditentukan.

/// Kategori notifikasi, dipetakan longgar ke event MutationStatus.
enum NotificationType {
  info,
  success,
  warning,
  action,
}

/// Entity domain untuk satu item notifikasi.
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;

  /// ID mutasi terkait (jika notifikasi berasal dari event mutasi),
  /// digunakan untuk deep-link ke detail saat notifikasi diketuk.
  final String? relatedMutationId;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.relatedMutationId,
  });

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        id: id,
        title: title,
        message: message,
        type: type,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
        relatedMutationId: relatedMutationId,
      );
}
