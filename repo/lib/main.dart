import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const WorkgridApp());
}

class WorkgridApp extends StatelessWidget {
  const WorkgridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workgrid Demo',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.dark,
        ),
      ),
      home: const ScheduleScreen(),
    );
  }
}

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime selectedDate = DateTime.now();
  final List<String> users = ["Иван", "Олег", "Анна"];
  Map<String, String> cellStatuses = {};
  List<String> log = [];

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      cellStatuses =
          Map<String, String>.from(prefs.getStringMap("cellStatuses") ?? {});
      log = prefs.getStringList("log") ?? [];
    });
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList("log", log);
    await prefs.setStringMap("cellStatuses", cellStatuses);
  }

  void _setStatus(String user, int hour) {
    String key = "$user-$hour-${selectedDate.toIso8601String()}";
    String? current = cellStatuses[key];
    String next = switch (current) {
      null => "Ожидается",
      "Ожидается" => "В работе",
      "В работе" => "Выполнено",
      _ => "Ожидается"
    };
    setState(() {
      cellStatuses[key] = next;
      log.add("[$selectedDate] $user $hour:00 → $next");
    });
    _saveState();
  }

  Color _statusColor(String? status) {
    switch (status) {
      case "Ожидается":
        return Colors.lightGreen.shade400;
      case "В работе":
        return Colors.grey.shade700;
      case "Выполнено":
        return Colors.green.shade600;
      default:
        return Colors.yellow.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<int> hours = List.generate(11, (i) => 8 + i);

    return Scaffold(
      appBar: AppBar(
        title: Text("График (${_formatDate(selectedDate)})"),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() => selectedDate = DateTime.now());
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "settings") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              } else if (value == "log") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LogScreen(log: log)),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: "settings",
                child: Text("Настройки проекта"),
              ),
              const PopupMenuItem(
                value: "log",
                child: Text("Журнал проекта"),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Row(
            children: [
              TextButton(
                child: const Text("Выбрать дату"),
                onPressed: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    initialDate: selectedDate,
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
              ),
              if (!_isToday(selectedDate))
                TextButton(
                  child: const Text("Сегодня"),
                  onPressed: () =>
                      setState(() => selectedDate = DateTime.now()),
                ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                border: TableBorder.all(color: Colors.grey),
                columns: [
                  const DataColumn(label: Text("Пользователь")),
                  for (var h in hours)
                    DataColumn(label: Text("$h:00")),
                ],
                rows: users.map((user) {
                  return DataRow(
                    cells: [
                      DataCell(Text(user)),
                      for (var h in hours)
                        DataCell(
                          InkWell(
                            onTap: () => _setStatus(user, h),
                            child: Container(
                              color: _statusColor(
                                cellStatuses[
                                    "$user-$h-${selectedDate.toIso8601String()}"],
                              ),
                              height: 40,
                              alignment: Alignment.center,
                            ),
                          ),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime d) {
    DateTime now = DateTime.now();
    return now.year == d.year && now.month == d.month && now.day == d.day;
  }

  String _formatDate(DateTime d) {
    return "${d.day}.${d.month}.${d.year}";
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Настройки проекта")),
      body: const Center(child: Text("Настройки будут тут")),
    );
  }
}

class LogScreen extends StatelessWidget {
  final List<String> log;
  const LogScreen({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Журнал проекта")),
      body: ListView.builder(
        itemCount: log.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(log[index]),
        ),
      ),
    );
  }
}
