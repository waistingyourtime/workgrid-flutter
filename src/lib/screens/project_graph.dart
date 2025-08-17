import 'package:flutter/material.dart';
import '../models/cell.dart';
import '../widgets/cell_editor.dart';

class ProjectGraphScreen extends StatefulWidget {
  final String projectName;
  const ProjectGraphScreen({super.key, required this.projectName});

  @override
  State<ProjectGraphScreen> createState() => _ProjectGraphScreenState();
}

class _ProjectGraphScreenState extends State<ProjectGraphScreen> {
  final List<String> users = ["Иван", "Петр", "Мария"];
  final Map<String, List<Cell>> grid = {};
  final List<int> hours = List.generate(11, (i) => 8 + i); // 08:00–18:00

  @override
  void initState() {
    super.initState();
    for (var user in users) {
      grid[user] = List.generate(hours.length, (i) => Cell());
    }
  }

  void _insertHourForAllBefore(int newHour) {
    // вставляем новый час в начало и добавляем Cell всем пользователям
    for (final u in users) {
      grid[u]!.insert(0, Cell());
    }
    hours.insert(0, newHour);
  }

  void _appendHourForAllAfter(int newHour) {
    // добавляем час в конец и добавляем Cell всем пользователям
    for (final u in users) {
      grid[u]!.add(Cell());
    }
    hours.add(newHour);
  }

  void addHourBefore() {
    setState(() {
      _insertHourForAllBefore(hours.first - 1);
    });
  }

  void addHourAfter() {
    setState(() {
      _appendHourForAllAfter(hours.last + 1);
    });
  }

  Color getCellColor(CellStatus? status) {
    switch (status) {
      case CellStatus.pending:     return Colors.yellow.shade200; // содержимое без статуса
      case CellStatus.inProgress:  return Colors.grey.shade400;   // В работе
      case CellStatus.done:        return Colors.green.shade400;  // Выполнено
      case CellStatus.expected:    return Colors.blue.shade400;   // Ожидается (синий)
      default:                     return Colors.white;           // пустая
    }
  }

  void openCellEditor(String user, int hourIndex) {
    final cell = grid[user]![hourIndex];
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CellEditor(cell: cell)),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    // Узкий столбец имён ~120dp
    Widget nameCell(String user) => SizedBox(
          width: 120,
          child: Tooltip(
            message: user,
            child: Text(
              user,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: users.map((user) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              nameCell(user),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Добавить час перед началом',
                onPressed: addHourBefore,
              ),
              ...List.generate(hours.length, (i) {
                final cell = grid[user]![i];
                return GestureDetector(
                  onTap: () => openCellEditor(user, i),
                  child: Container(
                    width: 80,
                    height: 60,
                    margin: const EdgeInsets.all(1),
                    color: getCellColor(cell.status),
                    child: Center(child: Text("${hours[i]}:00")),
                  ),
                );
              }),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Добавить час после конца',
                onPressed: addHourAfter,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
