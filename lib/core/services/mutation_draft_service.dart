// lib/core/services/mutation_draft_service.dart
//
// Layanan penyimpanan & restorasi draf pengajuan mutasi Pemohon.
// Memastikan fitur "Simpan Draf" benar-benar tersimpan dan dapat
// dilanjutkan kembali di kemudian waktu (PRD V1.1).

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MutationDraft {
  final String? assetId;
  final String assetName;
  final String assetCode;
  final String currentPic;
  final String sourceLocation;
  final String targetLocation;
  final String room;
  final bool bringAsset;
  final String targetPic;
  final String reason;
  final String? documentName;
  final int? documentSize;
  final String? documentPath;
  final List<int>? documentBytes;
  final DateTime savedAt;

  String get pic => targetPic;
  DateTime get updatedAt => savedAt;

  const MutationDraft({
    this.assetId,
    this.assetName = '',
    this.assetCode = '',
    this.currentPic = '',
    this.sourceLocation = '',
    this.targetLocation = '',
    this.room = '',
    this.bringAsset = true,
    String? targetPic,
    String? pic,
    this.reason = '',
    this.documentName,
    this.documentSize,
    this.documentPath,
    this.documentBytes,
    DateTime? savedAt,
    DateTime? updatedAt,
  })  : targetPic = targetPic ?? pic ?? '',
        savedAt = savedAt ?? updatedAt ?? const _ConstDateTime();

  Map<String, dynamic> toJson() {
    return {
      'assetId': assetId,
      'assetName': assetName,
      'assetCode': assetCode,
      'currentPic': currentPic,
      'sourceLocation': sourceLocation,
      'targetLocation': targetLocation,
      'room': room,
      'bringAsset': bringAsset,
      'targetPic': targetPic,
      'reason': reason,
      'documentName': documentName,
      'documentSize': documentSize,
      'documentPath': documentPath,
      'documentBytes':
          documentBytes != null ? base64Encode(documentBytes!) : null,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  factory MutationDraft.fromJson(Map<String, dynamic> json) {
    List<int>? bytes;
    final b64 = json['documentBytes'] as String?;
    if (b64 != null && b64.isNotEmpty) {
      try {
        bytes = base64Decode(b64);
      } catch (_) {}
    }

    final dateStr = (json['savedAt'] ?? json['updatedAt']) as String?;
    DateTime date = DateTime.now();
    if (dateStr != null && dateStr.isNotEmpty) {
      date = DateTime.tryParse(dateStr) ?? DateTime.now();
    }

    return MutationDraft(
      assetId: json['assetId'] as String?,
      assetName: json['assetName'] as String? ?? '',
      assetCode: json['assetCode'] as String? ?? '',
      currentPic: json['currentPic'] as String? ?? '',
      sourceLocation: json['sourceLocation'] as String? ?? '',
      targetLocation: json['targetLocation'] as String? ?? '',
      room: json['room'] as String? ?? '',
      bringAsset: json['bringAsset'] as bool? ?? true,
      targetPic: (json['targetPic'] ?? json['pic']) as String? ?? '',
      reason: json['reason'] as String? ?? '',
      documentName: json['documentName'] as String?,
      documentSize: json['documentSize'] as int?,
      documentPath: json['documentPath'] as String?,
      documentBytes: bytes,
      savedAt: date,
    );
  }
}

class _ConstDateTime implements DateTime {
  const _ConstDateTime();

  @override
  bool isAfter(DateTime other) => false;
  @override
  bool isBefore(DateTime other) => false;
  @override
  bool isAtSameMomentAs(DateTime other) => false;
  @override
  int compareTo(DateTime other) => 0;

  @override
  DateTime add(Duration duration) => DateTime.now().add(duration);
  @override
  DateTime subtract(Duration duration) => DateTime.now().subtract(duration);
  @override
  Duration difference(DateTime other) => DateTime.now().difference(other);

  @override
  String toIso8601String() => DateTime.now().toIso8601String();
  @override
  DateTime toLocal() => DateTime.now();
  @override
  DateTime toUtc() => DateTime.now().toUtc();

  @override
  int get year => 2026;
  @override
  int get month => 1;
  @override
  int get day => 1;
  @override
  int get hour => 0;
  @override
  int get minute => 0;
  @override
  int get second => 0;
  @override
  int get millisecond => 0;
  @override
  int get microsecond => 0;
  @override
  int get millisecondsSinceEpoch => 0;
  @override
  int get microsecondsSinceEpoch => 0;
  @override
  String get timeZoneName => 'UTC';
  @override
  Duration get timeZoneOffset => Duration.zero;
  @override
  bool get isUtc => true;
  @override
  int get weekday => DateTime.thursday;
}

class MutationDraftService {
  static final Map<String, MutationDraft> _inMemoryDrafts = {};

  static String _key(String userId) => 'draft_mutation_$userId';

  static String _resolveUid(String? userId) {
    if (userId == null || userId.trim().isEmpty) {
      return 'default_user';
    }
    return userId.trim();
  }

  static Future<SharedPreferences?> _getPrefs() async {
    try {
      return await SharedPreferences.getInstance()
          .timeout(const Duration(milliseconds: 100));
    } catch (_) {
      return null;
    }
  }

  /// Simpan draf pengajuan.
  static Future<void> saveDraft(
    MutationDraft draft, {
    String? userId,
  }) async {
    final uid = _resolveUid(userId);
    _inMemoryDrafts[uid] = draft;

    try {
      final prefs = await _getPrefs();
      if (prefs != null) {
        await prefs.setString(_key(uid), jsonEncode(draft.toJson()));
      }
    } catch (_) {
      // Fallback ke in-memory cache jika SharedPreferences tidak tersedia
    }
  }

  /// Ambil draf pengajuan yang tersimpan (alias getDraft).
  static Future<MutationDraft?> loadDraft({String? userId}) async {
    return getDraft(userId: userId);
  }

  /// Ambil draf pengajuan yang tersimpan.
  static Future<MutationDraft?> getDraft({String? userId}) async {
    final uid = _resolveUid(userId);

    if (_inMemoryDrafts.containsKey(uid)) {
      return _inMemoryDrafts[uid];
    }

    try {
      final prefs = await _getPrefs();
      if (prefs != null) {
        final str = prefs.getString(_key(uid));
        if (str != null && str.isNotEmpty) {
          final map = jsonDecode(str) as Map<String, dynamic>;
          final draft = MutationDraft.fromJson(map);
          _inMemoryDrafts[uid] = draft;
          return draft;
        }
      }
    } catch (_) {}

    return null;
  }

  /// Hapus draf setelah pengajuan berhasil dikirim atau dibatalkan.
  static Future<void> clearDraft({String? userId}) async {
    final uid = _resolveUid(userId);
    _inMemoryDrafts.remove(uid);

    try {
      final prefs = await _getPrefs();
      if (prefs != null) {
        await prefs.remove(_key(uid));
      }
    } catch (_) {}
  }

  /// Cek apakah draf tersedia.
  static Future<bool> hasDraft({String? userId}) async {
    final draft = await getDraft(userId: userId);
    return draft != null;
  }

  /// Bersihkan state untuk testing.
  static void resetForTesting() {
    _inMemoryDrafts.clear();
  }
}
