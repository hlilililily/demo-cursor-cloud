import SwiftUI

/// Shows a list of events for the selected date (used in day/week drill-down on iOS).
struct EventListView: View {
    let events: [CalendarEvent]
    let date: Date
    let onSelect: (CalendarEvent) -> Void
    let onNewEvent: () -> Void

    private var allDayEvents: [CalendarEvent] { events.filter(\.isAllDay) }
    private var timedEvents: [CalendarEvent] { events.filter { !$0.isAllDay } }

    var body: some View {
        Group {
            if events.isEmpty {
                emptyState
            } else {
                eventsList
            }
        }
    }

    private var eventsList: some View {
        List {
            if !allDayEvents.isEmpty {
                Section("All Day") {
                    ForEach(allDayEvents) { event in
                        EventRow(event: event)
                            .onTapGesture { onSelect(event) }
                    }
                }
            }

            if !timedEvents.isEmpty {
                Section("Timed") {
                    ForEach(timedEvents) { event in
                        EventRow(event: event)
                            .onTapGesture { onSelect(event) }
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No Events")
                .font(.headline)
                .foregroundStyle(.secondary)
            Button("New Event") { onNewEvent() }
                .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
