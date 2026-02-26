import Foundation
import EventKit
import Observation

/// Manages all interactions with the system EventKit framework.
/// Prioritizes iCloud calendars for storage to ensure cross-device sync.
@Observable
final class EventKitManager {
    private let store = EKEventStore()

    var authorizationStatus: EKAuthorizationStatus = .notDetermined
    var calendars: [EKCalendar] = []
    var sources: [EKSource] = []

    /// Reference to CloudKit manager for sync status updates.
    var cloudKitManager: CloudKitManager?

    /// Reference to synced settings for persisting calendar visibility across devices.
    var syncedSettings: SyncedSettings?

    /// Calendar IDs the user has toggled visible (delegates to SyncedSettings when available).
    var visibleCalendarIDs: Set<String> {
        get { syncedSettings?.visibleCalendarIDs ?? _localVisibleIDs }
        set {
            if let settings = syncedSettings {
                settings.visibleCalendarIDs = newValue
            } else {
                _localVisibleIDs = newValue
                UserDefaults.standard.set(Array(newValue), forKey: "visibleCalendarIDs")
            }
        }
    }
    private var _localVisibleIDs: Set<String> = Set(
        UserDefaults.standard.stringArray(forKey: "visibleCalendarIDs") ?? []
    )

    /// The preferred iCloud calendar for new events.
    var defaultCalendar: EKCalendar? {
        // 1. User's explicitly preferred calendar
        if let prefID = syncedSettings?.preferredCalendarID,
           let cal = store.calendar(withIdentifier: prefID) {
            return cal
        }
        // 2. First writable iCloud calendar
        if let iCloudCal = preferredICloudCalendar {
            return iCloudCal
        }
        // 3. System default
        return store.defaultCalendarForNewEvents
    }

    /// The best available iCloud source for creating calendars.
    var iCloudSource: EKSource? {
        sources.first { $0.sourceType == .calDAV && $0.title.lowercased().contains("icloud") }
        ?? sources.first { $0.sourceType == .calDAV }
    }

    /// Whether iCloud calendars are available.
    var hasICloudCalendars: Bool {
        iCloudCalendars.isEmpty == false
    }

    /// All iCloud calendars.
    var iCloudCalendars: [EKCalendar] {
        calendars.filter { cal in
            cal.source?.sourceType == .calDAV &&
            (cal.source?.title.lowercased().contains("icloud") ?? false)
        }
    }

    /// First writable iCloud calendar.
    private var preferredICloudCalendar: EKCalendar? {
        iCloudCalendars.first { $0.allowsContentModifications }
    }

    init() {
        self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        if authorizationStatus == .fullAccess || authorizationStatus == .authorized {
            reloadCalendars()
        }
        observeStoreChanges()
    }

    // MARK: - Authorization

    func requestAccess() async -> Bool {
        do {
            let granted: Bool
            if #available(iOS 17.0, macOS 14.0, *) {
                granted = try await store.requestFullAccessToEvents()
            } else {
                granted = try await store.requestAccess(to: .event)
            }
            await MainActor.run {
                authorizationStatus = EKEventStore.authorizationStatus(for: .event)
                if granted {
                    reloadCalendars()
                    if visibleCalendarIDs.isEmpty {
                        visibleCalendarIDs = Set(calendars.map(\.calendarIdentifier))
                    }
                    ensureICloudCalendarExists()
                }
            }
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Calendar Operations

    func reloadCalendars() {
        store.refreshSourcesIfNecessary()
        calendars = store.calendars(for: .event)
            .sorted { lhs, rhs in
                let lhsICloud = isICloudCalendar(lhs)
                let rhsICloud = isICloudCalendar(rhs)
                if lhsICloud != rhsICloud { return lhsICloud }
                return lhs.title.localizedCompare(rhs.title) == .orderedAscending
            }
        sources = store.sources
            .filter { !$0.calendars(for: .event).isEmpty }
            .sorted { lhs, rhs in
                let lhsICloud = lhs.sourceType == .calDAV && lhs.title.lowercased().contains("icloud")
                let rhsICloud = rhs.sourceType == .calDAV && rhs.title.lowercased().contains("icloud")
                if lhsICloud != rhsICloud { return lhsICloud }
                return lhs.title.localizedCompare(rhs.title) == .orderedAscending
            }
    }

    func calendarGroups() -> [CalendarGroup] {
        sources.map { CalendarGroup(from: $0, visibleCalendarIDs: visibleCalendarIDs) }
    }

    func calendar(withIdentifier id: String) -> EKCalendar? {
        store.calendar(withIdentifier: id)
    }

    func createCalendar(title: String, color: CGColor, source: EKSource? = nil) throws -> EKCalendar {
        let cal = EKCalendar(for: .event, eventStore: store)
        cal.title = title
        cal.cgColor = color
        // Prefer iCloud source for cross-device sync
        cal.source = source ?? iCloudSource ?? store.defaultCalendarForNewEvents?.source ?? store.sources.first
        try store.saveCalendar(cal, commit: true)
        reloadCalendars()
        visibleCalendarIDs.insert(cal.calendarIdentifier)
        cloudKitManager?.markSynced()
        return cal
    }

    func deleteCalendar(_ calendar: EKCalendar) throws {
        try store.removeCalendar(calendar, commit: true)
        var ids = visibleCalendarIDs
        ids.remove(calendar.calendarIdentifier)
        visibleCalendarIDs = ids
        reloadCalendars()
        cloudKitManager?.markSynced()
    }

    // MARK: - iCloud Calendar Management

    /// Ensures at least one iCloud calendar exists; creates a default one if needed.
    func ensureICloudCalendarExists() {
        guard let source = iCloudSource, iCloudCalendars.isEmpty else { return }
        do {
            let cal = try createCalendar(
                title: "CalendarPro",
                color: {
                    #if canImport(UIKit)
                    return UIColor.systemBlue.cgColor
                    #else
                    return NSColor.systemBlue.cgColor
                    #endif
                }(),
                source: source
            )
            // Set as preferred calendar
            syncedSettings?.preferredCalendarID = cal.calendarIdentifier
        } catch {
            print("Failed to create default iCloud calendar: \(error.localizedDescription)")
        }
    }

    private func isICloudCalendar(_ calendar: EKCalendar) -> Bool {
        calendar.source?.sourceType == .calDAV &&
        (calendar.source?.title.lowercased().contains("icloud") ?? false)
    }

    // MARK: - Event Operations

    func fetchEvents(from startDate: Date, to endDate: Date) -> [CalendarEvent] {
        let visibleCals = calendars.filter { visibleCalendarIDs.contains($0.calendarIdentifier) }
        guard !visibleCals.isEmpty else { return [] }

        let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: visibleCals)
        return store.events(matching: predicate)
            .map { CalendarEvent(from: $0) }
            .sorted { $0.startDate < $1.startDate }
    }

    func fetchEvents(for date: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }
        return fetchEvents(from: start, to: end)
    }

    func fetchEvents(forMonth date: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: date) else { return [] }
        let paddedStart = calendar.date(byAdding: .day, value: -7, to: interval.start) ?? interval.start
        let paddedEnd = calendar.date(byAdding: .day, value: 7, to: interval.end) ?? interval.end
        return fetchEvents(from: paddedStart, to: paddedEnd)
    }

    func fetchEvents(forWeekOf date: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: date) else { return [] }
        return fetchEvents(from: interval.start, to: interval.end)
    }

    func event(withIdentifier id: String) -> CalendarEvent? {
        guard let ekEvent = store.event(withIdentifier: id) else { return nil }
        return CalendarEvent(from: ekEvent)
    }

    @discardableResult
    func createEvent(_ event: CalendarEvent) throws -> String {
        cloudKitManager?.markSyncing()
        let ekEvent = EKEvent(eventStore: store)
        applyEventProperties(event, to: ekEvent)
        try store.save(ekEvent, span: .thisEvent)
        cloudKitManager?.markSynced()
        return ekEvent.eventIdentifier
    }

    func updateEvent(_ event: CalendarEvent, span: EKSpan = .thisEvent) throws {
        cloudKitManager?.markSyncing()
        guard let ekEvent = store.event(withIdentifier: event.id) else { return }
        applyEventProperties(event, to: ekEvent)
        try store.save(ekEvent, span: span)
        cloudKitManager?.markSynced()
    }

    func deleteEvent(withIdentifier id: String, span: EKSpan = .thisEvent) throws {
        cloudKitManager?.markSyncing()
        guard let ekEvent = store.event(withIdentifier: id) else { return }
        try store.remove(ekEvent, span: span)
        cloudKitManager?.markSynced()
    }

    // MARK: - Search

    func searchEvents(query: String, from startDate: Date, to endDate: Date) -> [CalendarEvent] {
        let allEvents = fetchEvents(from: startDate, to: endDate)
        let lowered = query.lowercased()
        return allEvents.filter { event in
            event.title.lowercased().contains(lowered) ||
            (event.location?.lowercased().contains(lowered) ?? false) ||
            (event.notes?.lowercased().contains(lowered) ?? false)
        }
    }

    // MARK: - Store Change Observation

    private func observeStoreChanges() {
        NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: store,
            queue: .main
        ) { [weak self] _ in
            self?.reloadCalendars()
            self?.cloudKitManager?.markSynced()
        }
    }

    // MARK: - Helpers

    private func applyEventProperties(_ event: CalendarEvent, to ekEvent: EKEvent) {
        ekEvent.title = event.title
        ekEvent.location = event.location
        ekEvent.notes = event.notes
        ekEvent.url = event.url
        ekEvent.startDate = event.startDate
        ekEvent.endDate = event.endDate
        ekEvent.isAllDay = event.isAllDay
        ekEvent.timeZone = event.timeZone

        if !event.calendarIdentifier.isEmpty,
           let cal = store.calendar(withIdentifier: event.calendarIdentifier) {
            ekEvent.calendar = cal
        } else {
            // Prefer iCloud calendar for new events
            ekEvent.calendar = defaultCalendar
        }

        ekEvent.recurrenceRules = event.recurrenceRules.isEmpty ? nil :
            event.recurrenceRules.map { $0.toEKRecurrenceRule() }

        ekEvent.alarms = event.alarms.isEmpty ? nil :
            event.alarms.map { $0.toEKAlarm() }

        switch event.availability {
        case .busy: ekEvent.availability = .busy
        case .free: ekEvent.availability = .free
        case .tentative: ekEvent.availability = .tentative
        case .unavailable: ekEvent.availability = .unavailable
        }
    }

    /// Date range spanning a full year centered on a month.
    func yearRange(around date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .month, value: -6, to: calendar.startOfDay(for: date))!
        let end = calendar.date(byAdding: .month, value: 6, to: calendar.startOfDay(for: date))!
        return (start, end)
    }
}
