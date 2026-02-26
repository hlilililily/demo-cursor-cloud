import SwiftUI

/// Sidebar with mini-month calendar and calendar list.
struct SidebarView: View {
    @Bindable var viewModel: CalendarViewModel

    var body: some View {
        VStack(spacing: 0) {
            miniCalendar
            Divider()
            calendarList
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
                    Text(group.title)
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
            }
        }
        .buttonStyle(.plain)
    }
}
