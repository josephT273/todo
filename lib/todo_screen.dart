import 'package:flutter/cupertino.dart';

class TodoScreen extends StatelessWidget {
  final String data;

  const TodoScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(data)),
      child: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return Text('Hello, $data!');
        },
      ),
    );
  }
}
