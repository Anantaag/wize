import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:wize_app/main.dart';

void main() {
  testWidgets('WizeApp launches', (WidgetTester tester) async {
    await tester.pumpWidget(WizeApp());

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}