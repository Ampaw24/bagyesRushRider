import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/features/rider/auth/viewmodels/rider_auth_viewmodel.dart';
import 'package:delivery_boy/features/rider/auth/views/screens/rider_delete_account_screen.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_password_field.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Stands in for the real deletion, which tears down the session, socket and
/// push registration — none of which this screen is responsible for.
class _FakeAuth extends RiderAuthNotifier {
  _FakeAuth({this.error});

  final String? error;
  ({String password, String? reason})? sent;

  @override
  Future<bool> deleteAccount({required String password, String? reason}) async {
    sent = (password: password, reason: reason);
    if (error != null) state = state.copyWith(errorMessage: error);
    return error == null;
  }
}

Future<_FakeAuth> _pump(WidgetTester tester, {String? error}) async {
  final auth = _FakeAuth(error: error);
  final router = GoRouter(
    initialLocation: AppRoutes.deleteAccount,
    routes: [
      GoRoute(
        path: AppRoutes.deleteAccount,
        builder: (_, __) => const RiderDeleteAccountScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const Scaffold(body: Text('Login screen')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(ProviderScope(
    overrides: [riderAuthProvider.overrideWith(() => auth)],
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();
  return auth;
}

ElevatedButton _deleteButton(WidgetTester tester) => tester.widget(
      find.ancestor(
        of: find.text('Delete My Account'),
        matching: find.byType(ElevatedButton),
      ),
    );

final _passwordField = find.descendant(
  of: find.byType(AppPasswordField),
  matching: find.byType(TextField),
);
final _otherReasonField = find.descendant(
  of: find.byType(AppTextField),
  matching: find.byType(TextField),
);

/// The list builds lazily, so anything below the fold must be scrolled to:
/// first until it's built, then fully into view.
Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    100,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, String reason) async {
  await _reveal(tester, find.text(reason));
  await tester.tap(find.text(reason));
  await tester.pump();
}

Future<void> _enterPassword(WidgetTester tester, String password) async {
  await _reveal(tester, _passwordField);
  await tester.enterText(_passwordField, password);
  await tester.pump();
}

Future<void> _enterOtherReason(WidgetTester tester, String text) async {
  await _reveal(tester, _otherReasonField);
  await tester.enterText(_otherReasonField, text);
  await tester.pump();
}

void main() {
  testWidgets('needs a reason and the password before it can delete',
      (tester) async {
    await _pump(tester);
    expect(find.text('This action is permanent'), findsOneWidget);
    expect(_deleteButton(tester).onPressed, isNull);

    await _choose(tester, 'I no longer want to deliver');
    expect(_deleteButton(tester).onPressed, isNull);

    await _enterPassword(tester, 'secret123');
    expect(_deleteButton(tester).onPressed, isNotNull);
  });

  testWidgets('"Other" needs the rider\'s own reason', (tester) async {
    final auth = await _pump(tester);
    await _choose(tester, 'Other');
    await _enterPassword(tester, 'secret123');
    expect(_deleteButton(tester).onPressed, isNull);

    await _enterOtherReason(tester, 'Moving abroad');
    expect(_deleteButton(tester).onPressed, isNotNull);

    await tester.tap(find.text('Delete My Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, Delete'));
    await tester.pumpAndSettle();
    expect(auth.sent?.reason, 'Moving abroad');
  });

  testWidgets('asks once more, deletes, then lands on login', (tester) async {
    final auth = await _pump(tester);
    await _choose(tester, 'I found another delivery job');
    await _enterPassword(tester, 'secret123');
    expect(_deleteButton(tester).onPressed, isNotNull);

    await tester.tap(find.text('Delete My Account'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Account Permanently?'), findsOneWidget);
    expect(auth.sent, isNull, reason: 'nothing is sent before confirming');

    await tester.tap(find.text('Yes, Delete'));
    await tester.pumpAndSettle();

    expect(auth.sent, (password: 'secret123', reason: 'I found another delivery job'));
    expect(find.text('Login screen'), findsOneWidget);
    expect(find.text('Account Deleted'), findsOneWidget);
  });

  testWidgets('backing out of the last confirmation keeps the account',
      (tester) async {
    final auth = await _pump(tester);
    await _choose(tester, 'Other');
    await _enterOtherReason(tester, 'x');
    await _enterPassword(tester, 'secret123');

    await tester.tap(find.text('Delete My Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep My Account'));
    await tester.pumpAndSettle();

    expect(auth.sent, isNull);
    expect(find.text('Delete My Account'), findsOneWidget);
  });

  testWidgets('a rejected password shows the server message and stays',
      (tester) async {
    await _pump(tester, error: 'The password is incorrect.');
    await _choose(tester, 'I receive too many notifications');
    await _enterPassword(tester, 'wrong');

    await tester.tap(find.text('Delete My Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, Delete'));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't Delete Account"), findsOneWidget);
    expect(find.text('The password is incorrect.'), findsOneWidget);
    expect(find.text('Login screen'), findsNothing);
  });

  testWidgets('fits a small phone with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 568) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pump(tester);
    await _choose(tester, 'Other');
    expect(tester.takeException(), isNull);
  });
}
