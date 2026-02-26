# CalendarPro

A full-featured work schedule management app for **iOS** and **macOS**, built with SwiftUI. Uses EventKit for calendar data; all app settings are stored locally.

## Features

- **Multiple Views** — Year, Month, Week, and Day views with smooth navigation
- **Event Management** — Create, edit, and delete events with full details
- **EventKit Integration** — Works with system calendars (local, Google, Exchange, etc.)
- **Local Settings** — User preferences (view mode, default calendar, alerts) stored in Application Support
- **Recurring Events** — Daily, weekly, monthly, yearly with custom intervals
- **Alerts & Reminders** — Configurable notifications before events
- **Multiple Calendars** — Color-coded calendar groups with visibility toggles
- **Search** — Find events by title, location, or notes
- **Cross-Platform** — Single codebase for iOS 17+ and macOS 14+
- **Adaptive UI** — NavigationSplitView on macOS, sheet-based navigation on iOS

## Data storage

| Data | Storage |
|------|---------|
| Calendar events | EventKit (system calendars) |
| App settings | Local file: Application Support/CalendarPro/settings.json |

## Requirements

- Xcode 16.0+
- iOS 17.0+ / macOS 14.0+
- Swift 5.9+

## Getting Started

### Option A: XcodeGen (Recommended)

1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen):
   ```bash
   brew install xcodegen
   ```
2. Generate the Xcode project:
   ```bash
   xcodegen generate
   ```
3. Open **`CalendarPro.xcodeproj`** in Xcode.
4. In **Signing & Capabilities**, select your team and enable **Calendars**.
5. To run:
   - **iOS**: Select scheme **CalendarPro-iOS**, choose an iOS Simulator (e.g. iPhone 16), press **⌘R**.
   - **macOS**: Select scheme **CalendarPro-macOS**, choose "My Mac", press **⌘R**.

### Option B: Manual Xcode Setup

1. Open Xcode → **File → New → Project → Multiplatform → App**.
2. Name it `CalendarPro`, select Swift & SwiftUI.
3. Replace the generated source files with the contents of the `CalendarPro/` directory.
4. Add `CalendarProTests/` as a test target.
5. In **Signing & Capabilities**, add **Calendars** capability.
6. Configure entitlements and Info.plist from the repository files.
7. Build and run.

## Architecture

```
CalendarPro/
├── App/                    # @main entry point
├── Models/
│   ├── CalendarEvent       # Event model wrapping EKEvent
│   ├── CalendarGroup       # Calendar group/source with calendars
│   ├── EventRecurrence     # Recurrence rules + EventAlarm
│   └── SyncedSettings      # Local settings (Application Support)
├── ViewModels/
│   ├── CalendarViewModel   # Main UI state, navigation, CRUD
│   └── EventEditorViewModel # Event form state
├── Views/
│   ├── Calendar/           # YearView, MonthView, WeekView, DayView, MiniMonthView
│   ├── Event/              # EventDetailView, EventEditorView, EventRow, EventListView
│   ├── Sidebar/            # SidebarView (calendar list + mini-month)
│   ├── Search/             # SearchView
│   ├── Settings/           # SettingsView (defaults, calendar list)
│   └── MainView            # Root layout (adaptive iOS/macOS)
├── Services/
│   ├── EventKitManager     # EventKit CRUD, default calendar
│   └── NotificationManager # Local notification scheduling
├── Extensions/             # Date+, Color+, View+ helpers
└── Resources/              # Assets, Info.plist, entitlements
```

### Design Decisions

| Decision | Rationale |
|----------|-----------|
| EventKit | System calendar API; works with local and account-based calendars |
| Local JSON for settings | Application Support/CalendarPro/settings.json; no cloud dependency |
| `@Observable` (Swift 5.9) | Cleaner than `ObservableObject`; less boilerplate |
| Platform `#if os()` guards | Single codebase; adaptive layouts per platform |

## Permissions

| Permission | Description |
|------------|-------------|
| `NSCalendarsFullAccessUsageDescription` | Read/write calendar events |
| Network Client | For future use if needed |
| Background Fetch | Silent push for remote calendar changes |

## Running Tests

```bash
# Via Xcode
⌘U

# Via command line
xcodebuild test -scheme CalendarPro -destination 'platform=iOS Simulator,name=iPhone 16'
```

## License

MIT
