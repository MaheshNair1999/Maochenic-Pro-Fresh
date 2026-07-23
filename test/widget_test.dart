import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mechanic_app/main.dart';

void main() {
  testWidgets('app boots without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MechProApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
