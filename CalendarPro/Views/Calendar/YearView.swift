import SwiftUI

/// Year overview showing 12 mini-month grids, matching Apple Calendar's year view.
struct YearView: View {
    @Bindable var viewModel: CalendarViewModel

    #if os(macOS)
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 24), count: 4)
    #else
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)
    #endif

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(viewModel.currentMonth.monthsInYear, id: \.self) { month in
                    YearMonthCell(
                        month: month,
                        selectedDate: viewModel.selectedDate,
                        hasEvents: { viewModel.hasEvents(on: $0) }
                    )
                    .onTapGesture {
                        viewModel.currentMonth = month
                        viewModel.selectedDate = month
                        viewModel.viewMode = .month
                        viewModel.loadEvents()
                    }
                }
            }
            .padding()
        }
        .gesture(swipeGesture)
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onEnded { value in
                if value.translation.width < -50 {
                    withAnimation { viewModel.navigateForward() }
                } else if value.translation.width > 50 {
                    withAnimation { viewModel.navigateBackward() }
                }
            }
    }
}

// MARK: - Year Month Cell

struct YearMonthCell: View {
    let month: Date
    let selectedDate: Date
    let hasEvents: (Date) -> Bool

    private let miniColumns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let weekdaySymbols: [String] = {
        let cal = Calendar.current
        let symbols = cal.veryShortWeekdaySymbols
        let first = cal.firstWeekday - 1
        return Array(symbols[first...]) + Array(symbols[..<first])
    }()

    var body: some View {
        VStack(spacing: 4) {
            Text(month.monthName)
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: miniColumns, spacing: 2) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }

                ForEach(month.calendarGridDates, id: \.self) { date in
                    if date.isSameMonth(as: month) {
                        ZStack {
                            if date.isToday {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 18, height: 18)
                            }
                            Text(date.dayNumber)
                                .font(.system(size: 10))
                                .foregroundStyle(date.isToday ? .white : .primary)
                        }
                        .frame(height: 18)
                    } else {
                        Text("")
                            .frame(height: 18)
                    }
                }
            }
        }
        .padding(8)
    }
}
