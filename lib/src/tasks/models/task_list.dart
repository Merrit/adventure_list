import 'package:equatable/equatable.dart';

import '../tasks.dart';

/// A Todo list.
///
/// Analogous to a `Calendar` object from the Google Calendar API.
class TaskList extends Equatable {
  /// The effective access role that the authenticated user has on the calendar.
  ///
  /// Read-only. Possible values are:
  /// - "freeBusyReader" - Provides read access to free/busy information.
  /// - "reader" - Provides read access to the calendar. Private events will
  /// appear to users with reader access, but event details will be hidden.
  /// - "writer" - Provides read and write access to the calendar. Private
  /// events will appear to users with writer access, and event details will be
  /// visible.
  /// - "owner" - Provides ownership of the calendar. This role has all of the
  /// permissions of the writer role with the additional ability to see and
  /// manipulate ACLs.
  final String? accessRole;

  /// The main color of the calendar in the hexadecimal format "#0088aa".
  ///
  /// This property supersedes the index-based colorId property. To set or
  /// change this property, you need to specify colorRgbFormat=true in the
  /// parameters of the insert, update and patch methods. Optional.
  final String? backgroundColor;

  /// The color of the calendar.
  ///
  /// This is an ID referring to an entry in the calendar section of the colors
  /// definition (see the colors endpoint). This property is superseded by the
  /// backgroundColor and foregroundColor properties and can be ignored when
  /// using these properties. Optional.
  final String? colorId;

  /// The default reminders that the authenticated user has for this calendar.
  // final List<EventReminder>? defaultReminders;

  /// Whether this calendar list entry has been deleted from the calendar list.
  ///
  /// Read-only. Optional. The default is False.
  final bool? deleted;

  /// Extended description of the list.
  final String? description;

  /// ETag of the resource.
  final String? etag;

  /// The foreground color of the calendar in the hexadecimal format "#ffffff".
  ///
  /// This property supersedes the index-based colorId property. To set or
  /// change this property, you need to specify colorRgbFormat=true in the
  /// parameters of the insert, update and patch methods. Optional.
  final String? foregroundColor;

  /// Whether the calendar has been hidden from the list.
  ///
  /// Optional. The attribute is only returned when the calendar is hidden, in
  /// which case the value is true.
  final bool? hidden;

  /// Identifier of the calendar.
  final String id;

  final List<Task> items;

  /// Type of the resource ("calendar#calendarListEntry").
  final String? kind;

  /// Geographic location of the calendar as free-form text.
  ///
  /// Optional. Read-only.
  final String? location;

  /// The notifications that the authenticated user is receiving for this
  /// calendar.
  // final CalendarListEntryNotificationSettings? notificationSettings;

  /// Whether the calendar is the primary calendar of the authenticated user.
  ///
  /// Read-only. Optional. The default is False.
  final bool? primary;

  /// Whether the calendar content shows up in the calendar UI.
  ///
  /// Optional. The default is False.
  final bool? selected;

  /// The summary that the authenticated user has set for this calendar.
  ///
  /// Optional.
  final String? summaryOverride;

  /// The time zone of the calendar.
  ///
  /// Optional. Read-only.
  final String? timeZone;

  final String title;

  const TaskList({
    this.accessRole,
    this.backgroundColor,
    this.colorId,
    // this.defaultReminders,
    this.deleted,
    this.description,
    this.etag,
    this.foregroundColor,
    this.hidden,
    required this.id,
    required this.items,
    this.kind,
    this.location,
    // this.notificationSettings,
    this.primary,
    this.selected,
    this.summaryOverride,
    this.timeZone,
    required this.title,
  });

  @override
  List<Object?> get props {
    return [
      accessRole,
      backgroundColor,
      colorId,
      deleted,
      description,
      etag,
      foregroundColor,
      hidden,
      id,
      items,
      kind,
      location,
      primary,
      selected,
      summaryOverride,
      timeZone,
      title,
    ];
  }

  TaskList copyWith({
    String? accessRole,
    String? backgroundColor,
    String? colorId,
    bool? deleted,
    String? description,
    String? etag,
    String? foregroundColor,
    bool? hidden,
    String? id,
    List<Task>? items,
    String? kind,
    String? location,
    bool? primary,
    bool? selected,
    String? summaryOverride,
    String? timeZone,
    String? title,
  }) {
    return TaskList(
      accessRole: accessRole ?? this.accessRole,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      colorId: colorId ?? this.colorId,
      deleted: deleted ?? this.deleted,
      description: description ?? this.description,
      etag: etag ?? this.etag,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      hidden: hidden ?? this.hidden,
      id: id ?? this.id,
      items: items ?? this.items,
      kind: kind ?? this.kind,
      location: location ?? this.location,
      primary: primary ?? this.primary,
      selected: selected ?? this.selected,
      summaryOverride: summaryOverride ?? this.summaryOverride,
      timeZone: timeZone ?? this.timeZone,
      title: title ?? this.title,
    );
  }
}
