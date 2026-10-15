// test/features/mutation/all_roles_ui_widget_render_test.dart
//
// Widget verification test for UI screens across all 4 roles:
// 1. Pemohon: PemohonMutationListScreen tabs (Semua, Diproses, Dialokasikan, Dikembalikan, Selesai, Ditolak)
// 2. Operator: OperatorMutationsScreen tabs (Diproses, Dialokasikan, Dikembalikan, Selesai, Ditolak, Aset TI, Aset Umum)
// 3. Bagian Aset: BagianAsetVerificationsScreen dropdown status filter
// 4. Kadiv: KadivApprovalsScreen dropdown status filter

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/features/asset/domain/entities/asset.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_category.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_status.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';
import 'package:mutasiku/features/pemohon/presentation/screens/pemohon_mutation_list_screen.dart';
import 'package:mutasiku/features/operator/presentation/providers/operator_verification_provider.dart';
import 'package:mutasiku/features/operator/presentation/screens/operator_mutations_screen.dart';
import 'package:mutasiku/features/bagian_aset/presentation/providers/bagian_aset_verification_provider.dart';
import 'package:mutasiku/features/bagian_aset/presentation/screens/bagian_aset_verifications_screen.dart';
import 'package:mutasiku/features/kadiv/presentation/providers/kadiv_approval_provider.dart';
import 'package:mutasiku/features/kadiv/presentation/screens/kadiv_approvals_screen.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/auth/domain/repositories/auth_repository.dart';
import 'package:mutasiku/features/auth/domain/usecases/login_usecase.dart';
import 'package:mutasiku/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mutasiku/features/auth/presentation/providers/auth_provider.dart';

class _FakeAuthRepo implements AuthRepository {
  final User? user;
  _FakeAuthRepo(this.user);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Result<User?>> getCurrentUser() async => Result.success(user);
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(User user)
      : super(
          loginUseCase: LoginUseCase(repository: _FakeAuthRepo(user)),
          logoutUseCase: LogoutUseCase(repository: _FakeAuthRepo(user)),
          authRepository: _FakeAuthRepo(user),
          checkInitialStatus: false,
        ) {
    state = AuthState(isLoading: false, user: user);
  }
}


Mutation _buildMockMutation({
  required String id,
  required String ticketNumber,
  required MutationStatus status,
  required String assetName,
  required String categoryName,
  required String categoryCode,
}) {
  return Mutation(
    id: id,
    ticketNumber: ticketNumber,
    applicantName: 'Budi Pemohon',
    currentLocation: 'Divisi Keuangan',
    targetLocation: 'Divisi Pemasaran',
    currentPic: 'Budi',
    targetPic: 'Siti',
    reason: 'Rotasi tim',
    status: status,
    createdAt: DateTime(2026, 3, 1),
    asset: Asset(
      id: 'ast-$id',
      assetCode: 'CODE-$id',
      name: assetName,
      category: AssetCategory(
        id: 'cat-$id',
        name: categoryName,
        code: categoryCode,
      ),
      location: 'Divisi Keuangan',
      pic: 'Budi',
      status: AssetStatus.inMutation,
      condition: 'Baik',
      acquisitionYear: 2024,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mutationSubmitted = _buildMockMutation(
    id: '1',
    ticketNumber: 'MUT-SUBMITTED-01',
    status: MutationStatus.submitted,
    assetName: 'MacBook Pro M2',
    categoryName: 'Teknologi Informasi',
    categoryCode: 'TI',
  );

  final mutationAllocated = _buildMockMutation(
    id: '2',
    ticketNumber: 'MUT-ALLOCATED-02',
    status: MutationStatus.waitingAssetVerification,
    assetName: 'Meja Kerja Kayu',
    categoryName: 'Mebel Kayu',
    categoryCode: 'MBL',
  );

  final mutationReturned = _buildMockMutation(
    id: '3',
    ticketNumber: 'MUT-RETURNED-03',
    status: MutationStatus.returned,
    assetName: 'Printer Canon LBP',
    categoryName: 'Teknologi Informasi',
    categoryCode: 'TI',
  );

  final mutationCompleted = _buildMockMutation(
    id: '4',
    ticketNumber: 'MUT-COMPLETED-04',
    status: MutationStatus.completed,
    assetName: 'Sofa Ruang Tamu',
    categoryName: 'Mebel Kayu',
    categoryCode: 'MBL',
  );

  final mutationRejected = _buildMockMutation(
    id: '5',
    ticketNumber: 'MUT-REJECTED-05',
    status: MutationStatus.rejected,
    assetName: 'Scanner Fujitsu',
    categoryName: 'Teknologi Informasi',
    categoryCode: 'TI',
  );

  final allMockMutations = [
    mutationSubmitted,
    mutationAllocated,
    mutationReturned,
    mutationCompleted,
    mutationRejected,
  ];

  const pemohonUser = User(
    id: 'u_pmh_01',
    username: 'pemohon1',
    name: 'Budi Pemohon',
    role: UserRole.pemohon,
  );

  const operatorUser = User(
    id: 'u_opr_01',
    username: 'operator1',
    name: 'Operator Officer',
    role: UserRole.operator,
  );

  const bagianAsetUser = User(
    id: 'u_ast_01',
    username: 'bagianaset1',
    name: 'Staff Aset',
    role: UserRole.bagianAset,
  );

  const kadivUser = User(
    id: 'u_kdv_01',
    username: 'kadiv1',
    name: 'Kadiv Boss',
    role: UserRole.kadiv,
  );

  group('Pemohon Screen UI Verification', () {
    testWidgets('Filter chip tabs memisahkan status tanpa duplikasi', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => _FakeAuthNotifier(pemohonUser)),
            mutationListProvider.overrideWith((ref) => Future.value(allMockMutations)),
          ],
          child: const MaterialApp(
            home: PemohonMutationListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Default filter adalah 'Semua'
      expect(find.textContaining('MUT-SUBMITTED-01'), findsOneWidget);
      expect(find.textContaining('MUT-ALLOCATED-02'), findsOneWidget);
      expect(find.textContaining('MUT-RETURNED-03'), findsOneWidget);
      expect(find.textContaining('MUT-COMPLETED-04'), findsOneWidget);
      expect(find.textContaining('MUT-REJECTED-05'), findsOneWidget);

      // Klik Chip 'Diproses'
      final diprosesChip = find.text('Diproses');
      expect(diprosesChip, findsWidgets);
      await tester.tap(diprosesChip.first);
      await tester.pumpAndSettle();

      expect(find.textContaining('MUT-SUBMITTED-01'), findsOneWidget);
      expect(find.textContaining('MUT-ALLOCATED-02'), findsNothing);
      expect(find.textContaining('MUT-RETURNED-03'), findsNothing);
      expect(find.textContaining('MUT-COMPLETED-04'), findsNothing);
      expect(find.textContaining('MUT-REJECTED-05'), findsNothing);

      // Klik Chip 'Dialokasikan'
      final dialokasikanChip = find.text('Dialokasikan');
      expect(dialokasikanChip, findsWidgets);
      await tester.tap(dialokasikanChip.first);
      await tester.pumpAndSettle();

      expect(find.textContaining('MUT-ALLOCATED-02'), findsOneWidget);
      expect(find.textContaining('MUT-SUBMITTED-01'), findsNothing);

      // Verifikasi Chip 'Dikembalikan' tidak lagi ditampilkan pada Pemohon
      expect(find.text('Dikembalikan'), findsNothing);

      // Klik Chip 'Selesai': Hanya menampilkan yang benar-benar Selesai (MUT-COMPLETED-04), tidak menggabungkan data pengembalian
      final selesaiChip = find.text('Selesai');
      expect(selesaiChip, findsWidgets);
      await tester.tap(selesaiChip.first);
      await tester.pumpAndSettle();

      expect(find.textContaining('MUT-COMPLETED-04'), findsOneWidget);
      expect(find.textContaining('MUT-RETURNED-03'), findsNothing);

      // Klik Chip 'Ditolak': Menampilkan pengajuan yang Ditolak secara terpisah
      final ditolakChip = find.text('Ditolak');
      expect(ditolakChip, findsWidgets);
      await tester.tap(ditolakChip.first);
      await tester.pumpAndSettle();

      expect(find.textContaining('MUT-REJECTED-05'), findsOneWidget);
      expect(find.textContaining('MUT-COMPLETED-04'), findsNothing);
      expect(find.textContaining('MUT-RETURNED-03'), findsNothing);
    });
  });

  group('Operator Screen UI Verification', () {
    testWidgets('Menampilkan tab status dan filter Aset TI/Umum tanpa tumpang tindih', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => _FakeAuthNotifier(operatorUser)),
            operatorAllMutationsProvider.overrideWith((ref) => Future.value(allMockMutations)),
          ],
          child: const MaterialApp(
            home: OperatorMutationsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Secara default active tab adalah submitted (Diproses)
      expect(find.text('MUT-SUBMITTED-01'), findsOneWidget);
      expect(find.text('MUT-ALLOCATED-02'), findsNothing);
      expect(find.text('MUT-RETURNED-03'), findsNothing);
      expect(find.text('MUT-COMPLETED-04'), findsNothing);
      expect(find.text('MUT-REJECTED-05'), findsNothing);

      // Pindah ke tab Dialokasikan
      final allocatedTab = find.textContaining('Dialokasikan');
      expect(allocatedTab, findsWidgets);
      await tester.tap(allocatedTab.first);
      await tester.pumpAndSettle();

      expect(find.text('MUT-ALLOCATED-02'), findsOneWidget);
      expect(find.text('MUT-SUBMITTED-01'), findsNothing);
      expect(find.text('MUT-RETURNED-03'), findsNothing);

      // Tab 'Dikembalikan' tidak lagi ditampilkan pada antrean Operator
      expect(find.textContaining('Dikembalikan'), findsNothing);

      // Pindah ke tab Selesai: Hanya menampilkan status selesai, bukan dikembalikan
      final completedTab = find.textContaining('Selesai');
      expect(completedTab, findsWidgets);
      await tester.tap(completedTab.first);
      await tester.pumpAndSettle();

      expect(completedTab, findsWidgets);
      await tester.tap(completedTab.first);
      await tester.pumpAndSettle();

      expect(find.text('MUT-COMPLETED-04'), findsOneWidget);
      expect(find.text('MUT-RETURNED-03'), findsNothing);

      // Pindah ke tab Ditolak
      final rejectedTab = find.textContaining('Ditolak');
      expect(rejectedTab, findsWidgets);
      await tester.tap(rejectedTab.first, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('MUT-REJECTED-05'), findsOneWidget);
      expect(find.text('MUT-COMPLETED-04'), findsNothing);

      // Pindah ke tab Aset TI
      final tiTab = find.textContaining('Aset TI');
      expect(tiTab, findsWidgets);
      await tester.tap(tiTab.first, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('MUT-SUBMITTED-01'), findsOneWidget);
      expect(find.text('MUT-RETURNED-03'), findsOneWidget);
      expect(find.text('MUT-REJECTED-05'), findsOneWidget);
      expect(find.text('MUT-ALLOCATED-02'), findsNothing);
      expect(find.text('MUT-COMPLETED-04'), findsNothing);

      // Pindah ke tab Aset Umum
      final umumTab = find.textContaining('Aset Umum');
      expect(umumTab, findsWidgets);
      await tester.tap(umumTab.first);
      await tester.pumpAndSettle();

      expect(find.text('MUT-ALLOCATED-02'), findsOneWidget);
      expect(find.text('MUT-COMPLETED-04'), findsOneWidget);
      expect(find.text('MUT-SUBMITTED-01'), findsNothing);
      expect(find.text('MUT-RETURNED-03'), findsNothing);
      expect(find.text('MUT-REJECTED-05'), findsNothing);
    });
  });

  group('Bagian Aset Screen UI Verification', () {
    testWidgets('Dropdown status memfilter item secara eksklusif', (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => _FakeAuthNotifier(bagianAsetUser)),
            bagianAsetAllMutationsProvider.overrideWith((ref) => Future.value(allMockMutations)),
          ],
          child: const MaterialApp(
            home: BagianAsetVerificationsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Default adalah Semua
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('MUT-ALLOCATED-02'), findsOneWidget);

      // Buka dropdown status
      final dropdown = find.byKey(const Key('dropdown_filter_bagian_aset_status'));
      expect(dropdown, findsOneWidget);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Pilihan 'Dikembalikan' tidak lagi ada di dropdown filter Bagian Aset
      expect(find.text('Dikembalikan'), findsNothing);

      // Pilih 'Ditolak'
      final rejectedItem = find.text('Ditolak').last;
      await tester.tap(rejectedItem);
      await tester.pumpAndSettle();

      expect(find.text('MUT-REJECTED-05'), findsOneWidget);
      expect(find.text('MUT-ALLOCATED-02'), findsNothing);
      expect(find.text('MUT-COMPLETED-04'), findsNothing);
    });
  });

  group('Kadiv Screen UI Verification', () {
    testWidgets('Dropdown status memfilter item secara eksklusif', (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => _FakeAuthNotifier(kadivUser)),
            kadivAllMutationsProvider.overrideWith((ref) => Future.value(allMockMutations)),
          ],
          child: const MaterialApp(
            home: KadivApprovalsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Buka dropdown status
      final dropdown = find.byKey(const Key('dropdown_filter_kadiv_status'));
      expect(dropdown, findsOneWidget);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Pilihan 'Dikembalikan' tidak ada di dropdown filter Kadiv
      expect(find.text('Dikembalikan'), findsNothing);

      // Pilih 'Ditolak'
      final rejectedItem = find.text('Ditolak').last;
      await tester.tap(rejectedItem);
      await tester.pumpAndSettle();

      expect(find.text('MUT-REJECTED-05'), findsOneWidget);
      expect(find.text('MUT-SUBMITTED-01'), findsNothing);
      expect(find.text('MUT-ALLOCATED-02'), findsNothing);
      expect(find.text('MUT-COMPLETED-04'), findsNothing);
    });
  });
}
