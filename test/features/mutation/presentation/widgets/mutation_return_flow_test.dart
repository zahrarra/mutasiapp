import 'package:mutasiku/core/errors/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/features/asset/data/repositories/asset_repository_impl.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/auth/domain/repositories/auth_repository.dart';
import 'package:mutasiku/features/auth/domain/usecases/login_usecase.dart';
import 'package:mutasiku/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mutasiku/features/auth/presentation/providers/auth_provider.dart';
import 'package:mutasiku/features/bagian_aset/presentation/screens/bagian_aset_verification_detail_screen.dart';
import 'package:mutasiku/features/mutation/data/repositories/mutation_repository_impl.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';
import 'package:mutasiku/features/operator/presentation/screens/operator_verification_detail_screen.dart';

class FakeAuthRepository implements AuthRepository {
  final User? user;
  FakeAuthRepository({this.user});

  @override
  Future<Result<User?>> getCurrentUser() async => Result.success(user);

  @override
  Future<Result<User>> login({
    required String username,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<void> logout() async {}
    @override
  Future<Result<User>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword.length < 8) {
      return Result.failure(
        const ValidationFailure(message: 'Password baru minimal 8 karakter.'),
      );
    }
    if (newPassword != confirmPassword) {
      return Result.failure(
        const ValidationFailure(message: 'Konfirmasi password baru tidak cocok.'),
      );
    }
    if (newPassword == currentPassword) {
      return Result.failure(
        const ValidationFailure(
          message: 'Password baru harus berbeda dengan password lama.',
        ),
      );
    }
    if (user != null) {
      return Result.success(user!.copyWith(mustChangePassword: false));
    }
    return Result.failure(
      const UnauthorizedFailure(message: 'Pengguna tidak ditemukan.'),
    );
  }
}

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(User user)
    : super(
        loginUseCase: LoginUseCase(repository: FakeAuthRepository(user: user)),
        logoutUseCase: LogoutUseCase(
          repository: FakeAuthRepository(user: user),
        ),
        authRepository: FakeAuthRepository(user: user),
        checkInitialStatus: false,
      ) {
    state = AuthState(isLoading: false, user: user);
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

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

  const bagianAsetUser = User(
    id: 'u_ast_01',
    username: 'bagian_aset1',
    name: 'Bambang Bagian Aset',
    email: 'bagian_aset@mutasiku.id',
    role: UserRole.bagianAset,
  );

  group('Flow Kembalikan Pengajuan (Modal in Detail Screen)', () {
    testWidgets(
      'Operator: Halaman Detail hanya menampilkan tombol Teruskan (tidak ada tombol Kembalikan)',
      (tester) async {
        tester.view.physicalSize = const Size(600, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final testWidget = ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => FakeAuthNotifier(operatorUser),
            ),
            apiMutationRepositoryProvider.overrideWith(
              (ref) => ref.watch(mutationRepositoryProvider),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              return const MaterialApp(
                home: Scaffold(
                  body: OperatorVerificationDetailScreen(mutationId: 'mut_001'),
                ),
              );
            },
          ),
        );

        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        // 1. Verify on Detail Pengajuan
        expect(find.text('Detail Pengajuan'), findsOneWidget);
        // Operator tidak berwenang mengembalikan/menolak
        expect(
          find.byKey(const Key('btn_kembalikan_pengajuan')),
          findsNothing,
        );
        // Operator hanya berwenang meneruskan ke Bagian Aset
        expect(
          find.byKey(const Key('btn_verifikasi_valid')),
          findsOneWidget,
        );
        expect(find.text('Teruskan ke Bagian Aset'), findsOneWidget);
      },
    );

    testWidgets(
      'Regresi: Bagian Aset (Verifikasi Mutasi Aset) TIDAK memiliki tombol Kembalikan dan hanya tombol Verifikasi',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final testWidget = ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => FakeAuthNotifier(bagianAsetUser),
            ),
            apiMutationRepositoryProvider.overrideWith(
              (ref) => ref.watch(mutationRepositoryProvider),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              return const MaterialApp(
                home: Scaffold(
                  body: BagianAsetVerificationDetailScreen(
                    mutationId: 'mut_004',
                  ),
                ),
              );
            },
          ),
        );

        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        // 1. Verify on Verifikasi Mutasi Aset
        expect(find.text('Verifikasi Mutasi Aset'), findsOneWidget);
        // Tombol Kembalikan sudah dihapus 100%
        expect(find.byKey(const Key('btn_tolak_approval')), findsNothing);
        expect(find.text('Kembalikan'), findsNothing);
        // Hanya ada tombol verifikasi & teruskan
        expect(find.byKey(const Key('btn_setujui_approval')), findsOneWidget);
      },
    );
  });
}
