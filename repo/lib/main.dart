import 'package:flutter/material.dart';

void main() {
  runApp(const WorkGridApp());
}

class WorkGridApp extends StatelessWidget {
  const WorkGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WorkGrid',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SchedulePage(),
    );
  }
}

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WorkGrid Schedule'),
      ),
      body: const Center(
        child: Text('Demo schedule table goes here'),
      ),
    );
  }
}
