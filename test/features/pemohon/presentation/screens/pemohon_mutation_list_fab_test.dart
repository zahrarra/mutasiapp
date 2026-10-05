import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/core/widgets/custom_floating_nav_bar.dart';
import 'package:mutasiku/features/asset/domain/entities/asset.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_category.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_status.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/auth/domain/repositories/auth_repository.dart';
import 'package:mutasiku/features/auth/domain/usecases/login_usecase.dart';
import 'package:mutasiku/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mutasiku/features/auth/presentation/providers/auth_provider.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/domain/repositories/mutation_repository.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';
import 'package:mutasiku/features/pemohon/presentation/screens/pemohon_mutation_list_screen.dart';

class _FakeAuthRepo implements AuthRepository {
  final User user;
  _FakeAuthRepo(this.user);

  @override
  Future<Result<User?>> getCurrentUser() async => Result.success(user);

  @override
  Future<Result<User>> login({required String username, required String password}) async =>
      throw UnimplementedError();

  @override
  Future<void> logout() async {}
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(User user)
      : super(
          loginUseCase: LoginUseCase(repository: _FakeAuthRepo(user)),
          logoutUseCase: LogoutUseCase(repository: _FakeAuthRepo(user)),
          authRepository: _FakeAuthRepo(user),
        ) {
    state = AuthState(isLoading: false, user: user);
  }
}

class _FakeRepo implements MutationRepository {
  final List<Mutation> mutations;
  _FakeRepo(this.mutations);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Result<List<Mutation>>> getAllMutations() async => Result.success(mutations);
}

void main() {
  testWidgets('Floating button "+ Ajukan Mutasi" sits snugly above navigation bar with 8-12dp gap and matches design spec', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const testUser = User(
      id: 'usr_pemohon',
      name: 'Pemohon Test',
      username: 'pemohon_test',
      email: 'pemohon@mutasiku.id',
      role: UserRole.pemohon,
      department: 'Finance',
    );

    final testMutation = Mutation(
      id: 'mut_1',
      ticketNumber: 'MUT-001',
      asset: const Asset(
        id: 'AST-1',
        assetCode: 'AST-ELK-1',
        name: 'MacBook Pro M2',
        category: AssetCategory(id: 'c1', code: 'ELK', name: 'Elektronik'),
        location: 'Kantor Pusat',
        pic: 'Pemohon User',
        status: AssetStatus.inMutation,
        condition: 'Baik',
        acquisitionYear: 2024,
      ),
      applicantId: 'usr_pemohon',
      applicantName: 'Pemohon Test',
      currentLocation: 'Kantor Pusat',
      targetLocation: 'Cabang Surabaya',
      currentPic: 'Pemohon Test',
      targetPic: 'Budi Santoso',
      reason: 'Mutasi dinas',
      status: MutationStatus.submitted,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mutationRepositoryProvider.overrideWithValue(_FakeRepo([testMutation])),
          authStateProvider.overrideWith((ref) => _FakeAuthNotifier(testUser)),
        ],
        child: const MaterialApp(
          home: PemohonMutationListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify FAB presence and text
    final fabFinder = find.byType(FloatingActionButton);
    expect(fabFinder, findsOneWidget);
    expect(find.text('Ajukan Mutasi'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);

    final fab = tester.widget<FloatingActionButton>(fabFinder);
    expect(fab.backgroundColor, const Color(0xFF00273A));
    expect(fab.foregroundColor, Colors.white);
    expect(fab.shape, isA<RoundedRectangleBorder>());

    // Verify layout positions
    final fabRect = tester.getRect(fabFinder);
    final navBarFinder = find.byType(CustomFloatingNavBar);
    expect(navBarFinder, findsOneWidget);
    final navBarRect = tester.getRect(navBarFinder);

    // Calculate vertical gap between bottom of FAB and top of navigation bar
    final verticalGap = navBarRect.top - fabRect.bottom;

    // Check gap is around 8-12 dp (precisely 10 dp)
    expect(verticalGap, inInclusiveRange(8.0, 12.0));

    // Confirm no overlap
    expect(fabRect.bottom < navBarRect.top, isTrue);

    // Confirm horizontal alignment anchored to bottom-right corner
    const screenWidth = 390.0;
    final rightMargin = screenWidth - fabRect.right;
    expect(rightMargin, equals(16.0));
  });
}
