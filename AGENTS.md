# AGENTS.md

## Cursor Cloud specific instructions

This is a SwiftUI calendar app targeting iOS 17+ and macOS 14+. **It requires Xcode on macOS to build and run** — it cannot be built or tested on a Linux cloud VM.

### Project overview

- **Language**: Swift 5.9+ with `@Observable` macro
- **UI**: SwiftUI, single codebase for iOS and macOS via `#if os()` conditionals
- **Data layer**: EventKit (system calendar integration)
- **Settings**: `LocalSettingsStorage` → Application Support/CalendarPro/settings.json via `SyncedSettings`
- **Architecture**: MVVM — ViewModels in `CalendarPro/ViewModels/`, Views in `CalendarPro/Views/`
- **Project generation**: Use [XcodeGen](https://github.com/yonaskolb/XcodeGen) with `project.yml` → `xcodegen generate`

### Key commands (all require macOS + Xcode)

| Action | Command |
|--------|---------|
| Generate project | `xcodegen generate` |
| Build iOS | `xcodebuild build -scheme "CalendarPro-iOS" -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.1'` |
| Build macOS | `xcodebuild build -scheme "CalendarPro-macOS" -destination 'platform=macOS'` |
| Test iOS | `xcodebuild test -scheme "CalendarPro-iOS" -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.1'` |
| Lint (SwiftLint) | `swiftlint` (if installed) |

### Data flow

- **Events**: EventKit (system calendars). `EventKitManager` handles CRUD and default calendar from settings.
- **Settings**: `SyncedSettings` backed by `LocalSettingsStorage` (JSON file in Application Support).

### Non-obvious notes

- **Cannot build on Linux**: This project uses `EventKit`, `UserNotifications`, and platform-specific SwiftUI APIs. Xcode on macOS is required.
- **Calendar permissions**: The app requests `NSCalendarsFullAccessUsageDescription` on first launch. In Simulator, grant access when prompted.
- **`@Observable` vs `ObservableObject`**: This project uses `@Observable` (iOS 17+ / macOS 14+). Do not downgrade to `ObservableObject` without updating all views that use `@Bindable`.
- **Platform conditionals**: macOS uses `NavigationSplitView` + native Settings scene; iOS uses `NavigationStack` + sheets. See `MainView.swift` and `CalendarProApp.swift`.
- **XcodeGen**: `project.yml` is the source of truth for build settings. Edit it and regenerate — do not hand-edit `.pbxproj`.
- **EventKit store changes**: `EventKitManager` observes `.EKEventStoreChanged` to auto-reload when other apps modify calendars.
