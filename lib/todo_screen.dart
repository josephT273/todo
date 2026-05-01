import 'package:flutter/cupertino.dart';
import 'package:todo/database_service.dart';

class TodoScreen extends StatefulWidget {
  final int taskID;
  final String title;

  const TodoScreen({super.key, required this.taskID, required this.title});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  List<Map<String, dynamic>> todos = [];
  final TextEditingController todoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadTodos();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showAddTodoDialog,
          child: const Icon(CupertinoIcons.add),
        ),
      ),

      child: SafeArea(
        child: todos.isEmpty
            ? const Center(child: Text("No todos found"))
            : ListView.builder(
                itemCount: todos.length,
                itemBuilder: (context, index) {
                  final todo = todos[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => toggleTodoStatus(todo['id']),
                          child: Icon(
                            todo['is_done'] == 1
                                ? CupertinoIcons.checkmark_circle_fill
                                : CupertinoIcons.circle,
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: GestureDetector(
                            onLongPress: () =>
                                _showEditDialog(todo['id'], todo['title']),
                            child: Text(
                              todo['title'],
                              style: TextStyle(
                                decoration: todo['is_done'] == 1
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ),

                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => deleteTodo(todo['id']),
                          child: const Icon(
                            CupertinoIcons.delete,
                            color: CupertinoColors.systemRed,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  // ───────────── DB OPERATIONS ─────────────

  Future<void> loadTodos() async {
    final db = await DB.database;

    final data = await db.query(
      'todos',
      where: 'task_id = ?',
      whereArgs: [widget.taskID],
    );

    setState(() {
      todos = data.map((e) => Map<String, dynamic>.from(e)).toList();
    });
  }

  Future<void> deleteTodo(int id) async {
    final db = await DB.database;
    await db.delete('todos', where: 'id = ?', whereArgs: [id]);

    setState(() {
      todos.removeWhere((todo) => todo['id'] == id);
    });
  }

  Future<void> addTodo(String title) async {
    final db = await DB.database;

    final id = await db.insert('todos', {
      'task_id': widget.taskID,
      'title': title,
      'is_done': 0,
    });

    setState(() {
      todos.add({
        'id': id,
        'task_id': widget.taskID,
        'title': title,
        'is_done': 0,
      });
    });
  }

  Future<void> editTodoTitle(int id, String newTitle) async {
    final db = await DB.database;

    await db.update(
      'todos',
      {'title': newTitle},
      where: 'id = ?',
      whereArgs: [id],
    );

    setState(() {
      final index = todos.indexWhere((t) => t['id'] == id);
      if (index != -1) {
        todos[index]['title'] = newTitle;
      }
    });
  }

  Future<void> toggleTodoStatus(int id) async {
    final db = await DB.database;

    final index = todos.indexWhere((t) => t['id'] == id);
    if (index == -1) return;

    final isDone = todos[index]['is_done'] == 1;

    await db.update(
      'todos',
      {'is_done': isDone ? 0 : 1},
      where: 'id = ?',
      whereArgs: [id],
    );

    setState(() {
      todos[index]['is_done'] = isDone ? 0 : 1;
    });
  }

  // ───────────── UI DIALOGS ─────────────

  void _showAddTodoDialog() {
    todoController.clear();

    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text("Add Todo"),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: CupertinoTextField(
            controller: todoController,
            placeholder: "Enter todo",
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text("Add"),
            onPressed: () async {
              final text = todoController.text.trim();
              if (text.isEmpty) return;

              await addTodo(text);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showEditDialog(int id, String oldTitle) {
    todoController.text = oldTitle;

    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text("Edit Todo"),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: CupertinoTextField(controller: todoController),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text("Save"),
            onPressed: () async {
              final text = todoController.text.trim();
              if (text.isEmpty) return;

              await editTodoTitle(id, text);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
