import 'work_object.dart';

enum CellStatus { pending, inProgress, done, expected }

class Cell {
  List<WorkObject> objects;
  CellStatus? status;
  bool hasUnread;

  Cell({this.objects = const [], this.status, this.hasUnread = false});
}
