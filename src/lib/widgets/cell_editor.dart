import 'package:flutter/material.dart';
import '../models/cell.dart';
import '../models/work_object.dart';
import '../models/note_item.dart';

class CellEditor extends StatefulWidget {
  final Cell cell;
  const CellEditor({super.key, required this.cell});

  @override
  State<CellEditor> createState() => _CellEditorState();
}

class _CellEditorState extends State<CellEditor> {
  String newObjectName = '';

  void addObject() async {
    if (newObjectName.isEmpty) return;
    final newObj = WorkObject(id: UniqueKey().toString(), title: newObjectName);
    setState(() {
      widget.cell.objects = [...widget.cell.objects, newObj];
      widget.cell.status ??= CellStatus.pending; // ячейка становится "жёлтой"
      newObjectName = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final objects = widget.cell.objects;

    return Scaffold(
      appBar: AppBar(title: const Text("Редактор ячейки")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // строка названия + кнопка "Добавить"
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Название объекта',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => newObjectName = v),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: addObject,
                  icon: const Icon(Icons.add),
                  label: const Text("Добавить"),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Expanded(
              child: objects.isEmpty
                  ? const Center(child: Text("Нет объектов"))
                  : ListView.builder(
                      itemCount: objects.length,
                      itemBuilder: (_, i) {
                        final obj = objects[i];
                        return GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ObjectEditor(obj: obj),
                              ),
                            );
                            if (!mounted) return;
                            setState(() {});
                          },
                          onLongPressStart: (details) async {
                            final selected = await showMenu<String>(
                              context: context,
                              position: RelativeRect.fromLTRB(
                                details.globalPosition.dx,
                                details.globalPosition.dy,
                                details.globalPosition.dx,
                                details.globalPosition.dy,
                              ),
                              items: const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Редактировать'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Удалить'),
                                ),
                              ],
                            );
                            if (!mounted) return;
                            if (selected == 'edit') {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ObjectEditor(obj: obj),
                                ),
                              );
                              if (!mounted) return;
                              setState(() {});
                            } else if (selected == 'delete') {
                              setState(() {
                                widget.cell.objects.removeAt(i);
                                if (widget.cell.objects.isEmpty) {
                                  widget.cell.status = null; // обнуляем статус
                                }
                              });
                            }
                          },
                          child: ListTile(
                            title: Text(obj.title),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class ObjectEditor extends StatefulWidget {
  final WorkObject obj;
  const ObjectEditor({super.key, required this.obj});

  @override
  State<ObjectEditor> createState() => _ObjectEditorState();
}

class _ObjectEditorState extends State<ObjectEditor> {
  @override
  Widget build(BuildContext context) {
    String newTask = '';
    String newResource = '';

    return Scaffold(
      appBar: AppBar(title: Text(widget.obj.title)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Text(
            "Задания",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          ...widget.obj.tasks.map(
            (t) => CheckboxListTile(
              value: t.done,
              onChanged: (_) => setState(() => t.done = !t.done),
              title: Text(t.text),
            ),
          ),
          TextField(
            decoration: const InputDecoration(labelText: 'Новое задание'),
            onSubmitted: (v) {
              if (v.isNotEmpty) {
                setState(() {
                  widget.obj.tasks.add(NoteItem(id: UniqueKey().toString(), text: v));
                });
              }
            },
          ),
          const SizedBox(height: 16),
          const Text(
            "Ресурсы",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          ...widget.obj.resources.map(
            (r) => CheckboxListTile(
              value: r.done,
              onChanged: (_) => setState(() => r.done = !r.done),
              title: Text(r.text),
            ),
          ),
          TextField(
            decoration: const InputDecoration(labelText: 'Новый ресурс'),
            onSubmitted: (v) {
              if (v.isNotEmpty) {
                setState(() {
                  widget.obj.resources.add(NoteItem(id: UniqueKey().toString(), text: v));
                });
              }
            },
          ),
        ],
      ),
    );
  }
}
