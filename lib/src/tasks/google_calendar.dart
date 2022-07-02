import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart';

import '../authentication/authentication.dart';
import 'models/models.dart' as models;
import 'tasks.dart';

/// *[Event](https://developers.google.com/calendar/v3/reference/events)* An
/// event on a calendar containing information such as the title, start and end
/// times, and attendees. Events can be either single events or [recurring
/// events](https://developers.google.com/calendar/concepts/events-calendars#recurring_events).
/// An event is represented by an [Event
/// resource](https://developers.google.com/calendar/v3/reference/events#resource-representations).

/// [Calendar](https://developers.google.com/calendar/v3/reference/calendars)
/// Analagous to the `TaskList`.

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
  CalendarApi _api;
  AuthClient _client;

  GoogleCalendar._(this._api, this._client) {
    getAll();
  }

  static Future<GoogleCalendar> initialize({
    required ClientId clientId,
    required AccessCredentials credentials,
  }) async {
    AuthClient client;
    // `google_sign_in` can't get us a refresh token, so.
    if (credentials.refreshToken != null) {
      client = autoRefreshingClient(
        clientId,
        credentials,
        Client(),
      );
    } else {
      // client = authenticatedClient(Client(), credentials);
      client = await GoogleAuth.refreshAuthClient();
    }

    return GoogleCalendar._(CalendarApi(client), client);
  }

  @override
  Future<List<models.TaskList>> getAll() async {
    final calendarListRepository = _api.calendarList;

    final apiCalendarsList = await calendarListRepository.list(
      showHidden: true,
    );

    apiCalendarsList.items?.removeWhere(
      (CalendarListEntry element) => element.location != 'adventure_list',
    );

    final taskLists = <models.TaskList>[];
    for (var calendarListEntry in apiCalendarsList.items!) {
      final calendar = await _api.calendars.get(calendarListEntry.id!);
      taskLists.add(await calendar.toModel(_api));
    }
    var end;
    return taskLists;
  }

  // Future<void> _refreshCredentials() async {
  //   bool tokenExpired = _client.credentials.accessToken.hasExpired;
  //   if (!tokenExpired) return;

  //   final String? newAccessToken = await GoogleAuth.refreshAccessToken();
  //   // final newClient = authenticatedClient(
  //   //   Client(),
  //   //   AccessCredentials(
  //   //     AccessToken(type, data, expiry),
  //   //     null,
  //   //     GoogleAuth.scopes,
  //   //   ),
  //   // );
  // }

  @override
  Future<models.TaskList> createList({required String title}) async {
    final newCalendar = await _api.calendars.insert(Calendar(
      description: '{}',
      location: 'adventure_list',
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
  Future<void> deleteList({required String id}) async {
    await _api.calendars.delete(id);
  }

  @override
  Future<void> updateList({required TaskList list}) async {
    await _api.calendars.update(
      list.toGoogleCalendar(),
      list.id,
    );
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

extension CalendarHelper on Calendar {
  Future<models.TaskList> toModel(CalendarApi api) async {
    final apiTasks = await api.events.list(
      id!,
      showDeleted: true,
    );

    return models.TaskList(
      details: models.TaskListDetails.fromJson('{}'),
      // details: models.TaskListDetails.fromJson(description ?? '{}'),
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

extension TaskListHelper on models.TaskList {
  Calendar toGoogleCalendar() {
    return Calendar(
      id: id,
      summary: title,
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
