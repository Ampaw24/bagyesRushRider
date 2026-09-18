import 'package:dartz/dartz.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/features/rider/auth/repositories/rider_auth_repository.dart';
import 'package:delivery_boy/features/rider/auth/views/screens/rider_password_reset_otp_screen.dart';
import 'package:delivery_boy/features/rider/auth/views/screens/rider_reset_password_screen.dart';
import 'package:delivery_boy/features/rider/shared_widgets/otp_code_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _phone = '+233201234567';
const _goodCode = '123456';

/// Only the forgot-password calls are real; anything else fails loudly.
class _FakeAuthRepository implements RiderAuthRepository {
  final verified = <String>[];
  final resets = <Map<String, String>>[];

  @override
  Future<Either<Failure, void>> sendForgotPasswordCode({
    required String phone,
  }) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> verifyPasswordResetCode({
    required String phone,
    required String code,
  }) async {
    verified.add(code);
    return code == _goodCode
        ? const Right(null)
        : const Left(ServerFailure('Invalid or expired code'));
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String phone,
    required String code,
    required String password,
    required String confirmPassword,
  }) async {
    resets.add({'phone': phone, 'code': code, 'password': password});
    return const Right(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

Future<void> _pumpInput(
  WidgetTester tester, {
  required List<String> completed,
  GlobalKey<OtpCodeInputState>? key,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: OtpCodeInput(
          key: key,
          onChanged: (_) {},
          onCompleted: completed.add,
        ),
      ),
    ),
  );
}

Finder _box(int i) => find.byType(TextField).at(i);

String _codeOf(WidgetTester tester) => List.generate(
      6,
      (i) => tester.widget<TextField>(_box(i)).controller!.text,
    ).join();

/// Real routes for the two screens, with stand-ins either side of them.
GoRouter _router() => GoRouter(
      initialLocation: AppRoutes.forgotPasswordOtp,
      initialExtra: _phone,
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (_, __) => const Scaffold(body: Text('login')),
        ),
        GoRoute(
          path: AppRoutes.forgotPasswordOtp,
          builder: (_, state) =>
              RiderPasswordResetOtpScreen(phone: state.extra! as String),
        ),
        GoRoute(
          path: AppRoutes.resetPassword,
          builder: (_, state) {
            final extra = state.extra! as Map;
            return RiderResetPasswordScreen(
              phone: extra['phone'] as String,
              code: extra['code'] as String,
            );
          },
        ),
      ],
    );

void main() {
  group('OtpCodeInput', () {
    testWidgets('typing each digit fills the code and completes it',
        (tester) async {
      final completed = <String>[];
      await _pumpInput(tester, completed: completed);

      for (var i = 0; i < 6; i++) {
        await tester.enterText(_box(i), '${i + 1}');
        await tester.pump();
      }

      expect(_codeOf(tester), '123456');
      expect(completed, ['123456']);
    });

    testWidgets('pasting a whole code spreads it across the boxes',
        (tester) async {
      final completed = <String>[];
      await _pumpInput(tester, completed: completed);

      await tester.enterText(_box(0), '654321');
      await tester.pump();

      expect(_codeOf(tester), '654321');
      expect(completed, ['654321']);
    });

    testWidgets('typing over a filled box replaces only that digit',
        (tester) async {
      final completed = <String>[];
      await _pumpInput(tester, completed: completed);

      await tester.enterText(_box(0), '1');
      await tester.enterText(_box(1), '2');
      await tester.pump();
      // Cursor sits after the existing digit, so the field reports "29".
      await tester.enterText(_box(1), '29');
      await tester.pump();

      expect(_codeOf(tester).substring(0, 2), '19');
      expect(completed, isEmpty);
    });

    testWidgets('clear empties every box', (tester) async {
      final key = GlobalKey<OtpCodeInputState>();
      await _pumpInput(tester, completed: [], key: key);

      await tester.enterText(_box(0), '654321');
      await tester.pump();
      key.currentState!.clear();
      await tester.pump();

      expect(_codeOf(tester), isEmpty);
    });
  });

  group('forgot password flow', () {
    late _FakeAuthRepository repo;

    setUp(() {
      repo = _FakeAuthRepository();
      sl.registerSingleton<RiderAuthRepository>(repo);
    });

    tearDown(() => sl.reset());

    Future<void> pumpFlow(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: _router())),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a wrong code shows the error and clears the boxes',
        (tester) async {
      await pumpFlow(tester);

      await tester.enterText(_box(0), '000000');
      await tester.pumpAndSettle();

      expect(repo.verified, ['000000']);
      expect(find.text('Invalid or expired code'), findsOneWidget);
      expect(_codeOf(tester), isEmpty);
      expect(find.byType(RiderPasswordResetOtpScreen), findsOneWidget);
    });

    testWidgets(
        'the verified code carries through to a reset gated on strength',
        (tester) async {
      await pumpFlow(tester);

      await tester.enterText(_box(0), _goodCode);
      await tester.pumpAndSettle();
      expect(find.byType(RiderResetPasswordScreen), findsOneWidget);

      AppGradientButton resetButton() =>
          tester.widget<AppGradientButton>(find.byType(AppGradientButton));
      final fields = find.byType(TextFormField);

      // Weak: under 8 characters, so the button stays disabled.
      await tester.enterText(fields.at(0), 'Ab1!');
      await tester.enterText(fields.at(1), 'Ab1!');
      await tester.pump();
      expect(find.text('Weak'), findsOneWidget);
      expect(resetButton().onPressed, isNull);

      await tester.enterText(fields.at(0), 'Abcd1234!');
      await tester.enterText(fields.at(1), 'Abcd1234!');
      await tester.pump();
      expect(find.text('Strong'), findsOneWidget);
      expect(resetButton().onPressed, isNotNull);

      await tester.ensureVisible(find.byType(AppGradientButton));
      await tester.tap(find.byType(AppGradientButton));
      await tester.pumpAndSettle();

      expect(repo.resets, [
        {'phone': _phone, 'code': _goodCode, 'password': 'Abcd1234!'},
      ]);
      expect(find.text('Password Reset Successful'), findsOneWidget);

      await tester.tap(find.text('Go to Login'));
      await tester.pumpAndSettle();
      expect(find.text('login'), findsOneWidget);
    });
  });
}
