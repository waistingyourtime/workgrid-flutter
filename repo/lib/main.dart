import 'dart:convert';
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
    // Статусы ячеек храним одной JSON-строкой
    final cellsJson = prefs.getString("cellStatuses");
    if (cellsJson != null && cellsJson.isNotEmpty) {
      final raw = jsonDecode(cellsJson);
      if (raw is Map) {
        cellStatuses = raw.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    }
    // Журнал — списком строк
    log = prefs.getStringList("log") ?? [];
    setState(() {});
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("cellStatuses", jsonEncode(cellStatuses));
    await prefs.setStringList("log", log);
  }

  void _setStatus(String user, int hour) {
    final dayKey = _isoDate(selectedDate); // чтобы ключи были короче
    final key = "$user-$hour-$dayKey";
    final current = cellStatuses[key];
    final next = switch (current) {
      null => "Ожидается",
      "Ожидается" => "В работе",
      "В работе" => "Выполнено",
      _ => "Ожидается",
    };
    setState(() {
      cellStatuses[key] = next;
      log.add("[$dayKey] $user $hour:00 → $next");
    });
    _saveState();
  }

  Color _statusColor(String? status) {
    switch (status) {
      case "Ожидается":
        return Colors.lightGreen.shade400.withOpacity(0.30);
      case "В работе":
        return Colors.blueGrey.shade600.withOpacity(0.35);
      case "Выполнено":
        return Colors.green.shade600.withOpacity(0.35);
      default:
        return Colors.amber.shade700.withOpacity(0.30); // «Без статуса»
    }
  }

  @override
  Widget build(BuildContext context) {
    final hours = List.generate(11, (i) => 8 + i); // 08..18

    return Scaffold(
      appBar: AppBar(
        title: Text("График (${_formatDate(selectedDate)})"),
        actions: [
          // Кнопка «Сегодня»
          if (!_isToday(selectedDate))
            TextButton(
              onPressed: () => setState(() => selectedDate = DateTime.now()),
              child: const Text("Сегодня", style: TextStyle(color: Colors.white)),
            ),
          // Выбор даты в меню
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                initialDate: selectedDate,
              );
              if (picked != null) setState(() => selectedDate = picked);
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "settings") {
                Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()));
              } else if (value == "log") {
                Navigator.push(context,
                  MaterialPageRoute(builder: (_) => LogScreen(log: log)));
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: "settings", child: Text("Настройки проекта")),
              PopupMenuItem(value: "log", child: Text("Журнал проекта")),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Полоса с выбранной датой
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _Chip(text: _formatDate(selectedDate)),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      initialDate: selectedDate,
                    );
                    if (picked != null) setState(() => selectedDate = picked);
                  },
                  icon: const Icon(Icons.event),
                  label: const Text("Дата"),
                ),
              ],
            ),
          ),

          // Таблица
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                border: TableBorder.all(color: Colors.grey.shade700),
                columns: [
                  const DataColumn(label: Text("Пользователь")),
                  for (final h in hours) DataColumn(label: Text("$h:00")),
                ],
                rows: users.map((user) {
                  return DataRow(
                    cells: [
                      DataCell(Text(user)),
                      for (final h in hours)
                        DataCell(
                          InkWell(
                            onTap: () => _setStatus(user, h),
                            child: Container(
                              color: _statusColor(
                                cellStatuses["$user-$h-${_isoDate(selectedDate)}"],
                              ),
                              height: 40,
                              alignment: Alignment.center,
                              child: Text(
                                cellStatuses["$user-$h-${_isoDate(selectedDate)}"] ?? "",
                                style: const TextStyle(fontSize: 12),
                              ),
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
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "График"),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "Участники"),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: "Ресурсы"),
        ],
        currentIndex: 0,
        onTap: (i) {
          if (i == 1) {
            Navigator.push(context,
              MaterialPageRoute(builder: (_) => const MembersScreen()));
          } else if (i == 2) {
            Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ResourcesScreen()));
          }
        },
      ),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return now.year == d.year && now.month == d.month && now.day == d.day;
  }

  String _formatDate(DateTime d) => "${d.day}.${d.month}.${d.year}";
  String _isoDate(DateTime d) => "${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}";
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
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
        itemBuilder: (context, i) => ListTile(title: Text(log[i])),
      ),
    );
  }
}

class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final members = const ["Иван", "Олег", "Анна", "Юлія"];
    return Scaffold(
      appBar: AppBar(title: const Text("Участники")),
      body: ListView.separated(
        itemCount: members.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) => ListTile(
          title: Text(members[i]),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});
  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}
class _ResourcesScreenState extends State<ResourcesScreen> {
  final items = <(String, bool)>[
    ('Кабель 3х2.5', true),
    ('Перчатки', false),
    ('Болгарка', true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ресурсы")),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (c, i) {
          final e = items[i];
          return SwitchListTile(
            title: Text(e.$1),
            value: e.$2,
            onChanged: (v) => setState(() => items[i] = (e.$1, v)),
          );
        },
      ),
    );
  }
}
