import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

import 'package:gopady_rider/core/widgets/app_loading_overlay.dart';
import 'package:gopady_rider/core/widgets/app_status_animation.dart';
import 'package:gopady_rider/core/widgets/app_toast.dart';
import 'package:gopady_rider/core/widgets/custom_dialogs.dart';

Future<BuildContext> _pumpHost(WidgetTester tester) async {
  late BuildContext hostContext;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) {
          hostContext = context;
          return const SizedBox.expand();
        }),
      ),
    ),
  );
  return hostContext;
}

AppStatus _shownStatus(WidgetTester tester) =>
    tester.widget<AppStatusAnimation>(find.byType(AppStatusAnimation)).status;

void main() {
  group('Lottie assets', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    for (final status in AppStatus.values) {
      test('${status.name} ships a valid Lottie file', () async {
        final file = File(status.asset);
        expect(file.existsSync(), isTrue, reason: '${status.asset} missing');
        expect(pubspec, contains('assets/lottie/'));

        final composition =
            await LottieComposition.fromBytes(file.readAsBytesSync());
        expect(composition.duration, greaterThan(Duration.zero));
      });
    }
  });

  group('CustomDialog', () {
    final outcomes = {
      CustomDialog.showSuccess: AppStatus.success,
      CustomDialog.showError: AppStatus.error,
      CustomDialog.showWarning: AppStatus.warning,
      CustomDialog.showInfo: AppStatus.info,
    };

    outcomes.forEach((show, status) {
      testWidgets('plays the ${status.name} animation', (tester) async {
        final context = await _pumpHost(tester);
        show(context: context, title: 'Title', subtitle: 'Subtitle');
        await tester.pumpAndSettle();

        expect(_shownStatus(tester), status);
      });
    });

    testWidgets('confirmations keep the static icon badge', (tester) async {
      final context = await _pumpHost(tester);
      CustomDialog.showConfirmation(
        context: context,
        title: 'Go offline?',
        subtitle: 'You will stop receiving requests.',
        onConfirm: () {},
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppStatusAnimation), findsNothing);
    });
  });

  testWidgets('AppToast plays success and error animations', (tester) async {
    final context = await _pumpHost(tester);

    AppToast.show(context,
        isSuccess: true, title: 'Saved', subtitle: 'All good');
    await tester.pump();
    expect(_shownStatus(tester), AppStatus.success);
    await tester.pumpAndSettle(const Duration(seconds: 4));

    AppToast.show(context,
        isSuccess: false, title: 'Failed', subtitle: 'Try again');
    await tester.pump();
    expect(_shownStatus(tester), AppStatus.error);
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });

  testWidgets('AppLoadingOverlay plays the processing animation',
      (tester) async {
    final context = await _pumpHost(tester);
    AppLoadingOverlay.show(context, message: 'Logging out...');
    await tester.pump();

    expect(_shownStatus(tester), AppStatus.processing);
    expect(find.text('Logging out...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  group('looping status', () {
    Future<void> pumpLoader(WidgetTester tester,
        {required bool reduceMotion}) async {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: AppLoader(message: 'Loading'),
          ),
        ),
      );
      // Real I/O so the composition actually loads and onLoaded runs.
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump();
    }

    testWidgets('keeps playing normally', (tester) async {
      await pumpLoader(tester, reduceMotion: false);

      await expectLater(
        () => tester.pumpAndSettle(const Duration(milliseconds: 100),
            EnginePhase.sendSemanticsUpdate, const Duration(seconds: 2)),
        throwsA(isA<FlutterError>()),
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('holds still with reduce motion on', (tester) async {
      await pumpLoader(tester, reduceMotion: true);

      // Would time out if the loop kept scheduling frames.
      await tester.pumpAndSettle();
      expect(find.text('Loading'), findsOneWidget);
    });
  });
}
