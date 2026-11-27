// lib/core/widgets/responsive_scaffold.dart
//
// Pembungkus responsif MutasiKu: layar HP tampil penuh seperti biasa,
// layar lebar (tablet/desktop/web) konten dibatasi lebar maksimum dan
// dipusatkan, supaya tidak melebar sampai ke tepi layar laptop.
//
// Prinsip:
// - TIDAK mengubah logika bisnis, alur 6 tahap mutasi, atau API.
// - TIDAK menambah padding di layar HP (tampilan HP tetap sama).
// - Satu titik perubahan: bungkus `body` Scaffold dengan [ResponsiveCenter].
//
// Yang sudah responsif sebelumnya dan TIDAK perlu dibungkus:
// - LoginScreen (breakpoint 960px, dua kolom di desktop).
// - ChangePasswordScreen (Center + maxWidth 480).
// - AdminUsersScreen (Center + maxWidth 1440).
// - CustomFloatingNavBar.scaffoldBottomBar (lebar dibatasi 440/520/640).

import 'package:flutter/material.dart';

/// Breakpoint dan lebar maksimum konten MutasiKu.
///
/// Dipakai konsisten dengan pola yang sudah ada di repo:
/// - LoginScreen memakai breakpoint 960px untuk layout dua kolom.
/// - CustomFloatingNavBar memakai 768px dan 1024px untuk lebar bar.
abstract final class ResponsiveBreakpoints {
  /// Mulai dianggap tablet / layar lebar kecil.
  static const double tablet = 600.0;

  /// Mulai dianggap desktop / layar lebar.
  static const double desktop = 1024.0;

  /// Lebar maksimum konten biasa (daftar, detail, form, dashboard).
  /// 1200px supaya di layar desktop tampil selebar desktop, bukan
  /// sekecil layar HP. (Sebelumnya 720px — terlalu sempit di desktop.)
  static const double defaultMaxWidth = 1200.0;

  /// Lebar maksimum konten berbentuk tabel lebar (mis. audit log).
  static const double wideMaxWidth = 1400.0;
}

/// Memusatkan [child] dan membatasi lebarnya di layar lebar.
///
/// - Layar sempit (lebar < [maxWidth]): [child] tampil selebar layar,
///   persis seperti tanpa pembungkus (tidak ada padding tambahan,
///   jadi tampilan HP tidak berubah).
/// - Layar lebar: [child] dibatasi [maxWidth] dan dipusatkan.
///
/// Dipakai untuk membungkus `body` Scaffold yang berisi:
/// Column (termasuk yang punya Expanded), SingleChildScrollView,
/// CustomScrollView, RefreshIndicator, dan hasil `AsyncValue.when`.
///
/// Tinggi [child] dibuat sama dengan tinggi viewport (bukan dibiarkan
/// longgar): kalau tinggi dibiarkan longgar, layar yang bisa di-scroll
/// akan mengembang setinggi seluruh isinya, bagian bawahnya terpotong
/// dan tidak bisa di-scroll. Dengan tinggi penuh, scroll dan Expanded
/// di dalam [child] bekerja seperti semula.
class ResponsiveCenter extends StatelessWidget {
  /// Konten yang dibatasi lebarnya (biasanya `body` sebuah Scaffold).
  final Widget child;

  /// Lebar maksimum konten di layar lebar.
  /// Default [ResponsiveBreakpoints.defaultMaxWidth] (720).
  /// Pakai [ResponsiveBreakpoints.wideMaxWidth] (960) untuk tabel lebar.
  final double maxWidth;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveBreakpoints.defaultMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder membaca ukuran body Scaffold (lebar + tinggi viewport).
    // Lebar dibatasi maxWidth dan dipusatkan; tinggi dibuat penuh supaya
    // layar yang bisa di-scroll tetap bisa di-scroll (jangan pakai Align:
    // Align memberi batas tinggi yang longgar, sehingga scroll view
    // mengembang setinggi isinya dan bagian bawah terpotong).
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth.isFinite
            ? (constraints.maxWidth > maxWidth ? maxWidth : constraints.maxWidth)
            : maxWidth;
        final double? height =
            constraints.maxHeight.isFinite ? constraints.maxHeight : null;
        return Center(
          child: SizedBox(width: width, height: height, child: child),
        );
      },
    );
  }
}

/// Scaffold yang bodinya sudah responsif (dibatasi + dipusatkan).
///
/// Pemakaian untuk layar baru:
/// ```dart
/// ResponsiveScaffold(
///   backgroundColor: _C.bg,
///   body: Column(children: [...]),
///   bottomNavigationBar: CustomFloatingNavBar.scaffoldBottomBar(...),
/// )
/// ```
/// Untuk layar yang sudah ada, lebih minim mengubah dengan membungkus
/// `body`-nya saja: `body: ResponsiveCenter(child: ...)`.
class ResponsiveScaffold extends StatelessWidget {
  /// Isi layar (akan dibatasi lebarnya dan dipusatkan).
  final Widget body;

  /// Lebar maksimum konten di layar lebar.
  final double maxWidth;

  final Color? backgroundColor;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool extendBody;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.maxWidth = ResponsiveBreakpoints.defaultMaxWidth,
    this.backgroundColor,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.extendBody = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: ResponsiveCenter(maxWidth: maxWidth, child: body),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      extendBody: extendBody,
    );
  }
}

/// Helper cepat untuk membaca ukuran layar dari [BuildContext].
///
/// Contoh: `if (context.isWideScreen) ...` untuk menyesuaikan
/// jumlah kolom atau ukuran judul di layar lebar.
extension ResponsiveContext on BuildContext {
  /// Lebar layar saat ini (logical pixels).
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// true kalau lebar layar >= 1024 (desktop / laptop).
  bool get isWideScreen => screenWidth >= ResponsiveBreakpoints.desktop;

  /// true kalau lebar layar 600–1023 (tablet / layar lebar kecil).
  bool get isTabletScreen =>
      screenWidth >= ResponsiveBreakpoints.tablet &&
      screenWidth < ResponsiveBreakpoints.desktop;

  /// true kalau lebar layar < 600 (ponsel).
  bool get isPhoneScreen => screenWidth < ResponsiveBreakpoints.tablet;
}
