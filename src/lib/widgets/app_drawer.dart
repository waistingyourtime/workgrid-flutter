import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final String? currentProjectName;
  final VoidCallback onCreateProject;

  const AppDrawer({
    super.key,
    required this.currentProjectName,
    required this.onCreateProject,
  });

  void _openStub(BuildContext context, String title) {
    Navigator.pop(context); // закрыть drawer
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _StubScreen(title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasProject = currentProjectName != null && currentProjectName!.isNotEmpty;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blueGrey),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                hasProject ? currentProjectName! : 'Нет активного проекта',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text('Управление аккаунтом'),
            onTap: () => _openStub(context, 'Управление аккаунтом'),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('Список проектов'),
            onTap: () => _openStub(context, 'Список проектов'),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Настройки'),
            onTap: () => _openStub(context, 'Настройки'),
          ),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('Обратная связь'),
            onTap: () => _openStub(context, 'Обратная связь'),
          ),
          // новая кнопка "Создать проект" — над "О приложении"
          ListTile(
            leading: const Icon(Icons.add_box_outlined),
            title: const Text('Создать проект'),
            onTap: onCreateProject,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('О приложении'),
            onTap: () => _openStub(context, 'О приложении'),
          ),
        ],
      ),
    );
  }
}

class _StubScreen extends StatelessWidget {
  final String title;
  const _StubScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title (заглушка)')),
    );
  }
}
