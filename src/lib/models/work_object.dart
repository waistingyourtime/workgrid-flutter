import 'note_item.dart';

class WorkObject {
  String id;
  String title;
  List<NoteItem> tasks;
  List<NoteItem> resources;
  String? assignedTo;

  WorkObject({
    required this.id,
    required this.title,
    List<NoteItem>? tasks,
    List<NoteItem>? resources,
    this.assignedTo,
  })  : tasks = tasks ?? <NoteItem>[],
        resources = resources ?? <NoteItem>[];
}
