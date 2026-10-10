// test/features/responsive/mobile_compact_screens_responsive_test.dart
//
// Widget test untuk verifikasi responsiveness dan bebas overflow
// pada layar HP berukuran compact/kecil (320px - 360px).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/features/asset/domain/entities/asset.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_category.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_status.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/auth/presentation/providers/auth_provider.dart';
import 'package:mutasiku/features/auth/presentation/widgets/role_dashboard_layout.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/pemohon/presentation/widgets/pemohon_mutation_card.dart';

class _MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _MockAuthNotifier(User user) : super(AuthState(user: user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const testCategory = AssetCategory(
    id: 'cat_1',
    code: 'ELK',
    name: 'Elektronik & TI',
  );

  final testAsset = Asset(
    id: 'asset-101',
    name: 'Workstation Dell Precision 3660 Tower Super Komputasi',
    assetCode: 'AST-DEL-2024-0099',
    serialNumber: 'SN-DEL-9876543210-XYZ',
    category: testCategory,
    location: 'Gedung Menara Kantor Pusat Lantai 12 Ruang Server Utama',
    pic: 'Rian Pratama',
    status: AssetStatus.inMutation,
    condition: 'Baik',
    acquisitionYear: 2024,
    estimatedValue: 25000000,
  );

  final testMutation = Mutation(
    id: 'mut-101',
    ticketNumber: 'MUT-2024-0099-REGIONAL',
    applicantId: 'user-pemohon-1',
    applicantName: 'Muhammad Rizki Pratama Putra',
    asset: testAsset,
    currentLocation: 'Gedung Menara Kantor Pusat Lantai 12 Ruang Server Utama',
    targetLocation: 'Kantor Cabang Pembantu Palu Barat — Ruang Layanan Terpadu',
    currentPic: 'Rian Pratama',
    targetPic: 'Ahmad Fauzi Supriyanto (Koordinator TI Cabang)',
    reason: 'Kebutuhan workstation baru untuk operasional cabang regional.',
    status: MutationStatus.waitingAssetVerification,
    createdAt: DateTime(2024, 5, 20),
  );

  group('Mobile Compact Screen Responsiveness Tests (320px & 360px)', () {
    testWidgets('PemohonMutationCard renders without overflow on ultra-compact mobile (320x568)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final oldHandler = FlutterError.onError;
      FlutterErrorDetails? caughtDetails;
      FlutterError.onError = (details) {
        caughtDetails = details;
      };

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: PemohonMutationCard(mutation: testMutation),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      } finally {
        FlutterError.onError = oldHandler;
      }

      if (caughtDetails != null) {
        // ignore: avoid_print
        print('OVERFLOW DETAIL: ${caughtDetails!.exception}');
        // ignore: avoid_print
        print('STACK TRACE:\n${caughtDetails!.stack}');
      }
      expect(caughtDetails, isNull);
    });

    testWidgets('PemohonMutationCard with Division Head Approval status renders without overflow on 360x640', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final kadivMutation = testMutation.copyWith(
        status: MutationStatus.waitingKadivApproval,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: PemohonMutationCard(mutation: kadivMutation),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MUT-2024-0099-REGIONAL'), findsOneWidget);
      expect(find.text('Approval Pemimpin Divisi'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('RoleDashboardLayout top bar renders without overflow on ultra-compact mobile (320x568)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testUser = User(
        id: 'user-kadiv-1',
        name: 'Dr. Bambang Suryonegoro, M.M.',
        username: 'bambang.suryo',
        role: UserRole.kadiv,
        email: 'bambang@bankkalteng.co.id',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => _MockAuthNotifier(testUser),
            ),
          ],
          child: const MaterialApp(
            home: RoleDashboardLayout(
              title: 'Dashboard Kadiv',
              child: Text('Dashboard Content'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pemimpin Divisi'), findsOneWidget);
      expect(find.text('MUTASIKU'), findsOneWidget);
      expect(find.text('Dashboard Content'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Action buttons with Kembalikan render cleanly without overflow on ultra-compact mobile (320x568)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        ),
                        child: const Text(
                          'Kembalikan',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        ),
                        child: const Text(
                          'Verifikasi Valid',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kembalikan'), findsOneWidget);
      expect(find.text('Verifikasi Valid'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
