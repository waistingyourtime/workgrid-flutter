import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(WorkGridApp(prefs: prefs));
}

class WorkGridApp extends StatefulWidget {
  final SharedPreferences prefs;
  const WorkGridApp({super.key, required this.prefs});
  @override
  State<WorkGridApp> createState() => _WorkGridAppState();
}

class _WorkGridAppState extends State<WorkGridApp> {
  AppSettings settings = const AppSettings();

  @override
  void initState() {
    super.initState();
    settings = AppSettings.fromPrefs(widget.prefs);
  }

  void updateSettings(AppSettings s) {
    setState(() => settings = s);
    s.save(widget.prefs);
  }

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
      home: HomeScreen(prefs: widget.prefs, settings: settings, onSettingsChanged: updateSettings),
    );
  }
}

/* -------------------- SETTINGS + JOURNAL -------------------- */

class AppSettings {
  final int startHour; // 6..10
  final bool showAvatars;
  final bool confirmCopy;

  const AppSettings({this.startHour = 8, this.showAvatars = true, this.confirmCopy = false});

  AppSettings copyWith({int? startHour, bool? showAvatars, bool? confirmCopy}) =>
      AppSettings(startHour: startHour ?? this.startHour, showAvatars: showAvatars ?? this.showAvatars, confirmCopy: confirmCopy ?? this.confirmCopy);

  Map<String, dynamic> toJson() => {'startHour': startHour, 'showAvatars': showAvatars, 'confirmCopy': confirmCopy};
  static AppSettings fromJson(Map<String, dynamic> j) => AppSettings(
    startHour: (j['startHour'] ?? 8) as int,
    showAvatars: (j['showAvatars'] ?? true) as bool,
    confirmCopy: (j['confirmCopy'] ?? false) as bool,
  );

  static const _k = 'settings';
  static AppSettings fromPrefs(SharedPreferences p) {
    final s = p.getString(_k);
    if (s == null || s.isEmpty) return const AppSettings();
    return AppSettings.fromJson(jsonDecode(s));
  }
  Future<void> save(SharedPreferences p) => p.setString(_k, jsonEncode(toJson()));
}

class Journal {
  static const _k = 'journal';
  static List<String> load(SharedPreferences p) => p.getStringList(_k) ?? <String>[];
  static Future<void> add(SharedPreferences p, String entry) async {
    final list = load(p);
    list.insert(0, '${DateTime.now().toIso8601String()} — $entry');
    await p.setStringList(_k, list.take(300).toList());
  }
}

/* -------------------- HOME -------------------- */

class HomeScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final AppSettings settings;
  final void Function(AppSettings) onSettingsChanged;
  const HomeScreen({super.key, required this.prefs, required this.settings, required this.onSettingsChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class Member {
  final String id;
  final String name;
  final bool isVirtual;
  const Member(this.id, this.name, this.isVirtual);
}

enum CellStatus { empty, awaiting, inWork, done, warn }
String label(CellStatus s) => switch (s) {
  CellStatus.empty => '',
  CellStatus.awaiting => 'Ожидается',
  CellStatus.inWork => 'В работе',
  CellStatus.done => 'Выполнено',
  CellStatus.warn => 'Без статуса',
};

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;
  DateTime day = _today();
  String? memberFilter;
  Map<String, String> dayData = {}; // 'memberId:hour' -> 'awaiting|inWork|done|warn'

  final members = const [
    Member('u1', 'Джон', false),
    Member('u2', 'Анна', false),
    Member('u3', 'Юлія', false),
    Member('u4', 'Михайло', true),
  ];

  List<int> get hours => List<int>.generate(11, (i) => widget.settings.startHour + i);

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  String get iso => '${day.year}-${day.month.toString().padLeft(2,'0')}-${day.day.toString().padLeft(2,'0')}';

  @override
  void initState() {
    super.initState();
    _loadDay();
  }

  Future<void> _loadDay() async {
    final s = widget.prefs.getString('cells:$iso');
    dayData = (s == null || s.isEmpty) ? {} : Map<String, String>.from(jsonDecode(s));
    setState(() {});
  }

  Future<void> _saveDay() async {
    await widget.prefs.setString('cells:$iso', jsonEncode(dayData));
  }

  void setStatus(String memberId, int h, CellStatus st) async {
    final key = '$memberId:$h';
    if (st == CellStatus.empty) {
      dayData.remove(key);
    } else {
      dayData[key] = st.name;
    }
    await _saveDay();
    await Journal.add(widget.prefs, 'Статус $memberId $h:00 = ${label(st)} (${_format(day)})');
    setState(() {});
  }

  void copyForward(String memberId, int h) async {
    final v = dayData['$memberId:$h'];
    if (v == null) return;
    if (widget.settings.confirmCopy) {
      final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
        title: const Text('Копировать статус'),
        content: Text('Скопировать $memberId $h:00 → ${h+1}:00?'),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(c,false), child: const Text('Отмена')),
          FilledButton(onPressed: ()=>Navigator.pop(c,true), child: const Text('Копировать')),
        ],
      ));
      if (ok != true) return;
    }
    dayData['$memberId:${h+1}'] = v;
    await _saveDay();
    await Journal.add(widget.prefs, 'Копирование: $memberId $h:00 → ${h+1}:00');
    setState(() {});
  }

  void changeDay(DateTime d) async {
    setState(() { day = DateTime(d.year, d.month, d.day); });
    await _loadDay();
    await Journal.add(widget.prefs, 'Выбрана дата ${_format(day)}');
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _sameDay(day, _today());
    final tabs = [
      _buildSchedule(),
      _MembersTab(
        members: members,
        showAvatars: widget.settings.showAvatars,
        onOpen: (m) {
          setState(() { tab = 0; memberFilter = m.id; });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Фильтр: ${m.name}')));
        },
      ),
      const _ObjectsTab(),
      _ResourcesTab(prefs: widget.prefs),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Проект A'),
        actions: [
          PopupMenuButton<int>(
            itemBuilder: (_) => const [
              PopupMenuItem(value: 1, child: Text('Настройки проекта')),
              PopupMenuItem(value: 2, child: Text('Журнал проекта')),
              PopupMenuItem(value: 3, child: Text('Быстрый переход к дате')),
            ],
            onSelected: (v) async {
              if (v == 1) {
                final res = await Navigator.push<AppSettings>(context, MaterialPageRoute(builder: (_)=>SettingsScreen(settings: widget.settings)));
                if (res != null) widget.onSettingsChanged(res);
                setState(() {}); // пересобрать сетку, если стартовый час изменился
              } else if (v == 2) {
                await Navigator.push(context, MaterialPageRoute(builder: (_)=>JournalScreen(prefs: widget.prefs)));
              } else if (v == 3) {
                _pickDate();
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: const Color(0xFF262B33),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                _Chip(text: _format(day)),
                const SizedBox(width: 8),
                if (!isToday) FilledButton(onPressed: ()=>changeDay(_today()), child: const Text('Сегодня')),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: _pickDate, child: const Text('Дата')),
                const Spacer(),
                if (memberFilter != null)
                  TextButton.icon(onPressed: ()=>setState(()=>memberFilter=null), icon: const Icon(Icons.filter_alt_off_outlined), label: const Text('Сбросить')),
              ],
            ),
          ),
        ),
      ),
      body: IndexedStack(index: tab, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i)=>setState(()=>tab=i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'График'),
          NavigationDestination(icon: Icon(Icons.group), label: 'Участники'),
          NavigationDestination(icon: Icon(Icons.domain), label: 'Объекты'),
          NavigationDestination(icon: Icon(Icons.inventory_2), label: 'Ресурсы'),
        ],
      ),
    );
  }

  /* ---------- schedule ---------- */
  Widget _buildSchedule() {
    final list = memberFilter == null ? members : members.where((m)=>m.id==memberFilter).toList();
    final border = const BorderSide(color: Color(0xFF3A414D), width: 1);
    final headers = [const _HeadCell('Участники', flex: 2), ...hours.map((h)=>_HeadCell('${h.toString().padLeft(2,'0')}:00'))];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2B313A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3A414D)),
        ),
        child: Column(
          children: [
            Row(children: headers.map((h)=>Expanded(flex:h.flex, child: _HeadCellWidget(h))).toList()),
            const Divider(height:1, color: Color(0xFF3A414D)),
            ...list.map((m)=>Row(children: [
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(border: Border(bottom: border)),
                  padding: const EdgeInsets.all(8),
                  child: Row(children: [
                    if (widget.settings.showAvatars) ...[
                      _Avatar(text: m.name.characters.first.toUpperCase()),
                      const SizedBox(width:8),
                    ],
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (m.isVirtual)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF3A414D)),
                            borderRadius: BorderRadius.circular(8),
                            color: const Color(0xFF343B46),
                          ),
                          child: const Text('виртуальный', style: TextStyle(fontSize: 11, color: Color(0xFFAAB4C4))),
                        ),
                    ])),
                  ]),
                ),
              ),
              ...hours.map((h) {
                final key = '${m.id}:$h';
                final v = dayData[key];
                final st = switch (v) {
                  'awaiting' => CellStatus.awaiting,
                  'inWork'   => CellStatus.inWork,
                  'done'     => CellStatus.done,
                  'warn'     => CellStatus.warn,
                  _          => CellStatus.empty,
                };
                return Expanded(
                  child: InkWell(
                    onTap: () => setStatus(m.id, h, _next(st)),
                    onLongPress: () async {
                      final selected = await showModalBottomSheet<String>(
                        context: context,
                        backgroundColor: const Color(0xFF262B33),
                        showDragHandle: true,
                        builder: (c) => SafeArea(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            for (final s in CellStatus.values)
                              ListTile(title: Text(label(s)), onTap: ()=>Navigator.pop(c, s.name)),
                            ListTile(title: const Text('Копировать → следующий час'), onTap: ()=>Navigator.pop(c, 'copy')),
                          ]),
                        ),
                      );
                      if (selected == null) return;
                      if (selected == 'copy') { copyForward(m.id, h); return; }
                      setStatus(m.id, h, CellStatus.values.firstWhere((e)=>e.name==selected));
                    },
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(border: Border(right: border, bottom: border)),
                      child: _StatusBlock(st),
                    ),
                  ),
                );
              }).toList(),
            ])),
          ],
        ),
      ),
    );
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: day,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Выберите дату',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(primary: const Color(0xFF4E8DFC))),
        child: child!,
      ),
    );
    if (picked != null) changeDay(picked);
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year==b.year && a.month==b.month && a.day==b.day;
  static String _format(DateTime d) {
    const m = ['янв','фев','мар','апр','мая','июн','июл','авг','сен','окт','ноя','дек'];
    const w = ['Пн','Вт','Ср','Чт','Пт','Сб','Вс'];
    return '${d.day.toString().padLeft(2,'0')} ${m[d.month-1]}, ${w[d.weekday-1]}';
  }
}

class _HeadCell {
  final String text; final int flex;
  const _HeadCell(this.text, {this.flex = 1});
}
class _HeadCellWidget extends StatelessWidget {
  final _HeadCell h; const _HeadCellWidget(this.h, {super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40, alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFF262B33),
        border: Border(
          right: BorderSide(color: Color(0xFF3A414D), width: 1),
          bottom: BorderSide(color: Color(0xFF3A414D), width: 1),
        ),
      ),
      child: Text(h.text, style: const TextStyle(color: Color(0xFFAAB4C4), fontWeight: FontWeight.w600)),
    );
  }
}
class _Avatar extends StatelessWidget {
  final String text; const _Avatar({required this.text, super.key});
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
class _StatusBlock extends StatelessWidget {
  final CellStatus s; const _StatusBlock(this.s, {super.key});
  @override
  Widget build(BuildContext context) {
    final bg = switch (s) {
      CellStatus.empty    => Colors.transparent,
      CellStatus.awaiting => const Color(0x3317C964),
      CellStatus.inWork   => const Color(0x337D8799),
      CellStatus.done     => const Color(0x383FA56F),
      CellStatus.warn     => const Color(0x40F2D27A),
    };
    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3A414D)),
      ),
      alignment: Alignment.center,
      child: Text(label(s), style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
CellStatus _next(CellStatus s) => switch (s) {
  CellStatus.empty => CellStatus.awaiting,
  CellStatus.awaiting => CellStatus.inWork,
  CellStatus.inWork => CellStatus.done,
  CellStatus.done => CellStatus.warn,
  CellStatus.warn => CellStatus.empty,
};

/* -------------------- TABS -------------------- */

class _MembersTab extends StatelessWidget {
  final List<Member> members;
  final bool showAvatars;
  final void Function(Member) onOpen;
  const _MembersTab({super.key, required this.members, required this.onOpen, required this.showAvatars});
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final m = members[i];
        return ListTile(
          tileColor: const Color(0xFF2B313A),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFF3A414D)),
            borderRadius: BorderRadius.circular(12),
          ),
          leading: showAvatars ? _Avatar(text: m.name.characters.first.toUpperCase()) : null,
          title: Text(m.name),
          subtitle: m.isVirtual ? const Text('виртуальный') : null,
          trailing: FilledButton(onPressed: ()=>onOpen(m), child: const Text('Открыть график')),
        );
      },
    );
  }
}

class _ObjectsTab extends StatelessWidget {
  const _ObjectsTab({super.key});
  @override
  Widget build(BuildContext context) {
    final data = const [
      ('Объект 101', 'Анна', 'Принят'),
      ('Склад 3', 'Юлія', 'Ожидается'),
      ('Участок B', 'Михайло', 'Передан'),
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: data.length,
      itemBuilder: (_, i) {
        final (name, who, status) = data[i];
        return Card(
          color: const Color(0xFF2B313A),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFF3A414D)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(name),
            subtitle: Text('ответственный: $who'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF3A414D)),
                borderRadius: BorderRadius.circular(999),
                color: const Color(0xFF343B46),
              ),
              child: Text(status, style: const TextStyle(color: Color(0xFFAAB4C4))),
            ),
          ),
        );
      },
    );
  }
}

class _ResourcesTab extends StatefulWidget {
  final SharedPreferences prefs;
  const _ResourcesTab({super.key, required this.prefs});
  @override
  State<_ResourcesTab> createState() => _ResourcesTabState();
}
class _ResourcesTabState extends State<_ResourcesTab> {
  late List<(String,bool)> items;
  @override
  void initState() {
    super.initState();
    final s = widget.prefs.getString('resources');
    items = (s==null||s.isEmpty)
        ? [('Кабель 3х2.5', true), ('Перчатки', false), ('Болгарка', true)]
        : (jsonDecode(s) as List).map<(String,bool)>((e)=>((e['name'] as String),(e['avail'] as bool))).toList();
  }
  Future<void> _save() async {
    await widget.prefs.setString('resources', jsonEncode(items.map((e)=>{'name':e.$1,'avail':e.$2}).toList()));
  }
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final it = items[i];
        return Card(
          color: const Color(0xFF2B313A),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFF3A414D)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SwitchListTile(
            title: Text(it.$1),
            value: it.$2,
            onChanged: (v) async {
              setState(()=>items[i]=(it.$1, v));
              await _save();
              await Journal.add(widget.prefs, 'Ресурс "${it.$1}" = ${v?'есть':'нет'}');
            },
          ),
        );
      },
    );
  }
}

/* -------------------- JOURNAL + SETTINGS SCREENS -------------------- */

class JournalScreen extends StatelessWidget {
  final SharedPreferences prefs;
  const JournalScreen({super.key, required this.prefs});
  @override
  Widget build(BuildContext context) {
    final items = Journal.load(prefs);
    return Scaffold(
      appBar: AppBar(title: const Text('Журнал проекта')),
      body: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) => ListTile(title: Text(items[i])),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  final AppSettings settings;
  const SettingsScreen({super.key, required this.settings});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}
class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings s;
  @override
  void initState() { super.initState(); s = widget.settings; }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки проекта')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Старт часа в графике'),
            subtitle: Text('${s.startHour}:00'),
            trailing: DropdownButton<int>(
              value: s.startHour,
              items: [6,7,8,9,10].map((e)=>DropdownMenuItem(value:e, child: Text('$e:00'))).toList(),
              onChanged: (v)=>setState(()=>s=s.copyWith(startHour: v)),
            ),
          ),
          SwitchListTile(
            title: const Text('Показывать аватары'),
            value: s.showAvatars,
            onChanged: (v)=>setState(()=>s=s.copyWith(showAvatars: v)),
          ),
          SwitchListTile(
            title: const Text('Подтверждать копирование статуса'),
            value: s.confirmCopy,
            onChanged: (v)=>setState(()=>s=s.copyWith(confirmCopy: v)),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton(onPressed: ()=>Navigator.pop(context, s), child: const Text('Сохранить')),
          )
        ],
      ),
    );
  }
}

/* -------------------- UI UTILS -------------------- */
class _Chip extends StatelessWidget {
  final String text; const _Chip({required this.text, super.key});
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
