import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '📝 待辦事項',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final List<Todo> _todos = [];
  final TextEditingController _textController = TextEditingController();
  bool _showCompletedTasks = true;

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // 從本地存儲加載待辦事項
  Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final todosJson = prefs.getStringList('todos') ?? [];

    setState(() {
      _todos.clear();
      for (final todoJson in todosJson) {
        final todoMap = jsonDecode(todoJson);
        _todos.add(Todo.fromJson(todoMap));
      }
    });
  }

  // 保存待辦事項到本地存儲
  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final todosJson = _todos.map((todo) => jsonEncode(todo.toJson())).toList();
    await prefs.setStringList('todos', todosJson);
  }

  // 添加新的待辦事項
  void _addTodo() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _todos.add(Todo(title: text));
        _textController.clear();
      });
      _saveTodos();
    }
  }

  // 編輯待辦事項
  void _editTodo(int index) async {
    final controller = TextEditingController(text: _todos[index].title);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('編輯待辦事項'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '輸入待辦事項內容',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      setState(() {
        _todos[index].title = result.trim();
      });
      _saveTodos();
    }
  }

  // 切換待辦事項的完成狀態
  void _toggleTodo(int index) {
    setState(() {
      _todos[index].isCompleted = !_todos[index].isCompleted;
    });
    _saveTodos();
  }

  // 刪除待辦事項
  void _deleteTodo(int index) {
    setState(() {
      _todos.removeAt(index);
    });
    _saveTodos();
  }

  @override
  Widget build(BuildContext context) {
    // 過濾待辦事項列表
    final pendingTodos = _todos.where((todo) => !todo.isCompleted).toList();
    final completedTodos = _todos.where((todo) => todo.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('📝 待辦事項'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: Icon(_showCompletedTasks
                ? Icons.check_circle
                : Icons.check_circle_outline),
            onPressed: () {
              setState(() {
                _showCompletedTasks = !_showCompletedTasks;
              });
            },
            tooltip: _showCompletedTasks ? '隱藏已完成事項' : '顯示已完成事項',
          ),
        ],
      ),
      body: Column(
        children: [
          // 輸入框和添加按鈕
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: '添加新的待辦事項...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addTodo(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addTodo,
                  child: const Text('添加'),
                ),
              ],
            ),
          ),

          // 待辦事項列表
          Expanded(
            child: _todos.isEmpty
                ? const Center(child: Text('沒有待辦事項，請添加！'))
                : ListView(
                    children: [
                      // 未完成事項
                      if (pendingTodos.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                          child: Text(
                            '未完成',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...pendingTodos.asMap().entries.map((entry) {
                          final index = _todos.indexOf(entry.value);
                          final todo = entry.value;
                          return _buildTodoItem(todo, index);
                        }),
                      ],

                      // 已完成事項
                      if (_showCompletedTasks && completedTodos.isNotEmpty) ...[
                        const Padding(
                          padding:
                              EdgeInsets.only(left: 16, top: 16, bottom: 8),
                          child: Text(
                            '已完成',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...completedTodos.asMap().entries.map((entry) {
                          final index = _todos.indexOf(entry.value);
                          final todo = entry.value;
                          return _buildTodoItem(todo, index);
                        }),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // 構建待辦事項列表項
  Widget _buildTodoItem(Todo todo, int index) {
    return ListTile(
      leading: Checkbox(
        value: todo.isCompleted,
        onChanged: (_) => _toggleTodo(index),
      ),
      title: Text(
        todo.title,
        style: TextStyle(
          decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
          color: todo.isCompleted ? Colors.grey : null,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editTodo(index),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteTodo(index),
          ),
        ],
      ),
    );
  }
}

// 待辦事項模型
class Todo {
  String title;
  bool isCompleted;

  Todo({required this.title, this.isCompleted = false});

  // 從JSON創建Todo物件
  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      title: json['title'],
      isCompleted: json['isCompleted'],
    );
  }

  // 將Todo物件轉換為JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'isCompleted': isCompleted,
    };
  }
}
