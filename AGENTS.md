# AGENTS.md

## Cursor Cloud specific instructions

This is a SwiftUI calendar app targeting iOS 17+ and macOS 14+. **It requires Xcode on macOS to build and run** — it cannot be built or tested on a Linux cloud VM.

### Project overview

- **Language**: Swift 5.9+ with `@Observable` macro
- **UI**: SwiftUI, single codebase for iOS and macOS via `#if os()` conditionals
- **Data layer**: EventKit (system calendar integration) with iCloud calendar prioritization
- **Settings sync**: `NSUbiquitousKeyValueStore` (iCloud KVS) via `SyncedSettings` model
- **Sync monitoring**: `CloudKitManager` tracks iCloud availability and sync status
- **Architecture**: MVVM — ViewModels in `CalendarPro/ViewModels/`, Views in `CalendarPro/Views/`
- **Project generation**: Use [XcodeGen](https://github.com/yonaskolb/XcodeGen) with `project.yml` → `xcodegen generate`

### Key commands (all require macOS + Xcode)

| Action | Command |
|--------|---------|
| Generate project | `xcodegen generate` |
| Build | `xcodebuild build -scheme CalendarPro -destination 'platform=iOS Simulator,name=iPhone 16'` |
| Test | `xcodebuild test -scheme CalendarPro -destination 'platform=iOS Simulator,name=iPhone 16'` |
| Lint (SwiftLint) | `swiftlint` (if installed) |

### iCloud data flow

- **Events**: EventKit → iCloud Calendar (CalDAV). `EventKitManager` prioritizes iCloud sources when creating calendars and defaults new events to iCloud calendars.
- **Settings**: `SyncedSettings` writes to both `UserDefaults` (local fallback) and `NSUbiquitousKeyValueStore` (iCloud KVS). Remote changes arrive via `didChangeExternallyNotification` and are applied in real time.
- **Sync status**: `CloudKitManager` monitors `CKAccountChanged` notifications and exposes `SyncStatus` (idle / syncing / synced / error / noAccount) shown in the sidebar and toolbar.

### Non-obvious notes

- **Cannot build on Linux**: This project uses `EventKit`, `CloudKit`, `UserNotifications`, and platform-specific SwiftUI APIs. Xcode on macOS is required.
- **iCloud container**: The CloudKit container identifier is `iCloud.com.calendarpro.app`. You must enable iCloud capability in Xcode's Signing & Capabilities to build successfully.
- **Calendar permissions**: The app requests `NSCalendarsFullAccessUsageDescription` on first launch. In Simulator, grant access when prompted.
- **`@Observable` vs `ObservableObject`**: This project uses `@Observable` (iOS 17+ / macOS 14+). Do not downgrade to `ObservableObject` without updating all views that use `@Bindable`.
- **Platform conditionals**: macOS uses `NavigationSplitView` + native Settings scene; iOS uses `NavigationStack` + sheets. See `MainView.swift` and `CalendarProApp.swift`.
- **XcodeGen**: `project.yml` is the source of truth for build settings. Edit it and regenerate — do not hand-edit `.pbxproj`.
- **EventKit store changes**: `EventKitManager` observes `.EKEventStoreChanged` to auto-reload when other apps modify calendars. This also triggers sync status updates.
- **Fallback behavior**: When iCloud is unavailable (no account, airplane mode), events save to local calendars and settings persist in `UserDefaults`. Everything syncs automatically when iCloud becomes available again.
