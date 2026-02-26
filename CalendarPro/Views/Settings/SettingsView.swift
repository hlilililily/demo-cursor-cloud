import SwiftUI

/// App settings with iCloud sync status and calendar preferences.
struct SettingsView: View {
    @Bindable var viewModel: CalendarViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                iCloudSection
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

    // MARK: - iCloud Section

    private var iCloudSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: viewModel.iCloudSyncStatus.systemImage)
                    .font(.title2)
                    .foregroundStyle(viewModel.iCloudAvailable ? .blue : .secondary)
                    .symbolEffect(.pulse, isActive: viewModel.iCloudSyncStatus == .syncing)

                VStack(alignment: .leading, spacing: 2) {
                    Text("iCloud Sync")
                        .font(.headline)
                    Text(viewModel.iCloudSyncStatus.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if viewModel.iCloudAvailable {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }

            if !viewModel.iCloudAvailable {
                iCloudUnavailableNotice
            }

            if viewModel.eventKitManager.hasICloudCalendars {
                HStack {
                    Text("iCloud Calendars")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(viewModel.eventKitManager.iCloudCalendars.count)")
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("iCloud")
        } footer: {
            Text("Events saved to iCloud calendars sync automatically across all your devices signed in with the same Apple ID.")
        }
    }

    @ViewBuilder
    private var iCloudUnavailableNotice: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("iCloud is not available", systemImage: "exclamationmark.triangle")
                .font(.subheadline)
                .foregroundStyle(.orange)
            Text("Sign in to iCloud in System Settings to enable cross-device sync. Events will be stored locally until iCloud is available.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
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
        let writableCalendars = viewModel.eventKitManager.calendars.filter(\.allowsContentModifications)
        let iCloudFirst = writableCalendars.sorted { lhs, rhs in
            let lhsIC = lhs.source?.title.lowercased().contains("icloud") ?? false
            let rhsIC = rhs.source?.title.lowercased().contains("icloud") ?? false
            if lhsIC != rhsIC { return lhsIC }
            return lhs.title < rhs.title
        }

        return Picker("Default Calendar", selection: Binding(
            get: { viewModel.eventKitManager.defaultCalendar?.calendarIdentifier ?? "" },
            set: { viewModel.syncedSettings.preferredCalendarID = $0 }
        )) {
            ForEach(iCloudFirst, id: \.calendarIdentifier) { cal in
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(cgColor: cal.cgColor))
                        .frame(width: 8, height: 8)
                    Text(cal.title)
                    if cal.source?.title.lowercased().contains("icloud") ?? false {
                        Image(systemName: "icloud")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
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
                            if cal.sourceType == .calDAV {
                                Image(systemName: "icloud")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
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
