import 'dart:convert';

import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart';

import '../../../authentication/authentication.dart';
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
  final CalendarApi? _api;

  GoogleCalendar._(this._api) {
    getAll();
  }

  static Future<GoogleCalendar> initialize({
    required ClientId clientId,
    required AccessCredentials credentials,
  }) async {
    AuthClient? client;
    // `google_sign_in` can't get us a refresh token, so.
    if (credentials.refreshToken != null) {
      client = autoRefreshingClient(
        clientId,
        credentials,
        Client(),
      );
    } else {
      client = await GoogleAuth.refreshAuthClient();
    }

    CalendarApi? calendarApi;
    if (client != null) calendarApi = CalendarApi(client);

    return GoogleCalendar._(calendarApi);
  }

  @override
  Future<List<TaskList>?> getAll() async {
    if (_api == null) return null;

    final calendarListRepository = _api!.calendarList;

    final apiCalendarsList = await calendarListRepository.list(
      showHidden: true,
    );

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
      final calendar = await _api!.calendars.get(calendarListEntry.id!);
      taskLists.add(await calendar.toModel(_api!));
    }

    return taskLists;
  }

  @override
  Future<TaskList?> createList(TaskList taskList) async {
    if (_api == null) return null;

    final newCalendar = await _api!.calendars.insert(Calendar(
      description: json.encode({'index': taskList.index}),
      location: 'adventure_list',
      summary: taskList.title,
    ));

    await _setListHidden(newCalendar.id!);

    return await newCalendar.toModel(_api!);
  }

  @override
  Future<bool> deleteList({required String id}) async {
    if (_api == null) return false;

    await _api!.calendars.delete(id);

    return true;
  }

  @override
  Future<TaskList?> updateList({required TaskList list}) async {
    if (_api == null) return null;

    final Calendar calendar = await _api!.calendars.update(
      list.toGoogleCalendar(),
      list.id,
    );

    return await calendar.toModel(_api!);
  }

  @override
  Future<Task?> createTask({
    required String taskListId,
    required Task newTask,
  }) async {
    if (_api == null) return null;

    final createdEvent = await _api!.events.insert(
      newTask.toGoogleEvent(),
      taskListId,
    );

    return createdEvent.toModel();
  }

  @override
  Future<Task?> updateTask({
    required String taskListId,
    required Task updatedTask,
  }) async {
    if (_api == null) return null;

    final updatedEvent = await _api!.events.update(
      updatedTask.toGoogleEvent(),
      taskListId,
      updatedTask.id,
    );

    return updatedEvent.toModel();
  }

  Future<bool> _setListHidden(String calendarId) async {
    if (_api == null) return false;

    await _api!.calendarList.update(
      // Set the calendar to hidden, so it doesn't appear when the user
      // accesses their calendars normally.
      CalendarListEntry(hidden: true),
      calendarId,
    );

    return true;
  }
}

extension CalendarHelper on Calendar {
  Future<TaskList> toModel(CalendarApi api) async {
    final apiTasks = await api.events.list(
      id!,
      showDeleted: true,
    );

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
    return Task.fromJson(description!) //
        // The inital task didn't have id, so grab from Event.
        .copyWith(id: id);
  }
}

extension GoogleTaskListHelper on TaskList {
  Calendar toGoogleCalendar() {
    final map = toMap()..remove('items');

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
      description: toJson(),
      end: EventDateTime(date: DateTime(2022, 06, 27)),
      start: EventDateTime(date: DateTime(2022, 06, 27)),
      status: completed ? 'cancelled' : 'confirmed',
      summary: title,
    );
  }
}
