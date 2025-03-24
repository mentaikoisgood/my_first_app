// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/main.dart';

void main() {
  testWidgets('Todo List app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app title is displayed
    expect(find.text('📝 待辦事項'), findsOneWidget);

    // Verify that add button exists
    expect(find.text('添加'), findsOneWidget);

    // Verify that input field exists
    expect(find.widgetWithText(TextField, '添加新的待辦事項...'), findsOneWidget);

    // Add a todo item
    await tester.enterText(
        find.widgetWithText(TextField, '添加新的待辦事項...'), '測試待辦事項');
    await tester.tap(find.text('添加'));
    await tester.pump();

    // Verify that the todo item was added
    expect(find.text('測試待辦事項'), findsOneWidget);

    // Test checkbox tap
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();

    // Verify item is still there after marked as completed
    expect(find.text('測試待辦事項'), findsOneWidget);
  });
}
