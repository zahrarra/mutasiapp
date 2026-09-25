import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/features/asset/domain/entities/asset.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_category.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_status.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/presentation/models/mutation_tracking_step.dart';
import 'package:mutasiku/features/pemohon/presentation/widgets/mutation_status_stepper.dart';

void main() {
  Mutation createDummyMutation({
    required MutationStatus status,
    bool requiresKadivApproval = false,
    bool isUnregistered = false,
    String? returnReason,
    String? rejectionReason,
    String? kadivRejectionReason,
    DateTime? kadivRejectedAt,
  }) {
    final asset = Asset(
      id: isUnregistered ? '' : 'AST-001',
      assetCode: isUnregistered ? '' : 'AST-001',
      name: isUnregistered ? 'Printer Rusak' : 'Laptop Dell XPS',
      category: const AssetCategory(id: 'cat_1', code: 'ELK', name: 'Elektronik'),
      location: 'Ruang IT',
      pic: 'Ahmad Pemohon',
      status: AssetStatus.inMutation,
      condition: 'Baik',
      acquisitionYear: 2024,
      estimatedValue: 10000000,
    );

    return Mutation(
      id: 'mut-test-1',
      ticketNumber: 'MUT-2026-001',
      asset: asset,
      applicantId: 'usr-1',
      applicantName: 'Ahmad Pemohon',
      currentLocation: 'Ruang IT',
      targetLocation: 'Cabang Solo',
      currentPic: 'Ahmad Pemohon',
      targetPic: 'Budi PIC',
      reason: 'Kebutuhan kerja',
      status: status,
      requiresKadivApproval: requiresKadivApproval,
      createdAt: DateTime(2026, 9, 25),
      returnReason: returnReason,
      rejectionReason: rejectionReason,
      kadivRejectionReason: kadivRejectionReason,
      kadivRejectedAt: kadivRejectedAt,
    );
  }

  Widget createWidget({
    required MutationStatus status,
    Mutation? mutation,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: MutationStatusStepper(
          status: status,
          mutation: mutation,
        ),
      ),
    );
  }

  group('MutationStatusStepper — Flow without Kadiv (5 steps)', () {
    testWidgets('renders exactly 5 steps and no Kadiv step', (tester) async {
      final mutation = createDummyMutation(
        status: MutationStatus.submitted,
        requiresKadivApproval: false,
      );
      await tester.pumpWidget(createWidget(
        status: MutationStatus.submitted,
        mutation: mutation,
      ));

      expect(find.text('Diajukan'), findsOneWidget);
      expect(find.text('Approval Kabag'), findsOneWidget);
      expect(find.text('Update Aset'), findsOneWidget);
      expect(find.text('Konfirmasi'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);

      // Approval Kadiv must NOT appear
      expect(find.text('Approval Kadiv'), findsNothing);
      expect(find.text('Verifikasi Operator'), findsNothing);
    });

    testWidgets('submitted: 0 checkmarks, Diajukan is active/current', (tester) async {
      final mutation = createDummyMutation(
        status: MutationStatus.submitted,
        requiresKadivApproval: false,
      );
      await tester.pumpWidget(createWidget(
        status: MutationStatus.submitted,
        mutation: mutation,
      ));

      // No steps checked yet (Diajukan is waiting for verification)
      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('waitingKabagApproval: 1 checkmark (Diajukan completed)', (tester) async {
      final mutation = createDummyMutation(
        status: MutationStatus.waitingKabagApproval,
        requiresKadivApproval: false,
      );
      await tester.pumpWidget(createWidget(
        status: MutationStatus.waitingKabagApproval,
        mutation: mutation,
      ));

      expect(find.byIcon(Icons.check), findsNWidgets(1));
    });

    testWidgets('approved (without Kadiv): 2 checkmarks (Diajukan & Kabag)', (tester) async {
      final mutation = createDummyMutation(
        status: MutationStatus.approved,
        requiresKadivApproval: false,
      );
      await tester.pumpWidget(createWidget(
        status: MutationStatus.approved,
        mutation: mutation,
      ));

      expect(find.byIcon(Icons.check), findsNWidgets(2));
    });

    testWidgets('pendingConfirmation (without Kadiv): 3 checkmarks (Diajukan, Kabag, Update Aset)', (tester) async {
      final mutation = createDummyMutation(
        status: MutationStatus.pendingConfirmation,
        requiresKadivApproval: false,
      );
      await tester.pumpWidget(createWidget(
        status: MutationStatus.pendingConfirmation,
        mutation: mutation,
      ));

      expect(find.byIcon(Icons.check), findsNWidgets(3));
    });

    testWidgets('completed (without Kadiv): all 5 steps checked', (tester) async {
      final mutation = createDummyMutation(
        status: MutationStatus.completed,
        requiresKadivApproval: false,
      );
      await tester.pumpWidget(createWidget(
        status: MutationStatus.completed,
        mutation: mutation,
      ));

      expect(find.byIcon(Icons.check), findsNWidgets(5));
    });

    testWidgets('returned: Diajukan shows alert icon and 0 checkmarks', (tester) async {
      final mutation = createDummyMutation(
        status: MutationStatus.returned,
        returnReason: 'Harap perbaiki surat pengantar',
        requiresKadivApproval: false,
      );
      await tester.pumpWidget(createWidget(
        status: MutationStatus.returned,
        mutation: mutation,
      ));

      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('rejected by Kabag: 1 checkmark (Diajukan) and alert on Kabag', (tester) async {
      final mutation = createDummyMutation(
        status: MutationStatus.rejected,
        rejectionReason: 'Tidak memenuhi urgensi',
        requiresKadivApproval: false,
      );
      await tester.pumpWidget(createWidget(
        status: MutationStatus.rejected,
        mutation: mutation,
      ));

      expect(find.byIcon(Icons.check), findsNWidgets(1));
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });

  group('MutationStatusStepper — Flow with Kadiv (6 steps)', () {
    testWidgets('renders all 6 steps when requiresKadivApproval is true', (tester) async {
      final mutation = createDummyMutation(
        status: MutationStatus.submitted,
        requiresKadivApproval: true,
      );
      await tester.pumpWidget(createWidget(
        status: MutationStatus.submitted,
        mutation: mutation,
      ));

      expect(find.text('Diajukan'), findsOneWidget);
      expect(find.text('Approval Kabag'), findsOneWidget);
      expect(find.text('Approval Kadiv'), findsOneWidget);
      expect(find.text('Update Aset'), findsOneWidget);
      expect(find.text('Konfirmasi'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);
    });

    testWidgets('waitingKadivApproval: 2 checkmarks (Diajukan, Kabag) and Kadiv current', (tester) async {
      final mutation = createDummyMutation(
        status: MutationStatus.waitingKadivApproval,
        requiresKadivApproval: true,
      );
      await tester.pumpWidget(createWidget(
        status: MutationStatus.waitingKadivApproval,
        mutation: mutation,
      ));

      expect(find.byIcon(Icons.check), findsNWidgets(2));
    });

    testWidgets('approved with Kadiv: 3 checkmarks (Diajukan, Kabag, Kadiv)', (tester) async {
      final mutation = createDummyMutation(
        status: MutationStatus.approved,
        requiresKadivApproval: true,
      );
      await tester.pumpWidget(createWidget(
        status: MutationStatus.approved,
        mutation: mutation,
      ));

      expect(find.byIcon(Icons.check), findsNWidgets(3));
    });

    testWidgets('pendingConfirmation with Kadiv: 4 checkmarks', (tester) async {
      final mutation = createDummyMutation(
        status: MutationStatus.pendingConfirmation,
        requiresKadivApproval: true,
      );
      await tester.pumpWidget(createWidget(
        status: MutationStatus.pendingConfirmation,
        mutation: mutation,
      ));

      expect(find.byIcon(Icons.check), findsNWidgets(4));
    });

    testWidgets('completed with Kadiv: all 6 checkmarks', (tester) async {
      final mutation = createDummyMutation(
        status: MutationStatus.completed,
        requiresKadivApproval: true,
      );
      await tester.pumpWidget(createWidget(
        status: MutationStatus.completed,
        mutation: mutation,
      ));

      expect(find.byIcon(Icons.check), findsNWidgets(6));
    });

    testWidgets('rejected by Kadiv: 2 checkmarks (Diajukan, Kabag) and alert on Kadiv', (tester) async {
      final mutation = createDummyMutation(
        status: MutationStatus.rejected,
        kadivRejectionReason: 'Anggaran divisi tidak mencukupi',
        kadivRejectedAt: DateTime(2026, 9, 25),
        requiresKadivApproval: true,
      );
      await tester.pumpWidget(createWidget(
        status: MutationStatus.rejected,
        mutation: mutation,
      ));

      expect(find.byIcon(Icons.check), findsNWidgets(2));
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });

  group('MutationTrackingHelper — 13 Mandatory Scenarios Unit Test', () {
    test('1. New submission', () {
      final steps = MutationTrackingHelper.buildTrackingSteps(
        status: MutationStatus.submitted,
        requiresKadivApproval: false,
      );
      expect(steps.length, 5);
      expect(steps[0].state, TrackingStepState.current);
      expect(steps[1].state, TrackingStepState.upcoming);
      expect(MutationTrackingHelper.getActiveStageNumber(steps), 1);
    });

    test('2. Waiting Kabag', () {
      final steps = MutationTrackingHelper.buildTrackingSteps(
        status: MutationStatus.waitingKabagApproval,
        requiresKadivApproval: false,
      );
      expect(steps[0].state, TrackingStepState.completed);
      expect(steps[1].state, TrackingStepState.current);
      expect(steps[2].state, TrackingStepState.upcoming);
      expect(MutationTrackingHelper.getActiveStageNumber(steps), 2);
    });

    test('3. Kabag approved without Kadiv', () {
      final steps = MutationTrackingHelper.buildTrackingSteps(
        status: MutationStatus.approved,
        requiresKadivApproval: false,
      );
      expect(steps.length, 5);
      expect(steps[0].state, TrackingStepState.completed);
      expect(steps[1].state, TrackingStepState.completed);
      expect(steps[2].title, 'Disetujui — Menunggu Update Aset');
      expect(steps[2].state, TrackingStepState.current);
      expect(MutationTrackingHelper.getActiveStageNumber(steps), 3);
    });

    test('4. Waiting Kadiv', () {
      final steps = MutationTrackingHelper.buildTrackingSteps(
        status: MutationStatus.waitingKadivApproval,
        requiresKadivApproval: true,
      );
      expect(steps.length, 6);
      expect(steps[0].state, TrackingStepState.completed);
      expect(steps[1].state, TrackingStepState.completed);
      expect(steps[2].title, 'Approval Kepala Divisi (Kadiv)');
      expect(steps[2].state, TrackingStepState.current);
      expect(MutationTrackingHelper.getActiveStageNumber(steps), 3);
    });

    test('5. Kadiv approved', () {
      final steps = MutationTrackingHelper.buildTrackingSteps(
        status: MutationStatus.approved,
        requiresKadivApproval: true,
      );
      expect(steps.length, 6);
      expect(steps[0].state, TrackingStepState.completed);
      expect(steps[1].state, TrackingStepState.completed);
      expect(steps[2].state, TrackingStepState.completed);
      expect(steps[3].title, 'Disetujui — Menunggu Update Aset');
      expect(steps[3].state, TrackingStepState.current);
      expect(MutationTrackingHelper.getActiveStageNumber(steps), 4);
    });

    test('6. Waiting confirmation (pendingConfirmation)', () {
      final steps = MutationTrackingHelper.buildTrackingSteps(
        status: MutationStatus.pendingConfirmation,
        requiresKadivApproval: false,
      );
      expect(steps[0].state, TrackingStepState.completed);
      expect(steps[1].state, TrackingStepState.completed);
      expect(steps[2].state, TrackingStepState.completed); // Update Aset completed!
      expect(steps[3].state, TrackingStepState.current); // Waiting confirmation
      expect(steps[3].subtitle.contains('Staff Aset telah menyelesaikan update aset'), isTrue);
      expect(steps[4].state, TrackingStepState.upcoming);
    });

    test('7. Completed', () {
      final steps = MutationTrackingHelper.buildTrackingSteps(
        status: MutationStatus.completed,
        requiresKadivApproval: false,
      );
      expect(steps.every((s) => s.state == TrackingStepState.completed), isTrue);
      expect(steps.last.title, 'Selesai');
      expect(MutationTrackingHelper.getActiveStageNumber(steps), 5);
    });

    test('8. Returned', () {
      final steps = MutationTrackingHelper.buildTrackingSteps(
        status: MutationStatus.returned,
        returnReason: 'Foto fisik aset buram',
        requiresKadivApproval: false,
      );
      expect(steps[0].state, TrackingStepState.alert);
      expect(steps[0].subtitle.contains('Foto fisik aset buram'), isTrue);
      expect(steps[1].state, TrackingStepState.upcoming);
    });

    test('9. Rejected (Kabag vs Kadiv)', () {
      // Kabag rejection
      final kabagReject = MutationTrackingHelper.buildTrackingSteps(
        status: MutationStatus.rejected,
        rejectionReason: 'Tidak ada anggaran relokasi',
        requiresKadivApproval: false,
      );
      expect(kabagReject[0].state, TrackingStepState.completed);
      expect(kabagReject[1].state, TrackingStepState.alert);
      expect(kabagReject[1].subtitle.contains('Tidak ada anggaran relokasi'), isTrue);

      // Kadiv rejection
      final kadivReject = MutationTrackingHelper.buildTrackingSteps(
        status: MutationStatus.rejected,
        kadivRejectionReason: 'Ditolak Kadiv',
        kadivRejectedAt: DateTime(2026, 9, 25),
        requiresKadivApproval: true,
      );
      expect(kadivReject[0].state, TrackingStepState.completed);
      expect(kadivReject[1].state, TrackingStepState.completed);
      expect(kadivReject[2].state, TrackingStepState.alert);
      expect(kadivReject[2].subtitle.contains('Ditolak Kadiv'), isTrue);
    });

    test('10 & 11. Registered vs Unregistered Asset works seamlessly', () {
      final registered = createDummyMutation(
        status: MutationStatus.submitted,
        isUnregistered: false,
      );
      final unreg = createDummyMutation(
        status: MutationStatus.submitted,
        isUnregistered: true,
      );

      final regSteps = MutationTrackingHelper.getStepsForMutation(registered.status, mutation: registered);
      final unregSteps = MutationTrackingHelper.getStepsForMutation(unreg.status, mutation: unreg);

      expect(regSteps.length, 5);
      expect(unregSteps.length, 5);
      expect(regSteps[0].state, TrackingStepState.current);
      expect(unregSteps[0].state, TrackingStepState.current);
    });

    test('12 & 13. requiresKadivApproval true vs false determines steps count', () {
      final withKadiv = MutationTrackingHelper.buildTrackingSteps(
        status: MutationStatus.submitted,
        requiresKadivApproval: true,
      );
      final withoutKadiv = MutationTrackingHelper.buildTrackingSteps(
        status: MutationStatus.submitted,
        requiresKadivApproval: false,
      );

      expect(withKadiv.length, 6);
      expect(withoutKadiv.length, 5);
      expect(withKadiv.any((s) => s.key == 'waitingKadivApproval'), isTrue);
      expect(withoutKadiv.any((s) => s.key == 'waitingKadivApproval'), isFalse);
    });
  });
}
