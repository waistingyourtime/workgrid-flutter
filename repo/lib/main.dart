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
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueGrey,
        scaffoldBackgroundColor: Colors.grey[900],
      ),
      home: const SchedulePage(),
    );
  }
}

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Дата: ${selectedDate.toLocal().toString().split(' ')[0]}"),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                selectedDate = DateTime.now();
              });
            },
            child: const Text("Сегодня", style: TextStyle(color: Colors.white)),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() {
                  selectedDate = picked;
                });
              }
            },
          ),
        ],
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
        ),
        itemCount: 50,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueGrey),
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey[850],
            ),
            child: Center(child: Text("Ячейка $index")),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Участники"),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: "Объекты"),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: "Ресурсы"),
        ],
      ),
    );
  }
}
