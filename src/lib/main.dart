import 'package:flutter/material.dart';
import 'screens/project_graph.dart';
import 'widgets/app_drawer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WorkGrid',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF607D8B), // пастельно-серо-синий
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String? currentProjectName = "Проект 1"; // тестовое имя
  bool projectOpened = true; // открыт график
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final body = projectOpened
        ? ProjectGraphScreen(projectName: currentProjectName ?? "Безымянный")
        : const Center(child: Text("Выберите проект"));

    return Scaffold(
      appBar: AppBar(title: Text(currentProjectName ?? "Нет активного проекта")),
      drawer: AppDrawer(
        currentProjectName: currentProjectName,
        onCreateProject: () {
          setState(() {
            currentProjectName = "Новый проект";
            projectOpened = true;
          });
        },
      ),
      body: body,
      // Нижняя панель только на экране графика проекта
      bottomNavigationBar: projectOpened
          ? BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (i) => setState(() => currentIndex = i),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Участники'),
                BottomNavigationBarItem(icon: Icon(Icons.workspaces_outline), label: 'Объекты'),
                BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Ресурсы'),
              ],
            )
          : null,
    );
  }
}
