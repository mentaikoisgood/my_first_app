import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // 主題模式狀態
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  // 從SharedPreferences讀取主題設置
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  // 切換主題模式
  void _toggleThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = _themeMode == ThemeMode.dark;

    // 保存相反的設置
    await prefs.setBool('isDarkMode', !isDarkMode);

    setState(() {
      _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '📝 待辦事項',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
        ),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: TodoListScreen(toggleTheme: _toggleThemeMode),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  final VoidCallback toggleTheme;

  const TodoListScreen({super.key, required this.toggleTheme});

  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final List<Todo> _todos = [];
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _showCompletedTasks = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadTodos();
    _loadShowCompletedPreference();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _searchController.dispose();
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

  // 加載是否顯示已完成任務的設置
  Future<void> _loadShowCompletedPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showCompletedTasks = prefs.getBool('showCompleted') ?? true;
    });
  }

  // 保存待辦事項到本地存儲
  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final todosJson = _todos.map((todo) => jsonEncode(todo.toJson())).toList();
    await prefs.setStringList('todos', todosJson);
  }

  // 保存是否顯示已完成任務的設置
  Future<void> _saveShowCompletedPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showCompleted', _showCompletedTasks);
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

  // 切換待辦事項的重要性
  void _toggleImportant(int index) {
    setState(() {
      _todos[index].isImportant = !_todos[index].isImportant;
    });
    _saveTodos();
  }

  // 設置待辦事項的截止日期
  Future<void> _setDueDate(int index) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _todos[index].dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _todos[index].dueDate = pickedDate;
      });
      _saveTodos();
    }
  }

  // 過濾待辦事項列表
  List<Todo> _filteredTodos() {
    return _todos
        .where((todo) =>
            (_showCompletedTasks || !todo.isCompleted) &&
            (todo.title.toLowerCase().contains(_searchQuery.toLowerCase())))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // 過濾待辦事項列表
    final filteredTodos = _filteredTodos();

    // 獲取當前主題
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text('📝 待辦事項'),
        actions: [
          // 顯示/隱藏已完成事項按鈕
          IconButton(
            icon: Icon(_showCompletedTasks
                ? Icons.check_circle
                : Icons.check_circle_outline),
            onPressed: () {
              setState(() {
                _showCompletedTasks = !_showCompletedTasks;
                _saveShowCompletedPreference();
              });
            },
            tooltip: _showCompletedTasks ? '隱藏已完成事項' : '顯示已完成事項',
          ),
          // 切換主題模式按鈕
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.toggleTheme,
            tooltip: isDarkMode ? '切換至亮色模式' : '切換至深色模式',
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索欄 - 移到這裡來避免渲染錯誤
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: "🔍",
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),

          // 清除搜索按鈕
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.clear),
                    label: const Text('清除搜尋'),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                      });
                    },
                  ),
                ],
              ),
            ),

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

          // 使用新的過濾後的待辦事項列表視圖
          Expanded(
            child: filteredTodos.isEmpty
                ? const Center(child: Text("沒有符合條件的待辦事項！"))
                : ListView.builder(
                    itemCount: filteredTodos.length,
                    itemBuilder: (context, index) {
                      final todo = filteredTodos[index];
                      return _buildTodoItem(todo, _todos.indexOf(todo));
                    },
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
          fontWeight: todo.isImportant ? FontWeight.bold : null,
        ),
      ),
      subtitle: todo.dueDate != null
          ? Text(
              '截止日期: ${_formatDate(todo.dueDate!)}',
              style: TextStyle(
                color: todo.dueDate!.isBefore(DateTime.now())
                    ? Colors.red
                    : Colors.grey,
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              todo.isImportant ? Icons.star : Icons.star_border,
              color: todo.isImportant ? Colors.amber : null,
            ),
            onPressed: () => _toggleImportant(index),
            tooltip: todo.isImportant ? '取消重要標記' : '標記為重要',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _setDueDate(index),
            tooltip: '設置截止日期',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editTodo(index),
            tooltip: '編輯',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteTodo(index),
            tooltip: '刪除',
          ),
        ],
      ),
    );
  }

  // 添加這個新的方法來格式化日期
  String _formatDate(DateTime date) {
    // 檢查是否是當年的日期
    final now = DateTime.now();
    if (date.year == now.year) {
      // 如果是當年的日期，只顯示月和日
      return '${date.month}/${date.day}';
    } else {
      // 如果不是當年的日期，顯示年月日
      return '${date.year}/${date.month}/${date.day}';
    }
  }
}

// 待辦事項模型
class Todo {
  String title;
  bool isCompleted;
  bool isImportant;
  DateTime? dueDate;

  Todo({
    required this.title,
    this.isCompleted = false,
    this.isImportant = false,
    this.dueDate,
  });

  // 從JSON創建Todo物件
  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      title: json['title'],
      isCompleted: json['isCompleted'],
      isImportant: json['isImportant'] ?? false,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
    );
  }

  // 將Todo物件轉換為JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'isCompleted': isCompleted,
      'isImportant': isImportant,
      'dueDate': dueDate?.toIso8601String(),
    };
  }
}
