import 'dart:convert';

import 'package:googleapis/calendar/v3.dart';
import '../../../logs/logging_manager.dart';
import '../../tasks.dart';

/// Notes on interfacing with the Google Calendar API.

/// [Event](https://developers.google.com/calendar/v3/reference/events)
/// Analagous to a [Task].
///
/// An event on a calendar containing information such as the title, start and
/// end times, and attendees. Events can be either single events or [recurring
/// events](https://developers.google.com/calendar/concepts/events-calendars#recurring_events).
/// An event is represented by an [Event
/// resource](https://developers.google.com/calendar/v3/reference/events#resource-representations).

/// [Calendar](https://developers.google.com/calendar/v3/reference/calendars)
/// Analagous to a `TaskList`.

/// [Calendar List](https://developers.google.com/calendar/v3/reference/calendarList)
///
/// A list of all calendars on a user's calendar list in the Calendar UI. The
/// metadata for a single calendar that appears on the calendar list is
/// represented by a [CalendarListEntry resource](https://developers.google.com/calendar/v3/reference/calendarList).
/// This metadata includes user-specific properties of the calendar, such as its
/// color or notifications for new events.

/// [Setting](https://developers.google.com/calendar/v3/reference/settings)
///
/// A user preference from the Calendar UI, such as the user's time zone. A
/// single user preference is represented by a [Setting Resource](https://developers.google.com/calendar/v3/reference/settings).

/// [ACL](https://developers.google.com/calendar/v3/reference/acl)
///
/// An access control rule granting a user (or a group of users) a specified
/// level of access to a calendar. A single access control rule is represented
/// by an [ACL resource](https://developers.google.com/calendar/v3/reference/acl).

class GoogleCalendar implements TasksRepository {
  /// The Google Calendar API.
  final CalendarApi _api;

  const GoogleCalendar(this._api);

  @override
  Future<List<TaskList>?> getAll() async {
    final calendarListRepository = _api.calendarList;

    final CalendarList apiCalendarsList;
    try {
      apiCalendarsList = await calendarListRepository.list(
        showHidden: true,
      );
    } on Exception catch (e) {
      // This has previously thrown a "503 Service Unavailable" error.
      // This is supposed to be temporary, and has only happened once.
      // This should likely be updated to bubble up a custom error to the UI.
      log.e('Failed to get all lists', error: e);
      return null;
    }

    apiCalendarsList.items?.removeWhere(
      (CalendarListEntry element) => element.location != 'adventure_list',
    );

    // Double check our calendars have been marked hidden,
    // occasionally it will fail when creating the calendar.
    for (var calendar in apiCalendarsList.items ?? <CalendarListEntry>[]) {
      if (calendar.hidden != true) {
        await _setListHidden(calendar.id!);
      }
    }

    final taskLists = <TaskList>[];
    for (var calendarListEntry in apiCalendarsList.items!) {
      final Calendar calendar;
      try {
        calendar = await _api.calendars.get(calendarListEntry.id!);
      } on Exception catch (e) {
        log.e('Failed to get list', error: e);
        return null;
      }

      final model = await calendar.toModel(_api);
      if (model == null) return null;
      taskLists.add(model);
    }

    return taskLists;
  }

  @override
  Future<TaskList?> createList(TaskList taskList) async {
    final Calendar newCalendar;
    try {
      newCalendar = await _api.calendars.insert(Calendar(
        description: json.encode({'index': taskList.index}),
        location: 'adventure_list',
        summary: taskList.title,
      ));
    } on Exception catch (e) {
      log.e('Failed to create list', error: e);
      return null;
    }

    final isHidden = await _setListHidden(newCalendar.id!);
    if (!isHidden) {
      log.e('Failed to hide list');
      await _api.calendars.delete(newCalendar.id!);
      return null;
    }

    return await newCalendar.toModel(_api);
  }

  @override
  Future<bool> deleteList({required String id}) async {
    try {
      await _api.calendars.delete(id);
    } on Exception catch (e) {
      log.e('Failed to delete list from Google Calendar', error: e);
      rethrow;
    }

    return true;
  }

  @override
  Future<bool> deleteTask({
    required String taskListId,
    required String taskId,
  }) async {
    try {
      // Get the events associated with the iCalUID.
      final events = await _api.events.list(taskListId, iCalUID: taskId);
      if (events.items == null || events.items!.isEmpty) {
        throw Exception('Failed to delete task, no events found');
      }

      // Is it always sufficient to only delete the first event?
      // There __should__ only be one event per task.
      // Are there ever multiple?
      // Would trying to delete multiple throw an error?
      await _api.events.delete(taskListId, events.items!.first.id!);
    } on Exception catch (e) {
      log.e('Failed to delete task from Google Calendar', error: e);
      rethrow;
    }

    return true;
  }

  @override
  Future<TaskList?> updateList({required TaskList list}) async {
    final Calendar calendar;
    try {
      calendar = await _api.calendars.update(
        list.toGoogleCalendar(),
        list.id,
      );
    } on Exception catch (e) {
      log.e('Failed to update list', error: e);
      return null;
    }

    return await calendar.toModel(_api);
  }

  @override
  Future<Task?> createTask({
    required String taskListId,
    required Task newTask,
  }) async {
    final Event createdEvent;
    try {
      createdEvent = await _api.events.insert(
        newTask.toGoogleEvent(),
        taskListId,
      );
    } on Exception catch (e) {
      log.e('Failed to create task', error: e);
      return null;
    }

    return createdEvent.toModel();
  }

  @override
  Future<Task?> updateTask({
    required String taskListId,
    required Task updatedTask,
  }) async {
    final Event updatedEvent;
    try {
      final Events events = await _api.events.list(taskListId, iCalUID: updatedTask.id);
      if (events.items == null || events.items!.isEmpty) {
        log.e('Failed to update task, no events found');
        return null;
      }

      updatedEvent = await _api.events.update(
        updatedTask.toGoogleEvent(),
        taskListId,
        events.items!.first.id!,
      );
    } on DetailedApiRequestError catch (e) {
      log.e('Failed to update task', error: e);
      return null;
    }

    return updatedEvent.toModel();
  }

  Future<bool> _setListHidden(String calendarId) async {
    try {
      await _api.calendarList.update(
        // Set the calendar to hidden, so it doesn't appear when the user
        // accesses their calendars normally.
        CalendarListEntry(hidden: true),
        calendarId,
      );
    } on Exception catch (e) {
      log.e('Failed to set list hidden', error: e);
      return false;
    }

    return true;
  }
}

extension CalendarHelper on Calendar {
  Future<TaskList?> toModel(CalendarApi api) async {
    final Events apiTasks;
    try {
      apiTasks = await api.events.list(id!);
    } on Exception catch (e) {
      log.e('Failed to get tasks for list', error: e);
      return null;
    }

    // Convert events to Tasks.
    final List<Task> tasks = apiTasks.items!.map((e) => e.toModel()).toList();

    int index = -1;

    if (description != null) {
      index = jsonDecode(description!)['index'] ?? -1;
    }

    return TaskList(
      id: id!,
      index: index,
      items: tasks,
      title: summary ?? 'title',
    );
  }
}

extension EventHelper on Event {
  Task toModel() {
    Task task = Task.fromJson(jsonDecode(description!));

    /// We may need to transition old tasks that didn't use the iCalUID.
    if (iCalUID != null && task.id != iCalUID) {
      task = task.copyWith(id: iCalUID!);
    }

    return task;
  }
}

extension GoogleTaskListHelper on TaskList {
  Calendar toGoogleCalendar() {
    final map = toJson()..remove('items');

    return Calendar(
      // The description field appears to have a length limit, so we definitely
      // do not want to include the tasks, just basic info.
      description: jsonEncode(map),
      id: id,
      location: 'adventure_list',
      summary: title,
    );
  }
}

extension TaskHelper on Task {
  Event toGoogleEvent() {
    return Event(
      iCalUID: id,
      description: jsonEncode(toJson()),
      end: EventDateTime(date: DateTime(2022, 06, 27)),
      start: EventDateTime(date: DateTime(2022, 06, 27)),
      // Google Calendar seems to consider events with a 'cancelled' status the
      // same as deleted, so we use 'confirmed' instead.
      //
      // Whether a task is completed or not is determined by the 'completed'
      // field on the task.
      status: 'confirmed',
      summary: title,
    );
  }
}
