import SwiftUI

/// Full event creation/editing form matching Apple Calendar's editor.
struct EventEditorView: View {
    @State var editor: EventEditorViewModel
    let calendars: [CalendarGroup.CalendarInfo]
    let onSave: (CalendarEvent) -> Void
    let onCancel: () -> Void

    init(
        event: CalendarEvent? = nil,
        defaultCalendarID: String = "",
        calendars: [CalendarGroup.CalendarInfo],
        onSave: @escaping (CalendarEvent) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self._editor = State(initialValue: EventEditorViewModel(event: event, defaultCalendarID: defaultCalendarID))
        self.calendars = calendars
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationStack {
            Form {
                titleSection
                dateTimeSection
                recurrenceSection
                alertsSection
                calendarSection
                notesSection
            }
            .navigationTitle(editor.isNewEvent ? "New Event" : "Edit Event")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(editor.isNewEvent ? "Add" : "Done") {
                        onSave(editor.buildEvent())
                    }
                    .fontWeight(.semibold)
                    .disabled(!editor.isValid)
                }
            }
            #else
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editor.isNewEvent ? "Add" : "Done") {
                        onSave(editor.buildEvent())
                    }
                    .disabled(!editor.isValid)
                }
            }
            #endif
        }
        .frame(minWidth: 380, minHeight: 500)
    }

    // MARK: - Title & Location

    private var titleSection: some View {
        Section {
            TextField("Title", text: $editor.title)
                .font(.headline)
            TextField("Location", text: $editor.location)
        }
    }

    // MARK: - Date & Time

    private var dateTimeSection: some View {
        Section {
            Toggle("All-day", isOn: $editor.isAllDay)

            if editor.isAllDay {
                DatePicker("Starts", selection: $editor.startDate, displayedComponents: .date)
                DatePicker("Ends", selection: $editor.endDate, displayedComponents: .date)
            } else {
                DatePicker("Starts", selection: $editor.startDate)
                    .onChange(of: editor.startDate) { editor.adjustEndDateIfNeeded() }
                DatePicker("Ends", selection: $editor.endDate)
            }

            Picker("Availability", selection: $editor.availability) {
                ForEach(CalendarEvent.EventAvailability.allCases, id: \.rawValue) { avail in
                    Text(avail.label).tag(avail)
                }
            }
        }
    }

    // MARK: - Recurrence

    private var recurrenceSection: some View {
        Section("Repeat") {
            recurrencePresetRows
            recurrenceEndSection
        }
    }

    private var recurrencePresetRows: some View {
        RecurrencePresetRowsView(
            selectedRecurrence: $editor.recurrence,
            recurrenceMatches: recurrenceMatches
        )
    }

    @ViewBuilder
    private var recurrenceEndSection: some View {
        if let rule = editor.recurrence {
            if rule.endRule == nil {
                Button("Add End Date…") {
                    editor.recurrence?.endRule = .endDate(
                        editor.startDate.addingTimeInterval(86400 * 365)
                    )
                }
            } else {
                switch rule.endRule! {
                case .endDate(let date):
                    DatePicker("End Repeat", selection: Binding(
                        get: { date },
                        set: { editor.recurrence?.endRule = .endDate($0) }
                    ), displayedComponents: .date)
                case .occurrenceCount(let count):
                    Stepper("After \(count) events", value: Binding(
                        get: { count },
                        set: { editor.recurrence?.endRule = .occurrenceCount($0) }
                    ), in: 1...999)
                }
            }
        }
    }

    // MARK: - Alerts

    private var alertsSection: some View {
        Section("Alert") {
            ForEach(editor.alarms) { alarm in
                Text(alarm.displayText)
            }
            .onDelete { offsets in
                editor.removeAlarm(at: offsets)
            }

            Menu("Add Alert…") {
                ForEach(EventAlarm.presets, id: \.offset) { preset in
                    Button(preset.label) {
                        editor.addAlarm(EventAlarm(offset: preset.offset))
                    }
                }
            }
        }
    }

    // MARK: - Calendar Picker

    private var calendarSection: some View {
        Section("Calendar") {
            calendarPickerRows
        }
    }

    private var calendarPickerRows: some View {
        CalendarPickerRowsView(
            calendars: calendars,
            selectedID: $editor.calendarIdentifier
        )
    }

    // MARK: - Notes & URL

    private var notesSection: some View {
        Section {
            TextField("URL", text: $editor.urlString)
                #if os(iOS)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                #endif
            TextField("Notes", text: $editor.notes, axis: .vertical)
                .lineLimit(4...8)
        }
    }

    // MARK: - Helpers

    private func recurrenceMatches(_ preset: EventRecurrence?) -> Bool {
        if preset == nil && editor.recurrence == nil { return true }
        guard let p = preset, let r = editor.recurrence else { return false }
        return p.frequency == r.frequency && p.interval == r.interval
    }
}

// MARK: - Helper subviews (isolate ForEach from @State to fix overload resolution)

private struct RecurrencePresetRowsView: View {
    @Binding var selectedRecurrence: EventRecurrence?
    let recurrenceMatches: (EventRecurrence?) -> Bool

    private static let presets = EventEditorViewModel.recurrencePresetItems

    var body: some View {
        Group {
            presetButton(Self.presets[0])
            presetButton(Self.presets[1])
            presetButton(Self.presets[2])
            presetButton(Self.presets[3])
            presetButton(Self.presets[4])
            presetButton(Self.presets[5])
        }
    }

    private func presetButton(_ preset: EventEditorViewModel.RecurrencePresetItem) -> some View {
        Button {
            selectedRecurrence = preset.rule
        } label: {
            HStack {
                Text(preset.label)
                    .foregroundStyle(.primary)
                Spacer()
                if recurrenceMatches(preset.rule) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }
}

private struct CalendarPickerRowsView: View {
    let calendars: [CalendarGroup.CalendarInfo]
    @Binding var selectedID: String

    var body: some View {
        let indices = Array(calendars.indices)
        return ForEach(indices, id: \.self) { index in
            Button {
                selectedID = calendars[index].id
            } label: {
                HStack(spacing: 8) {
                    Circle()
                        .fill(calendars[index].color)
                        .frame(width: 10, height: 10)
                    Text(calendars[index].title)
                        .foregroundStyle(.primary)
                    Spacer()
                    if selectedID == calendars[index].id {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
        }
    }
}
