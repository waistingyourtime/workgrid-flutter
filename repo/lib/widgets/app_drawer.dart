import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final String? currentProjectName;
  final VoidCallback onCreateProject;

  const AppDrawer({
    super.key,
    required this.currentProjectName,
    required this.onCreateProject,
  });

  @override
  Widget build(BuildContext context) {
    final hasProject =
        currentProjectName != null && currentProjectName!.isNotEmpty;

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
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('Список проектов'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Настройки'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('Обратная связь'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.add_box_outlined),
            title: const Text('Создать проект'),
            onTap: onCreateProject,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('О приложении'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
