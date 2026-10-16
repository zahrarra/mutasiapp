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
    bool requiresKadivApproval = true,
    bool isUnregistered = false,
    String? returnReason,
    String? assetReturnReason,
    String? rejectionReason,
    String? kadivRejectionReason,
    DateTime? kadivRejectedAt,
  }) {
    final asset = Asset(
      id: isUnregistered ? '' : 'AST-001',
      assetCode: isUnregistered ? '' : 'AST-001',
      name: isUnregistered ? 'Printer Rusak' : 'Laptop Dell XPS',
      category: const AssetCategory(
        id: 'cat_1',
        code: 'ELK',
        name: 'Elektronik',
      ),
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
      assetReturnReason: assetReturnReason,
      rejectionReason: rejectionReason,
      kadivRejectionReason: kadivRejectionReason,
      kadivRejectedAt: kadivRejectedAt,
    );
  }

  Widget createWidget({required MutationStatus status, Mutation? mutation}) {
    return MaterialApp(
      home: Scaffold(
        body: MutationStatusStepper(status: status, mutation: mutation),
      ),
    );
  }

  group('MutationStatusStepper — PRD V1.1 Workflow (6 steps)', () {
    testWidgets('renders all 6 workflow steps', (tester) async {
      final mutation = createDummyMutation(status: MutationStatus.submitted);
      await tester.pumpWidget(
        createWidget(status: MutationStatus.submitted, mutation: mutation),
      );

      expect(find.text('Pengajuan'), findsOneWidget);
      expect(find.text('Pemeriksaan Operator'), findsOneWidget);
      expect(find.text('Verifikasi Aset'), findsOneWidget);
      expect(find.text('Approval Final'), findsOneWidget);
      expect(find.text('Konfirmasi'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);
    });

    testWidgets(
      'submitted: step 1 completed, step 2 current (waiting operator)',
      (tester) async {
        final mutation = createDummyMutation(status: MutationStatus.submitted);
        await tester.pumpWidget(
          createWidget(status: MutationStatus.submitted, mutation: mutation),
        );

        final steps = MutationTrackingHelper.getStepsForMutation(
          MutationStatus.submitted,
          mutation: mutation,
        );
        expect(steps.length, 6);
        expect(steps[0].state, TrackingStepState.completed);
        expect(steps[1].state, TrackingStepState.current);
        expect(steps[2].state, TrackingStepState.upcoming);
      },
    );

    testWidgets(
      'waitingAssetVerification: step 1 and 2 completed, step 3 current',
      (tester) async {
        final mutation = createDummyMutation(
          status: MutationStatus.waitingAssetVerification,
        );
        await tester.pumpWidget(
          createWidget(
            status: MutationStatus.waitingAssetVerification,
            mutation: mutation,
          ),
        );

        final steps = MutationTrackingHelper.getStepsForMutation(
          MutationStatus.waitingAssetVerification,
          mutation: mutation,
        );
        expect(steps[0].state, TrackingStepState.completed);
        expect(steps[1].state, TrackingStepState.completed);
        expect(steps[2].state, TrackingStepState.current);
      },
    );

    testWidgets(
      'waitingDivisionHeadApproval: step 1-3 completed, step 4 current',
      (tester) async {
        final mutation = createDummyMutation(
          status: MutationStatus.waitingDivisionHeadApproval,
        );
        await tester.pumpWidget(
          createWidget(
            status: MutationStatus.waitingDivisionHeadApproval,
            mutation: mutation,
          ),
        );

        final steps = MutationTrackingHelper.getStepsForMutation(
          MutationStatus.waitingDivisionHeadApproval,
          mutation: mutation,
        );
        expect(steps[0].state, TrackingStepState.completed);
        expect(steps[1].state, TrackingStepState.completed);
        expect(steps[2].state, TrackingStepState.completed);
        expect(steps[3].state, TrackingStepState.current);
      },
    );

    testWidgets('waitingConfirmation: step 1-4 completed, step 5 current', (
      tester,
    ) async {
      final mutation = createDummyMutation(
        status: MutationStatus.waitingConfirmation,
      );
      await tester.pumpWidget(
        createWidget(
          status: MutationStatus.waitingConfirmation,
          mutation: mutation,
        ),
      );

      final steps = MutationTrackingHelper.getStepsForMutation(
        MutationStatus.waitingConfirmation,
        mutation: mutation,
      );
      expect(steps[0].state, TrackingStepState.completed);
      expect(steps[1].state, TrackingStepState.completed);
      expect(steps[2].state, TrackingStepState.completed);
      expect(steps[3].state, TrackingStepState.completed);
      expect(steps[4].state, TrackingStepState.current);
    });

    testWidgets('completed: all 6 steps completed', (tester) async {
      final mutation = createDummyMutation(status: MutationStatus.completed);
      await tester.pumpWidget(
        createWidget(status: MutationStatus.completed, mutation: mutation),
      );

      final steps = MutationTrackingHelper.getStepsForMutation(
        MutationStatus.completed,
        mutation: mutation,
      );
      expect(
        steps.every((s) => s.state == TrackingStepState.completed),
        isTrue,
      );
    });

    testWidgets('returned by Operator: shows alert on step 2', (tester) async {
      final mutation = createDummyMutation(
        status: MutationStatus.returned,
        returnReason: 'Dokumen SK belum lengkap',
      );
      await tester.pumpWidget(
        createWidget(status: MutationStatus.returned, mutation: mutation),
      );

      final steps = MutationTrackingHelper.getStepsForMutation(
        MutationStatus.returned,
        mutation: mutation,
      );
      expect(steps[1].state, TrackingStepState.alert);
      expect(steps[1].subtitle, contains('Dokumen SK belum lengkap'));
    });

    testWidgets('returned by Bagian Aset: shows alert on step 3', (
      tester,
    ) async {
      final mutation = createDummyMutation(
        status: MutationStatus.returned,
        assetReturnReason: 'Aset tidak berada di lokasi asal',
      );
      await tester.pumpWidget(
        createWidget(status: MutationStatus.returned, mutation: mutation),
      );

      final steps = MutationTrackingHelper.getStepsForMutation(
        MutationStatus.returned,
        mutation: mutation,
      );
      expect(steps[2].state, TrackingStepState.alert);
      expect(steps[2].subtitle, contains('Aset tidak berada di lokasi asal'));
    });

    testWidgets('rejected by Pemimpin Divisi: shows alert on step 4', (
      tester,
    ) async {
      final mutation = createDummyMutation(
        status: MutationStatus.rejected,
        kadivRejectionReason: 'Pengajuan ditolak oleh Pemimpin Divisi',
      );
      await tester.pumpWidget(
        createWidget(status: MutationStatus.rejected, mutation: mutation),
      );

      final steps = MutationTrackingHelper.getStepsForMutation(
        MutationStatus.rejected,
        mutation: mutation,
      );
      expect(steps[3].state, TrackingStepState.alert);
      expect(
        steps[3].subtitle,
        contains('Pengajuan ditolak oleh Pemimpin Divisi'),
      );
    });
  });

  group('MutationTrackingHelper — Unit Tests', () {
    test('getActiveStageNumber returns correct stage number', () {
      final subSteps = MutationTrackingHelper.buildTrackingSteps(
        status: MutationStatus.submitted,
      );
      expect(MutationTrackingHelper.getActiveStageNumber(subSteps), 2);

      final assetSteps = MutationTrackingHelper.buildTrackingSteps(
        status: MutationStatus.waitingAssetVerification,
      );
      expect(MutationTrackingHelper.getActiveStageNumber(assetSteps), 3);

      final divSteps = MutationTrackingHelper.buildTrackingSteps(
        status: MutationStatus.waitingDivisionHeadApproval,
      );
      expect(MutationTrackingHelper.getActiveStageNumber(divSteps), 4);

      final confSteps = MutationTrackingHelper.buildTrackingSteps(
        status: MutationStatus.waitingConfirmation,
      );
      expect(MutationTrackingHelper.getActiveStageNumber(confSteps), 5);

      final compSteps = MutationTrackingHelper.buildTrackingSteps(
        status: MutationStatus.completed,
      );
      expect(MutationTrackingHelper.getActiveStageNumber(compSteps), 6);
    });

    test('Registered vs Unregistered Asset works seamlessly', () {
      final registered = createDummyMutation(
        status: MutationStatus.submitted,
        isUnregistered: false,
      );
      final unreg = createDummyMutation(
        status: MutationStatus.submitted,
        isUnregistered: true,
      );

      final regSteps = MutationTrackingHelper.getStepsForMutation(
        registered.status,
        mutation: registered,
      );
      final unregSteps = MutationTrackingHelper.getStepsForMutation(
        unreg.status,
        mutation: unreg,
      );

      expect(regSteps.length, 6);
      expect(unregSteps.length, 6);
      expect(regSteps[0].state, TrackingStepState.completed);
      expect(unregSteps[0].state, TrackingStepState.completed);
      expect(regSteps[1].state, TrackingStepState.current);
      expect(unregSteps[1].state, TrackingStepState.current);
    });
  });
}
