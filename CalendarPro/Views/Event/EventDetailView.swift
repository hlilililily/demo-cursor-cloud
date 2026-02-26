import SwiftUI
import EventKit

/// Displays full event details with edit/delete actions.
struct EventDetailView: View {
    let event: CalendarEvent
    let onEdit: () -> Void
    let onDelete: (EKSpan) -> Void
    let onDismiss: () -> Void

    @State private var showDeleteConfirmation = false
    @State private var showDeleteSpanPicker = false

    var body: some View {
        NavigationStack {
            List {
                titleSection
                timeSection
                if event.location != nil || event.url != nil { locationSection }
                if !event.recurrenceRules.isEmpty { recurrenceSection }
                if !event.alarms.isEmpty { alarmsSection }
                if event.notes != nil { notesSection }
                calendarSection
                deleteSection
            }
            .navigationTitle("Event Details")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { onDismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") { onEdit() }
                }
            }
            #else
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Edit") { onEdit() }
                }
            }
            #endif
        }
        .frame(minWidth: 350, minHeight: 400)
    }

    // MARK: - Sections

    private var titleSection: some View {
        Section {
            HStack(spacing: 10) {
                Circle()
                    .fill(Color(cgColor: event.calendarColor))
                    .frame(width: 12, height: 12)
                Text(event.title)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
        }
    }

    private var timeSection: some View {
        Section {
            if event.isAllDay {
                LabeledContent("All Day") {
                    Text(event.startDate.formatted(date: .long, time: .omitted))
                }
                if event.isMultiDay {
                    LabeledContent("To") {
                        Text(event.endDate.formatted(date: .long, time: .omitted))
                    }
                }
            } else {
                LabeledContent("Starts") {
                    Text(event.startDate.formatted(date: .long, time: .shortened))
                }
                LabeledContent("Ends") {
                    Text(event.endDate.formatted(date: .long, time: .shortened))
                }
            }
        }
    }

    @ViewBuilder
    private var locationSection: some View {
        Section {
            if let location = event.location, !location.isEmpty {
                LabeledContent("Location") {
                    Text(location)
                        .foregroundStyle(.secondary)
                }
            }
            if let url = event.url {
                LabeledContent("URL") {
                    Link(url.absoluteString, destination: url)
                        .lineLimit(1)
                }
            }
        }
    }

    private var recurrenceSection: some View {
        Section("Repeat") {
            ForEach(event.recurrenceRules) { rule in
                Text(rule.displayText)
            }
        }
    }

    private var alarmsSection: some View {
        Section("Alerts") {
            ForEach(event.alarms) { alarm in
                Text(alarm.displayText)
            }
        }
    }

    private var notesSection: some View {
        Section("Notes") {
            Text(event.notes ?? "")
                .font(.body)
        }
    }

    private var calendarSection: some View {
        Section {
            HStack {
                Circle()
                    .fill(Color(cgColor: event.calendarColor))
                    .frame(width: 10, height: 10)
                Text(event.calendarTitle)
            }
        }
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                if event.recurrenceRules.isEmpty {
                    onDelete(.thisEvent)
                } else {
                    showDeleteSpanPicker = true
                }
            } label: {
                HStack {
                    Spacer()
                    Text("Delete Event")
                    Spacer()
                }
            }
            .confirmationDialog("Delete Recurring Event", isPresented: $showDeleteSpanPicker) {
                Button("This Event Only", role: .destructive) { onDelete(.thisEvent) }
                Button("All Future Events", role: .destructive) { onDelete(.futureEvents) }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}
