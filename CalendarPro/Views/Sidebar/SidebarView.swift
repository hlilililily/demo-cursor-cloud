import SwiftUI

/// Sidebar with mini-month calendar, calendar list, and iCloud status.
struct SidebarView: View {
    @Bindable var viewModel: CalendarViewModel

    var body: some View {
        VStack(spacing: 0) {
            miniCalendar
            Divider()
            calendarList
            Divider()
            iCloudStatusBar
        }
        #if os(macOS)
        .frame(minWidth: 220, idealWidth: 240, maxWidth: 280)
        #endif
    }

    // MARK: - Mini Calendar

    private var miniCalendar: some View {
        MiniMonthView(
            selectedDate: $viewModel.selectedDate,
            currentMonth: $viewModel.currentMonth,
            onDateSelected: { date in
                viewModel.selectDate(date)
            }
        )
        .padding(.horizontal, 4)
        .padding(.top, 8)
    }

    // MARK: - Calendar List

    private var calendarList: some View {
        List {
            ForEach(viewModel.eventKitManager.calendarGroups()) { group in
                Section {
                    ForEach(group.calendars) { cal in
                        calendarRow(cal)
                    }
                } header: {
                    HStack {
                        Text(group.title)
                        if isICloudGroup(group) {
                            Image(systemName: "icloud")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }

    private func calendarRow(_ cal: CalendarGroup.CalendarInfo) -> some View {
        let isVisible = viewModel.eventKitManager.visibleCalendarIDs.contains(cal.id)
        return Button {
            viewModel.toggleCalendarVisibility(cal.id)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isVisible ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(cal.color)
                    .font(.body)
                Text(cal.title)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer()
                if cal.sourceType == .calDAV {
                    Image(systemName: "icloud")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - iCloud Status Bar

    private var iCloudStatusBar: some View {
        HStack(spacing: 8) {
            Image(systemName: viewModel.iCloudSyncStatus.systemImage)
                .font(.caption)
                .foregroundStyle(viewModel.iCloudAvailable ? .blue : .secondary)
                .symbolEffect(.pulse, isActive: viewModel.iCloudSyncStatus == .syncing)

            Text(viewModel.iCloudSyncStatus.label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            if !viewModel.iCloudAvailable {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    // MARK: - Helpers

    private func isICloudGroup(_ group: CalendarGroup) -> Bool {
        group.calendars.contains { $0.sourceType == .calDAV }
    }
}
