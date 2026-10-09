import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mutasiku/features/operator/presentation/widgets/operator_verification_success_dialog.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget buildTestApp({
    required Size size,
    VoidCallback? onNextTicket,
    VoidCallback? onOpenHistory,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('btn_trigger_dialog'),
                onPressed: () {
                  showOperatorVerificationSuccessDialog(
                    context,
                    onNextTicket: onNextTicket ?? () {},
                    onOpenHistory: onOpenHistory ?? () {},
                  );
                },
                child: const Text('Buka Dialog'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'renders OperatorVerificationSuccessDialog with Montserrat and compact styling',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool nextTicketTapped = false;
      bool openHistoryTapped = false;

      await tester.pumpWidget(
        buildTestApp(
          size: const Size(375, 812),
          onNextTicket: () => nextTicketTapped = true,
          onOpenHistory: () => openHistoryTapped = true,
        ),
      );
      await tester.pumpAndSettle();

      // Trigger dialog
      await tester.tap(find.byKey(const Key('btn_trigger_dialog')));
      await tester.pumpAndSettle();

      // Verify Title & Subtitle
      expect(find.text('Verifikasi Berhasil'), findsOneWidget);
      expect(
        find.text(
          'Tiket telah berhasil diverifikasi dan diteruskan ke pimpinan.',
        ),
        findsOneWidget,
      );

      // Verify Action buttons
      expect(find.byKey(const Key('btn_operator_next_ticket')), findsOneWidget);
      expect(
        find.byKey(const Key('btn_operator_open_history')),
        findsOneWidget,
      );

      // Verify no overflow
      expect(tester.takeException(), isNull);

      // Tap Periksa Tiket Berikutnya
      await tester.tap(find.byKey(const Key('btn_operator_next_ticket')));
      await tester.pumpAndSettle();
      expect(nextTicketTapped, isTrue);

      // Re-open dialog and tap Buka Riwayat Verifikasi
      await tester.tap(find.byKey(const Key('btn_trigger_dialog')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_operator_open_history')));
      await tester.pumpAndSettle();
      expect(openHistoryTapped, isTrue);
    },
  );

  testWidgets(
    'renders seamlessly on ultra-compact mobile (320x568) without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestApp(size: const Size(320, 568)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_trigger_dialog')));
      await tester.pumpAndSettle();

      expect(find.text('Verifikasi Berhasil'), findsOneWidget);
      expect(find.byKey(const Key('btn_operator_next_ticket')), findsOneWidget);
      expect(
        find.byKey(const Key('btn_operator_open_history')),
        findsOneWidget,
      );

      // Ensure zero overflow on ultra-compact screens
      expect(tester.takeException(), isNull);
    },
  );
}
