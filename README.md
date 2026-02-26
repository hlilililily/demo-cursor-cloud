# CalendarPro

A full-featured work schedule management app for **iOS** and **macOS**, built with SwiftUI. Designed to match Apple Calendar's capabilities.

## Features

- **Multiple Views** — Year, Month, Week, and Day views with smooth navigation
- **Event Management** — Create, edit, and delete events with full details
- **EventKit Integration** — Syncs with system calendars (iCloud, Google, Exchange, etc.)
- **Recurring Events** — Daily, weekly, monthly, yearly with custom intervals
- **Alerts & Reminders** — Configurable notifications before events
- **Multiple Calendars** — Color-coded calendar groups with visibility toggles
- **Search** — Find events by title, location, or notes
- **Cross-Platform** — Single codebase for iOS 17+ and macOS 14+
- **Adaptive UI** — NavigationSplitView on macOS, sheet-based navigation on iOS

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
3. Open `CalendarPro.xcodeproj` in Xcode.
4. Select a target (iOS Simulator or My Mac) and press **⌘R**.

### Option B: Manual Xcode Setup

1. Open Xcode → **File → New → Project → Multiplatform → App**.
2. Name it `CalendarPro`, select Swift & SwiftUI.
3. Replace the generated source files with the contents of the `CalendarPro/` directory.
4. Add `CalendarProTests/` as a test target.
5. Configure entitlements and Info.plist from the repository files.
6. Build and run.

## Architecture

```
CalendarPro/
├── App/                    # @main entry point
├── Models/                 # CalendarEvent, CalendarGroup, EventRecurrence
├── ViewModels/             # CalendarViewModel, EventEditorViewModel
├── Views/
│   ├── Calendar/           # YearView, MonthView, WeekView, DayView, MiniMonthView
│   ├── Event/              # EventDetailView, EventEditorView, EventRow, EventListView
│   ├── Sidebar/            # SidebarView (calendar list + mini-month)
│   ├── Search/             # SearchView
│   └── MainView.swift      # Root layout (adaptive iOS/macOS)
├── Services/               # EventKitManager, NotificationManager
├── Extensions/             # Date+, Color+, View+ helpers
└── Resources/              # Assets, Info.plist, entitlements
```

### Design Decisions

| Decision | Rationale |
|----------|-----------|
| `@Observable` (Swift 5.9) | Cleaner than `ObservableObject`; less boilerplate |
| EventKit as source of truth | No local database duplication; direct system calendar sync |
| Platform `#if os()` guards | Single codebase; adaptive layouts per platform |
| MVVM | Clear separation; testable ViewModels |

## Permissions

The app requires **Calendar access** (`NSCalendarsFullAccessUsageDescription`) to read and write events. On first launch, the system will prompt the user.

## Running Tests

```bash
# Via Xcode
⌘U

# Via command line (requires xcodebuild)
xcodebuild test -scheme CalendarPro -destination 'platform=iOS Simulator,name=iPhone 16'
```

## License

MIT
