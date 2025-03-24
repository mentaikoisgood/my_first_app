import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/main.dart';

void main() {
  testWidgets('應該顯示標題「📝 待辦事項」', (WidgetTester tester) async {
    await tester
        .pumpWidget(MaterialApp(home: TodoListScreen(toggleTheme: () {})));
    expect(find.text('📝 待辦事項'), findsOneWidget);
  });

  testWidgets('應該能夠新增待辦事項', (WidgetTester tester) async {
    await tester
        .pumpWidget(MaterialApp(home: TodoListScreen(toggleTheme: () {})));

    final textFieldFinder = find.widgetWithText(TextField, '添加新的待辦事項...');
    final addButtonFinder = find.widgetWithText(ElevatedButton, '添加');

    await tester.enterText(textFieldFinder, '新增待辦事項');
    await tester.pump();
    await tester.tap(addButtonFinder);
    await tester.pump();

    expect(find.text('新增待辦事項'), findsOneWidget);
  });

  testWidgets('應該能夠刪除待辦事項', (WidgetTester tester) async {
    await tester
        .pumpWidget(MaterialApp(home: TodoListScreen(toggleTheme: () {})));

    // 添加待辦事項
    final textFieldFinder = find.widgetWithText(TextField, '添加新的待辦事項...');
    final addButtonFinder = find.widgetWithText(ElevatedButton, '添加');

    await tester.enterText(textFieldFinder, '刪除測試');
    await tester.pump();
    await tester.tap(addButtonFinder);
    await tester.pump();

    // 確認已添加項目
    expect(find.text('刪除測試'), findsOneWidget);

    // 使用更穩定的方式找到刪除按鈕
    final deleteIconFinder = find.byIcon(Icons.delete);
    await tester.tap(deleteIconFinder);
    await tester.pumpAndSettle();

    // 確認項目已刪除
    expect(find.text('刪除測試'), findsNothing);
  });

  testWidgets('應該能夠標記待辦事項為已完成', (WidgetTester tester) async {
    await tester
        .pumpWidget(MaterialApp(home: TodoListScreen(toggleTheme: () {})));

    // 添加待辦事項
    final textFieldFinder = find.widgetWithText(TextField, '添加新的待辦事項...');
    final addButtonFinder = find.widgetWithText(ElevatedButton, '添加');

    await tester.enterText(textFieldFinder, '完成測試');
    await tester.pump();
    await tester.tap(addButtonFinder);
    await tester.pump();

    // 確認已添加項目
    expect(find.text('完成測試'), findsOneWidget);

    // 找到並點擊複選框
    final checkboxFinder = find.byType(Checkbox);
    await tester.tap(checkboxFinder);
    await tester.pumpAndSettle();

    // 項目應該保留在列表中
    expect(find.text('完成測試'), findsOneWidget);

    // 無法直接測試文字裝飾，但項目應保持可見
  });

  testWidgets('應該能夠進行關鍵字搜尋', (WidgetTester tester) async {
    await tester
        .pumpWidget(MaterialApp(home: TodoListScreen(toggleTheme: () {})));

    // 添加多個待辦事項
    final textFieldFinder = find.widgetWithText(TextField, '添加新的待辦事項...');
    final addButtonFinder = find.widgetWithText(ElevatedButton, '添加');

    // 添加第一個待辦事項
    await tester.enterText(textFieldFinder, '買牛奶');
    await tester.pump();
    await tester.tap(addButtonFinder);
    await tester.pumpAndSettle();

    // 添加第二個待辦事項
    await tester.enterText(textFieldFinder, '讀書');
    await tester.pump();
    await tester.tap(addButtonFinder);
    await tester.pumpAndSettle();

    // 確認兩個項目都被添加
    expect(find.text('買牛奶'), findsOneWidget);
    expect(find.text('讀書'), findsOneWidget);

    // 找到搜尋框 - 這裡根據提示文字找到搜尋框
    final searchFieldFinder = find.widgetWithText(TextField, '🔍');
    await tester.enterText(searchFieldFinder, '牛奶');
    await tester.pumpAndSettle(); // 等待所有動畫和狀態更新完成

    // 確認只顯示包含「牛奶」的待辦事項
    expect(find.text('買牛奶'), findsOneWidget);
    expect(find.text('讀書'), findsNothing);
  });
}
