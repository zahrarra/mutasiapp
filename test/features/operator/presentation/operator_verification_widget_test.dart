// test/features/operator/presentation/operator_verification_widget_test.dart
//
// Widget & presentation tests untuk screen Operator Verification.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/features/asset/data/repositories/asset_repository_impl.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/auth/domain/repositories/auth_repository.dart';
import 'package:mutasiku/features/auth/domain/usecases/login_usecase.dart';
import 'package:mutasiku/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mutasiku/features/auth/presentation/providers/auth_provider.dart';
import 'package:mutasiku/features/mutation/data/repositories/mutation_repository_impl.dart';
import 'package:mutasiku/features/operator/presentation/screens/operator_dashboard_screen.dart';
import 'package:mutasiku/features/operator/presentation/screens/operator_mutations_screen.dart';

class FakeAuthRepository implements AuthRepository {
  final User? user;

  FakeAuthRepository({this.user});

  @override
  Future<Result<User?>> getCurrentUser() async => Result.success(user);

  @override
  Future<Result<User>> login({
    required String username,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}
}

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(User user)
      : super(
          loginUseCase: LoginUseCase(repository: FakeAuthRepository(user: user)),
          logoutUseCase: LogoutUseCase(repository: FakeAuthRepository(user: user)),
          authRepository: FakeAuthRepository(user: user),
        ) {
    state = AuthState(isLoading: false, user: user);
  }
}

void main() {
  setUp(() {
    MutationRepositoryImpl.resetForTesting();
    final assetRepo = AssetRepositoryImpl();
    MutationRepositoryImpl(assetRepository: assetRepo);
  });

  const operatorUser = User(
    id: 'u_opr_01',
    username: 'operator1',
    name: 'Siti Operator',
    email: 'operator@mutasiku.id',
    role: UserRole.operator,
  );

  Widget createTestWidget(Widget child) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => FakeAuthNotifier(operatorUser),
        ),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets('OperatorDashboardScreen displays greeting and stat cards',
      (tester) async {
    await tester.pumpWidget(createTestWidget(const OperatorDashboardScreen()));
    await tester.pumpAndSettle();

    // Verifikasi teks greeting
    expect(find.text('Halo, Siti Operator'), findsOneWidget);

    // Verifikasi stat cards
    expect(find.text('Menunggu Verifikasi'), findsOneWidget);
    expect(find.text('Pengajuan Dikembalikan'), findsOneWidget);

    // Verifikasi tombol primary action
    expect(find.byKey(const Key('btn_lihat_pengajuan')), findsOneWidget);
  });

  testWidgets('OperatorMutationsScreen renders search bar and sort chips',
      (tester) async {
    await tester.pumpWidget(createTestWidget(const OperatorMutationsScreen()));
    await tester.pumpAndSettle();

    // Verifikasi appbar
    expect(find.text('Pengajuan Masuk'), findsOneWidget);

    // Verifikasi search input
    expect(find.byKey(const Key('input_search_mutations')), findsOneWidget);

    // Verifikasi sort chips
    expect(find.byKey(const Key('chip_sort_terbaru')), findsOneWidget);
    expect(find.byKey(const Key('chip_sort_terlama')), findsOneWidget);

    // Verifikasi card pengajuan masuk berstatus Diajukan tampil
    expect(find.text('Diajukan'), findsWidgets);
  });
}
