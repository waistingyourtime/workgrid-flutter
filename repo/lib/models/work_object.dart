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
    this.tasks = const [],
    this.resources = const [],
    this.assignedTo,
  });
}
