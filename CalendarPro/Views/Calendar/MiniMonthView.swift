import SwiftUI

/// Compact month calendar for the sidebar, similar to Apple Calendar's mini-month.
struct MiniMonthView: View {
    @Binding var selectedDate: Date
    @Binding var currentMonth: Date
    var onDateSelected: ((Date) -> Void)?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let weekdaySymbols: [String] = {
        let cal = Calendar.current
        let symbols = cal.veryShortWeekdaySymbols
        let first = cal.firstWeekday - 1
        return Array(symbols[first...]) + Array(symbols[..<first])
    }()

    var body: some View {
        VStack(spacing: 6) {
            header
            weekdays
            daysGrid
        }
        .padding(8)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text(currentMonth.monthYearString)
                .font(.subheadline)
                .fontWeight(.semibold)

            Spacer()

            Button {
                withAnimation { currentMonth = currentMonth.addingMonths(-1) }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.caption)
            }
            .buttonStyle(.plain)

            Button {
                withAnimation { currentMonth = currentMonth.addingMonths(1) }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Weekdays

    private var weekdays: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Days Grid

    private var daysGrid: some View {
        let gridDates = currentMonth.calendarGridDates

        return LazyVGrid(columns: columns, spacing: 2) {
            ForEach(gridDates, id: \.self) { date in
                miniDayCell(date)
                    .onTapGesture {
                        selectedDate = date
                        if !date.isSameMonth(as: currentMonth) {
                            currentMonth = date
                        }
                        onDateSelected?(date)
                    }
            }
        }
    }

    private func miniDayCell(_ date: Date) -> some View {
        ZStack {
            if date.isSameDay(as: selectedDate) {
                Circle()
                    .fill(Color.accentColor.opacity(0.25))
                    .frame(width: 24, height: 24)
            }
            if date.isToday {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 24, height: 24)
            }
            Text(date.dayNumber)
                .font(.system(size: 11))
                .foregroundStyle(dayForeground(date))
        }
        .frame(width: 28, height: 24)
    }

    private func dayForeground(_ date: Date) -> Color {
        if date.isToday { return .white }
        if !date.isSameMonth(as: currentMonth) { return .secondary.opacity(0.4) }
        return .primary
    }
}
