import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(WorkGridApp(prefs: prefs));
}

class WorkGridApp extends StatelessWidget {
  final SharedPreferences prefs;
  const WorkGridApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WorkGrid',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4E8DFC),
          secondary: Color(0xFF7AA4FF),
          surface: Color(0xFF262B33),
          background: Color(0xFF20242B),
        ),
        scaffoldBackgroundColor: const Color(0xFF20242B),
      ),
      home: SchedulePage(prefs: prefs),
    );
  }
}

/* ====================== МОДЕЛИ / ХРАНИЛИЩЕ ====================== */

enum CellStatus { empty, awaiting, inWork, done, warn }
String statusLabel(CellStatus s) => switch (s) {
  CellStatus.empty => '',
  CellStatus.awaiting => 'Ожидается',
  CellStatus.inWork => 'В работе',
  CellStatus.done => 'Выполнено',
  CellStatus.warn => 'Без статуса',
};

class ChecklistItem {
  String text;
  bool checked;
  ChecklistItem(this.text, this.checked);

  Map<String, dynamic> toJson() => {'text': text, 'checked': checked};
  static ChecklistItem fromJson(Map<String, dynamic> j) =>
      ChecklistItem(j['text'] as String, j['checked'] as bool);
}

class Storage {
  final SharedPreferences prefs;
  Storage(this.prefs);

  String iso(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  /* --- статусы и заметки ячеек --- */
  Map<String, String> loadStatuses(DateTime day) {
    final s = prefs.getString('cells:${iso(day)}');
    return (s == null || s.isEmpty) ? {} : Map<String, String>.from(jsonDecode(s));
  }
  Future<void> saveStatuses(DateTime day, Map<String, String> data) =>
      prefs.setString('cells:${iso(day)}', jsonEncode(data));

  Map<String, String> loadNotes(DateTime day) {
    final s = prefs.getString('notes:${iso(day)}');
    return (s == null || s.isEmpty) ? {} : Map<String, String>.from(jsonDecode(s));
  }
  Future<void> saveNotes(DateTime day, Map<String, String> data) =>
      prefs.setString('notes:${iso(day)}', jsonEncode(data));

  /* --- чеклисты ресурсов: общие для даты и по объектам --- */
  List<ChecklistItem> loadChecklist(DateTime day, {String? objectId}) {
    final key = objectId == null
        ? 'reslist:${iso(day)}'
        : 'reslist:${iso(day)}:obj:$objectId';
    final s = prefs.getString(key);
    if (s == null || s.isEmpty) return <ChecklistItem>[];
    final raw = jsonDecode(s) as List;
    return raw.map((e) => ChecklistItem.fromJson(Map<String, dynamic>.from(e))).toList();
  }
  Future<void> saveChecklist(DateTime day, List<ChecklistItem> list, {String? objectId}) {
    final key = objectId == null
        ? 'reslist:${iso(day)}'
        : 'reslist:${iso(day)}:obj:$objectId';
    return prefs.setString(key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  /* --- журнал --- */
  List<String> loadJournal() => prefs.getStringList('journal') ?? <String>[];
  Future<void> addJournal(String text) async {
    final list = loadJournal();
    list.insert(0, "${DateTime.now().toIso8601String()} — $text");
    await prefs.setStringList('journal', list.take(300).toList());
  }
}

/* ====================== СТРАНИЦА ГРАФИКА ====================== */

class SchedulePage extends StatefulWidget {
  final SharedPreferences prefs;
  const SchedulePage({super.key, required this.prefs});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  late final Storage store;
  DateTime day = _today();
  final users = const ["Иван", "Олег", "Анна", "Юлія"];
  final hours = List<int>.generate(11, (i) => 8 + i); // 08..18

  final objects = const <(String id, String name)>[
    ('obj101', 'Объект 101'),
    ('s3', 'Склад 3'),
    ('sectB', 'Участок B'),
  ];

  Map<String, String> statuses = {}; // key: user:hour
  Map<String, String> notes = {};    // key: user:hour

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void initState() {
    super.initState();
    store = Storage(widget.prefs);
    _loadDay();
  }

  Future<void> _loadDay() async {
    statuses = store.loadStatuses(day);
    notes = store.loadNotes(day);
    setState(() {});
  }

  Future<void> _saveDay() async {
    await store.saveStatuses(day, statuses);
    await store.saveNotes(day, notes);
  }

  String _key(String u, int h) => "$u:$h";
  bool get _isToday =>
      day.year == _today().year &&
      day.month == _today().month &&
      day.day == _today().day;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _MainDrawer(
        onOpenJournal: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => JournalPage(prefs: widget.prefs),
          ));
        },
        onOpenGeneralResources: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => ChecklistScreen(
              title: 'Ресурсы (дата)',
              day: day,
              store: store,
              objectId: null,
            ),
          ));
        },
        onOpenObjects: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => ObjectsScreen(
              day: day,
              objects: objects,
              store: store,
            ),
          ));
        },
      ),
      appBar: AppBar(
        title: const Text('WorkGrid · График'),
        actions: [
          IconButton(
            tooltip: 'Выбрать дату',
            icon: const Icon(Icons.event),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: day,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => day = DateTime(picked.year, picked.month, picked.day));
                await _loadDay();
                await store.addJournal('Выбрана дата ${store.iso(day)}');
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Row(
              children: [
                _Chip(text: _formatDate(day)),
                const SizedBox(width: 8),
                if (!_isToday)
                  FilledButton(
                    onPressed: () async {
                      setState(() => day = _today());
                      await _loadDay();
                      await store.addJournal('Переход на текущую дату ${store.iso(day)}');
                    },
                    child: const Text('Сегодня'),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: _grid(),
    );
  }

  /* ---------- сетка с БОЛЬШИМИ ячейками ---------- */
  Widget _grid() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _HeaderCell(text: 'Участники', flex: 2),
            for (final h in hours) _HeaderCell(text: '${h.toString().padLeft(2, '0')}:00'),
          ]),
          const SizedBox(height: 6),
          for (final u in users) _rowForUser(u),
        ],
      ),
    );
  }

  Widget _rowForUser(String user) {
    final border = const BorderSide(color: Color(0xFF3A414D), width: 1);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 220,
          height: 96,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2B313A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF3A414D)),
          ),
          margin: const EdgeInsets.only(bottom: 8, right: 8),
          child: Row(
            children: [
              _Avatar(text: user.characters.first.toUpperCase()),
              const SizedBox(width: 10),
              Expanded(
                child: Text(user, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
        for (final h in hours)
          _BigCell(
            status: _statusOf(user, h),
            note: notes[_key(user, h)],
            onTap: () => _openCellCard(user, h),
            onLongPress: () => _openStatusMenu(user, h),
            border: border,
          ),
      ],
    );
  }

  CellStatus _statusOf(String u, int h) {
    final v = statuses[_key(u, h)];
    return switch (v) {
      'awaiting' => CellStatus.awaiting,
      'inWork'   => CellStatus.inWork,
      'done'     => CellStatus.done,
      'warn'     => CellStatus.warn,
      _          => CellStatus.empty,
    };
  }

  Future<void> _openStatusMenu(String user, int h) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF262B33),
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final s in CellStatus.values)
            ListTile(
              title: Text(statusLabel(s).isEmpty ? 'Очистить (пусто)' : statusLabel(s)),
              onTap: () => Navigator.pop(c, s.name),
            ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.arrow_forward),
            title: const Text('Копировать → следующий час'),
            onTap: () => Navigator.pop(c, 'copy'),
          ),
        ]),
      ),
    );
    if (selected == null) return;

    if (selected == 'copy') {
      final v = statuses[_key(user, h)];
      if (v != null) {
        statuses[_key(user, h + 1)] = v;
        await _saveDay();
        await store.addJournal('Копирование $user $h:00 → ${h + 1}:00 (${store.iso(day)})');
        setState(() {});
      }
      return;
    }

    final st = CellStatus.values.firstWhere((e) => e.name == selected);
    if (st == CellStatus.empty) {
      statuses.remove(_key(user, h));
    } else {
      statuses[_key(user, h)] = st.name;
    }
    await _saveDay();
    await store.addJournal('Статус $user $h:00 = ${statusLabel(st)} (${store.iso(day)})');
    setState(() {});
  }

  Future<void> _openCellCard(String user, int h) async {
    final key = _key(user, h);
    final st = _statusOf(user, h);
    final controller = TextEditingController(text: notes[key] ?? '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF262B33),
      showDragHandle: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 8,
            bottom: MediaQuery.of(_).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$user — ${h.toString().padLeft(2, '0')}:00', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Text('Статус: '),
                  Text(statusLabel(st).isEmpty ? '—' : statusLabel(st), style: const TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  FilledButton.tonal(
                    onPressed: () {
                      Navigator.pop(_);
                      _openStatusMenu(user, h);
                    },
                    child: const Text('Изменить статус'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Заметка/содержимое:'),
              const SizedBox(height: 6),
              TextField(
                controller: controller,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  filled: true,
                  border: OutlineInputBorder(),
                  hintText: 'Добавьте описание…',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(onPressed: () => controller.clear(), child: const Text('Очистить')),
                  const Spacer(),
                  FilledButton(
                    onPressed: () async {
                      final text = controller.text.trim();
                      if (text.isEmpty) { notes.remove(key); } else { notes[key] = text; }
                      await _saveDay();
                      await store.addJournal('Обновлена заметка $user $h:00 (${store.iso(day)})');
                      if (mounted) Navigator.pop(_);
                      setState(() {});
                    },
                    child: const Text('Сохранить'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime d) {
    const months = ['янв','фев','мар','апр','мая','июн','июл','авг','сен','окт','ноя','дек'];
    const w = ['Пн','Вт','Ср','Чт','Пт','Сб','Вс'];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]}, ${w[d.weekday - 1]}';
  }
}

/* ====================== ОБЪЕКТЫ + ЧЕКЛИСТЫ ====================== */

class ObjectsScreen extends StatelessWidget {
  final DateTime day;
  final List<(String id, String name)> objects;
  final Storage store;
  const ObjectsScreen({super.key, required this.day, required this.objects, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Объекты')),
      body: ListView.separated(
        itemCount: objects.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final o = objects[i];
          return ListTile(
            title: Text(o.$2),
            subtitle: Text('Дата: ${store.iso(day)}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ChecklistScreen(
                  title: 'Ресурсы: ${o.$2}',
                  day: day,
                  store: store,
                  objectId: o.$1,
                ),
              ));
            },
          );
        },
      ),
    );
  }
}

class ChecklistScreen extends StatefulWidget {
  final String title;
  final DateTime day;
  final String? objectId; // null -> общий список для даты
  final Storage store;
  const ChecklistScreen({super.key, required this.title, required this.day, required this.store, required this.objectId});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  late List<ChecklistItem> items;
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    items = widget.store.loadChecklist(widget.day, objectId: widget.objectId);
  }

  Future<void> _save() async {
    await widget.store.saveChecklist(widget.day, items, objectId: widget.objectId);
  }

  void _addItem() async {
    final t = controller.text.trim();
    if (t.isEmpty) return;
    setState(() => items.add(ChecklistItem(t, false)));
    controller.clear();
    await _save();
    await widget.store.addJournal('Добавлен ресурс "${t}" (${widget.store.iso(widget.day)} ${widget.objectId == null ? "общий" : "объект"})');
  }

  void _removeAt(int i) async {
    final name = items[i].text;
    setState(() => items.removeAt(i));
    await _save();
    await widget.store.addJournal('Удалён ресурс "${name}" (${widget.store.iso(widget.day)})');
  }

  @override
  Widget build(BuildContext context) {
    final dayStr = widget.store.iso(widget.day);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Row(
              children: [
                _Chip(text: 'Дата: $dayStr'),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Новый пункт…',
                      prefixIcon: Icon(Icons.add),
                      filled: true,
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _addItem, child: const Text('Добавить')),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              itemCount: items.length,
              onReorder: (oldIndex, newIndex) async {
                if (newIndex > oldIndex) newIndex -= 1;
                setState(() => items.insert(newIndex, items.removeAt(oldIndex)));
                await _save();
              },
              itemBuilder: (_, i) {
                final it = items[i];
                return Dismissible(
                  key: ValueKey('item_${i}_${it.text}'),
                  background: Container(color: Colors.red),
                  onDismissed: (_) => _removeAt(i),
                  child: CheckboxListTile(
                    value: it.checked,
                    title: Text(it.text),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (v) async {
                      setState(() => it.checked = (v ?? false));
                      await _save();
                    },
                    secondary: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _removeAt(i),
                      tooltip: 'Удалить',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/* ====================== ЖУРНАЛ ====================== */

class JournalPage extends StatelessWidget {
  final SharedPreferences prefs;
  const JournalPage({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    final items = prefs.getStringList('journal') ?? <String>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Журнал')),
      body: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) => ListTile(title: Text(items[i])),
      ),
    );
  }
}

/* ====================== DRAWER (главное меню) ====================== */

class _MainDrawer extends StatelessWidget {
  final VoidCallback onOpenJournal;
  final VoidCallback onOpenGeneralResources;
  final VoidCallback onOpenObjects;
  const _MainDrawer({
    required this.onOpenJournal,
    required this.onOpenGeneralResources,
    required this.onOpenObjects,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const ListTile(
              title: Text('Меню', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('График'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.warehouse_outlined),
              title: const Text('Объекты'),
              onTap: onOpenObjects,
            ),
            ListTile(
              leading: const Icon(Icons.checklist_outlined),
              title: const Text('Ресурсы (дата)'),
              onTap: onOpenGeneralResources,
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Журнал'),
              onTap: onOpenJournal,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('О приложении'),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: 'WorkGrid',
                  applicationVersion: '1.0.0',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/* ====================== ВИЖЕТЫ СЕТКИ ====================== */

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  const _HeaderCell({required this.text, this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: flex == 2 ? 220 : 120,
      height: 44,
      alignment: Alignment.center,
      margin: const EdgeInsets.only(right: 8, bottom: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF262B33),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF3A414D)),
      ),
      child: Text(text, style: const TextStyle(color: Color(0xFFAAB4C4), fontWeight: FontWeight.w600)),
    );
  }
}

class _BigCell extends StatelessWidget {
  final CellStatus status;
  final String? note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final BorderSide border;

  const _BigCell({
    super.key,
    required this.status,
    required this.note,
    required this.onTap,
    required this.onLongPress,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    final bg = switch (status) {
      CellStatus.empty    => Colors.transparent,
      CellStatus.awaiting => const Color(0x3317C964),
      CellStatus.inWork   => const Color(0x337D8799),
      CellStatus.done     => const Color(0x383FA56F),
      CellStatus.warn     => const Color(0x40F2D27A),
    };

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 120,
        height: 96,
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2B313A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3A414D)),
        ),
        padding: const EdgeInsets.all(10),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF3A414D)),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(statusLabel(status),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              if ((note ?? '').isNotEmpty)
                Expanded(
                  child: Text(
                    note!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFFAAB4C4)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String text;
  const _Avatar({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28, height: 28, alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF343B46),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3A414D)),
      ),
      child: Text(text, style: const TextStyle(color: Color(0xFFAAB4C4), fontWeight: FontWeight.w600)),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF343B46),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF3A414D)),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
