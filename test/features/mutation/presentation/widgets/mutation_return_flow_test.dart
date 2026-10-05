import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mutasiku/app/theme/app_colors.dart';
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
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
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
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> logout() async {}
}

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(User user)
      : super(
          loginUseCase: LoginUseCase(repository: FakeAuthRepository(user: user)),
          logoutUseCase: LogoutUseCase(repository: FakeAuthRepository(user: user)),
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
        'Operator: Klik Kembalikan -> Buka Modal -> Isi Alasan -> Submit -> Modal Close -> Tetap di Detail -> Status Returned -> Notifikasi Merah Muncul',
        (tester) async {
      tester.view.physicalSize = const Size(600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late WidgetRef containerRef;

      final testWidget = ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => FakeAuthNotifier(operatorUser),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            containerRef = ref;
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
      expect(find.byKey(const Key('btn_kembalikan_pengajuan')), findsOneWidget);

      // 2. Klik "Kembalikan"
      await tester.tap(find.byKey(const Key('btn_kembalikan_pengajuan')));
      await tester.pumpAndSettle();

      // 3. Modal "Kembalikan Pengajuan" muncul
      expect(find.text('Kembalikan Pengajuan'), findsOneWidget);
      expect(
          find.text('Tuliskan catatan perbaikan berkas untuk pemohon.'), findsOneWidget);
      expect(find.byKey(const Key('btn_submit_kembalikan')), findsOneWidget);

      // 4. User mengisi alasan
      await tester.enterText(
        find.byType(TextField),
        'Dokumen SK belum ditandatangani oleh pejabat berwenang.',
      );
      await tester.pumpAndSettle();

      // 5. Klik "Kembalikan"
      await tester.tap(find.byKey(const Key('btn_submit_kembalikan')));
      await tester.pumpAndSettle();

      // 6. Modal tertutup
      expect(
          find.text('Tuliskan catatan perbaikan berkas untuk pemohon.'), findsNothing);

      // 7. Tetap berada di Detail Pengajuan (tidak navigate ke halaman lain)
      expect(find.text('Detail Pengajuan'), findsOneWidget);

      // 8. Status pengajuan berubah ke returned
      final detail =
          await containerRef.read(mutationDetailProvider('mut_001').future);
      expect(detail.status, MutationStatus.returned);
      expect(detail.returnReason,
          'Dokumen SK belum ditandatangani oleh pejabat berwenang.');

      // 9. Notifikasi merah "Pengajuan dikembalikan" muncul
      expect(find.text('Pengajuan dikembalikan'), findsOneWidget);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, AppColors.error);
    });

    testWidgets(
        'Bagian Aset (Verifikasi Mutasi Aset): Klik Kembalikan -> Buka Modal -> Isi Alasan -> Submit -> Modal Close -> Tetap di Detail -> Status Returned -> Notifikasi Merah Muncul',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late WidgetRef containerRef;

      final testWidget = ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => FakeAuthNotifier(bagianAsetUser),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            containerRef = ref;
            return const MaterialApp(
              home: Scaffold(
                body: BagianAsetVerificationDetailScreen(mutationId: 'mut_004'),
              ),
            );
          },
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // 1. Verify on Verifikasi Mutasi Aset
      expect(find.text('Verifikasi Mutasi Aset'), findsOneWidget);
      expect(find.byKey(const Key('btn_tolak_approval')), findsOneWidget);

      // 2. Klik "Kembalikan"
      await tester.tap(find.byKey(const Key('btn_tolak_approval')));
      await tester.pumpAndSettle();

      // 3. Modal "Kembalikan Pengajuan" muncul (sama seperti Operator)
      expect(find.text('Kembalikan Pengajuan'), findsOneWidget);
      expect(
          find.text('Tuliskan catatan perbaikan berkas untuk pemohon.'), findsOneWidget);
      expect(find.byKey(const Key('btn_submit_kembalikan')), findsOneWidget);

      // 4. User mengisi alasan
      await tester.enterText(
        find.byType(TextField),
        'Data fisik aset tidak sesuai dengan kode inventaris.',
      );
      await tester.pumpAndSettle();

      // 5. Klik "Kembalikan"
      await tester.tap(find.byKey(const Key('btn_submit_kembalikan')));
      await tester.pumpAndSettle();

      // 6. Modal tertutup
      expect(
          find.text('Tuliskan catatan perbaikan berkas untuk pemohon.'), findsNothing);

      // 7. Tetap berada di Detail Pengajuan (tidak navigate ke halaman lain)
      expect(find.text('Verifikasi Mutasi Aset'), findsOneWidget);

      // 8. Status pengajuan berubah ke returned
      final detail =
          await containerRef.read(mutationDetailProvider('mut_004').future);
      expect(detail.status, MutationStatus.returned);
      expect(detail.returnReason,
          'Data fisik aset tidak sesuai dengan kode inventaris.');

      // 9. Notifikasi merah "Pengajuan dikembalikan" muncul
      expect(find.text('Pengajuan dikembalikan'), findsOneWidget);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, AppColors.error);
    });
  });
}
