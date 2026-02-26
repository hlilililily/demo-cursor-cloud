# CalendarPro

A full-featured work schedule management app for **iOS** and **macOS**, built with SwiftUI. Designed to match Apple Calendar's capabilities with **iCloud sync** for seamless cross-device data sharing.

## Features

- **iCloud Sync** — Events stored in iCloud calendars sync automatically across all devices with the same Apple ID
- **Multiple Views** — Year, Month, Week, and Day views with smooth navigation
- **Event Management** — Create, edit, and delete events with full details
- **EventKit Integration** — Syncs with system calendars (iCloud, Google, Exchange, etc.)
- **Settings Sync** — User preferences (view mode, default calendar, alerts) sync via iCloud KVS
- **Recurring Events** — Daily, weekly, monthly, yearly with custom intervals
- **Alerts & Reminders** — Configurable notifications before events
- **Multiple Calendars** — Color-coded calendar groups with visibility toggles; iCloud calendars prioritized
- **Search** — Find events by title, location, or notes
- **Cross-Platform** — Single codebase for iOS 17+ and macOS 14+
- **Adaptive UI** — NavigationSplitView on macOS, sheet-based navigation on iOS
- **Sync Status** — Real-time iCloud sync status indicator in toolbar and sidebar

## iCloud Architecture

```
┌─────────────────────────────────────────────────┐
│                    iCloud                        │
│  ┌─────────────┐  ┌──────────────────────────┐  │
│  │  iCloud KVS  │  │   iCloud Calendar (CalDAV)│  │
│  │  (Settings)  │  │   (Events via EventKit)   │  │
│  └──────┬───────┘  └──────────┬───────────────┘  │
│         │                     │                   │
└─────────┼─────────────────────┼───────────────────┘
          │                     │
    ┌─────┴─────┐         ┌────┴────┐
    │SyncedSettings│      │EventKit  │
    │(preferences)│       │Manager   │
    └─────┬─────┘         └────┬────┘
          │                     │
    ┌─────┴─────────────────────┴─────┐
    │       CalendarViewModel          │
    │  (orchestrates all data flows)   │
    └──────────────────────────────────┘
```

### How data syncs across devices

| Data | Storage | Sync Method |
|------|---------|-------------|
| Calendar events | EventKit → iCloud Calendar | Automatic via CalDAV (same as Apple Calendar) |
| Calendar groups & colors | EventKit → iCloud Calendar | Automatic via CalDAV |
| Visible calendar IDs | `NSUbiquitousKeyValueStore` | iCloud Key-Value Store (< 1 MB) |
| Default view mode | `NSUbiquitousKeyValueStore` | iCloud Key-Value Store |
| Preferred calendar | `NSUbiquitousKeyValueStore` | iCloud Key-Value Store |
| Default alert offset | `NSUbiquitousKeyValueStore` | iCloud Key-Value Store |
| Week number preference | `NSUbiquitousKeyValueStore` | iCloud Key-Value Store |

## Requirements

- Xcode 16.0+
- iOS 17.0+ / macOS 14.0+
- Swift 5.9+
- **iCloud account** (for cross-device sync; app works locally without it)

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
4. In **Signing & Capabilities**, select your team and enable:
   - **iCloud** → CloudKit + Key-value storage
   - **Calendars**
5. Select a target (iOS Simulator or My Mac) and press **⌘R**.

### Option B: Manual Xcode Setup

1. Open Xcode → **File → New → Project → Multiplatform → App**.
2. Name it `CalendarPro`, select Swift & SwiftUI.
3. Replace the generated source files with the contents of the `CalendarPro/` directory.
4. Add `CalendarProTests/` as a test target.
5. In **Signing & Capabilities**, add:
   - **iCloud** capability with CloudKit and Key-value storage
   - Container: `iCloud.com.calendarpro.app`
6. Configure entitlements and Info.plist from the repository files.
7. Build and run.

### iCloud Setup Checklist

- [ ] Apple Developer account with iCloud capability
- [ ] CloudKit container `iCloud.com.calendarpro.app` created (Xcode does this automatically)
- [ ] Key-value storage enabled in iCloud capability
- [ ] Network client entitlement enabled (for CloudKit API calls)
- [ ] Signed in to iCloud on test device(s)

## Architecture

```
CalendarPro/
├── App/                    # @main entry point
├── Models/
│   ├── CalendarEvent       # Event model wrapping EKEvent
│   ├── CalendarGroup       # Calendar group/source with calendars
│   ├── EventRecurrence     # Recurrence rules + EventAlarm
│   └── SyncedSettings      # iCloud KVS-backed user preferences
├── ViewModels/
│   ├── CalendarViewModel   # Main UI state, navigation, CRUD
│   └── EventEditorViewModel # Event form state
├── Views/
│   ├── Calendar/           # YearView, MonthView, WeekView, DayView, MiniMonthView
│   ├── Event/              # EventDetailView, EventEditorView, EventRow, EventListView
│   ├── Sidebar/            # SidebarView (calendar list + mini-month + iCloud status)
│   ├── Search/             # SearchView
│   ├── Settings/           # SettingsView (iCloud status, defaults, calendar list)
│   └── MainView            # Root layout (adaptive iOS/macOS)
├── Services/
│   ├── EventKitManager     # EventKit CRUD, iCloud calendar prioritization
│   ├── CloudKitManager     # iCloud availability, sync status, KVS
│   └── NotificationManager # Local notification scheduling
├── Extensions/             # Date+, Color+, View+ helpers
└── Resources/              # Assets, Info.plist, entitlements
```

### Design Decisions

| Decision | Rationale |
|----------|-----------|
| EventKit + iCloud Calendar | Same approach as Apple Calendar; events sync via CalDAV automatically |
| `NSUbiquitousKeyValueStore` for settings | Lightweight, instant sync, no CloudKit schema needed |
| iCloud calendar prioritization | New events default to iCloud calendar for cross-device availability |
| `@Observable` (Swift 5.9) | Cleaner than `ObservableObject`; less boilerplate |
| Platform `#if os()` guards | Single codebase; adaptive layouts per platform |

## Permissions

| Permission | Description |
|------------|-------------|
| `NSCalendarsFullAccessUsageDescription` | Read/write calendar events |
| iCloud (CloudKit + KVS) | Cross-device data and settings sync |
| Network Client | CloudKit API access |
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
