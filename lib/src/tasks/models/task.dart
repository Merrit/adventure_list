import 'package:equatable/equatable.dart';

class Task extends Equatable {
  final bool completed;

  final bool deleted;

  final String? description;

  final DateTime? dueDate;

  /// ETag of the resource.
  final String etag;

  // final bool hidden;

  final String id;

  // final String? notes;

  // final String? parent;

  // final String position;

  // final String status;

  /// Title of the task.
  final String title;

  final DateTime updated;

  Task({
    this.completed = false,
    this.deleted = false,
    this.description,
    this.dueDate,
    this.etag = '',
    // required this.hidden,
    this.id = '',
    // required this.notes,
    // required this.parent,
    // required this.position,
    // required this.status,
    required this.title,
    DateTime? updated,
  }) : updated = updated ?? DateTime.now();

  @override
  List<Object?> get props {
    return [
      completed,
      deleted,
      description,
      dueDate,
      etag,
      // hidden,
      id,
      // notes,
      // parent,
      // position,
      // status,
      title,
      updated,
    ];
  }

  Task copyWith({
    bool? completed,
    bool? deleted,
    String? description,
    DateTime? due,
    String? etag,
    bool? hidden,
    String? id,
    String? notes,
    String? parent,
    String? position,
    String? status,
    String? title,
    DateTime? updated,
  }) {
    return Task(
      completed: completed ?? this.completed,
      deleted: deleted ?? this.deleted,
      description: description ?? this.description,
      dueDate: due ?? dueDate,
      etag: etag ?? this.etag,
      // hidden: hidden ?? this.hidden,
      id: id ?? this.id,
      // notes: notes ?? this.notes,
      // parent: parent ?? this.parent,
      // position: position ?? this.position,
      // status: status ?? this.status,
      title: title ?? this.title,
      updated: updated ?? this.updated,
    );
  }
}

///
/// class Event {
///   /// Whether anyone can invite themselves to the event (deprecated).
///   ///
///   /// Optional. The default is False.
///   core.bool? anyoneCanAddSelf;
///
///   /// File attachments for the event.
///   /// In order to modify attachments the supportsAttachments request parameter
///   /// should be set to true.
///   /// There can be at most 25 attachments per event,
///   core.List<EventAttachment>? attachments;

///   /// The attendees of the event.
///   ///
///   /// See the Events with attendees guide for more information on scheduling
///   /// events with other calendar users. Service accounts need to use domain-wide
///   /// delegation of authority to populate the attendee list.
///   core.List<EventAttendee>? attendees;

///   /// Whether attendees may have been omitted from the event's representation.
///   ///
///   /// When retrieving an event, this may be due to a restriction specified by
///   /// the maxAttendee query parameter. When updating an event, this can be used
///   /// to only update the participant's response. Optional. The default is False.
///   core.bool? attendeesOmitted;

///   /// The color of the event.
///   ///
///   /// This is an ID referring to an entry in the event section of the colors
///   /// definition (see the colors endpoint). Optional.
///   core.String? colorId;

///   /// The conference-related information, such as details of a Google Meet
///   /// conference.
///   ///
///   /// To create new conference details use the createRequest field. To persist
///   /// your changes, remember to set the conferenceDataVersion request parameter
///   /// to 1 for all event modification requests.
///   ConferenceData? conferenceData;

///   /// Creation time of the event (as a RFC3339 timestamp).
///   ///
///   /// Read-only.
///   core.DateTime? created;

///   /// The creator of the event.
///   ///
///   /// Read-only.
///   EventCreator? creator;

///   /// Description of the event.
///   ///
///   /// Can contain HTML. Optional.
///   core.String? description;

///   /// The (exclusive) end time of the event.
///   ///
///   /// For a recurring event, this is the end time of the first instance.
///   EventDateTime? end;

///   /// Whether the end time is actually unspecified.
///   ///
///   /// An end time is still provided for compatibility reasons, even if this
///   /// attribute is set to True. The default is False.
///   core.bool? endTimeUnspecified;

///   /// ETag of the resource.
///   core.String? etag;

///   /// Specific type of the event.
///   ///
///   /// Read-only. Possible values are:
///   /// - "default" - A regular event or not further specified.
///   /// - "outOfOffice" - An out-of-office event.
///   /// - "focusTime" - A focus-time event.
///   core.String? eventType;

///   /// Extended properties of the event.
///   EventExtendedProperties? extendedProperties;

///   /// A gadget that extends this event.
///   ///
///   /// Gadgets are deprecated; this structure is instead only used for returning
///   /// birthday calendar metadata.
///   EventGadget? gadget;

///   /// Whether attendees other than the organizer can invite others to the event.
///   ///
///   /// Optional. The default is True.
///   core.bool? guestsCanInviteOthers;

///   /// Whether attendees other than the organizer can modify the event.
///   ///
///   /// Optional. The default is False.
///   core.bool? guestsCanModify;

///   /// Whether attendees other than the organizer can see who the event's
///   /// attendees are.
///   ///
///   /// Optional. The default is True.
///   core.bool? guestsCanSeeOtherGuests;

///   /// An absolute link to the Google Hangout associated with this event.
///   ///
///   /// Read-only.
///   core.String? hangoutLink;

///   /// An absolute link to this event in the Google Calendar Web UI.
///   ///
///   /// Read-only.
///   core.String? htmlLink;

///   /// Event unique identifier as defined in RFC5545.
///   ///
///   /// It is used to uniquely identify events accross calendaring systems and
///   /// must be supplied when importing events via the import method.
///   /// Note that the icalUID and the id are not identical and only one of them
///   /// should be supplied at event creation time. One difference in their
///   /// semantics is that in recurring events, all occurrences of one event have
///   /// different ids while they all share the same icalUIDs.
///   core.String? iCalUID;

///   /// Opaque identifier of the event.
///   ///
///   /// When creating new single or recurring events, you can specify their IDs.
///   /// Provided IDs must follow these rules:
///   /// - characters allowed in the ID are those used in base32hex encoding, i.e.
///   /// lowercase letters a-v and digits 0-9, see section 3.1.2 in RFC2938
///   /// - the length of the ID must be between 5 and 1024 characters
///   /// - the ID must be unique per calendar Due to the globally distributed
///   /// nature of the system, we cannot guarantee that ID collisions will be
///   /// detected at event creation time. To minimize the risk of collisions we
///   /// recommend using an established UUID algorithm such as one described in
///   /// RFC4122.
///   /// If you do not specify an ID, it will be automatically generated by the
///   /// server.
///   /// Note that the icalUID and the id are not identical and only one of them
///   /// should be supplied at event creation time. One difference in their
///   /// semantics is that in recurring events, all occurrences of one event have
///   /// different ids while they all share the same icalUIDs.
///   core.String? id;

///   /// Type of the resource ("calendar#event").
///   core.String? kind;

///   /// Geographic location of the event as free-form text.
///   ///
///   /// Optional.
///   core.String? location;

///   /// Whether this is a locked event copy where no changes can be made to the
///   /// main event fields "summary", "description", "location", "start", "end" or
///   /// "recurrence".
///   ///
///   /// The default is False. Read-Only.
///   core.bool? locked;

///   /// The organizer of the event.
///   ///
///   /// If the organizer is also an attendee, this is indicated with a separate
///   /// entry in attendees with the organizer field set to True. To change the
///   /// organizer, use the move operation. Read-only, except when importing an
///   /// event.
///   EventOrganizer? organizer;

///   /// For an instance of a recurring event, this is the time at which this event
///   /// would start according to the recurrence data in the recurring event
///   /// identified by recurringEventId.
///   ///
///   /// It uniquely identifies the instance within the recurring event series even
///   /// if the instance was moved to a different time. Immutable.
///   EventDateTime? originalStartTime;

///   /// If set to True, Event propagation is disabled.
///   ///
///   /// Note that it is not the same thing as Private event properties. Optional.
///   /// Immutable. The default is False.
///   core.bool? privateCopy;

///   /// List of RRULE, EXRULE, RDATE and EXDATE lines for a recurring event, as
///   /// specified in RFC5545.
///   ///
///   /// Note that DTSTART and DTEND lines are not allowed in this field; event
///   /// start and end times are specified in the start and end fields. This field
///   /// is omitted for single events or instances of recurring events.
///   core.List<core.String>? recurrence;

///   /// For an instance of a recurring event, this is the id of the recurring
///   /// event to which this instance belongs.
///   ///
///   /// Immutable.
///   core.String? recurringEventId;

///   /// Information about the event's reminders for the authenticated user.
///   EventReminders? reminders;

///   /// Sequence number as per iCalendar.
///   core.int? sequence;

///   /// Source from which the event was created.
///   ///
///   /// For example, a web page, an email message or any document identifiable by
///   /// an URL with HTTP or HTTPS scheme. Can only be seen or modified by the
///   /// creator of the event.
///   EventSource? source;

///   /// The (inclusive) start time of the event.
///   ///
///   /// For a recurring event, this is the start time of the first instance.
///   EventDateTime? start;

///   /// Status of the event.
///   ///
///   /// Optional. Possible values are:
///   /// - "confirmed" - The event is confirmed. This is the default status.
///   /// - "tentative" - The event is tentatively confirmed.
///   /// - "cancelled" - The event is cancelled (deleted). The list method returns
///   /// cancelled events only on incremental sync (when syncToken or updatedMin
///   /// are specified) or if the showDeleted flag is set to true. The get method
///   /// always returns them.
///   /// A cancelled status represents two different states depending on the event
///   /// type:
///   /// - Cancelled exceptions of an uncancelled recurring event indicate that
///   /// this instance should no longer be presented to the user. Clients should
///   /// store these events for the lifetime of the parent recurring event.
///   /// Cancelled exceptions are only guaranteed to have values for the id,
///   /// recurringEventId and originalStartTime fields populated. The other fields
///   /// might be empty.
///   /// - All other cancelled events represent deleted events. Clients should
///   /// remove their locally synced copies. Such cancelled events will eventually
///   /// disappear, so do not rely on them being available indefinitely.
///   /// Deleted events are only guaranteed to have the id field populated. On the
///   /// organizer's calendar, cancelled events continue to expose event details
///   /// (summary, location, etc.) so that they can be restored (undeleted).
///   /// Similarly, the events to which the user was invited and that they manually
///   /// removed continue to provide details. However, incremental sync requests
///   /// with showDeleted set to false will not return these details.
///   /// If an event changes its organizer (for example via the move operation) and
///   /// the original organizer is not on the attendee list, it will leave behind a
///   /// cancelled event where only the id field is guaranteed to be populated.
///   core.String? status;

///   /// Title of the event.
///   core.String? summary;

///   /// Whether the event blocks time on the calendar.
///   ///
///   /// Optional. Possible values are:
///   /// - "opaque" - Default value. The event does block time on the calendar.
///   /// This is equivalent to setting Show me as to Busy in the Calendar UI.
///   /// - "transparent" - The event does not block time on the calendar. This is
///   /// equivalent to setting Show me as to Available in the Calendar UI.
///   core.String? transparency;

///   /// Last modification time of the event (as a RFC3339 timestamp).
///   ///
///   /// Read-only.
///   core.DateTime? updated;

///   /// Visibility of the event.
///   ///
///   /// Optional. Possible values are:
///   /// - "default" - Uses the default visibility for events on the calendar. This
///   /// is the default value.
///   /// - "public" - The event is public and event details are visible to all
///   /// readers of the calendar.
///   /// - "private" - The event is private and only event attendees may view event
///   /// details.
///   /// - "confidential" - The event is private. This value is provided for
///   /// compatibility reasons.
///   core.String? visibility;

///   Event({
///     this.anyoneCanAddSelf,
///     this.attachments,
///     this.attendees,
///     this.attendeesOmitted,
///     this.colorId,
///     this.conferenceData,
///     this.created,
///     this.creator,
///     this.description,
///     this.end,
///     this.endTimeUnspecified,
///     this.etag,
///     this.eventType,
///     this.extendedProperties,
///     this.gadget,
///     this.guestsCanInviteOthers,
///     this.guestsCanModify,
///     this.guestsCanSeeOtherGuests,
///     this.hangoutLink,
///     this.htmlLink,
///     this.iCalUID,
///     this.id,
///     this.kind,
///     this.location,
///     this.locked,
///     this.organizer,
///     this.originalStartTime,
///     this.privateCopy,
///     this.recurrence,
///     this.recurringEventId,
///     this.reminders,
///     this.sequence,
///     this.source,
///     this.start,
///     this.status,
///     this.summary,
///     this.transparency,
///     this.updated,
///     this.visibility,
///   });

///   Event.fromJson(core.Map _json)
///       : this(
///           anyoneCanAddSelf: _json.containsKey('anyoneCanAddSelf')
///               ? _json['anyoneCanAddSelf'] as core.bool
///               : null,
///           attachments: _json.containsKey('attachments')
///               ? (_json['attachments'] as core.List)
///                   .map((value) => EventAttachment.fromJson(
///                       value as core.Map<core.String, core.dynamic>))
///                   .toList()
///               : null,
///           attendees: _json.containsKey('attendees')
///               ? (_json['attendees'] as core.List)
///                   .map((value) => EventAttendee.fromJson(
///                       value as core.Map<core.String, core.dynamic>))
///                   .toList()
///               : null,
///           attendeesOmitted: _json.containsKey('attendeesOmitted')
///               ? _json['attendeesOmitted'] as core.bool
///               : null,
///           colorId: _json.containsKey('colorId')
///               ? _json['colorId'] as core.String
///               : null,
///           conferenceData: _json.containsKey('conferenceData')
///               ? ConferenceData.fromJson(_json['conferenceData']
///                   as core.Map<core.String, core.dynamic>)
///               : null,
///           created: _json.containsKey('created')
///               ? core.DateTime.parse(_json['created'] as core.String)
///               : null,
///           creator: _json.containsKey('creator')
///               ? EventCreator.fromJson(
///                   _json['creator'] as core.Map<core.String, core.dynamic>)
///               : null,
///           description: _json.containsKey('description')
///               ? _json['description'] as core.String
///               : null,
///           end: _json.containsKey('end')
///               ? EventDateTime.fromJson(
///                   _json['end'] as core.Map<core.String, core.dynamic>)
///               : null,
///           endTimeUnspecified: _json.containsKey('endTimeUnspecified')
///               ? _json['endTimeUnspecified'] as core.bool
///               : null,
///           etag: _json.containsKey('etag') ? _json['etag'] as core.String : null,
///           eventType: _json.containsKey('eventType')
///               ? _json['eventType'] as core.String
///               : null,
///           extendedProperties: _json.containsKey('extendedProperties')
///               ? EventExtendedProperties.fromJson(_json['extendedProperties']
///                   as core.Map<core.String, core.dynamic>)
///               : null,
///           gadget: _json.containsKey('gadget')
///               ? EventGadget.fromJson(
///                   _json['gadget'] as core.Map<core.String, core.dynamic>)
///               : null,
///           guestsCanInviteOthers: _json.containsKey('guestsCanInviteOthers')
///               ? _json['guestsCanInviteOthers'] as core.bool
///               : null,
///           guestsCanModify: _json.containsKey('guestsCanModify')
///               ? _json['guestsCanModify'] as core.bool
///               : null,
///           guestsCanSeeOtherGuests: _json.containsKey('guestsCanSeeOtherGuests')
///               ? _json['guestsCanSeeOtherGuests'] as core.bool
///               : null,
///           hangoutLink: _json.containsKey('hangoutLink')
///               ? _json['hangoutLink'] as core.String
///               : null,
///           htmlLink: _json.containsKey('htmlLink')
///               ? _json['htmlLink'] as core.String
///               : null,
///           iCalUID: _json.containsKey('iCalUID')
///               ? _json['iCalUID'] as core.String
///               : null,
///           id: _json.containsKey('id') ? _json['id'] as core.String : null,
///           kind: _json.containsKey('kind') ? _json['kind'] as core.String : null,
///           location: _json.containsKey('location')
///               ? _json['location'] as core.String
///               : null,
///           locked:
///               _json.containsKey('locked') ? _json['locked'] as core.bool : null,
///           organizer: _json.containsKey('organizer')
///               ? EventOrganizer.fromJson(
///                   _json['organizer'] as core.Map<core.String, core.dynamic>)
///               : null,
///           originalStartTime: _json.containsKey('originalStartTime')
///               ? EventDateTime.fromJson(_json['originalStartTime']
///                   as core.Map<core.String, core.dynamic>)
///               : null,
///           privateCopy: _json.containsKey('privateCopy')
///               ? _json['privateCopy'] as core.bool
///               : null,
///           recurrence: _json.containsKey('recurrence')
///               ? (_json['recurrence'] as core.List)
///                   .map((value) => value as core.String)
///                   .toList()
///               : null,
///           recurringEventId: _json.containsKey('recurringEventId')
///               ? _json['recurringEventId'] as core.String
///               : null,
///           reminders: _json.containsKey('reminders')
///               ? EventReminders.fromJson(
///                   _json['reminders'] as core.Map<core.String, core.dynamic>)
///               : null,
///           sequence: _json.containsKey('sequence')
///               ? _json['sequence'] as core.int
///               : null,
///           source: _json.containsKey('source')
///               ? EventSource.fromJson(
///                   _json['source'] as core.Map<core.String, core.dynamic>)
///               : null,
///           start: _json.containsKey('start')
///               ? EventDateTime.fromJson(
///                   _json['start'] as core.Map<core.String, core.dynamic>)
///               : null,
///           status: _json.containsKey('status')
///               ? _json['status'] as core.String
///               : null,
///           summary: _json.containsKey('summary')
///               ? _json['summary'] as core.String
///               : null,
///           transparency: _json.containsKey('transparency')
///               ? _json['transparency'] as core.String
///               : null,
///           updated: _json.containsKey('updated')
///               ? core.DateTime.parse(_json['updated'] as core.String)
///               : null,
///           visibility: _json.containsKey('visibility')
///               ? _json['visibility'] as core.String
///               : null,
///         );

///   core.Map<core.String, core.dynamic> toJson() => {
///         if (anyoneCanAddSelf != null) 'anyoneCanAddSelf': anyoneCanAddSelf!,
///         if (attachments != null) 'attachments': attachments!,
///         if (attendees != null) 'attendees': attendees!,
///         if (attendeesOmitted != null) 'attendeesOmitted': attendeesOmitted!,
///         if (colorId != null) 'colorId': colorId!,
///         if (conferenceData != null) 'conferenceData': conferenceData!,
///         if (created != null) 'created': created!.toUtc().toIso8601String(),
///         if (creator != null) 'creator': creator!,
///         if (description != null) 'description': description!,
///         if (end != null) 'end': end!,
///         if (endTimeUnspecified != null)
///           'endTimeUnspecified': endTimeUnspecified!,
///         if (etag != null) 'etag': etag!,
///         if (eventType != null) 'eventType': eventType!,
///         if (extendedProperties != null)
///           'extendedProperties': extendedProperties!,
///         if (gadget != null) 'gadget': gadget!,
///         if (guestsCanInviteOthers != null)
///           'guestsCanInviteOthers': guestsCanInviteOthers!,
///         if (guestsCanModify != null) 'guestsCanModify': guestsCanModify!,
///         if (guestsCanSeeOtherGuests != null)
///           'guestsCanSeeOtherGuests': guestsCanSeeOtherGuests!,
///         if (hangoutLink != null) 'hangoutLink': hangoutLink!,
///         if (htmlLink != null) 'htmlLink': htmlLink!,
///         if (iCalUID != null) 'iCalUID': iCalUID!,
///         if (id != null) 'id': id!,
///         if (kind != null) 'kind': kind!,
///         if (location != null) 'location': location!,
///         if (locked != null) 'locked': locked!,
///         if (organizer != null) 'organizer': organizer!,
///         if (originalStartTime != null) 'originalStartTime': originalStartTime!,
///         if (privateCopy != null) 'privateCopy': privateCopy!,
///         if (recurrence != null) 'recurrence': recurrence!,
///         if (recurringEventId != null) 'recurringEventId': recurringEventId!,
///         if (reminders != null) 'reminders': reminders!,
///         if (sequence != null) 'sequence': sequence!,
///         if (source != null) 'source': source!,
///         if (start != null) 'start': start!,
///         if (status != null) 'status': status!,
///         if (summary != null) 'summary': summary!,
///         if (transparency != null) 'transparency': transparency!,
///         if (updated != null) 'updated': updated!.toUtc().toIso8601String(),
///         if (visibility != null) 'visibility': visibility!,
///       };
/// }