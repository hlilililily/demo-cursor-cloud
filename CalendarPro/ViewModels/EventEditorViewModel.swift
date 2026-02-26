import Foundation
import EventKit
import SwiftUI

/// Manages state for the event creation/editing form.
@Observable
final class EventEditorViewModel {
    var title: String
    var location: String
    var notes: String
    var urlString: String
    var startDate: Date
    var endDate: Date
    var isAllDay: Bool
    var calendarIdentifier: String
    var recurrence: EventRecurrence?
    var alarms: [EventAlarm]
    var availability: CalendarEvent.EventAvailability
    var showRecurrencePicker = false
    var showAlarmPicker = false

    private let originalEvent: CalendarEvent?

    var isNewEvent: Bool { originalEvent == nil || originalEvent?.title.isEmpty == true }

    var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    init(event: CalendarEvent? = nil, defaultCalendarID: String = "") {
        let e = event ?? CalendarEvent()
        self.originalEvent = event
        self.title = e.title
        self.location = e.location ?? ""
        self.notes = e.notes ?? ""
        self.urlString = e.url?.absoluteString ?? ""
        self.startDate = e.startDate
        self.endDate = e.endDate
        self.isAllDay = e.isAllDay
        self.calendarIdentifier = e.calendarIdentifier.isEmpty ? defaultCalendarID : e.calendarIdentifier
        self.recurrence = e.recurrenceRules.first
        self.alarms = e.alarms
        self.availability = e.availability
    }

    /// Build a CalendarEvent from the current form state.
    func buildEvent() -> CalendarEvent {
        CalendarEvent(
            id: originalEvent?.id ?? UUID().uuidString,
            title: title.trimmingCharacters(in: .whitespaces),
            location: location.isEmpty ? nil : location,
            notes: notes.isEmpty ? nil : notes,
            url: URL(string: urlString),
            startDate: startDate,
            endDate: endDate,
            isAllDay: isAllDay,
            calendarIdentifier: calendarIdentifier,
            recurrenceRules: recurrence.map { [$0] } ?? [],
            alarms: alarms,
            availability: availability
        )
    }

    func addAlarm(_ alarm: EventAlarm) {
        alarms.append(alarm)
    }

    func removeAlarm(at offsets: IndexSet) {
        alarms.remove(atOffsets: offsets)
    }

    func adjustEndDateIfNeeded() {
        if endDate <= startDate {
            endDate = startDate.addingTimeInterval(3600)
        }
    }

    /// Recurrence preset options for quick selection.
    static let recurrencePresets: [(label: String, rule: EventRecurrence?)] = [
        ("Never", nil),
        ("Every Day", EventRecurrence(frequency: .daily)),
        ("Every Week", EventRecurrence(frequency: .weekly)),
        ("Every 2 Weeks", EventRecurrence(frequency: .weekly, interval: 2)),
        ("Every Month", EventRecurrence(frequency: .monthly)),
        ("Every Year", EventRecurrence(frequency: .yearly)),
    ]

    /// Identifiable wrapper for ForEach.
    struct RecurrencePresetItem: Identifiable {
        let id: String
        let label: String
        let rule: EventRecurrence?
    }

    static var recurrencePresetItems: [RecurrencePresetItem] {
        recurrencePresets.enumerated().map { offset, item in
            RecurrencePresetItem(id: "\(offset)-\(item.label)", label: item.label, rule: item.rule)
        }
    }
}
