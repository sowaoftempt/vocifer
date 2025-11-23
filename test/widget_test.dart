// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocifer_fixed/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VociferApp());

    // Verify that splash screen appears
    expect(find.text('VOCIFER'), findsOneWidget);
    expect(find.text('Emergency Response System'), findsOneWidget);
  });
}
