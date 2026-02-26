import Foundation
import Observation

/// User preferences persisted locally (Application Support/CalendarPro/settings.json).
@Observable
final class SyncedSettings {
    private let storage = LocalSettingsStorage()

    // MARK: - Properties

    /// Calendar IDs the user has toggled visible.
    var visibleCalendarIDs: Set<String> {
        didSet { save("visibleCalendarIDs", value: Array(visibleCalendarIDs)) }
    }

    /// Preferred default view mode.
    var defaultViewMode: String {
        didSet { save("defaultViewMode", value: defaultViewMode) }
    }

    /// The identifier of the user's preferred default calendar for new events.
    var preferredCalendarID: String? {
        didSet { save("preferredCalendarID", value: preferredCalendarID) }
    }

    /// Whether week numbers are shown.
    var showWeekNumbers: Bool {
        didSet { save("showWeekNumbers", value: showWeekNumbers) }
    }

    /// First day of the week override (nil = system default).
    var firstWeekday: Int? {
        didSet { save("firstWeekday", value: firstWeekday) }
    }

    /// Default alert offset in seconds (nil = no default alert).
    var defaultAlertOffset: Double? {
        didSet { save("defaultAlertOffset", value: defaultAlertOffset) }
    }

    init() {
        self.visibleCalendarIDs = Set(
            storage.load("visibleCalendarIDs") as [String]? ?? []
        )
        self.defaultViewMode = storage.load("defaultViewMode") ?? "month"
        self.preferredCalendarID = storage.load("preferredCalendarID")
        self.showWeekNumbers = storage.load("showWeekNumbers") ?? false
        let fw: Int? = storage.load("firstWeekday")
        self.firstWeekday = (fw == 0) ? nil : fw
        self.defaultAlertOffset = storage.load("defaultAlertOffset")
    }

    private func save(_ key: String, value: Any?) {
        storage.save(key, value: value)
    }
}
