// lib/features/admin/presentation/screens/admin_audit_log_screen.dart
//
// Screen: Log Audit Sistem & Rekam Jejak Tata Kelola Admin MutasiKu.
// 100% Visual & Design matching Stitch HTML Admin Design System.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/custom_floating_nav_bar.dart';
import '../../../../core/widgets/mutasiku_page_header.dart';
import '../../../auth/domain/entities/user_role.dart';

abstract final class _AuditColors {
  static const primaryNavy = Color(0xFF0F3D56);
  static const canvasBg = Color(0xFFF8F9FA);
  static const surfaceWhite = Color(0xFFFFFFFF);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);
  static const slate800 = Color(0xFF1E293B);
  static const emerald500 = Color(0xFF10B981);
}

class AdminAuditLogScreen extends ConsumerStatefulWidget {
  const AdminAuditLogScreen({super.key});

  @override
  ConsumerState<AdminAuditLogScreen> createState() =>
      _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends ConsumerState<AdminAuditLogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  final List<String> _categories = const [
    'Semua',
    'User & Role',
    'Master Data',
    'Sistem',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  TextStyle _t({
    required double size,
    FontWeight w = FontWeight.w400,
    Color color = _AuditColors.slate800,
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

  @override
  Widget build(BuildContext context) {
    final logs = _getFilteredLogs();

    return Scaffold(
      backgroundColor: _AuditColors.canvasBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SafeArea(
            bottom: false,
            child: MutasiKuPageHeader(
              title: 'Log Audit Sistem',
              subtitle: 'Histori pembaruan konfigurasi & rekam jejak tata kelola',
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(RouteNames.adminDashboardPath);
                }
              },
            ),
          ),

          // Search & Filter Category Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: _t(size: 13, color: _AuditColors.slate800),
                  decoration: InputDecoration(
                    hintText: 'Cari log, kode tag, atau aktivitas...',
                    hintStyle: _t(size: 13, color: _AuditColors.slate400),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 20,
                      color: _AuditColors.primaryNavy,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(
                        color: _AuditColors.slate200,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(
                        color: _AuditColors.slate200,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(
                        color: _AuditColors.primaryNavy,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val.trim());
                  },
                ),
                const SizedBox(height: 10),

                // Category Chips
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (ctx, idx) {
                      final cat = _categories[idx];
                      final isSelected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(
                          cat,
                          style: _t(
                            size: 12,
                            w: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : _AuditColors.slate600,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: _AuditColors.primaryNavy,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: isSelected
                              ? _AuditColors.primaryNavy
                              : _AuditColors.slate200,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        onSelected: (val) {
                          if (val) {
                            setState(() => _selectedCategory = cat);
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // List of Audit Logs
          Expanded(
            child: logs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 48,
                          color: _AuditColors.slate400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada log audit yang cocok.',
                          style: _t(
                            size: 14,
                            w: FontWeight.w600,
                            color: _AuditColors.slate600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    itemCount: logs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final item = logs[idx];
                      return _buildLogCard(item);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: CustomFloatingNavBar.scaffoldBottomBar(
        items: RoleNavConfig.getNavItemsForRole(UserRole.admin),
      ),
    );
  }

  List<_AuditLogItem> _getFilteredLogs() {
    final all = [
      const _AuditLogItem(
        avatarText: 'AP',
        title: 'Pembaruan Node Cabang',
        category: 'Master Data',
        time: '12m lalu',
        desc:
            'Node transit aset logistik regional ditambahkan ke KCP Thamrin.',
        tagCode: '#LOC-1092',
        statusLabel: 'Sukses Diterapkan',
        isSuccess: true,
      ),
      const _AuditLogItem(
        avatarText: 'DP',
        title: 'Penugasan Role Pegawai',
        category: 'User & Role',
        time: '1j lalu',
        desc:
            'User Dimas Pratama dialokasikan hak akses Petugas Aset TI oleh Admin Utama.',
        tagCode: '#RBAC-441',
        statusLabel: 'Oleh Admin Utama',
        isSuccess: true,
      ),
      const _AuditLogItem(
        avatarText: 'SYS',
        title: 'Sinkronisasi Basis Data Aset',
        category: 'Sistem',
        time: '3j lalu',
        desc:
            'Validasi 6.302 entitas inventaris server selesai tanpa anomali data.',
        tagCode: '#SYNC-882',
        statusLabel: 'Integritas Terverifikasi',
        isSuccess: true,
      ),
      const _AuditLogItem(
        avatarText: 'SEC',
        title: 'Pembaruan Kebijakan Token Sesi',
        category: 'Sistem',
        time: '5j lalu',
        desc:
            'Ambang batas token refresh diperpanjang 15 menit untuk kestabilan koneksi operator.',
        tagCode: '#SEC-019',
        statusLabel: 'Kebijakan Aktif',
        isSuccess: true,
      ),
      const _AuditLogItem(
        avatarText: 'USR',
        title: 'Pendaftaran Akun Baru Pemohon',
        category: 'User & Role',
        time: '1h lalu',
        desc:
            'Akun baru untuk staf operasional Rina Wati berhasil dibuat dan dikaitkan ke KC Surabaya.',
        tagCode: '#USR-902',
        statusLabel: 'Akun Aktif',
        isSuccess: true,
      ),
      const _AuditLogItem(
        avatarText: 'AST',
        title: 'Penambahan Kategori Aset Baru',
        category: 'Master Data',
        time: '2h lalu',
        desc:
            'Kategori aset "Peralatan Laboratorium TI" ditambahkan ke hierarki master kategori.',
        tagCode: '#CAT-314',
        statusLabel: 'Sukses Diterapkan',
        isSuccess: true,
      ),
    ];

    return all.where((log) {
      if (_selectedCategory != 'Semua' &&
          log.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = log.title.toLowerCase().contains(q);
        final matchDesc = log.desc.toLowerCase().contains(q);
        final matchTag = log.tagCode.toLowerCase().contains(q);
        return matchTitle || matchDesc || matchTag;
      }
      return true;
    }).toList();
  }

  Widget _buildLogCard(_AuditLogItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AuditColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _AuditColors.slate200.withValues(alpha: 0.8),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _AuditColors.primaryNavy.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _AuditColors.primaryNavy.withValues(alpha: 0.15),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              item.avatarText,
              style: _t(
                size: 11,
                w: FontWeight.w700,
                color: _AuditColors.primaryNavy,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        item.title,
                        style: _t(
                          size: 13,
                          w: FontWeight.w700,
                          color: _AuditColors.slate800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      item.time,
                      style: _t(size: 10, color: _AuditColors.slate500),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.desc,
                  style: _t(
                    size: 12,
                    color: _AuditColors.slate600,
                    h: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _AuditColors.slate100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _AuditColors.slate200,
                        ),
                      ),
                      child: Text(
                        item.tagCode,
                        style: _t(
                          size: 10,
                          w: FontWeight.w600,
                          color: _AuditColors.slate600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: item.isSuccess
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: item.isSuccess
                              ? const Color(0xFFA7F3D0)
                              : const Color(0xFFFECACA),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: item.isSuccess
                                  ? _AuditColors.emerald500
                                  : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.statusLabel,
                            style: _t(
                              size: 10,
                              w: FontWeight.w600,
                              color: item.isSuccess
                                  ? const Color(0xFF065F46)
                                  : Colors.red[800]!,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditLogItem {
  final String avatarText;
  final String title;
  final String category;
  final String time;
  final String desc;
  final String tagCode;
  final String statusLabel;
  final bool isSuccess;

  const _AuditLogItem({
    required this.avatarText,
    required this.title,
    required this.category,
    required this.time,
    required this.desc,
    required this.tagCode,
    required this.statusLabel,
    required this.isSuccess,
  });
}
