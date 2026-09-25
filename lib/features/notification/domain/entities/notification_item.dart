// lib/features/notification/domain/entities/notification_item.dart
//
// Domain Entity: NotificationItem.
// Sumber: ROLE-FLOW.md, TECHNICAL-DESIGN.md, PRD.md.

import '../../../auth/domain/entities/user_role.dart';

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

  /// Role pengguna target penerima notifikasi (null jika untuk semua role)
  final UserRole? targetRole;

  /// ID pengguna spesifik target penerima notifikasi (opsional, misal pemohon spesifik)
  final String? targetUserId;

  /// Set ID user yang telah membaca notifikasi ini (mendukung read status independen per user).
  final Set<String> readByUserIds;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.relatedMutationId,
    this.targetRole,
    this.targetUserId,
    this.readByUserIds = const {},
  });

  /// Mengecek apakah notifikasi ini sudah dibaca oleh user tertentu.
  bool isReadBy(String? userId) {
    if (userId != null && readByUserIds.contains(userId)) {
      return true;
    }
    if (targetUserId != null && userId != null && targetUserId == userId) {
      return isRead || readByUserIds.contains(userId);
    }
    return isRead;
  }

  NotificationItem copyWith({
    bool? isRead,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? createdAt,
    String? relatedMutationId,
    UserRole? targetRole,
    String? targetUserId,
    Set<String>? readByUserIds,
  }) =>
      NotificationItem(
        id: id,
        title: title ?? this.title,
        message: message ?? this.message,
        type: type ?? this.type,
        createdAt: createdAt ?? this.createdAt,
        isRead: isRead ?? this.isRead,
        relatedMutationId: relatedMutationId ?? this.relatedMutationId,
        targetRole: targetRole ?? this.targetRole,
        targetUserId: targetUserId ?? this.targetUserId,
        readByUserIds: readByUserIds ?? this.readByUserIds,
      );
}
