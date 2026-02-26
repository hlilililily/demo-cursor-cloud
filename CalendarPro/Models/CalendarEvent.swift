import Foundation
import CoreGraphics
import EventKit

/// Represents a calendar event, wrapping EKEvent for use throughout the app.
struct CalendarEvent: Identifiable, Hashable {
    let id: String
    var title: String
    var location: String?
    var notes: String?
    var url: URL?
    var startDate: Date
    var endDate: Date
    var isAllDay: Bool
    var calendarIdentifier: String
    var calendarTitle: String
    var calendarColor: CGColor?
    var recurrenceRules: [EventRecurrence]
    var alarms: [EventAlarm]
    var availability: EventAvailability
    var status: EventStatus
    var organizer: String?
    var attendees: [String]
    var timeZone: TimeZone?

    enum EventAvailability: Int, CaseIterable {
        case busy = 0
        case free = 1
        case tentative = 2
        case unavailable = 3

        var label: String {
            switch self {
            case .busy: "Busy"
            case .free: "Free"
            case .tentative: "Tentative"
            case .unavailable: "Unavailable"
            }
        }
    }

    enum EventStatus: Int {
        case none = 0
        case confirmed = 1
        case tentative = 2
        case canceled = 3
    }

    init(from ekEvent: EKEvent) {
        self.id = ekEvent.eventIdentifier ?? UUID().uuidString
        self.title = ekEvent.title ?? ""
        self.location = ekEvent.location
        self.notes = ekEvent.notes
        self.url = ekEvent.url
        self.startDate = ekEvent.startDate
        self.endDate = ekEvent.endDate
        self.isAllDay = ekEvent.isAllDay
        self.calendarIdentifier = ekEvent.calendar?.calendarIdentifier ?? ""
        self.calendarTitle = ekEvent.calendar?.title ?? ""
        self.calendarColor = ekEvent.calendar?.cgColor
        self.recurrenceRules = ekEvent.recurrenceRules?.map { EventRecurrence(from: $0) } ?? []
        self.alarms = ekEvent.alarms?.map { EventAlarm(from: $0) } ?? []
        self.availability = EventAvailability(rawValue: ekEvent.availability.rawValue) ?? .busy
        self.status = EventStatus(rawValue: ekEvent.status.rawValue) ?? .none
        self.organizer = ekEvent.organizer?.name
        self.attendees = ekEvent.attendees?.compactMap { $0.name } ?? []
        self.timeZone = ekEvent.timeZone
    }

    init(
        id: String = UUID().uuidString,
        title: String = "",
        location: String? = nil,
        notes: String? = nil,
        url: URL? = nil,
        startDate: Date = Date(),
        endDate: Date = Date().addingTimeInterval(3600),
        isAllDay: Bool = false,
        calendarIdentifier: String = "",
        calendarTitle: String = "",
        calendarColor: CGColor? = nil,
        recurrenceRules: [EventRecurrence] = [],
        alarms: [EventAlarm] = [],
        availability: EventAvailability = .busy,
        status: EventStatus = .none,
        organizer: String? = nil,
        attendees: [String] = [],
        timeZone: TimeZone? = nil
    ) {
        self.id = id
        self.title = title
        self.location = location
        self.notes = notes
        self.url = url
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.calendarIdentifier = calendarIdentifier
        self.calendarTitle = calendarTitle
        self.calendarColor = calendarColor
        self.recurrenceRules = recurrenceRules
        self.alarms = alarms
        self.availability = availability
        self.status = status
        self.organizer = organizer
        self.attendees = attendees
        self.timeZone = timeZone
    }

    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    var isMultiDay: Bool {
        !Calendar.current.isDate(startDate, inSameDayAs: endDate)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CalendarEvent, rhs: CalendarEvent) -> Bool {
        lhs.id == rhs.id
    }
}
