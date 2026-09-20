// lib/features/pemohon/presentation/screens/pemohon_select_asset_screen.dart
// UI mengikuti mockup "Pilih Aset" + mutationFormProvider.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';

// Sesuaikan import Asset entity jika path beda
// import '../../../asset/domain/entities/asset.dart';

class _C {
  static const background = Color(0xFFF6F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFF00273A);
  static const primaryContainer = Color(0xFF0F3D56);
  static const secondary = Color(0xFF006A63);
  static const secondaryContainer = Color(0xFF99EFE5);
  static const textPrimary = Color(0xFF172B4D);
  static const textSecondary = Color(0xFF52606D);
  static const success = Color(0xFF15803D);
  static const warning = Color(0xFFB45309);
  static const disabled = Color(0xFF98A2B3);
  static const surfaceLow = Color(0xFFECF4FF);
  static const surfaceHigh = Color(0xFFDBEAF9);
  static const surfaceBright = Color(0xFFF7F9FF);
}

/// Model lokal untuk list (ganti dengan entity Asset dari repo bila sudah ada).
class _AssetItem {
  const _AssetItem({
    required this.id,
    required this.name,
    required this.code,
    required this.category,
    required this.location,
    required this.picLabel,
    required this.condition,
    this.locked = false,
    this.lockTicket,
  });

  final String id;
  final String name;
  final String code;
  final String category; // all | laptop | display | peripheral
  final String location;
  final String picLabel;
  final String condition;
  final bool locked;
  final String? lockTicket;
}

class PemohonSelectAssetScreen extends ConsumerStatefulWidget {
  const PemohonSelectAssetScreen({super.key});

  @override
  ConsumerState<PemohonSelectAssetScreen> createState() =>
      _PemohonSelectAssetScreenState();
}

class _PemohonSelectAssetScreenState
    extends ConsumerState<PemohonSelectAssetScreen> {
  final _search = TextEditingController();
  String _category = 'all';
  String? _selectedId;

  // Dummy sesuai mockup — nanti diganti provider aset real
  final _assets = const [
    _AssetItem(
      id: 'AST-NB-2024-88392',
      name: 'Lenovo ThinkPad T14 Gen 4',
      code: 'AST-NB-2024-88392',
      category: 'laptop',
      location: 'Kantor Pusat Lt. 4, Jakarta',
      picLabel: 'PIC: Anda',
      condition: 'Baik',
    ),
    _AssetItem(
      id: 'AST-MON-2024-40912',
      name: 'Dell UltraSharp 27" 4K Monitor',
      code: 'AST-MON-2024-40912',
      category: 'display',
      location: 'Kantor Pusat Lt. 4, Jakarta',
      picLabel: 'PIC: Anda',
      condition: 'Baik',
    ),
    _AssetItem(
      id: 'AST-PRN-2023-11029',
      name: 'HP LaserJet Pro M404dn',
      code: 'AST-PRN-2023-11029',
      category: 'peripheral',
      location: 'Kantor Pusat Lt. 4, Jakarta',
      picLabel: 'PIC: Anda',
      condition: 'Baik',
    ),
    _AssetItem(
      id: 'AST-NB-2023-01452',
      name: 'MacBook Pro 14" M2',
      code: 'AST-NB-2023-01452',
      category: 'laptop',
      location: 'Kantor Pusat Lt. 4, Jakarta',
      picLabel: 'PIC: Anda',
      condition: 'Baik',
      locked: true,
      lockTicket: 'TIK-2026-00039',
    ),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<_AssetItem> get _filtered {
    final q = _search.text.trim().toLowerCase();
    return _assets.where((a) {
      final catOk = _category == 'all' || a.category == _category;
      final qOk =
          q.isEmpty ||
          a.name.toLowerCase().contains(q) ||
          a.code.toLowerCase().contains(q);
      return catOk && qOk;
    }).toList();
  }

  _AssetItem? get _selected {
    if (_selectedId == null) return null;
    try {
      return _assets.firstWhere((a) => a.id == _selectedId);
    } catch (_) {
      return null;
    }
  }

  IconData _iconFor(String category) {
    switch (category) {
      case 'display':
        return Icons.desktop_windows_outlined;
      case 'peripheral':
        return Icons.print_outlined;
      default:
        return Icons.laptop_mac_outlined;
    }
  }

  void _continue() {
    final item = _selected;
    if (item == null || item.locked) return;

    // Simpan ke form provider — SESUAIKAN dengan API mutationFormProvider kamu
    // Contoh:
    // ref.read(mutationFormProvider.notifier).selectAsset(...);

    // Navigasi ke form
    context.push(RouteNames.pemohonMutasiCreatePath);
    // atau: RouteNames.pemohonMutasiCreatePath
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    final selected = _selected;

    return Scaffold(
      backgroundColor: _C.background,
      body: Column(
        children: [
          // Header
          Material(
            color: _C.surface.withValues(alpha: 0.92),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back),
                      color: _C.textPrimary,
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _C.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.sync_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Pilih Aset',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _C.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () =>
                          context.go(RouteNames.pemohonNotificationsPath),
                      icon: const Icon(Icons.notifications_outlined),
                      color: _C.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
              children: [
                // Banner sinkron
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _C.surface,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: _C.success),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Terhubung ke Database Inventaris Internal',
                          style: TextStyle(
                            fontSize: 11,
                            color: _C.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Pilih Aset untuk Dimutasi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _C.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pilih aset yang menjadi tanggung jawab Anda saat ini untuk diajukan mutasi.',
                  style: TextStyle(fontSize: 14, color: _C.textSecondary),
                ),
                const SizedBox(height: 16),

                // Search
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: _C.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Cari nama atau kode aset...',
                      hintStyle: TextStyle(
                        color: _C.textSecondary.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: _C.textSecondary,
                        size: 20,
                      ),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _search.clear();
                                setState(() {});
                              },
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Category chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip('all', 'Semua (${_assets.length})'),
                      _chip(
                        'laptop',
                        'Komputer & Laptop (${_assets.where((a) => a.category == 'laptop').length})',
                      ),
                      _chip(
                        'display',
                        'Hardware Display (${_assets.where((a) => a.category == 'display').length})',
                      ),
                      _chip(
                        'peripheral',
                        'Periferal (${_assets.where((a) => a.category == 'peripheral').length})',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Cards
                ...list.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AssetCard(
                      item: a,
                      selected: _selectedId == a.id,
                      icon: _iconFor(a.category),
                      onTap: a.locked
                          ? null
                          : () => setState(() => _selectedId = a.id),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Sticky bottom
      bottomNavigationBar: Material(
        color: _C.surface,
        elevation: 8,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: _C.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selected == null
                            ? 'Belum ada aset dipilih'
                            : '1 Aset Dipilih: ${selected.name}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _C.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Text(
                      'Langkah 1/3',
                      style: TextStyle(fontSize: 11, color: _C.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: selected != null && !selected.locked
                        ? _continue
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _C.disabled,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Pilih Aset',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Lanjutkan ke formulir pengisian data mutasi aset',
                  style: TextStyle(fontSize: 12, color: _C.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String id, String label) {
    final active = _category == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _category = id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? _C.primary : _C.surface,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : _C.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _AssetCard extends StatelessWidget {
  const _AssetCard({
    required this.item,
    required this.selected,
    required this.icon,
    this.onTap,
  });

  final _AssetItem item;
  final bool selected;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locked = item.locked;
    return Opacity(
      opacity: locked ? 0.7 : 1,
      child: Material(
        color: selected ? _C.surfaceLow : _C.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: locked ? _C.surfaceHigh : _C.surfaceHigh,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            icon,
                            color: locked
                                ? _C.textSecondary
                                : _C.primaryContainer,
                          ),
                        ),
                        if (locked)
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: _C.warning,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock,
                                size: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: locked ? _C.textSecondary : _C.textPrimary,
                            ),
                          ),
                          Text(
                            item.code,
                            style: TextStyle(
                              fontSize: 11,
                              color: locked ? _C.disabled : _C.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (locked)
                      const Icon(Icons.lock, size: 20, color: _C.disabled)
                    else
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: selected ? _C.primary : _C.surfaceHigh,
                          shape: BoxShape.circle,
                        ),
                        child: selected
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: selected ? _C.surface : _C.surfaceBright,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: locked ? _C.disabled : _C.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.location,
                              style: TextStyle(
                                fontSize: 12,
                                color: locked ? _C.disabled : _C.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            size: 16,
                            color: locked ? _C.disabled : _C.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.picLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: locked ? _C.disabled : _C.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (locked) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _C.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 14, color: _C.warning),
                        SizedBox(width: 4),
                        Text(
                          'Dalam Proses Mutasi',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _C.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Aset sedang memiliki tiket aktif ${item.lockTicket ?? '-'} dan terkunci sementara.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _C.textSecondary,
                    ),
                  ),
                ] else
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _C.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified, size: 14, color: _C.success),
                            SizedBox(width: 4),
                            Text(
                              'Kondisi: Baik',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _C.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _C.secondaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.circle, size: 6, color: _C.secondary),
                            SizedBox(width: 4),
                            Text(
                              'Tersedia untuk Mutasi',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF006F67),
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
        ),
      ),
    );
  }
}
