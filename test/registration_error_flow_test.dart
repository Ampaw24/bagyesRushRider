import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:gopady_rider/core/router/app_routes.dart';
import 'package:gopady_rider/core/widgets/custom_dialogs.dart';
import 'package:gopady_rider/features/rider/auth/viewmodels/rider_auth_viewmodel.dart';
import 'package:gopady_rider/features/rider/auth/views/screens/rider_signup_screen.dart';
import 'package:gopady_rider/features/rider/auth/views/screens/rider_terms_conditions_screen.dart';
import 'package:gopady_rider/features/rider/legal/models/legal_document_model.dart';
import 'package:gopady_rider/features/rider/legal/providers/legal_document_providers.dart';
import 'package:gopady_rider/features/rider/vehicles/model/vehicle_type_model.dart';
import 'package:gopady_rider/features/rider/vehicles/viewmodel/vehicle_catalog_viewmodel.dart';

/// Fails `/register` the way the real notifier reports it: a message, plus
/// per-field errors for a 422.
class _FailingAuth extends RiderAuthNotifier {
  _FailingAuth(this.message, [this.fieldErrors = const {}]);

  final String message;
  final Map<String, List<String>> fieldErrors;

  /// What the terms screen sent for the vehicle — `/register` rejects a
  /// rider without them.
  int? sentVehicleTypeId;
  String? sentPlateNumber;

  @override
  Future<bool> registerAndAcceptAgreement({
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required String firstName,
    required String lastName,
    required String city,
    required int vehicleTypeId,
    String? plateNumber,
    required bool acceptTerms,
    required bool consentToVerification,
    String? termsVersion,
  }) async {
    sentVehicleTypeId = vehicleTypeId;
    sentPlateNumber = plateNumber;
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    state = state.copyWith(
      status: AuthStatus.error,
      errorMessage: message,
      fieldErrors: fieldErrors,
    );
    return false;
  }
}

const _motorbike = VehicleTypeModel(
  id: 1,
  name: 'Motorbike',
  slug: 'motorbike',
  requiresPlate: true,
  maxParcelSize: 'small',
  maxParcelSizeLabel: 'Small',
  isActive: true,
  displayOrder: 0,
);

/// Serves the live catalogue's one selectable type without the network.
class _OneTypeCatalog extends VehicleCatalogNotifier {
  @override
  Future<void> loadTypes() async =>
      state = const VehicleCatalogState(types: [_motorbike]);
}

/// What the terms screen hands back to the wizard (see
/// `RiderSignupScreen._proceedToTerms`).
const _collected = <String, dynamic>{
  'first_name': 'Ama',
  'last_name': 'Mensah',
  'email': 'ama@example.com',
  'phone': '+233241234567',
  'city': 'Accra',
  'password': 'Str0ng!Passw0rd',
  'vehicle_type_id': '1',
  'plate_number': 'GR-1234-24',
};

Future<void> _pumpSignup(
  WidgetTester tester,
  Map<String, dynamic> prefill,
) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [vehicleCatalogProvider.overrideWith(_OneTypeCatalog.new)],
    child: MaterialApp(home: RiderSignupScreen(prefill: prefill)),
  ));
  await tester.pumpAndSettle();
}

Future<void> _pumpWithErrors(
  WidgetTester tester,
  Map<String, String> fieldErrors,
) =>
    _pumpSignup(tester, {..._collected, 'field_errors': fieldErrors});

final _dialog = find.byType(CustomDialog);

Finder _inDialog(String text) =>
    find.descendant(of: _dialog, matching: find.text(text));

void main() {
  _registerTermsTests();

  group('reopening after a register field error', () {
    testWidgets('shows the Registration Failed dialog with the message',
        (tester) async {
      await _pumpWithErrors(
          tester, {'email': 'The email has already been registered.'});

      expect(tester.takeException(), isNull);
      expect(_inDialog('Registration Failed'), findsOneWidget);
      expect(
          _inDialog('The email has already been registered.'), findsOneWidget);
    });

    testWidgets('lists every rejected field once', (tester) async {
      await _pumpWithErrors(tester, {
        'first_name': 'The first name is required.',
        'password': 'The password is too common.',
      });

      expect(
        _inDialog('The first name is required.\nThe password is too common.'),
        findsOneWidget,
      );
    });

    testWidgets('still reaches the rider for a field with no inline slot',
        (tester) async {
      await _pumpWithErrors(
          tester, {'accept_terms': 'You must accept the terms.'});

      expect(_inDialog('You must accept the terms.'), findsOneWidget);
    });

    final stepFor = {
      'phone': 'Personal Profile',
      'password': 'Secure Your Account',
      'vehicle_type_id': 'Your Vehicle',
      'plate_number': 'Your Vehicle',
    };
    stepFor.forEach((field, stepTitle) {
      testWidgets('opens on "$stepTitle" for a $field error', (tester) async {
        await _pumpWithErrors(tester, {field: 'Rejected.'});
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(find.text(stepTitle), findsOneWidget);
        if (stepTitle != 'Personal Profile') {
          expect(find.text('Personal Profile'), findsNothing);
        }
      });
    });
  });

  testWidgets('backing out of terms returns to the last step',
      (tester) async {
    await _pumpSignup(tester, {..._collected, 'resume_step': 2});

    expect(tester.takeException(), isNull);
    expect(_dialog, findsNothing);
    expect(find.text('Your Vehicle'), findsOneWidget);
    expect(find.text('Personal Profile'), findsNothing);
  });

  testWidgets('one vehicle step, with the only type pre-selected',
      (tester) async {
    // No earlier choice to restore: the type must be picked for them.
    await _pumpSignup(
      tester,
      {..._collected, 'resume_step': 2}..remove('vehicle_type_id'),
    );

    expect(find.text('Step 3 of 3'), findsOneWidget);
    expect(find.text('Motorbike'), findsOneWidget);
    expect(find.text('GR-1234-24'), findsOneWidget);
    // Make, model and year stay in KYC.
    expect(find.text('Make'), findsNothing);
    expect(find.text('Year'), findsNothing);
  });
}

/// Drives the real hand-off: the terms screen registers, and on a field
/// error sends the rider back to the wizard through the router.
Future<void> _submitTerms(WidgetTester tester, _FailingAuth auth) async {
  final router = GoRouter(
    initialLocation: AppRoutes.termsAndConditions,
    routes: [
      GoRoute(
        path: AppRoutes.termsAndConditions,
        builder: (_, __) =>
            const RiderTermsConditionsScreen(credentials: _collected),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (_, state) => RiderSignupScreen(
          prefill: (state.extra as Map<String, dynamic>?) ?? const {},
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const Scaffold(body: Text('Login screen')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(ProviderScope(
    overrides: [
      riderAuthProvider.overrideWith(() => auth),
      vehicleCatalogProvider.overrideWith(_OneTypeCatalog.new),
      riderAgreementProvider.overrideWith((_) async => const LegalDocumentModel(
            version: '1',
            title: 'Rider Agreement',
            body: '<p>Terms</p>',
          )),
    ],
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();

  for (final consent in [
    'I accept the Terms & Conditions',
    'I consent to verification checks',
    'Accept & Continue',
  ]) {
    await tester.ensureVisible(find.text(consent));
    await tester.pumpAndSettle();
    await tester.tap(find.text(consent));
    await tester.pumpAndSettle();
  }
}

void _registerTermsTests() {
  group('submitting the terms screen', () {
    testWidgets('sends the vehicle type and plate /register requires',
        (tester) async {
      final auth = _FailingAuth('Unable to reach the server. Try again.');
      await _submitTerms(tester, auth);

      expect(auth.sentVehicleTypeId, 1);
      expect(auth.sentPlateNumber, 'GR-1234-24');
    });

    testWidgets('a network/server failure shows the error dialog',
        (tester) async {
      await _submitTerms(
          tester, _FailingAuth('Unable to reach the server. Try again.'));

      expect(_inDialog('Registration Failed'), findsOneWidget);
      expect(
          _inDialog('Unable to reach the server. Try again.'), findsOneWidget);
    });

    testWidgets('a field error reopens the wizard with the error dialog',
        (tester) async {
      await _submitTerms(
        tester,
        _FailingAuth('The given data was invalid.', {
          'password': ['The password has appeared in a data leak.'],
        }),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(RiderSignupScreen), findsOneWidget);
      expect(_inDialog('The password has appeared in a data leak.'),
          findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Secure Your Account'), findsOneWidget);
    });
  });
}
