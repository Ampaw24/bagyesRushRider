import 'package:delivery_boy/core/widgets/custom_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hosts a screen pushed on top of a root route, so a stray extra pop is
/// observable as the screen disappearing.
Future<BuildContext> _pumpHost(WidgetTester tester) async {
  late BuildContext screenContext;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (rootContext) => TextButton(
          onPressed: () => Navigator.of(rootContext).push(
            MaterialPageRoute<void>(
              builder: (context) {
                screenContext = context;
                return const Scaffold(body: Text('screen'));
              },
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return screenContext;
}

void main() {
  const longMessage = 'The phone has already been taken. '
      'Please sign in with this number or use a different one to register. '
      'If you believe this is a mistake, contact support for help.';

  testWidgets('showError renders the title and API message', (tester) async {
    final context = await _pumpHost(tester);

    CustomDialog.showError(
      context: context,
      title: 'Sign In Failed',
      subtitle: 'Invalid credentials.',
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign In Failed'), findsOneWidget);
    expect(find.text('Invalid credentials.'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
  });

  testWidgets('the first tap wins during the exit animation', (tester) async {
    final context = await _pumpHost(tester);
    var confirmed = false;
    var cancelled = false;

    CustomDialog.showConfirmation(
      context: context,
      title: 'Account Already Exists',
      subtitle: 'The phone has already been taken.',
      confirmText: 'Sign In',
      cancelText: 'Not Now',
      onConfirm: () => confirmed = true,
      onCancel: () => cancelled = true,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign In'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Not Now'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
    expect(cancelled, isFalse);
    expect(find.text('Account Already Exists'), findsNothing);
    expect(find.text('screen'), findsOneWidget);
  });

  testWidgets('onConfirm runs after the dialog is popped', (tester) async {
    final context = await _pumpHost(tester);

    // Had the callback run first, this pop would close the dialog instead
    // of the screen.
    CustomDialog.showError(
      context: context,
      title: 'Error',
      subtitle: 'Something failed',
      onConfirm: () => Navigator.of(context).pop(),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Something failed'), findsNothing);
    expect(find.text('screen'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('confirmation runs onCancel from the cancel button',
      (tester) async {
    final context = await _pumpHost(tester);
    var confirmed = false;
    var cancelled = false;

    CustomDialog.showConfirmation(
      context: context,
      title: 'Account Already Exists',
      subtitle: longMessage,
      confirmText: 'Sign In',
      cancelText: 'Not Now',
      onConfirm: () => confirmed = true,
      onCancel: () => cancelled = true,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not Now'));
    await tester.pumpAndSettle();

    expect(cancelled, isTrue);
    expect(confirmed, isFalse);
    expect(find.text('screen'), findsOneWidget);
  });

  for (final (label, size) in [
    ('small phone', const Size(320, 568)),
    ('landscape phone', const Size(844, 390)),
    ('tablet', const Size(1024, 1366)),
  ]) {
    testWidgets('no overflow on $label with large text', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final context = await _pumpHost(tester);
      CustomDialog.showConfirmation(
        context: context,
        title: 'Account Already Exists',
        subtitle: longMessage,
        confirmText: 'Sign In',
        cancelText: 'Not Now',
        onConfirm: () {},
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Sign In'), findsOneWidget);
    });
  }
}
