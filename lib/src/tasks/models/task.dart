import 'package:freezed_annotation/freezed_annotation.dart';

part 'task.freezed.dart';
part 'task.g.dart';

@freezed
class Task with _$Task {
  const factory Task._({
    /// Whether the task is completed.
    @JsonKey(defaultValue: false)
        required bool completed,

    /// Whether the task is deleted.
    @JsonKey(defaultValue: false)
        required bool deleted,

    /// Description of the task.
    required String? description,

    /// Due date of the task.
    @JsonKey(
      fromJson: _dueDateFromJson,
      toJson: _dueDateToJson,
    )
        required DateTime? dueDate,

    /// ID of the task.
    @JsonKey(defaultValue: '')
        required String id,

    /// Index of the task in the list.
    @JsonKey(defaultValue: -1)
        required int index,

    /// The ID of the task considered the parent, only if this task is nested.
    required String? parent,

    /// Title of the task.
    @JsonKey(defaultValue: '')
        required String title,

    /// Last time the task was updated.
    @JsonKey(
      fromJson: _updateFromJson,
      toJson: _updateToJson,
    )
        required DateTime updated,
  }) = _Task;

  factory Task.empty() => Task._(
        completed: false,
        deleted: false,
        description: null,
        dueDate: null,
        id: '',
        index: -1,
        parent: null,
        title: '',
        updated: DateTime.now(),
      );

  factory Task({
    bool completed = false,
    bool deleted = false,
    String? description,
    DateTime? dueDate,
    String id = '',
    int index = -1,
    String? parent,
    required String title,
    DateTime? updated,
  }) {
    if (dueDate != null) {
      // Remove microseconds so serialization will work reliably.
      dueDate = DateTime.fromMillisecondsSinceEpoch(
        dueDate.millisecondsSinceEpoch,
      );
    }

    if (parent == '') parent = null;

    updated ??= DateTime.now();
    // Remove microseconds so serialization will work reliably.
    updated = DateTime.fromMillisecondsSinceEpoch(
      updated.millisecondsSinceEpoch,
    );

    return Task._(
      completed: completed,
      deleted: deleted,
      description: description,
      dueDate: dueDate,
      id: id,
      index: index,
      parent: parent,
      title: title,
      updated: updated,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}

DateTime? _dueDateFromJson(int? date) {
  if (date == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(date);
}

int? _dueDateToJson(DateTime? date) {
  if (date == null) return null;
  return date.millisecondsSinceEpoch;
}

DateTime _updateFromJson(int date) {
  return DateTime.fromMillisecondsSinceEpoch(date);
}

int _updateToJson(DateTime date) {
  return date.millisecondsSinceEpoch;
}
