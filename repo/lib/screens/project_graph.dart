import 'package:flutter/material.dart';
import '../models/cell.dart';
import '../models/work_object.dart';
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

  void addHourBefore(String user) {
    setState(() {
      hours.insert(0, hours.first - 1);
      grid[user]!.insert(0, Cell());
    });
  }

  void addHourAfter(String user) {
    setState(() {
      hours.add(hours.last + 1);
      grid[user]!.add(Cell());
    });
  }

  Color getCellColor(CellStatus? status) {
    switch (status) {
      case CellStatus.pending:
        return Colors.yellow.shade200;
      case CellStatus.inProgress:
        return Colors.grey.shade400;
      case CellStatus.done:
        return Colors.green.shade400;
      case CellStatus.expected:
        return Colors.blue.shade400; // Ожидается = синий
      default:
        return Colors.white;
    }
  }

  void openCellEditor(String user, int hourIndex) {
    final cell = grid[user]![hourIndex];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CellEditor(cell: cell),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: users.map((user) {
          return Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => addHourBefore(user),
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
                onPressed: () => addHourAfter(user),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
