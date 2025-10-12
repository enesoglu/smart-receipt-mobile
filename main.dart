import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.cyan),
      home: Scaffold(
        backgroundColor: Colors.cyan[50],
        appBar: AppBar(title: Center(child: Text("Hello World"))),
        floatingActionButton: FloatingActionButton(
          onPressed: printHelloWorld,
          child: Icon(Icons.print),
        ),
      ),
    );
  }
}

void printHelloWorld() {
  print("Hello World!");
}
