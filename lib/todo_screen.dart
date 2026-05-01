import 'package:flutter/cupertino.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
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
  final controller = TextEditingController();

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
          onPressed: _showAddDialog,
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
                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: CupertinoColors.systemGrey4,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Slidable(
                      key: ValueKey(todo['id']),
                      startActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (_) => _showEditDialog(
                              todo['id'],
                              todo['title'],
                            ),
                            backgroundColor: CupertinoColors.activeBlue,
                            foregroundColor: CupertinoColors.white,
                            icon: CupertinoIcons.pencil,
                            label: 'Edit',
                          ),
                        ],
                      ),
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (_) => _deleteTodo(todo['id']),
                            backgroundColor: CupertinoColors.destructiveRed,
                            foregroundColor: CupertinoColors.white,
                            icon: CupertinoIcons.delete,
                            label: 'Delete',
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 12,
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => _toggleStatus(todo['id']),
                              child: Icon(
                                todo['is_done'] == 1
                                    ? CupertinoIcons.checkmark_circle_fill
                                    : CupertinoIcons.circle,
                                color: todo['is_done'] == 1
                                    ? CupertinoColors.systemGreen
                                    : CupertinoColors.systemGrey,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                todo['title'],
                                style: TextStyle(
                                  fontSize: 16,
                                  decoration: todo['is_done'] == 1
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

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

  Future<void> _deleteTodo(int id) async {
    final db = await DB.database;
    await db.delete('todos', where: 'id = ?', whereArgs: [id]);
    setState(() => todos.removeWhere((t) => t['id'] == id));
  }

  Future<void> _addTodo(String title) async {
    final db = await DB.database;
    final id = await db.insert('todos', {
      'task_id': widget.taskID,
      'title': title,
      'is_done': 0,
    });
    setState(() => todos.add({
          'id': id,
          'task_id': widget.taskID,
          'title': title,
          'is_done': 0,
        }));

    // Update task: set to in_progress & update date to now (handles expired/done tasks)
    await db.update(
      'tasks',
      {'status': 'in_progress', 'due_date': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [widget.taskID],
    );
  }

  Future<void> _editTodo(int id, String newTitle) async {
    final db = await DB.database;
    await db.update(
      'todos',
      {'title': newTitle},
      where: 'id = ?',
      whereArgs: [id],
    );
    setState(() {
      final i = todos.indexWhere((t) => t['id'] == id);
      if (i != -1) todos[i]['title'] = newTitle;
    });
  }

  Future<void> _toggleStatus(int id) async {
    final i = todos.indexWhere((t) => t['id'] == id);
    if (i == -1) return;
    final newVal = todos[i]['is_done'] == 1 ? 0 : 1;
    final db = await DB.database;
    await db.update(
      'todos',
      {'is_done': newVal},
      where: 'id = ?',
      whereArgs: [id],
    );
    setState(() => todos[i]['is_done'] = newVal);

    // Update task status based on todos
    if (todos.isEmpty) return;
    final allDone = todos.every((t) => t['is_done'] == 1);
    if (allDone) {
      await db.update(
        'tasks',
        {'status': 'done'},
        where: 'id = ?',
        whereArgs: [widget.taskID],
      );
    } else {
      await db.update(
        'tasks',
        {'status': 'in_progress'},
        where: 'id = ? AND status = ?',
        whereArgs: [widget.taskID, 'done'],
      );
    }
  }

  void _showAddDialog() {
    controller.clear();
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text("Add Todo"),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: CupertinoTextField(
            controller: controller,
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
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              _addTodo(text);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showEditDialog(int id, String oldTitle) {
    controller.text = oldTitle;
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text("Edit Todo"),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: CupertinoTextField(controller: controller),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text("Save"),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              _editTodo(id, text);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
