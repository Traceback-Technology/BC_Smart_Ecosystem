import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fontend/main.dart';

void main() {
  testWidgets(
    'BC Smart Ecosystem launches successfully',
    (WidgetTester tester) async {
      await tester.pumpWidget(const BCSmartApp());
      await tester.pump();

      expect(find.byType(MaterialApp), findsOneWidget);
    },
  );
}