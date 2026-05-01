import 'package:flutter/cupertino.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:todo/database_service.dart';
import 'package:todo/todo_screen.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Brightness _brightness = Brightness.light;

  void _toggleTheme() {
    setState(() {
      _brightness = _brightness == Brightness.light
          ? Brightness.dark
          : Brightness.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'ToDo and Task Management App',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(brightness: _brightness),
      home: Home(onToggleTheme: _toggleTheme),
    );
  }
}

class Home extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const Home({super.key, required this.onToggleTheme});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final title = TextEditingController();
  final description = TextEditingController();
  final searchController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  List<List<dynamic>> taskList = [];
  List<List<dynamic>> filteredList = [];
  Map<String, int> stats = {'total': 0, 'done': 0, 'pending': 0, 'expired': 0};

  @override
  void initState() {
    super.initState();
    loadTasks();
    searchController.addListener(_filterTasks);
  }

  void _filterTasks() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredList = query.isEmpty
          ? taskList
          : taskList.where((t) {
              final ttl = (t[1] as String).toLowerCase();
              final desc = (t[2] as String).toLowerCase();
              return ttl.contains(query) || desc.contains(query);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: const Text("My Tasks"),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: widget.onToggleTheme,
          child: Icon(
            isDark ? CupertinoIcons.sun_max_fill : CupertinoIcons.moon_fill,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildOverview(),
            _buildSearchRow(),
            _buildHeader(),
            Expanded(child: _buildTaskList()),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview() {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? CupertinoColors.darkBackgroundGray
              : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem("Total", stats['total']!, CupertinoColors.systemBlue),
            _statItem("Done", stats['done']!, CupertinoColors.systemGreen),
            _statItem(
              "Pending",
              stats['pending']!,
              CupertinoColors.systemOrange,
            ),
            _statItem("Expired", stats['expired']!, CupertinoColors.systemRed),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          "$value",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  String? _statusFilter;
  final List<String> _statusFilters = [
    'all',
    'not_started',
    'started',
    'in_progress',
    'done',
    'cancelled',
    'expired',
    'due_today',
  ];

  Widget _buildSearchRow() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: CupertinoSearchTextField(
              controller: searchController,
              placeholder: "Search tasks...",
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: _showFilterDialog,
            child: Icon(
              CupertinoIcons.slider_horizontal_3,
              color: _statusFilter != null && _statusFilter != 'all'
                  ? CupertinoColors.activeBlue
                  : CupertinoColors.systemYellow,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        final isDark =
            CupertinoTheme.of(ctx).brightness == Brightness.dark;
        return Container(
          color: isDark
              ? CupertinoColors.darkBackgroundGray
              : CupertinoColors.systemGrey6,
          height: 300,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: isDark
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  CupertinoButton(
                    child: Text(
                      "Reset",
                      style: TextStyle(
                        color: CupertinoColors.activeBlue,
                      ),
                    ),
                    onPressed: () {
                      setState(() => _statusFilter = null);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _statusFilters.length,
                  itemBuilder: (ctx2, i) {
                    final f = _statusFilters[i];
                    final isSelected = (_statusFilter == f) ||
                        (f == 'all' && _statusFilter == null);
                    return CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      onPressed: () {
                        setState(() =>
                            _statusFilter = f == 'all' ? null : f);
                        Navigator.pop(ctx);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            f == 'all' ? 'All' : f.replaceAll('_', ' '),
                            style: TextStyle(
                              color: isSelected
                                  ? CupertinoColors.activeBlue
                                  : (isDark
                                      ? CupertinoColors.white
                                      : CupertinoColors.black),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              CupertinoIcons.check_mark,
                              color: CupertinoColors.activeBlue,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "All Tasks",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _showTaskDialog(),
            child: const Row(
              children: [
                Icon(CupertinoIcons.add, size: 18),
                SizedBox(width: 4),
                Text("Add Task"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    final query = searchController.text.toLowerCase();
    final list = taskList.where((t) {
      final matchesSearch =
          query.isEmpty ||
          (t[1] as String).toLowerCase().contains(query) ||
          (t[2] as String).toLowerCase().contains(query);
      if (_statusFilter == null || _statusFilter == 'all') {
        return matchesSearch;
      }
      final status = getStatus(t);
      return matchesSearch && status == _statusFilter;
    }).toList();

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, i) {
        final t = list[i];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Slidable(
            key: ValueKey(t[0]),
            startActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (_) => _showTaskDialog(task: t),
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
                  onPressed: (_) => _deleteTask(t[0]),
                  backgroundColor: CupertinoColors.destructiveRed,
                  foregroundColor: CupertinoColors.white,
                  icon: CupertinoIcons.delete,
                  label: 'Delete',
                ),
              ],
            ),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              onPressed: () async {
                await Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (_) => TodoScreen(taskID: t[0], title: t[1]),
                  ),
                );
                loadTasks(); // Refresh when returning
              },
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t[1],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${t[2]}  •  ${t[4].year}:${t[4].month.toString().padLeft(2, '0')}:${t[4].day.toString().padLeft(2, '0')}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  statusBox(getStatus(t)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> insertTask(Map<String, dynamic> task) async {
    final db = await DB.database;
    await db.insert('tasks', task);
    loadTasks();
  }

  Future<void> updateTask(Map<String, dynamic> task) async {
    final db = await DB.database;
    await db.update('tasks', task, where: 'id = ?', whereArgs: [task['id']]);
    loadTasks();
  }

  Future<void> _deleteTask(int id) async {
    final db = await DB.database;
    await db.delete('todos', where: 'task_id = ?', whereArgs: [id]);
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
    loadTasks();
  }

  Future<void> loadTasks() async {
    final db = await DB.database;
    final maps = await db.query('tasks', orderBy: 'due_date ASC');
    int done = 0, pending = 0, expired = 0;
    setState(() {
      taskList = List.generate(maps.length, (i) {
        final task = [
          maps[i]['id'],
          maps[i]['title'],
          maps[i]['description'],
          maps[i]['priority'],
          DateTime.parse(maps[i]['due_date'] as String),
          maps[i]['status'] ?? 'pending',
        ];
        final s = getStatus(task);
        if (s == 'done') {
          done++;
        } else if (s == 'expired') {
          expired++;
        } else {
          pending++;
        }
        return task;
      });
      stats = {
        'total': maps.length,
        'done': done,
        'pending': pending,
        'expired': expired,
      };
      _filterTasks();
    });
  }

  String getStatus(List<dynamic> task) {
    final String status = task[5] as String;

    // If status is a final state, return it
    if (status == "done" || status == "cancelled") return status;

    // For active statuses, return them directly (don't override with date)
    if (status == "started" ||
        status == "in_progress" ||
        status == "not_started") {
      return status;
    }

    // Fallback to date-based logic for unknown statuses
    final DateTime date = task[4] as DateTime;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDay = DateTime(date.year, date.month, date.day);
    if (taskDay.isBefore(today)) return "expired";
    if (taskDay == today) return "due_today";
    return status;
  }

  void _showTaskDialog({List<dynamic>? task}) {
    final isEdit = task != null;
    if (isEdit) {
      title.text = task[1] as String;
      description.text = task[2] as String;
      selectedDate = task[4] as DateTime;
    } else {
      title.clear();
      description.clear();
      selectedDate = DateTime.now();
    }

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(isEdit ? "Edit Task" : "Add Task"),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SingleChildScrollView(
            child: Column(
              children: [
                CupertinoTextField(
                  controller: title,
                  placeholder: "Title",
                  padding: const EdgeInsets.all(10),
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: description,
                  placeholder: "Description",
                  padding: const EdgeInsets.all(10),
                ),
                const SizedBox(height: 8),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _showDatePicker(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Date"),
                      Text(
                        "${selectedDate.year}:${selectedDate.month.toString().padLeft(2, '0')}:${selectedDate.day.toString().padLeft(2, '0')}",
                        style: const TextStyle(
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              if (title.text.trim().isEmpty ||
                  description.text.trim().isEmpty) {
                return;
              }
              if (isEdit) {
                updateTask({
                  'id': task[0],
                  'title': title.text.trim(),
                  'description': description.text.trim(),
                  'due_date': selectedDate.toIso8601String(),
                });
              } else {
                insertTask({
                  'title': title.text.trim(),
                  'description': description.text.trim(),
                  'due_date': selectedDate.toIso8601String(),
                  'status': 'not_started',
                  'priority': 4,
                });
              }
              Navigator.pop(ctx);
            },
            child: Text(isEdit ? "Save" : "Add"),
          ),
        ],
      ),
    );
  }

  void _showDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoButton(
                  child: const Text("Done"),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: selectedDate,
                onDateTimeChanged: (d) => setState(() => selectedDate = d),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget statusBox(String text) {
  IconData icon;
  Color color;
  switch (text) {
    case "not_started":
      icon = CupertinoIcons.circle;
      color = CupertinoColors.systemGrey;
      break;
    case "started":
      icon = CupertinoIcons.play_circle;
      color = CupertinoColors.systemBlue;
      break;
    case "in_progress":
      icon = CupertinoIcons.clock_fill;
      color = CupertinoColors.systemIndigo;
      break;
    case "done":
      icon = CupertinoIcons.checkmark_circle_fill;
      color = CupertinoColors.systemGreen;
      break;
    case "cancelled":
      icon = CupertinoIcons.xmark_circle_fill;
      color = CupertinoColors.systemRed;
      break;
    case "expired":
      icon = CupertinoIcons.exclamationmark_circle_fill;
      color = CupertinoColors.systemRed;
      break;
    case "due_today":
      icon = CupertinoIcons.sun_max_fill;
      color = CupertinoColors.systemOrange;
      break;
    default:
      icon = CupertinoIcons.time;
      color = CupertinoColors.systemYellow;
  }
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 4),
      Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}
