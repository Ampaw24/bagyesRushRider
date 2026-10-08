import 'dart:convert';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/features/rider/home/views/widgets/customer_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

Future<void> _pump(
  WidgetTester tester, {
  bool isVerified = false,
  int unread = 0,
}) async {
  FlutterSecureStorage.setMockInitialValues({
    'auth_token': 't',
    'user_data': jsonEncode({
      'id': 1,
      'first_name': 'Ama',
      'last_name': 'Mensah',
      'email': 'ama@example.com',
    }),
  });
  final session = UserSessionManager(const FlutterSecureStorage());
  await session.load();
  sl.registerSingleton<UserSessionManager>(session);
  addTearDown(sl.reset);

  void noop() {}
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: CustomerDrawer(
        onClose: noop,
        onOrders: noop,
        onWallet: noop,
        onProfile: noop,
        onLogout: noop,
        onDeleteAccount: noop,
        isVerified: isVerified,
        notificationBadgeCount: unread,
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

Color? _iconColor(WidgetTester tester, String label) {
  final tile = find.ancestor(of: find.text(label), matching: find.byType(Row));
  final icon = find.descendant(of: tile.first, matching: find.byType(Icon));
  return tester.widget<Icon>(icon.first).color;
}

void main() {
  testWidgets('menu items share the brand colour; only destructive differ',
      (tester) async {
    await _pump(tester);
    for (final label in ['My Profile', 'My Orders', 'Wallet', 'Help & Support']) {
      expect(_iconColor(tester, label), AppColors.primary, reason: label);
    }
    expect(_iconColor(tester, 'Delete Account'), AppColors.warning);
    expect(_iconColor(tester, 'Logout'), AppColors.error);
  });

  testWidgets('a verified rider gets the tick beside their name',
      (tester) async {
    await _pump(tester, isVerified: true);
    expect(find.byIcon(HugeIcons.strokeRoundedCheckmarkBadge01), findsOneWidget);
    expect(
      tester
          .widget<Icon>(find.byIcon(HugeIcons.strokeRoundedCheckmarkBadge01))
          .color,
      AppColors.info,
    );
  });

  testWidgets('an unverified rider gets no tick', (tester) async {
    await _pump(tester);
    expect(find.byIcon(HugeIcons.strokeRoundedCheckmarkBadge01), findsNothing);
  });

  testWidgets('unread notifications are badged', (tester) async {
    await _pump(tester, unread: 3);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('fits a small phone with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 568) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pump(tester, isVerified: true, unread: 12);
    expect(tester.takeException(), isNull);
  });
}
