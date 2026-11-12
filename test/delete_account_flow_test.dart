import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gopady_rider/core/utils/account_deletion_prompt.dart';
import 'package:gopady_rider/core/utils/legal_links.dart';

/// Account deletion happens on the GoPady website; the app only warns the
/// rider and opens that page.
Future<List<LegalDocument>> _pumpPrompt(WidgetTester tester) async {
  final opened = <LegalDocument>[];
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => confirmAccountDeletion(
            context,
            open: (_, doc) async => opened.add(doc),
          ),
          child: const Text('Delete Account'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('Delete Account'));
  await tester.pumpAndSettle();
  return opened;
}

void main() {
  test('the deletion page is the website one', () {
    expect(
      LegalDocument.deleteAccount.url,
      'https://gopady.com/delete-account',
    );
  });

  testWidgets('Continue opens the website deletion page', (tester) async {
    final opened = await _pumpPrompt(tester);
    expect(find.textContaining('GoPady website'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(opened, [LegalDocument.deleteAccount]);
  });

  testWidgets('Cancel opens nothing', (tester) async {
    final opened = await _pumpPrompt(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(opened, isEmpty);
    expect(find.textContaining('GoPady website'), findsNothing);
  });
}
