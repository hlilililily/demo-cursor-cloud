import Foundation
import CloudKit
import Observation

/// Manages iCloud availability checks, sync status, and account monitoring.
@Observable
final class CloudKitManager {
    enum SyncStatus: Equatable {
        case idle
        case syncing
        case synced(Date)
        case error(String)
        case noAccount

        var label: String {
            switch self {
            case .idle: return "Waiting…"
            case .syncing: return "Syncing…"
            case .synced(let date): return "Synced \(date.formatted(.relative(presentation: .named)))"
            case .error(let msg): return "Error: \(msg)"
            case .noAccount: return "No iCloud Account"
            }
        }

        var systemImage: String {
            switch self {
            case .idle: return "icloud"
            case .syncing: return "arrow.triangle.2.circlepath.icloud"
            case .synced: return "checkmark.icloud"
            case .error: return "exclamationmark.icloud"
            case .noAccount: return "xmark.icloud"
            }
        }

        var isAvailable: Bool {
            switch self {
            case .synced, .syncing, .idle: return true
            case .error, .noAccount: return false
            }
        }
    }

    static let containerIdentifier = "iCloud.com.calendarpro.app"

    var syncStatus: SyncStatus = .idle
    var iCloudAvailable = false

    private let container: CKContainer

    init() {
        self.container = CKContainer(identifier: Self.containerIdentifier)
        Task { await checkAccountStatus() }
        observeAccountChanges()
    }

    // MARK: - Account Status

    func checkAccountStatus() async {
        do {
            let status = try await container.accountStatus()
            await MainActor.run {
                switch status {
                case .available:
                    iCloudAvailable = true
                    if case .noAccount = syncStatus { syncStatus = .idle }
                case .noAccount, .restricted:
                    iCloudAvailable = false
                    syncStatus = .noAccount
                case .couldNotDetermine:
                    iCloudAvailable = false
                    syncStatus = .error("Could not determine iCloud status")
                case .temporarilyUnavailable:
                    iCloudAvailable = false
                    syncStatus = .error("iCloud temporarily unavailable")
                @unknown default:
                    iCloudAvailable = false
                    syncStatus = .error("Unknown iCloud status")
                }
            }
        } catch {
            await MainActor.run {
                iCloudAvailable = false
                syncStatus = .error(error.localizedDescription)
            }
        }
    }

    // MARK: - Sync Trigger

    /// Call after EventKit saves to reflect that data has been pushed to iCloud.
    func markSynced() {
        syncStatus = .synced(Date())
    }

    func markSyncing() {
        guard iCloudAvailable else { return }
        syncStatus = .syncing
    }

    // MARK: - Account Change Observation

    private func observeAccountChanges() {
        NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { await self.checkAccountStatus() }
        }
    }

    // MARK: - NSUbiquitousKeyValueStore (Settings Sync)

    /// Syncs a key-value pair across devices via iCloud KVS.
    func syncKeyValue(_ key: String, value: Any?) {
        guard iCloudAvailable else { return }
        let store = NSUbiquitousKeyValueStore.default
        if let value {
            store.set(value, forKey: key)
        } else {
            store.removeObject(forKey: key)
        }
        store.synchronize()
    }

    /// Reads a value from iCloud KVS.
    func readKeyValue<T>(_ key: String) -> T? {
        NSUbiquitousKeyValueStore.default.object(forKey: key) as? T
    }

    /// Reads an array of strings from iCloud KVS.
    func readStringArray(_ key: String) -> [String]? {
        NSUbiquitousKeyValueStore.default.array(forKey: key) as? [String]
    }

    /// Force-syncs the KVS store.
    func forceSync() {
        NSUbiquitousKeyValueStore.default.synchronize()
    }
}
