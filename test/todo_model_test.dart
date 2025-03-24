import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/main.dart';

void main() {
  group('Todo Model Tests', () {
    test('應該能正確建立 Todo 物件', () {
      final todo = Todo(title: '寫測試');

      expect(todo.title, '寫測試');
      expect(todo.isImportant, false);
      expect(todo.isCompleted, false);
      expect(todo.dueDate, isNull);
    });

    test('應該能正確轉換為 json', () {
      final todo = Todo(title: '寫測試', isCompleted: true, isImportant: true);
      final json = todo.toJson();

      expect(json['title'], '寫測試');
      expect(json['isCompleted'], true);
      expect(json['isImportant'], true);
      expect(json.containsKey('dueDate'), true);
    });

    test('應該能正確從 json 轉換回 Todo 物件', () {
      final json = {
        'title': '寫測試',
        'isCompleted': true,
        'isImportant': true,
        'dueDate': '2025-01-01'
      };
      final todo = Todo.fromJson(json);

      expect(todo.title, '寫測試');
      expect(todo.isCompleted, true);
      expect(todo.isImportant, true);
      expect(todo.dueDate, isNotNull);
    });
  });
}
