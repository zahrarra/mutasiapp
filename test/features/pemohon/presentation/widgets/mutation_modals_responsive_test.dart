import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mutasiku/features/mutation/presentation/widgets/mutation_submit_success_dialog.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('MutationSubmitSuccessDialog (Stitch HTML Terbaru)', () {
    final viewports = [
      const Size(320, 640), // Small Mobile
      const Size(360, 780), // Standard Mobile
      const Size(390, 844), // iPhone 12/13/14
      const Size(768, 1024), // Tablet
      const Size(1280, 800), // Desktop
    ];

    for (final size in viewports) {
      testWidgets(
        'Renders properly without overflow on ${size.width}x${size.height}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(
                home: Scaffold(
                  body: MutationSubmitSuccessDialog(
                    ticketNumber: 'TI-2026-00126',
                    mutationId: 'mut_test_123',
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Pengajuan Berhasil Dikirim'), findsOneWidget);
          expect(
            find.text(
              'Pengajuan perpindahan aset Anda telah berhasil dicatat dan siap diproses.',
            ),
            findsOneWidget,
          );
          expect(find.text('NOMOR TIKET'), findsOneWidget);
          expect(find.text('TI-2026-00126'), findsOneWidget);
          expect(find.text('Salin'), findsOneWidget);
          expect(find.text('Lihat Status Tracking'), findsOneWidget);
          expect(find.text('Kembali ke Beranda'), findsOneWidget);
        },
      );
    }
  });
}
