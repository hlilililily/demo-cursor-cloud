import Foundation
import Observation

/// User preferences synced across devices via iCloud KVS (NSUbiquitousKeyValueStore).
/// Falls back to UserDefaults when iCloud is unavailable.
@Observable
final class SyncedSettings {
    private let cloudKit: CloudKitManager
    private let ubiquitousStore = NSUbiquitousKeyValueStore.default

    // MARK: - Synced Properties

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

    init(cloudKit: CloudKitManager) {
        self.cloudKit = cloudKit

        // Load from iCloud KVS first, fall back to UserDefaults
        self.visibleCalendarIDs = Set(
            Self.load("visibleCalendarIDs") as [String]? ?? []
        )
        self.defaultViewMode = Self.load("defaultViewMode") ?? "month"
        self.preferredCalendarID = Self.load("preferredCalendarID")
        self.showWeekNumbers = Self.load("showWeekNumbers") ?? false
        self.firstWeekday = Self.load("firstWeekday")
        self.defaultAlertOffset = Self.load("defaultAlertOffset")

        observeRemoteChanges()
    }

    // MARK: - Persistence

    private func save(_ key: String, value: Any?) {
        // Always write to UserDefaults as fallback
        if let value {
            UserDefaults.standard.set(value, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }

        // Also write to iCloud KVS
        cloudKit.syncKeyValue(key, value: value)
    }

    private static func load<T>(_ key: String) -> T? {
        // Prefer iCloud KVS, fall back to UserDefaults
        if let iCloudValue = NSUbiquitousKeyValueStore.default.object(forKey: key) as? T {
            return iCloudValue
        }
        return UserDefaults.standard.object(forKey: key) as? T
    }

    // MARK: - Remote Change Observation

    private func observeRemoteChanges() {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: ubiquitousStore,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            guard let changedKeys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else { return }

            for key in changedKeys {
                self.applyRemoteChange(key: key)
            }
        }

        // Kick off initial sync
        ubiquitousStore.synchronize()
    }

    private func applyRemoteChange(key: String) {
        switch key {
        case "visibleCalendarIDs":
            if let arr = ubiquitousStore.array(forKey: key) as? [String] {
                visibleCalendarIDs = Set(arr)
            }
        case "defaultViewMode":
            if let val = ubiquitousStore.string(forKey: key) {
                defaultViewMode = val
            }
        case "preferredCalendarID":
            preferredCalendarID = ubiquitousStore.string(forKey: key)
        case "showWeekNumbers":
            showWeekNumbers = ubiquitousStore.bool(forKey: key)
        case "firstWeekday":
            let val = ubiquitousStore.longLong(forKey: key)
            firstWeekday = val == 0 ? nil : Int(val)
        case "defaultAlertOffset":
            if let val = ubiquitousStore.object(forKey: key) as? Double {
                defaultAlertOffset = val
            } else {
                defaultAlertOffset = nil
            }
        default:
            break
        }
    }
}
