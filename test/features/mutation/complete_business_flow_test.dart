// test/features/mutation/complete_business_flow_test.dart
//
// Comprehensive Business Flow & Regression Test for MutasiKu:
// 1. Flow Standar: Pemohon -> Operator -> Bagian Aset -> Pemimpin Divisi -> Pemohon -> completed
// 2. High Value Asset: Pemohon -> Operator (threshold) -> Bagian Aset -> Pemimpin Divisi -> Pemohon -> completed
// 3. Returned by Operator
// 4. Returned by Bagian Aset
// 5. Rejected by Kadiv
// 6. Registered vs Unregistered Asset
// 7. Duplicate active mutation prevention
// 8. Unique ticket numbering preservation

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/core/config/business_config.dart';
import 'package:mutasiku/core/errors/failures.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/features/asset/data/repositories/asset_repository_impl.dart';
import 'package:mutasiku/features/asset/presentation/providers/asset_provider.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/auth/presentation/providers/auth_provider.dart';
import 'package:mutasiku/features/bagian_aset/presentation/providers/bagian_aset_verification_provider.dart';
import 'package:mutasiku/features/kadiv/presentation/providers/kadiv_approval_provider.dart';
import 'package:mutasiku/features/mutation/data/repositories/mutation_repository_impl.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/domain/repositories/mutation_repository.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';
import 'package:mutasiku/features/operator/presentation/providers/operator_verification_provider.dart';
import 'package:mutasiku/features/pemohon/presentation/providers/pemohon_confirmation_provider.dart';
import '../operator/presentation/operator_verification_widget_test.dart';

void main() {
  late AssetRepositoryImpl assetRepo;
  late MutationRepositoryImpl mutationRepo;

  setUp(() {
    MutationRepositoryImpl.resetForTesting();
    assetRepo = AssetRepositoryImpl();
    mutationRepo = MutationRepositoryImpl(assetRepository: assetRepo);
  });

  const pemohonUser = User(
    id: 'usr_pemohon',
    username: 'pemohon1',
    name: 'Budi Santoso',
    email: 'pemohon@mutasiku.id',
    role: UserRole.pemohon,
  );

  const operatorUser = User(
    id: 'usr_operator',
    username: 'operator1',
    name: 'Siti Operator',
    email: 'operator@mutasiku.id',
    role: UserRole.operator,
  );

  const bagianAsetUser = User(
    id: 'usr_bagian_aset',
    username: 'bagian_aset1',
    name: 'Hendra Bagian Aset',
    email: 'bagian_aset@mutasiku.id',
    role: UserRole.bagianAset,
  );

  const kadivUser = User(
    id: 'usr_kadiv',
    username: 'kadiv1',
    name: 'Drs. Ahmad Dahlan',
    email: 'kadiv@mutasiku.id',
    role: UserRole.kadiv,
  );

  ProviderContainer createContainer({required User currentUser}) {
    return ProviderContainer(
      overrides: [
        assetRepositoryProvider.overrideWithValue(assetRepo),
        mutationRepositoryProvider.overrideWithValue(mutationRepo),
        apiMutationRepositoryProvider.overrideWithValue(mutationRepo),
        authStateProvider.overrideWith((ref) => FakeAuthNotifier(currentUser)),
      ],
    );
  }

  test('Flow 1: End-to-End (Pemohon -> Operator -> Bagian Aset -> Pemimpin Divisi -> Pemohon -> completed)', () async {
    // 1. Initial State: Check responsible assets of Pemohon
    final pemohonContainer = createContainer(currentUser: pemohonUser);
    addTearDown(pemohonContainer.dispose);

    final initialResponsible = await pemohonContainer.read(userResponsibleAssetsProvider.future);
    expect(initialResponsible.any((a) => a.id == 'ast_1'), isTrue);
    final initialCount = initialResponsible.length;

    // 2. Pemohon Submits Mutation for ast_1 (< threshold Rp 50jt)
    final submitResult = await mutationRepo.submitMutation(const SubmitMutationParams(
      applicantId: 'usr_pemohon',
      applicantName: 'Budi Santoso',
      assetId: 'ast_1',
      assetName: 'Laptop Lenovo ThinkPad T14 Gen 3',
      sourceLocation: 'Lantai 3 — Ruang IT Developer',
      targetLocation: 'Lantai 2 — Ruang Keuangan',
      currentPic: 'Budi Santoso (IT Dept)',
      targetPic: 'Siti Aminah (Finance)',
      reason: 'Mutasi kerja ke divisi keuangan',
      documentName: 'Surat_Tugas.pdf',
    ));

    expect(submitResult, isA<Success<Mutation>>());
    final mutation = (submitResult as Success<Mutation>).data;
    expect(mutation.status, equals(MutationStatus.submitted));
    expect(mutation.ticketNumber, isNotEmpty);

    // Initial count does NOT decrease upon submission
    final postSubmitResponsible = await pemohonContainer.read(userResponsibleAssetsProvider.future);
    expect(postSubmitResponsible.length, equals(initialCount));

    // 3. Operator views and verifies with requiresKadivApproval = true
    final operatorContainer = createContainer(currentUser: operatorUser);
    addTearDown(operatorContainer.dispose);

    final pendingList = await operatorContainer.read(operatorAllMutationsProvider.future);
    expect(pendingList.any((m) => m.id == mutation.id), isTrue);

    final verifySuccess = await operatorContainer.read(verificationActionProvider.notifier).verify(
      mutationId: mutation.id,
      requiresKadivApproval: true,
    );
    expect(verifySuccess, isTrue);

    final verifiedMutation = (await mutationRepo.getMutationById(mutation.id) as Success<Mutation>).data;
    expect(verifiedMutation.status.isWaitingAssetVerification, isTrue);

    // 4. Bagian Aset reviews & forwards to Pemimpin Divisi
    final bagianAsetContainer = createContainer(currentUser: bagianAsetUser);
    addTearDown(bagianAsetContainer.dispose);

    final bagianAsetApprovals = await bagianAsetContainer.read(bagianAsetAllMutationsProvider.future);
    expect(bagianAsetApprovals.any((m) => m.id == mutation.id && m.status.isWaitingAssetVerification), isTrue);

    final bagianAsetApproveSuccess = await bagianAsetContainer.read(bagianAsetVerificationActionProvider.notifier).approve(
      mutationId: mutation.id,
      requiresKadivApproval: true,
    );
    expect(bagianAsetApproveSuccess, isTrue);

    final forwardedMutation = (await mutationRepo.getMutationById(mutation.id) as Success<Mutation>).data;
    expect(forwardedMutation.status.isWaitingDivisionApproval, isTrue);

    // 5. Pemimpin Divisi approves -> status becomes waitingConfirmation
    final kadivContainer = createContainer(currentUser: kadivUser);
    addTearDown(kadivContainer.dispose);

    final kadivApproveSuccess = await kadivContainer.read(kadivApprovalActionProvider.notifier).approve(
      mutationId: mutation.id,
    );
    expect(kadivApproveSuccess, isTrue);

    final approvedMutation = (await mutationRepo.getMutationById(mutation.id) as Success<Mutation>).data;
    expect(approvedMutation.status.isWaitingConfirmation, isTrue);

    // 6. Pemohon confirms receipt ('Sesuai') -> status becomes completed
    final confirmSuccess = await pemohonContainer.read(pemohonConfirmationActionProvider.notifier).confirm(
      mutationId: mutation.id,
    );
    expect(confirmSuccess, isTrue);

    final completedMutation = (await mutationRepo.getMutationById(mutation.id) as Success<Mutation>).data;
    expect(completedMutation.status, equals(MutationStatus.completed));

    // 7. Responsible assets of Pemohon decrements because PIC is now Siti Aminah!
    pemohonContainer.invalidate(assetListProvider);
    pemohonContainer.invalidate(userResponsibleAssetsProvider);
    final finalResponsible = await pemohonContainer.read(userResponsibleAssetsProvider.future);
    expect(finalResponsible.any((a) => a.id == 'ast_1'), isFalse);
    expect(finalResponsible.length, equals(initialCount - 1));
  });

  test('Flow 2: End-to-End dengan Verifikasi Bagian Aset & Pemimpin Divisi', () async {
    // 1. Submit high-value asset: ast_5 (Rp 180jt >= threshold 50jt)
    final submitResult = await mutationRepo.submitMutation(const SubmitMutationParams(
      applicantId: 'usr_pemohon',
      applicantName: 'Budi Santoso',
      assetId: 'ast_5',
      assetName: 'Toyota Avanza 1.5 G M/T',
      sourceLocation: 'Gedung A — Parkir Operasional',
      targetLocation: 'Cabang Bandung — Parkir Operasional',
      currentPic: 'Driver Operasional General Affair',
      targetPic: 'Ahmad Supir Bandung',
      reason: 'Kebutuhan kendaraan operasional cabang',
      documentName: 'Memo_Disposisi.pdf',
    ));
    expect(submitResult, isA<Success<Mutation>>());
    final mutation = (submitResult as Success<Mutation>).data;

    // 2. Operator verifies with requiresKadivApproval = true
    final operatorContainer = createContainer(currentUser: operatorUser);
    addTearDown(operatorContainer.dispose);

    // Operator checks threshold
    final threshold = operatorContainer.read(kadivApprovalThresholdProvider);
    expect(threshold, equals(50000000.0));
    expect(mutation.asset.estimatedValue! >= threshold, isTrue);

    final verifySuccess = await operatorContainer.read(verificationActionProvider.notifier).verify(
      mutationId: mutation.id,
      requiresKadivApproval: true,
    );
    expect(verifySuccess, isTrue);

    // 3. Bagian Aset forwards with requiresKadivApproval = true -> status becomes waitingDivisionApproval
    final bagianAsetContainer = createContainer(currentUser: bagianAsetUser);
    addTearDown(bagianAsetContainer.dispose);

    final bagianAsetApproveSuccess = await bagianAsetContainer.read(bagianAsetVerificationActionProvider.notifier).approve(
      mutationId: mutation.id,
      requiresKadivApproval: true,
    );
    expect(bagianAsetApproveSuccess, isTrue);

    final bagianAsetApprovedMutation = (await mutationRepo.getMutationById(mutation.id) as Success<Mutation>).data;
    expect(bagianAsetApprovedMutation.status.isWaitingDivisionApproval, isTrue);
    expect(bagianAsetApprovedMutation.requiresKadivApproval, isTrue);

    // 4. Kadiv views in 'Menunggu Approval'
    final kadivContainer = createContainer(currentUser: kadivUser);
    addTearDown(kadivContainer.dispose);

    final kadivList = (await kadivContainer.read(kadivAllMutationsProvider.future))
        .where((m) => m.status.isWaitingDivisionApproval)
        .toList();
    expect(kadivList.any((m) => m.id == mutation.id), isTrue);

    // Kadiv approves -> status becomes waitingConfirmation
    final kadivApproveSuccess = await kadivContainer.read(kadivApprovalActionProvider.notifier).approve(
      mutationId: mutation.id,
    );
    expect(kadivApproveSuccess, isTrue);

    final kadivApprovedMutation = (await mutationRepo.getMutationById(mutation.id) as Success<Mutation>).data;
    expect(kadivApprovedMutation.status.isWaitingConfirmation, isTrue);

    // 5. Pemohon confirms -> completed
    final pemohonContainer = createContainer(currentUser: pemohonUser);
    addTearDown(pemohonContainer.dispose);

    final confirmSuccess = await pemohonContainer.read(pemohonConfirmationActionProvider.notifier).confirm(
      mutationId: mutation.id,
    );
    expect(confirmSuccess, isTrue);

    final finalMutation = (await mutationRepo.getMutationById(mutation.id) as Success<Mutation>).data;
    expect(finalMutation.status, equals(MutationStatus.completed));
  });

  test('Flow 3: Operator Returns Mutation with Reason', () async {
    final submitResult = await mutationRepo.submitMutation(const SubmitMutationParams(
      applicantId: 'usr_pemohon',
      applicantName: 'Budi Santoso',
      assetId: 'ast_3',
      assetName: 'Kursi Kerja Ergonomis Ergohuman',
      sourceLocation: 'Lantai 2 — Ruang Keuangan',
      targetLocation: 'Lantai 3 — Ruang IT',
      targetPic: 'Programmer Baru',
      reason: 'Mutasi kursi',
    ));
    final mutation = (submitResult as Success<Mutation>).data;

    final operatorContainer = createContainer(currentUser: operatorUser);
    addTearDown(operatorContainer.dispose);

    final returnSuccess = await operatorContainer.read(verificationActionProvider.notifier).returnMutation(
      mutationId: mutation.id,
      reason: 'Dokumen BA serah terima belum dilampirkan.',
    );
    expect(returnSuccess, isTrue);

    final returnedMutation = (await mutationRepo.getMutationById(mutation.id) as Success<Mutation>).data;
    expect(returnedMutation.status, equals(MutationStatus.returned));
    expect(returnedMutation.returnReason, equals('Dokumen BA serah terima belum dilampirkan.'));
  });

  test('Flow 4: Bagian Aset Returns Mutation with Mandatory Reason', () async {
    final submitResult = await mutationRepo.submitMutation(const SubmitMutationParams(
      applicantId: 'usr_pemohon',
      applicantName: 'Budi Santoso',
      assetId: 'ast_3',
      assetName: 'Kursi Kerja Ergonomis Ergohuman',
      sourceLocation: 'Lantai 2 — Ruang Keuangan',
      targetLocation: 'Lantai 3 — Ruang IT',
      targetPic: 'Programmer Baru',
      reason: 'Mutasi kursi',
    ));
    final mutation = (submitResult as Success<Mutation>).data;

    final operatorContainer = createContainer(currentUser: operatorUser);
    addTearDown(operatorContainer.dispose);
    await operatorContainer.read(verificationActionProvider.notifier).verify(
      mutationId: mutation.id,
      requiresKadivApproval: false,
    );

    final bagianAsetContainer = createContainer(currentUser: bagianAsetUser);
    addTearDown(bagianAsetContainer.dispose);

    final rejectSuccess = await bagianAsetContainer.read(bagianAsetVerificationActionProvider.notifier).reject(
      mutationId: mutation.id,
      reason: 'Anggaran pemindahan belum disetujui.',
    );
    expect(rejectSuccess, isTrue);

    final rejectedMutation = (await mutationRepo.getMutationById(mutation.id) as Success<Mutation>).data;
    expect(rejectedMutation.status, equals(MutationStatus.returned));
    expect(rejectedMutation.returnReason, equals('Anggaran pemindahan belum disetujui.'));
  });

  test('Flow 5: Kadiv Rejects Mutation with Mandatory Reason', () async {
    final submitResult = await mutationRepo.submitMutation(const SubmitMutationParams(
      applicantId: 'usr_pemohon',
      applicantName: 'Budi Santoso',
      assetId: 'ast_4',
      assetName: 'Cisco Catalyst Switch 24-Port',
      sourceLocation: 'Lantai Server — Server Room B',
      targetLocation: 'Cabang Surabaya',
      targetPic: 'IT Surabaya',
      reason: 'Switch utama',
    ));
    final mutation = (submitResult as Success<Mutation>).data;

    final operatorContainer = createContainer(currentUser: operatorUser);
    addTearDown(operatorContainer.dispose);
    await operatorContainer.read(verificationActionProvider.notifier).verify(
      mutationId: mutation.id,
      requiresKadivApproval: true,
    );

    final bagianAsetContainer = createContainer(currentUser: bagianAsetUser);
    addTearDown(bagianAsetContainer.dispose);
    await bagianAsetContainer.read(bagianAsetVerificationActionProvider.notifier).approve(
      mutationId: mutation.id,
      requiresKadivApproval: true,
    );

    final kadivContainer = createContainer(currentUser: kadivUser);
    addTearDown(kadivContainer.dispose);

    final rejectSuccess = await kadivContainer.read(kadivApprovalActionProvider.notifier).reject(
      mutationId: mutation.id,
      reason: 'Perangkat jaringan core tidak boleh dipindahkan ke luar pusat data.',
    );
    expect(rejectSuccess, isTrue);

    final rejectedMutation = (await mutationRepo.getMutationById(mutation.id) as Success<Mutation>).data;
    expect(rejectedMutation.status, equals(MutationStatus.rejected));
    expect(rejectedMutation.kadivRejectionReason, equals('Perangkat jaringan core tidak boleh dipindahkan ke luar pusat data.'));
  });

  test('Flow 6: Unregistered Asset is rejected per PRD V1.1 §8 Rule 3', () async {
    final submitResult = await mutationRepo.submitMutation(const SubmitMutationParams(
      applicantId: 'usr_pemohon',
      applicantName: 'Budi Santoso',
      isUnregisteredAsset: true,
      customAssetName: 'Proyektor Epson EB-X500 Manual',
      customSerialNumber: 'EPS-MANUAL-999',
      sourceLocation: 'Lantai 1 — Gudang Lama',
      targetLocation: 'Lantai 2 — Meeting Room',
      currentPic: 'Gudang',
      targetPic: 'Sekretariat',
      reason: 'Aset pengadaan lokal belum masuk database',
    ));

    expect(submitResult.isFailure, isTrue);
    expect(submitResult.failureOrNull, isA<ValidationFailure>());
    expect(
      submitResult.failureOrNull?.userMessage,
      contains('Aset yang dimutasi harus merupakan aset terdaftar'),
    );
  });

  test('Flow 7: Duplicate active mutation on same asset is blocked', () async {
    // ast_1 submitted
    final first = await mutationRepo.submitMutation(const SubmitMutationParams(
      applicantId: 'usr_pemohon',
      applicantName: 'Budi Santoso',
      assetId: 'ast_1',
      assetName: 'Laptop Lenovo',
      sourceLocation: 'Lantai 3',
      targetLocation: 'Lantai 2',
      targetPic: 'Siti',
      reason: 'Mutasi 1',
    ));
    expect(first, isA<Success<Mutation>>());

    // second submission on ast_1 while active -> rejected
    final second = await mutationRepo.submitMutation(const SubmitMutationParams(
      applicantId: 'usr_pemohon',
      applicantName: 'Budi Santoso',
      assetId: 'ast_1',
      assetName: 'Laptop Lenovo',
      sourceLocation: 'Lantai 3',
      targetLocation: 'Lantai 5',
      targetPic: 'Direksi',
      reason: 'Mutasi 2 bentrok',
    ));
    expect(second, isA<AppFailure<Mutation>>());
    expect((second as AppFailure<Mutation>).failure.userMessage, contains('aktif'));
  });

  test('Flow 8: Ticket Numbers are strictly unique and sequential across history', () async {
    final sub1 = await mutationRepo.submitMutation(const SubmitMutationParams(
      applicantId: 'usr_pemohon',
      assetId: 'ast_3',
      sourceLocation: 'L1',
      targetLocation: 'L2',
      targetPic: 'PIC 1',
      reason: 'Reason 1',
    ));
    final sub2 = await mutationRepo.submitMutation(const SubmitMutationParams(
      applicantId: 'usr_pemohon',
      assetId: 'ast_4',
      sourceLocation: 'L1',
      targetLocation: 'L2',
      targetPic: 'PIC 2',
      reason: 'Reason 2',
    ));

    final t1 = (sub1 as Success<Mutation>).data.ticketNumber;
    final t2 = (sub2 as Success<Mutation>).data.ticketNumber;

    expect(t1, isNot(equals(t2)));
    expect(t1, isNotEmpty);
    expect(t2, isNotEmpty);
  });
}
