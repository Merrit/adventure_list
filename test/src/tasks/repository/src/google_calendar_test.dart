import 'dart:convert';

import 'package:adventure_list/src/logs/logging_manager.dart';
import 'package:adventure_list/src/tasks/tasks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateNiceMocks([
  MockSpec<CalendarApi>(),
  MockSpec<CalendarsResource>(),
  MockSpec<CalendarListResource>(),
  MockSpec<EventsResource>(),
])
import 'google_calendar_test.mocks.dart';

MockCalendarApi calendarApi = MockCalendarApi();
MockCalendarsResource calendarsResource = MockCalendarsResource();
MockCalendarListResource calendarListResource = MockCalendarListResource();
MockEventsResource eventsResource = MockEventsResource();

late GoogleCalendar calendar;

void main() {
  setUpAll(() async {
    await LoggingManager.initialize(verbose: false);
  });

  setUp(() async {
    reset(calendarApi);
    reset(calendarsResource);
    reset(calendarListResource);
    reset(eventsResource);

    when(calendarApi.calendars).thenReturn(calendarsResource);
    when(calendarApi.calendarList).thenReturn(calendarListResource);
    when(calendarApi.events).thenReturn(eventsResource);

    when(calendarsResource.delete(any)).thenAnswer((_) async {});
    when(calendarsResource.get(any)).thenAnswer((_) async => Calendar(id: ''));
    when(calendarsResource.insert(any)).thenAnswer((_) async => Calendar(id: ''));
    when(calendarsResource.update(any, any)).thenAnswer((_) async => Calendar(id: ''));

    when(calendarListResource.list(showHidden: anyNamed('showHidden')))
        .thenAnswer((_) async => CalendarList(items: []));
    when(calendarListResource.update(any, any))
        .thenAnswer((_) async => CalendarListEntry());

    when(eventsResource.delete(any, any)).thenAnswer((_) async {});
    when(eventsResource.list(
      any,
      showDeleted: anyNamed('showDeleted'),
    )).thenAnswer((_) async => Events(items: []));
    when(calendarListResource.update(any, any))
        .thenAnswer((_) async => CalendarListEntry());

    when(eventsResource.insert(any, any))
        .thenAnswer((_) async => Event(id: '', description: ''));
    when(eventsResource.list(
      any,
      showDeleted: anyNamed('showDeleted'),
    )).thenAnswer((_) async => Events(items: []));
    when(eventsResource.update(any, any, any)).thenAnswer((_) async => Event(id: ''));

    calendar = GoogleCalendar(calendarApi);
  });

  group('GoogleCalendar:', () {
    group('getAll:', () {
      test('returns null if api call fails', () async {
        when(calendarListResource.list(showHidden: anyNamed('showHidden')))
            .thenThrow(Exception('Failed to get lists'));
        final result = await calendar.getAll();
        expect(result, isNull);
      });

      test('returns empty list if calendar.toModel fails', () async {
        when(calendarsResource.get(any)).thenThrow(Exception('Failed to get list'));
        final result = await calendar.getAll();
        expect(result, isEmpty);
      });

      test('returns null if _api.calendars.get fails', () async {
        when(calendarListResource.list(
          showHidden: anyNamed('showHidden'),
        )).thenAnswer((_) async => CalendarList(
              items: [
                CalendarListEntry(id: 'fakeid1', location: 'adventure_list'),
                CalendarListEntry(id: 'fakeid2', location: 'adventure_list'),
              ],
            ));
        when(calendarsResource.get(any)).thenThrow(Exception('Failed to get list'));
        final result = await calendar.getAll();
        expect(result, isNull);
      });

      test('returns list of TaskLists if successful', () async {
        when(calendarListResource.list(
          showHidden: anyNamed('showHidden'),
        )).thenAnswer((_) async => CalendarList(
              items: [
                CalendarListEntry(id: 'fakeid1', location: 'adventure_list'),
                CalendarListEntry(id: 'fakeid2', location: 'adventure_list'),
              ],
            ));
        final result = await calendar.getAll();
        expect(result, isNotNull);
        expect(result!.length, 2);
        expect(result.first, isA<TaskList>());
      });
    });

    group('createList:', () {
      test('returns null if api call fails', () async {
        when(calendarsResource.insert(any)).thenThrow(Exception('Failed to create list'));
        final result = await calendar.createList(TaskList.empty());
        expect(result, isNull);
      });

      test('returns null if _setListHidden fails', () async {
        when(calendarListResource.update(any, any))
            .thenThrow(Exception('Failed to set list hidden'));
        final result = await calendar.createList(TaskList.empty());
        expect(result, isNull);
      });

      test('returns TaskList if successful', () async {
        final result = await calendar.createList(TaskList.empty());
        expect(result, isA<TaskList>());
      });
    });

    group('deleteList:', () {
      test('returns false if api call fails', () async {
        when(calendarsResource.delete(any)).thenThrow(Exception('Failed to delete list'));
        final result = await calendar.deleteList(id: 'fakeid');
        expect(result, isFalse);
      });

      test('returns true if successful', () async {
        final result = await calendar.deleteList(id: 'fakeid');
        expect(result, isTrue);
      });
    });

    group('deleteTask:', () {
      test('returns false if api call fails', () async {
        when(eventsResource.delete(any, any))
            .thenThrow(Exception('Failed to delete task'));
        final result = await calendar.deleteTask(
          taskListId: 'fakeid',
          taskId: 'fakeid',
        );
        expect(result, isFalse);
      });

      test('returns true if successful', () async {
        final result = await calendar.deleteTask(
          taskListId: 'fakeid',
          taskId: 'fakeid',
        );
        expect(result, isTrue);
      });
    });

    group('updateList:', () {
      test('returns null if api call fails', () async {
        when(calendarsResource.update(any, any))
            .thenThrow(Exception('Failed to update list'));
        final result = await calendar.updateList(list: TaskList.empty());
        expect(result, isNull);
      });

      test('returns updated TaskList if successful', () async {
        final fakeTaskList = TaskList(
          id: 'fakeid',
          title: 'fake title',
          items: const [],
          index: 3,
        );

        when(calendarsResource.update(any, any))
            .thenAnswer((Invocation invocation) async {
          return invocation.positionalArguments[0] as Calendar;
        });

        final result = await calendar.updateList(list: fakeTaskList);
        expect(result, fakeTaskList);
      });
    });

    group('createTask:', () {
      test('returns null if api call fails', () async {
        when(eventsResource.insert(any, any))
            .thenThrow(Exception('Failed to create task'));
        final result = await calendar.createTask(
          taskListId: 'fakeid',
          newTask: Task.empty(),
        );
        expect(result, isNull);
      });

      test('returns null if _api.events.insert fails', () async {
        when(eventsResource.insert(any, any))
            .thenThrow(Exception('Failed to create task'));
        final result = await calendar.createTask(
          taskListId: 'fakeid',
          newTask: Task.empty(),
        );
        expect(result, isNull);
      });

      test('returns Task if successful', () async {
        final fakeTask = Task(
          taskListId: 'fakeid',
          title: 'fake task',
        );

        when(eventsResource.insert(any, any)).thenAnswer((_) async => Event(
              id: 'fakeid',
              description: jsonEncode(fakeTask.toJson()),
              summary: 'fake task',
              start: EventDateTime(
                dateTime: DateTime.now(),
              ),
              end: EventDateTime(
                dateTime: DateTime.now(),
              ),
            ));

        final result = await calendar.createTask(
          taskListId: 'fakeid',
          newTask: fakeTask,
        );

        expect(result, fakeTask.copyWith(id: 'fakeid'));
      });
    });

    group('updateTask:', () {
      test('returns null if api call fails', () async {
        when(eventsResource.update(any, any, any))
            .thenThrow(DetailedApiRequestError(404, 'Not Found'));
        final result = await calendar.updateTask(
          taskListId: 'fakeid',
          updatedTask: Task.empty(),
        );
        expect(result, isNull);
      });

      test('returns updated Task if successful', () async {
        final fakeTask = Task(
          id: 'fakeid',
          taskListId: 'fakeid',
          title: 'fake task',
          completed: true,
        );

        when(eventsResource.update(any, any, any)).thenAnswer((_) async => Event(
              id: 'fakeid',
              description: jsonEncode(fakeTask.toJson()),
              summary: 'fake task',
              start: EventDateTime(
                dateTime: DateTime.now(),
              ),
              end: EventDateTime(
                dateTime: DateTime.now(),
              ),
            ));

        final result = await calendar.updateTask(
          taskListId: 'fakeid',
          updatedTask: fakeTask,
        );

        expect(result, fakeTask.copyWith(id: 'fakeid'));
      });
    });
  });

  group('CalendarHelper:', () {
    group('toModel:', () {
      test('returns null if api request fails', () async {
        when(eventsResource.list(any)).thenThrow(Exception());
        final calendar = Calendar(id: 'fakeid');
        final result = await calendar.toModel(calendarApi);
        expect(result, isNull);
      });

      test('returns TaskList if calendar is not null', () async {
        final calendar = Calendar(id: 'fakeid');
        final result = await calendar.toModel(calendarApi);
        expect(result, isA<TaskList>());
        expect(result!.id, 'fakeid');
      });
    });
  });
}
