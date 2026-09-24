import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/pemohon/presentation/widgets/mutation_status_stepper.dart';

void main() {
  Widget createWidget(MutationStatus status) {
    return MaterialApp(
      home: Scaffold(
        body: MutationStatusStepper(status: status),
      ),
    );
  }

  group('MutationStatusStepper Tests', () {
    testWidgets('renders all 6 tracking step labels', (tester) async {
      await tester.pumpWidget(createWidget(MutationStatus.submitted));

      expect(find.text('Diajukan'), findsOneWidget);
      expect(find.text('Verifikasi Operator'), findsOneWidget);
      expect(find.text('Approval Kabag Aset'), findsOneWidget);
      expect(find.text('Approval Kadiv'), findsOneWidget);
      expect(find.text('Update Staf Aset'), findsOneWidget);
      expect(find.text('Selesai/Konfirmasi'), findsOneWidget);
    });

    testWidgets('when status is submitted, Diajukan is checked (1 checkmark)',
        (tester) async {
      await tester.pumpWidget(createWidget(MutationStatus.submitted));

      // 1 step completed (Diajukan)
      expect(find.byIcon(Icons.check), findsNWidgets(1));
    });

    testWidgets(
        'when status is waitingKabagApproval, Diajukan and Verifikasi are checked (2 checkmarks)',
        (tester) async {
      await tester.pumpWidget(createWidget(MutationStatus.waitingKabagApproval));

      // 2 steps completed: Diajukan, Verifikasi Operator
      expect(find.byIcon(Icons.check), findsNWidgets(2));
    });

    testWidgets(
        'when status is waitingKadivApproval, 3 steps are checked (3 checkmarks)',
        (tester) async {
      await tester.pumpWidget(createWidget(MutationStatus.waitingKadivApproval));

      // 3 steps completed: Diajukan, Verifikasi, Approval Kabag
      expect(find.byIcon(Icons.check), findsNWidgets(3));
    });

    testWidgets(
        'when status is approved, 4 steps are checked (4 checkmarks)',
        (tester) async {
      await tester.pumpWidget(createWidget(MutationStatus.approved));

      // 4 steps completed: Diajukan, Verifikasi, Approval Kabag, Approval Kadiv
      expect(find.byIcon(Icons.check), findsNWidgets(4));
    });

    testWidgets(
        'when status is pendingConfirmation, 5 steps are checked (5 checkmarks)',
        (tester) async {
      await tester.pumpWidget(createWidget(MutationStatus.pendingConfirmation));

      // 5 steps completed: Diajukan, Verifikasi, Approval Kabag, Approval Kadiv, Update Staf
      expect(find.byIcon(Icons.check), findsNWidgets(5));
    });

    testWidgets(
        'when status is completed, all 6 steps are checked (6 checkmarks)',
        (tester) async {
      await tester.pumpWidget(createWidget(MutationStatus.completed));

      // All 6 steps completed
      expect(find.byIcon(Icons.check), findsNWidgets(6));
    });
  });
}
