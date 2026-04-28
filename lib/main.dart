import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final title = TextEditingController();
    final description = TextEditingController();

    return MaterialApp(
      title: 'ToDo and Task Management App',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          elevation: 0,
          title: Text("My Tasks"),
          actions: [CircleAvatar(child: Icon(Icons.person))],
        ),

        body: Home(title: title, description: description),
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
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search tasks...",
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                      prefixIcon: Icon(Icons.search),
                    ),
                    // style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.filter_alt_sharp, color: Colors.amber),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("All Tasks", style: TextStyle(fontWeight: FontWeight(700))),
              TextButton.icon(
                icon: Icon(Icons.add),
                label: Text("Add Task"),
                onPressed: () {
                  showDialog<String>(
                    context: context, // ✅ now valid
                    builder: (dialogContext) => AlertDialog(
                      title: Text("Add Task"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: widget.title,
                            decoration: InputDecoration(
                              hintText: "Enter task title",
                            ),
                          ),

                          TextField(
                            controller: widget.description,
                            decoration: InputDecoration(
                              hintText: "Enter task description",
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(dialogContext, "cancel"),
                          child: Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => {
                            if (widget.title.text.isNotEmpty &&
                                widget.description.text.isNotEmpty)
                              {Navigator.pop(dialogContext, "add")},
                          },
                          child: Text("Add"),
                        ),
                      ],
                    ),
                  ).then((returnValue) {
                    if (!context.mounted) return;

                    // [1, 1, "Task 1", "Description 1", 3, DateTime(2026, 5, 1), "pending"]
                    if (returnValue == "add") {
                      taskList.add([
                        taskList.length + 1,
                        1,
                        widget.title.text,
                        widget.description.text,
                        4,
                        DateTime.now(),
                        "pending",
                      ]);
                      setState(() {
                        widget.title.text = "";
                        widget.description.text = "";
                      });
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text("Task added")));
                    }
                  });
                },
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            itemCount: taskList.length,
            itemBuilder: (BuildContext context, int i) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    // leading: Checkbox(value: i % 2 == 0, onChanged: (value) {}),
                    title: Text(taskList[i][2]),
                    subtitle: Text(taskList[i][3]),
                    trailing: statusBox(taskList[i][6]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

Widget statusBox(String text) {
  Widget icon = Icon(Icons.pending);
  switch (text) {
    case "done":
      icon = Icon(Icons.done);
      break;
    case "in progress":
      icon = Icon(Icons.timer);
    case "cancel":
      icon = Icon(Icons.cancel);
    default:
      icon = Icon(Icons.pending);
  }
  return TextButton.icon(
    onPressed: () {},
    label: Text(text.toUpperCase()),
    icon: icon,
  );
}
