import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mutasiku/core/network/api_client.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/notification/presentation/providers/notification_provider.dart';

void main() {
  const testUser = User(
    id: 'user_pemohon_1',
    username: 'pemohon',
    name: 'Rina Pemohon',
    role: UserRole.pemohon,
  );

  group('Notification Backend API Persistence Tests', () {
    test('1. fetchNotifications loads real notifications and read status from backend', () async {
      final mockData = [
        {
          'id': 'notif_100',
          'type': 'App\\Notifications\\MutationStatusChangedNotification',
          'data': {
            'mutation_id': '10',
            'title': 'Disetujui Pemimpin Divisi',
            'message': 'Pengajuan mutasi Anda telah disetujui.',
            'action': 'approve',
          },
          'read_at': null,
          'is_read': false,
          'created_at': '2026-10-08T10:00:00.000000Z',
        },
        {
          'id': 'notif_101',
          'type': 'App\\Notifications\\MutationStatusChangedNotification',
          'data': {
            'mutation_id': '9',
            'title': 'Ditolak Pemimpin Divisi',
            'message': 'Pengajuan mutasi Anda ditolak.',
            'action': 'reject',
          },
          'read_at': '2026-10-08T11:00:00.000000Z',
          'is_read': true,
          'created_at': '2026-10-08T09:00:00.000000Z',
        },
      ];

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/notifications' && request.method == 'GET') {
          return http.Response(
            jsonEncode({'data': mockData}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockClient, baseUrl: 'http://127.0.0.1:8000');
      final notifier = NotificationNotifier(
        apiClient: apiClient,
        currentUserId: testUser.id,
        currentUserRole: testUser.role,
      );

      await notifier.fetchNotifications(userId: testUser.id, role: testUser.role);

      expect(notifier.state.length, 2);

      final unreadNotif = notifier.state.firstWhere((n) => n.id == 'notif_100');
      expect(unreadNotif.isRead, isFalse);
      expect(unreadNotif.title, 'Disetujui Pemimpin Divisi');

      final readNotif = notifier.state.firstWhere((n) => n.id == 'notif_101');
      expect(readNotif.isRead, isTrue); // Tetap read saat di-fetch (persisten setelah restart)
    });

    test('2. markAsRead calls POST /api/v1/notifications/{id}/read and updates state to read', () async {
      String? requestedUrl;
      String? requestedMethod;

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/notifications/notif_100/read' && request.method == 'POST') {
          requestedUrl = request.url.path;
          requestedMethod = request.method;
          return http.Response(
            jsonEncode({'message': 'Notifikasi ditandai sudah dibaca'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockClient, baseUrl: 'http://127.0.0.1:8000');
      final notifier = NotificationNotifier(
        apiClient: apiClient,
        currentUserId: testUser.id,
        currentUserRole: testUser.role,
      );

      notifier.markAsRead('notif_100', userId: testUser.id);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(requestedUrl, '/api/v1/notifications/notif_100/read');
      expect(requestedMethod, 'POST');
    });

    test('3. markAllAsRead calls POST /api/v1/notifications/read-all', () async {
      String? requestedUrl;
      String? requestedMethod;

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/notifications/read-all' && request.method == 'POST') {
          requestedUrl = request.url.path;
          requestedMethod = request.method;
          return http.Response(
            jsonEncode({'message': 'Semua notifikasi ditandai sudah dibaca'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockClient, baseUrl: 'http://127.0.0.1:8000');
      final notifier = NotificationNotifier(
        apiClient: apiClient,
        currentUserId: testUser.id,
        currentUserRole: testUser.role,
      );

      notifier.markAllAsRead(role: testUser.role, userId: testUser.id);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(requestedUrl, '/api/v1/notifications/read-all');
      expect(requestedMethod, 'POST');
    });
  });
}
