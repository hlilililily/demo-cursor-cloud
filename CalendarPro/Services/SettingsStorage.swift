import Foundation

/// Persists app settings to a JSON file in Application Support. All data is stored locally.
final class LocalSettingsStorage {
    private let fileURL: URL
    private let queue = DispatchQueue(label: "com.calendarpro.settings.local")
    private var cache: [String: Any] = [:]

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("CalendarPro", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("settings.json")
        self.cache = loadFromDisk()
    }

    private func loadFromDisk() -> [String: Any] {
        guard let data = try? Data(contentsOf: fileURL),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return dict
    }

    private func writeToDisk(_ dict: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict) else { return }
        try? data.write(to: fileURL)
    }

    func load<T>(_ key: String) -> T? {
        queue.sync {
            let raw = cache[key]
            if raw == nil { return nil }
            if let n = raw as? NSNumber {
                if T.self == Int.self || T.self == Int?.self { return (n.intValue as Int) as? T }
                if T.self == Double.self || T.self == Double?.self { return (n.doubleValue as Double) as? T }
                if T.self == Bool.self || T.self == Bool?.self { return (n.boolValue as Bool) as? T }
            }
            return raw as? T
        }
    }

    func save(_ key: String, value: Any?) {
        queue.async { [weak self] in
            guard let self else { return }
            if let value {
                self.cache[key] = value
            } else {
                self.cache.removeValue(forKey: key)
            }
            self.writeToDisk(self.cache)
        }
    }
}
