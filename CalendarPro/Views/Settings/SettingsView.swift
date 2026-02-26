import SwiftUI

/// App settings and calendar preferences.
struct SettingsView: View {
    @Bindable var viewModel: CalendarViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                defaultsSection
                calendarsSection
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            #else
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            #endif
        }
        .frame(minWidth: 380, minHeight: 450)
    }

    // MARK: - Defaults Section

    private var defaultsSection: some View {
        Section("Defaults") {
            Picker("Default View", selection: Binding(
                get: { viewModel.viewMode },
                set: { viewModel.setViewMode($0) }
            )) {
                ForEach(CalendarViewModel.ViewMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }

            defaultCalendarPicker

            defaultAlertPicker

            Toggle("Show Week Numbers", isOn: Binding(
                get: { viewModel.syncedSettings.showWeekNumbers },
                set: { viewModel.syncedSettings.showWeekNumbers = $0 }
            ))
        }
    }

    private var defaultCalendarPicker: some View {
        let writableCalendars = viewModel.eventKitManager.calendars
            .filter(\.allowsContentModifications)
            .sorted { $0.title.localizedCompare($1.title) == .orderedAscending }

        return Picker("Default Calendar", selection: Binding(
            get: { viewModel.eventKitManager.defaultCalendar?.calendarIdentifier ?? "" },
            set: { viewModel.syncedSettings.preferredCalendarID = $0 }
        )) {
            ForEach(writableCalendars, id: \.calendarIdentifier) { cal in
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(cgColor: cal.cgColor))
                        .frame(width: 8, height: 8)
                    Text(cal.title)
                }
                .tag(cal.calendarIdentifier)
            }
        }
    }

    private var defaultAlertPicker: some View {
        let options: [(label: String, value: Double?)] = [("None", nil)] +
            EventAlarm.presets.map { ($0.label, Optional($0.offset)) }
        let currentIndex = options.firstIndex { $0.value == viewModel.syncedSettings.defaultAlertOffset } ?? 0

        return Picker("Default Alert", selection: Binding(
            get: { currentIndex },
            set: { viewModel.syncedSettings.defaultAlertOffset = options[$0].value }
        )) {
            ForEach(Array(options.enumerated()), id: \.offset) { idx, option in
                Text(option.label).tag(idx)
            }
        }
    }

    // MARK: - Calendars Section

    private var calendarsSection: some View {
        Section("Calendars") {
            ForEach(viewModel.eventKitManager.calendarGroups()) { group in
                DisclosureGroup(group.title) {
                    ForEach(group.calendars) { cal in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(cal.color)
                                .frame(width: 10, height: 10)
                            Text(cal.title)
                            Spacer()
                            if cal.isSubscribed {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
}
