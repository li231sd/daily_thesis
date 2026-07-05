import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daily_thesis/main.dart';

void main() {
  testWidgets('app mounts successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const DailyThesisApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(AppRoot), findsOneWidget);
  });
}
