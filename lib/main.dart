import 'package:flutter/cupertino.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final title = TextEditingController();
    final description = TextEditingController();

    return CupertinoApp(
      title: 'ToDo and Task Management App',
      debugShowCheckedModeBanner: false,
      home: CupertinoPageScaffold(
        // backgroundColor: CupertinoColors.systemGroupedBackground,
        navigationBar: CupertinoNavigationBar(
          leading: Text("My Tasks"),
          trailing: Icon(CupertinoIcons.person_circle),
        ),
        child: SafeArea(
          child: Home(title: title, description: description),
        ),
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key, required this.title, required this.description});

  final TextEditingController title;
  final TextEditingController description;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<List<dynamic>> taskList = [
    [1, 1, "Task 1", "Description 1", 3, DateTime(2026, 5, 1), "pending"],
    [2, 1, "Task 2", "Description 2", 1, DateTime(2026, 5, 2), "done"],
  ];

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
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 10.0,
                  ),
                  child: Row(
                    children: [
                      // Title + Description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              taskList[i][2],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              taskList[i][3],
                              style: TextStyle(
                                fontSize: 13,
                                // color: CupertinoColors.secondaryLabel,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status badge
                      statusBox(taskList[i][6]),
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

  void _showAddTaskDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text("Add Task"),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            children: [
              CupertinoTextField(
                controller: widget.title,
                placeholder: "Enter task title",
                padding: EdgeInsets.all(10),
              ),
              SizedBox(height: 8),
              CupertinoTextField(
                controller: widget.description,
                placeholder: "Enter task description",
                padding: EdgeInsets.all(10),
              ),
            ],
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
              if (widget.title.text.trim().isNotEmpty &&
                  widget.description.text.trim().isNotEmpty) {
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
          taskList.add([
            taskList.length + 1,
            1,
            widget.title.text,
            widget.description.text,
            4,
            DateTime.now(),
            "pending",
          ]);
          widget.title.text = "";
          widget.description.text = "";
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
}

Widget statusBox(String text) {
  IconData icon;
  Color color;

  switch (text) {
    case "done":
      icon = CupertinoIcons.checkmark_circle_fill;
      color = CupertinoColors.systemGreen;
      break;
    case "in progress":
      icon = CupertinoIcons.clock_fill;
      color = CupertinoColors.systemBlue;
      break;
    case "cancel":
      icon = CupertinoIcons.xmark_circle_fill;
      color = CupertinoColors.systemRed;
      break;
    default:
      icon = CupertinoIcons.circle;
      color = CupertinoColors.systemGrey;
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
