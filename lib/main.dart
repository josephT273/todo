import 'package:flutter/cupertino.dart';
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'ToDo and Task Management App',
      debugShowCheckedModeBanner: false,
      home: CupertinoPageScaffold(
        // backgroundColor: CupertinoColors.systemGroupedBackground,
        navigationBar: CupertinoNavigationBar(
          leading: Text("My Tasks"),
          trailing: Icon(CupertinoIcons.person_circle),
        ),
        child: SafeArea(child: Home()),
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController title = TextEditingController();
  final TextEditingController description = TextEditingController();
  DateTime selectedDate = DateTime.now();

  List<List<dynamic>> taskList = [];

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Search + Filter Row ──
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: CupertinoSearchTextField(placeholder: "Search tasks..."),
              ),
              SizedBox(width: 8),
              CupertinoButton(
                padding: EdgeInsets.all(8),
                onPressed: () {},
                child: Icon(
                  CupertinoIcons.slider_horizontal_3,
                  color: CupertinoColors.systemYellow,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 10),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "All Tasks",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _showAddTaskDialog(context),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.add, size: 18),
                    SizedBox(width: 4),
                    Text("Add Task"),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Task List ──
        Expanded(
          child: ListView.builder(
            itemCount: taskList.length,
            itemBuilder: (context, i) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: CupertinoButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (context) => TodoScreen(
                          taskID: taskList[i][0],
                          title: taskList[i][1],
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      // Title + Description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              taskList[i][1], // title
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            SizedBox(height: 4),

                            Row(
                              children: [
                                Text(
                                  taskList[i][2], // description
                                  style: TextStyle(fontSize: 13),
                                ),
                                Text(
                                  "  •  ${taskList[i][4].year}:${taskList[i][4].month.toString().padLeft(2, '0')}:${taskList[i][4].day.toString().padLeft(2, '0')}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Status badge
                      statusBox(getStatus(taskList[i])),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<int> insertTask(Map<String, dynamic> task) async {
    final db = await DB.database;
    return await db.insert('tasks', task);
  }

  Future<int> deleteTask(Map<String, dynamic> task) async {
    final db = await DB.database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [task['id']]);
  }

  Future<int> updateTask(Map<String, dynamic> task) async {
    final db = await DB.database;
    return await db.update(
      'tasks',
      task,
      where: 'id = ?',
      whereArgs: [task['id']],
    );
  }

  Future<int> loadTasks() async {
    final db = await DB.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      orderBy: 'due_date ASC',
    );
    setState(() {
      taskList = List.generate(maps.length, (i) {
        return [
          maps[i]['id'],
          maps[i]['title'],
          maps[i]['description'],
          maps[i]['priority'],
          DateTime.parse(maps[i]['due_date']),
          maps[i]['status'],
        ];
      });
    });
    return maps.length;
  }

  String getStatus(List task) {
    final DateTime date = task[4];
    final String status = task[5];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDay = DateTime(date.year, date.month, date.day);
    if (status == "done") return "done";
    if (status == "cancelled") return "cancelled";
    if (taskDay.isBefore(today)) return "expired";
    if (taskDay == today) return "due_today";
    return status;
  }

  void _showAddTaskDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text("Add Task"),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                CupertinoTextField(
                  controller: title,
                  placeholder: "Enter task title",
                  padding: EdgeInsets.all(10),
                ),
                SizedBox(height: 8),
                CupertinoTextField(
                  controller: description,
                  placeholder: "Enter task description",
                  padding: EdgeInsets.all(10),
                ),
                SizedBox(width: 8),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _showTimePicker(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Date"),

                      // show selected date and time in "YY:MM:DD" format
                      Text(
                        "${selectedDate.year.toString()}:${selectedDate.month.toString().padLeft(2, '0')}:${selectedDate.day.toString().padLeft(2, '0')}",
                        style: TextStyle(color: CupertinoColors.systemGrey),
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
            onPressed: () => Navigator.pop(dialogContext, "cancel"),
            child: Text("Cancel"),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              if (title.text.trim().isNotEmpty &&
                  description.text.trim().isNotEmpty &&
                  !selectedDate.isBefore(DateTime.now())) {
                Navigator.pop(dialogContext, "add");
              }
            },
            child: Text("Add"),
          ),
        ],
      ),
    ).then((returnValue) {
      if (!context.mounted) return;

      if (returnValue == "add") {
        setState(() {
          insertTask({
            'title': title.text.trim(),
            'description': description.text.trim(),
            'due_date': selectedDate.toIso8601String(),
          });
          loadTasks();
          title.text = "";
          description.text = "";
        });

        // Cupertino toast-style feedback
        showCupertinoDialog(
          context: context,
          barrierDismissible: true,
          builder: (_) => CupertinoAlertDialog(
            content: Text("✅ Task added"),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              ),
            ],
          ),
        );
      }
    });
  }

  void _showTimePicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) {
        return Container(
          height:
              MediaQuery.of(context).size.height *
              0.5, // half screen (can make 1.0)
          color: CupertinoColors.black,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: Text("Cancel"),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: Text("Done"),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  use24hFormat: false,
                  initialDateTime: selectedDate,
                  onDateTimeChanged: (date) {
                    setState(() {
                      selectedDate = date;
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
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
      SizedBox(width: 4),
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
