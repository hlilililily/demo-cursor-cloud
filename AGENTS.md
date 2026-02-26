# AGENTS.md

## Cursor Cloud specific instructions

This is a SwiftUI calendar app targeting iOS 17+ and macOS 14+. **It requires Xcode on macOS to build and run** — it cannot be built or tested on a Linux cloud VM.

### Project overview

- **Language**: Swift 5.9+ with `@Observable` macro
- **UI**: SwiftUI, single codebase for iOS and macOS via `#if os()` conditionals
- **Data layer**: EventKit (system calendar integration; no local database)
- **Architecture**: MVVM — ViewModels in `CalendarPro/ViewModels/`, Views in `CalendarPro/Views/`
- **Project generation**: Use [XcodeGen](https://github.com/yonaskolb/XcodeGen) with `project.yml` → `xcodegen generate`

### Key commands (all require macOS + Xcode)

| Action | Command |
|--------|---------|
| Generate project | `xcodegen generate` |
| Build | `xcodebuild build -scheme CalendarPro -destination 'platform=iOS Simulator,name=iPhone 16'` |
| Test | `xcodebuild test -scheme CalendarPro -destination 'platform=iOS Simulator,name=iPhone 16'` |
| Lint (SwiftLint) | `swiftlint` (if installed) |

### Non-obvious notes

- **Cannot build on Linux**: Swift Package Manager alone cannot build this project because it uses `EventKit`, `UserNotifications`, and platform-specific SwiftUI APIs. You need Xcode.
- **Calendar permissions**: The app requests `NSCalendarsFullAccessUsageDescription` on first launch. In Simulator, grant access when prompted or tests that touch EventKit will fail.
- **`@Observable` vs `ObservableObject`**: This project uses `@Observable` (iOS 17+ / macOS 14+). Do not downgrade to `ObservableObject` without updating all views that use `@Bindable`.
- **Platform conditionals**: macOS uses `NavigationSplitView`; iOS uses `NavigationStack` + sheets. Check `MainView.swift` for the layout split.
- **XcodeGen**: The `project.yml` at repo root is the source of truth for build settings. If you change targets, sources, or settings, edit `project.yml` and regenerate — do not hand-edit `pbxproj`.
