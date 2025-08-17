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

  void addObject() {
    if (newObjectName.isEmpty) return;
    final newObj = WorkObject(id: UniqueKey().toString(), title: newObjectName);
    setState(() {
      widget.cell.objects = [...widget.cell.objects, newObj];
      widget.cell.status ??= CellStatus.pending;
      newObjectName = '';
    });
  }

  void toggleTask(WorkObject obj, NoteItem item) {
    setState(() {
      item.done = !item.done;
    });
  }

  void toggleResource(WorkObject obj, NoteItem item) {
    setState(() {
      item.done = !item.done;
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
            TextField(
              decoration: const InputDecoration(
                  labelText: 'Название объекта', border: OutlineInputBorder()),
              onChanged: (v) => setState(() => newObjectName = v),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: addObject,
              icon: const Icon(Icons.add),
              label: const Text("Добавить"),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: objects.isEmpty
                  ? const Center(child: Text("Нет объектов"))
                  : ListView.builder(
                      itemCount: objects.length,
                      itemBuilder: (_, i) {
                        final obj = objects[i];
                        return ListTile(
                          title: Text(obj.title),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ObjectEditor(obj: obj),
                              ),
                            ).then((_) => setState(() {}));
                          },
                        );
                      },
                    ),
            )
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
  String newTask = '';
  String newResource = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.obj.title)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Text("Задания",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ...widget.obj.tasks.map((t) => CheckboxListTile(
                value: t.done,
                onChanged: (_) => setState(() => t.done = !t.done),
                title: Text(t.text),
              )),
          TextField(
            decoration: const InputDecoration(labelText: 'Новое задание'),
            onChanged: (v) => newTask = v,
            onSubmitted: (v) {
              if (v.isNotEmpty) {
                setState(() {
                  widget.obj.tasks
                      .add(NoteItem(id: UniqueKey().toString(), text: v));
                });
              }
            },
          ),
          const SizedBox(height: 16),
          const Text("Ресурсы",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ...widget.obj.resources.map((r) => CheckboxListTile(
                value: r.done,
                onChanged: (_) => setState(() => r.done = !r.done),
                title: Text(r.text),
              )),
          TextField(
            decoration: const InputDecoration(labelText: 'Новый ресурс'),
            onChanged: (v) => newResource = v,
            onSubmitted: (v) {
              if (v.isNotEmpty) {
                setState(() {
                  widget.obj.resources
                      .add(NoteItem(id: UniqueKey().toString(), text: v));
                });
              }
            },
          ),
        ],
      ),
    );
  }
}
