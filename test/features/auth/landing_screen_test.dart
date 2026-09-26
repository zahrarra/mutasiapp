import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mutasiku/app/router/route_names.dart';
import 'package:mutasiku/features/auth/presentation/screens/landing_screen.dart';

void main() {
  testWidgets(
      'LandingScreen renders Stitch branding, progress bar, and smoothly transitions to Login',
      (tester) async {
    bool navigatedToLogin = false;

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const LandingScreen(),
        ),
        GoRoute(
          path: RouteNames.loginPath,
          builder: (context, state) {
            navigatedToLogin = true;
            return const Scaffold(body: Text('Login Screen Mock'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
      ),
    );

    // Verify Title & Tagline
    expect(find.text('MutasiKu'), findsOneWidget);
    expect(find.text('Transparan. Terstruktur. Akuntabel.'), findsOneWidget);

    // Verify progress bar exists
    expect(find.byKey(const Key('landing_progress_bar')), findsOneWidget);

    // Initial state: not navigated yet
    expect(navigatedToLogin, isFalse);

    // Advance progress animation (2000ms) + delay (150ms) + fade-out (350ms)
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // Verify auto-transition to Login Page
    expect(navigatedToLogin, isTrue);
  });
}
