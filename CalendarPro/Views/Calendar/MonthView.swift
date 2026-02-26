import SwiftUI

/// Full month grid matching Apple Calendar's month view.
struct MonthView: View {
    @Bindable var viewModel: CalendarViewModel
    let namespace: Namespace.ID

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let weekdaySymbols: [String] = {
        let cal = Calendar.current
        let symbols = cal.veryShortWeekdaySymbols
        let first = cal.firstWeekday - 1
        return Array(symbols[first...]) + Array(symbols[..<first])
    }()

    var body: some View {
        VStack(spacing: 0) {
            weekdayHeader
            monthGrid
        }
        .gesture(swipeGesture)
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Month Grid

    private var monthGrid: some View {
        let gridDates = viewModel.currentMonth.calendarGridDates

        return LazyVGrid(columns: columns, spacing: 0) {
            ForEach(Array(gridDates.enumerated()), id: \.offset) { _, date in
                MonthDayCell(
                    date: date,
                    isCurrentMonth: date.isSameMonth(as: viewModel.currentMonth),
                    isSelected: date.isSameDay(as: viewModel.selectedDate),
                    isToday: date.isToday,
                    events: viewModel.eventsForDate(date)
                )
                .onTapGesture(count: 2) {
                    viewModel.switchToDay(date)
                }
                .onTapGesture {
                    viewModel.selectDate(date)
                }
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Swipe Navigation

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onEnded { value in
                if value.translation.width < -50 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.navigateForward()
                    }
                } else if value.translation.width > 50 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.navigateBackward()
                    }
                }
            }
    }
}

// MARK: - Month Day Cell

struct MonthDayCell: View {
    let date: Date
    let isCurrentMonth: Bool
    let isSelected: Bool
    let isToday: Bool
    let events: [CalendarEvent]

    private let maxDots = 3

    var body: some View {
        VStack(spacing: 2) {
            dayNumber
            eventDots
            eventPreviews
        }
        .frame(maxWidth: .infinity, minHeight: 70, alignment: .top)
        .padding(.vertical, 2)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var dayNumber: some View {
        Text(date.dayNumber)
            .font(.system(.callout, design: .rounded))
            .fontWeight(isToday ? .bold : .regular)
            .foregroundStyle(foregroundColor)
            .frame(width: 28, height: 28)
            .background(isToday ? Color.accentColor : Color.clear)
            .clipShape(Circle())
            .foregroundStyle(isToday ? .white : foregroundColor)
    }

    private var eventDots: some View {
        HStack(spacing: 3) {
            ForEach(Array(events.prefix(maxDots).enumerated()), id: \.offset) { _, event in
                Circle()
                    .fill(Color(cgColor: event.calendarColor))
                    .frame(width: 5, height: 5)
            }
        }
        .frame(height: 6)
    }

    @ViewBuilder
    private var eventPreviews: some View {
        #if os(macOS)
        VStack(spacing: 1) {
            ForEach(Array(events.prefix(3).enumerated()), id: \.offset) { _, event in
                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(cgColor: event.calendarColor))
                        .frame(width: 3)
                    Text(event.title)
                        .font(.system(size: 9))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 12)
            }
            if events.count > 3 {
                Text("+\(events.count - 3) more")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 2)
        #endif
    }

    private var foregroundColor: Color {
        if isToday { return .white }
        if !isCurrentMonth { return .secondary.opacity(0.5) }
        return .primary
    }
}
