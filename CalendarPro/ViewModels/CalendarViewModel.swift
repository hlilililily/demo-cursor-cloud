import Foundation
import EventKit
import SwiftUI

/// Drives the main calendar UI: view mode, navigation, and event fetching.
@Observable
final class CalendarViewModel {
    enum ViewMode: String, CaseIterable, Identifiable {
        case day, week, month, year
        var id: String { rawValue }

        var label: String {
            switch self {
            case .day: "Day"
            case .week: "Week"
            case .month: "Month"
            case .year: "Year"
            }
        }

        var systemImage: String {
            switch self {
            case .day: "calendar.day.timeline.left"
            case .week: "calendar.day.timeline.leading"
            case .month: "calendar"
            case .year: "calendar.badge.clock"
            }
        }
    }

    let eventKitManager: EventKitManager
    let notificationManager: NotificationManager
    let cloudKitManager: CloudKitManager
    let syncedSettings: SyncedSettings

    var viewMode: ViewMode = .month
    var selectedDate: Date = Date()
    var currentMonth: Date = Date()
    var events: [CalendarEvent] = []
    var selectedEvent: CalendarEvent?
    var showingEventEditor = false
    var showingNewEvent = false
    var showingSearch = false
    var showingSidebar = true
    var showingSettings = false
    var editingEvent: CalendarEvent?

    /// Events grouped by date for the current view.
    var eventsByDate: [Date: [CalendarEvent]] {
        Dictionary(grouping: events) { event in
            Calendar.current.startOfDay(for: event.startDate)
        }
    }

    init(
        cloudKitManager: CloudKitManager = CloudKitManager(),
        eventKitManager: EventKitManager = EventKitManager(),
        notificationManager: NotificationManager = NotificationManager()
    ) {
        self.cloudKitManager = cloudKitManager
        let settings = SyncedSettings(cloudKit: cloudKitManager)
        self.syncedSettings = settings
        self.eventKitManager = eventKitManager
        self.notificationManager = notificationManager

        // Wire up cross-references
        eventKitManager.cloudKitManager = cloudKitManager
        eventKitManager.syncedSettings = settings

        // Restore last-used view mode
        if let savedMode = ViewMode(rawValue: settings.defaultViewMode) {
            self.viewMode = savedMode
        }
    }

    // MARK: - Data Loading

    func loadEvents() {
        switch viewMode {
        case .day:
            events = eventKitManager.fetchEvents(for: selectedDate)
        case .week:
            events = eventKitManager.fetchEvents(forWeekOf: selectedDate)
        case .month:
            events = eventKitManager.fetchEvents(forMonth: currentMonth)
        case .year:
            let range = eventKitManager.yearRange(around: currentMonth)
            events = eventKitManager.fetchEvents(from: range.start, to: range.end)
        }
    }

    func eventsForDate(_ date: Date) -> [CalendarEvent] {
        eventsByDate[Calendar.current.startOfDay(for: date)] ?? []
    }

    func hasEvents(on date: Date) -> Bool {
        !eventsForDate(date).isEmpty
    }

    // MARK: - Navigation

    func goToToday() {
        selectedDate = Date()
        currentMonth = Date()
        loadEvents()
    }

    func navigateForward() {
        switch viewMode {
        case .day:
            selectedDate = selectedDate.addingDays(1)
            currentMonth = selectedDate
        case .week:
            selectedDate = selectedDate.addingWeeks(1)
            currentMonth = selectedDate
        case .month:
            currentMonth = currentMonth.addingMonths(1)
            selectedDate = currentMonth
        case .year:
            let cal = Calendar.current
            currentMonth = cal.date(byAdding: .year, value: 1, to: currentMonth) ?? currentMonth
            selectedDate = currentMonth
        }
        loadEvents()
    }

    func navigateBackward() {
        switch viewMode {
        case .day:
            selectedDate = selectedDate.addingDays(-1)
            currentMonth = selectedDate
        case .week:
            selectedDate = selectedDate.addingWeeks(-1)
            currentMonth = selectedDate
        case .month:
            currentMonth = currentMonth.addingMonths(-1)
            selectedDate = currentMonth
        case .year:
            let cal = Calendar.current
            currentMonth = cal.date(byAdding: .year, value: -1, to: currentMonth) ?? currentMonth
            selectedDate = currentMonth
        }
        loadEvents()
    }

    func selectDate(_ date: Date) {
        selectedDate = date
        if !date.isSameMonth(as: currentMonth) {
            currentMonth = date
        }
        loadEvents()
    }

    func switchToDay(_ date: Date) {
        selectedDate = date
        currentMonth = date
        viewMode = .day
        loadEvents()
    }

    func setViewMode(_ mode: ViewMode) {
        viewMode = mode
        syncedSettings.defaultViewMode = mode.rawValue
        loadEvents()
    }

    // MARK: - Title

    var navigationTitle: String {
        switch viewMode {
        case .day:
            return selectedDate.formatted(.dateTime.weekday(.wide).month(.wide).day())
        case .week:
            let start = selectedDate.startOfWeek
            let end = selectedDate.endOfWeek
            if start.isSameMonth(as: end) {
                return "\(start.monthName) \(start.dayNumber)–\(end.dayNumber), \(start.yearString)"
            }
            return "\(start.shortMonthName) \(start.dayNumber) – \(end.shortMonthName) \(end.dayNumber), \(start.yearString)"
        case .month:
            return currentMonth.monthYearString
        case .year:
            return currentMonth.yearString
        }
    }

    // MARK: - Event CRUD

    func createNewEvent(at date: Date? = nil) {
        let start = date ?? selectedDate
        let cal = Calendar.current
        let hour = cal.component(.hour, from: Date())
        let roundedStart = cal.date(bySettingHour: hour + 1, minute: 0, second: 0, of: start) ?? start

        var newEvent = CalendarEvent(
            title: "",
            startDate: roundedStart,
            endDate: roundedStart.addingTimeInterval(3600),
            calendarIdentifier: eventKitManager.defaultCalendar?.calendarIdentifier ?? ""
        )

        // Apply default alert if configured
        if let offset = syncedSettings.defaultAlertOffset {
            newEvent.alarms = [EventAlarm(offset: offset)]
        }

        editingEvent = newEvent
        showingNewEvent = true
    }

    func saveEvent(_ event: CalendarEvent) {
        do {
            if showingNewEvent {
                try eventKitManager.createEvent(event)
            } else {
                try eventKitManager.updateEvent(event)
            }
            loadEvents()
            showingNewEvent = false
            showingEventEditor = false
            editingEvent = nil
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }

    func deleteEvent(_ event: CalendarEvent, span: EKSpan = .thisEvent) {
        do {
            try eventKitManager.deleteEvent(withIdentifier: event.id, span: span)
            loadEvents()
            selectedEvent = nil
        } catch {
            print("Failed to delete event: \(error.localizedDescription)")
        }
    }

    func editEvent(_ event: CalendarEvent) {
        editingEvent = event
        showingEventEditor = true
    }

    // MARK: - Calendar Visibility

    func toggleCalendarVisibility(_ calendarID: String) {
        var ids = eventKitManager.visibleCalendarIDs
        if ids.contains(calendarID) {
            ids.remove(calendarID)
        } else {
            ids.insert(calendarID)
        }
        eventKitManager.visibleCalendarIDs = ids
        loadEvents()
    }

    func setAllCalendarsVisible(_ visible: Bool) {
        if visible {
            eventKitManager.visibleCalendarIDs = Set(eventKitManager.calendars.map(\.calendarIdentifier))
        } else {
            eventKitManager.visibleCalendarIDs = Set()
        }
        loadEvents()
    }

    // MARK: - iCloud Status

    var iCloudSyncStatus: CloudKitManager.SyncStatus {
        cloudKitManager.syncStatus
    }

    var iCloudAvailable: Bool {
        cloudKitManager.iCloudAvailable
    }
}
