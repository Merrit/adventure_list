import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart';

import 'models/models.dart' as models;
import 'tasks.dart';

/// *[Event](https://developers.google.com/calendar/v3/reference/events)* An
/// event on a calendar containing information such as the title, start and end
/// times, and attendees. Events can be either single events or [recurring
/// events](https://developers.google.com/calendar/concepts/events-calendars#recurring_events).
/// An event is represented by an [Event
/// resource](https://developers.google.com/calendar/v3/reference/events#resource-representations).

/// *[Calendar](https://developers.google.com/calendar/v3/reference/calendars)*
/// A collection of events. Each calendar has associated metadata, such as
/// calendar description or default calendar time zone. The metadata for a
/// single calendar is represented by a [Calendar
/// resource](https://developers.google.com/calendar/v3/reference/calendars).

/// *[Calendar List](https://developers.google.com/calendar/v3/reference/calendarList)* A
/// list of all calendars on a user's calendar list in the Calendar UI. The
/// metadata for a single calendar that appears on the calendar list is
/// represented by a [CalendarListEntry
/// resource](https://developers.google.com/calendar/v3/reference/calendarList).
/// This metadata includes user-specific properties of the calendar, such as its
/// color or notifications for new events.

/// *[Setting](https://developers.google.com/calendar/v3/reference/settings)* A
/// user preference from the Calendar UI, such as the user's time zone. A single
/// user preference is represented by a [Setting
/// Resource](https://developers.google.com/calendar/v3/reference/settings).

/// *[ACL](https://developers.google.com/calendar/v3/reference/acl)* An access
/// control rule granting a user (or a group of users) a specified level of
/// access to a calendar. A single access control rule is represented by an [ACL
/// resource](https://developers.google.com/calendar/v3/reference/acl).

class GoogleCalendar implements TasksRepository {
  final CalendarApi _api;

  GoogleCalendar._(this._api) {
    getAll();
  }

  factory GoogleCalendar({
    required ClientId clientId,
    required AccessCredentials credentials,
  }) {
    final client = autoRefreshingClient(
      clientId,
      credentials,
      Client(),
    );

    return GoogleCalendar._(CalendarApi(client));
  }

  @override
  Future<List<models.TaskList>> getAll() async {
    final calendarListRepository = _api.calendarList;
    final apiCalendarsList = await calendarListRepository.list(
      showHidden: true,
    );

    apiCalendarsList.items?.removeWhere((element) {
      bool? isTodoList = element.description?.contains(
        RegExp(r'adventure_list'),
      );

      if (isTodoList == true) {
        return false;
      } else {
        return true;
      }
    });

    final taskLists = <models.TaskList>[];
    for (var calendar in apiCalendarsList.items!) {
      taskLists.add(await calendar.toModel(_api));
    }

    return taskLists;
  }

  @override
  Future<models.TaskList> createList({required String title}) async {
    final newCalendar = await _api.calendars.insert(Calendar(
      description: 'adventure_list_uuid',
      summary: title,
    ));

    await _api.calendarList.update(
      // Set the calendar to hidden, so it doesn't appear when the user
      // accesses their calendars normally.
      CalendarListEntry(hidden: true),
      newCalendar.id!,
    );

    return await newCalendar.toModel(_api);
  }

  @override
  Future<models.Task> createTask({
    required String calendarId,
    required Task newTask,
  }) async {
    final createdEvent = await _api.events.insert(
      newTask.toGoogleEvent(),
      calendarId,
    );

    return createdEvent.toModel();
  }

  @override
  Future<Task> updateTask({
    required String calendarId,
    required Task updatedTask,
  }) async {
    final updatedEvent = await _api.events.update(
      updatedTask.toGoogleEvent(),
      calendarId,
      updatedTask.id,
    );

    return updatedEvent.toModel();
  }
}

extension CalendarListEntryHelper on CalendarListEntry {
  Future<models.TaskList> toModel(CalendarApi api) async {
    final calendar = await api.calendars.get(id!);

    return await calendar.toModel(api);
  }
}

extension CalendarHelper on Calendar {
  Future<models.TaskList> toModel(CalendarApi api) async {
    final apiTasks = await api.events.list(
      id!,
      showDeleted: true,
    );

    return models.TaskList(
      id: id!,
      items: apiTasks.items!.map((e) => e.toModel()).toList(),
      title: summary ?? 'title',
    );
  }
}

extension EventHelper on Event {
  models.Task toModel() {
    return models.Task(
      completed: (status == 'confirmed') ? false : true,
      deleted: false,
      dueDate: null,
      etag: etag!,
      id: id!,
      title: summary ?? '',
      updated: updated!,
    );
  }
}

extension TaskHelper on models.Task {
  Event toGoogleEvent() {
    return Event(
      end: EventDateTime(date: DateTime(2022, 06, 27)),
      // endTimeUnspecified: true,
      start: EventDateTime(date: DateTime(2022, 06, 27)),
      status: completed ? 'cancelled' : 'confirmed',
      summary: title,
    );
  }
}
