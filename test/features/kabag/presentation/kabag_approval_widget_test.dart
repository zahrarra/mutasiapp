// test/features/kabag/presentation/kabag_approval_widget_test.dart
//
// Widget & presentation tests untuk screen Kabag Aset.

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
import 'package:mutasiku/features/kabag/presentation/screens/kabag_approvals_screen.dart';
import 'package:mutasiku/features/kabag/presentation/screens/kabag_dashboard_screen.dart';
import 'package:mutasiku/features/mutation/data/repositories/mutation_repository_impl.dart';

class FakeKabagAuthRepository implements AuthRepository {
  final User? user;

  FakeKabagAuthRepository({this.user});

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

class FakeKabagAuthNotifier extends AuthNotifier {
  FakeKabagAuthNotifier(User user)
      : super(
          loginUseCase: LoginUseCase(repository: FakeKabagAuthRepository(user: user)),
          logoutUseCase: LogoutUseCase(repository: FakeKabagAuthRepository(user: user)),
          authRepository: FakeKabagAuthRepository(user: user),
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

  const kabagUser = User(
    id: 'u_kbg_01',
    username: 'kabag1',
    name: 'Bambang Kabag',
    email: 'kabag@mutasiku.id',
    role: UserRole.kabagAset,
  );

  Widget createTestWidget(Widget child) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => FakeKabagAuthNotifier(kabagUser),
        ),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets('KabagDashboardScreen displays greeting and overview stat cards',
      (tester) async {
    await tester.pumpWidget(createTestWidget(const KabagDashboardScreen()));
    await tester.pumpAndSettle();

    // Verifikasi teks greeting
    expect(find.text('Halo, Bambang Kabag'), findsOneWidget);

    // Verifikasi stat cards
    expect(find.text('Menunggu Approval'), findsOneWidget);
    expect(find.text('Disetujui'), findsOneWidget);
    expect(find.text('Ditolak'), findsOneWidget);

    // Verifikasi tombol primary action
    expect(find.byKey(const Key('btn_lihat_approval')), findsOneWidget);
  });

  testWidgets('KabagApprovalsScreen renders search bar, filters, and cards',
      (tester) async {
    await tester.pumpWidget(createTestWidget(const KabagApprovalsScreen()));
    await tester.pumpAndSettle();

    // Verifikasi appbar
    expect(find.text('Menunggu Approval'), findsOneWidget);

    // Verifikasi search input
    expect(find.byKey(const Key('input_search_approvals')), findsOneWidget);

    // Verifikasi filter chips
    expect(find.byKey(const Key('chip_filter_semua')), findsOneWidget);
    expect(find.byKey(const Key('chip_filter_terbaru')), findsOneWidget);
    expect(find.byKey(const Key('chip_filter_terlama')), findsOneWidget);

    // Verifikasi badge Menunggu Approval Kabag tampil
    expect(find.text('Menunggu Approval Kabag'), findsWidgets);
  });
}
