import SwiftUI

/// Week timeline view with hour slots, matching Apple Calendar's week layout.
struct WeekView: View {
    @Bindable var viewModel: CalendarViewModel

    private let hourHeight: CGFloat = 60
    private let timeColumnWidth: CGFloat = 56
    private let hours = Date.hourSlots

    var body: some View {
        GeometryReader { geometry in
            let dayWidth = (geometry.size.width - timeColumnWidth) / 7

            VStack(spacing: 0) {
                weekdayHeader(dayWidth: dayWidth)
                Divider()
                allDaySection(dayWidth: dayWidth)
                Divider()
                timelineGrid(dayWidth: dayWidth)
            }
        }
        .gesture(swipeGesture)
    }

    // MARK: - Weekday Header

    private func weekdayHeader(dayWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: timeColumnWidth)
            ForEach(viewModel.selectedDate.weekDates, id: \.self) { date in
                VStack(spacing: 2) {
                    Text(date.shortWeekday)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(date.dayNumber)
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(date.isToday ? .bold : .regular)
                        .frame(width: 32, height: 32)
                        .background(date.isToday ? Color.accentColor : Color.clear)
                        .foregroundStyle(date.isToday ? .white : .primary)
                        .clipShape(Circle())
                }
                .frame(width: dayWidth)
                .onTapGesture { viewModel.selectDate(date) }
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - All-Day Events

    @ViewBuilder
    private func allDaySection(dayWidth: CGFloat) -> some View {
        let weekDates = viewModel.selectedDate.weekDates
        let allDayEvents = weekDates.map { date in
            viewModel.eventsForDate(date).filter(\.isAllDay)
        }

        if allDayEvents.contains(where: { !$0.isEmpty }) {
            HStack(spacing: 0) {
                Text("all-day")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: timeColumnWidth)
                ForEach(Array(weekDates.enumerated()), id: \.element) { idx, _ in
                    VStack(spacing: 2) {
                        ForEach(allDayEvents[idx]) { event in
                            Text(event.title)
                                .font(.caption2)
                                .lineLimit(1)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(cgColor: event.calendarColor).opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                                .onTapGesture { viewModel.selectedEvent = event }
                        }
                    }
                    .frame(width: dayWidth)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Timeline Grid

    private func timelineGrid(dayWidth: CGFloat) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                ZStack(alignment: .topLeading) {
                    hourLines(dayWidth: dayWidth)
                    eventBlocks(dayWidth: dayWidth)
                    nowIndicator(dayWidth: dayWidth)
                }
                .frame(height: hourHeight * 24)
                .id("timeline")
            }
            .onAppear {
                let currentHour = Calendar.current.component(.hour, from: Date())
                let targetHour = max(0, currentHour - 2)
                proxy.scrollTo("hour-\(targetHour)", anchor: .top)
            }
        }
    }

    private func hourLines(dayWidth: CGFloat) -> some View {
        let weekDates = viewModel.selectedDate.weekDates
        return ZStack(alignment: .topLeading) {
            ForEach(hours, id: \.self) { hour in
                HStack(spacing: 0) {
                    Text(viewModel.selectedDate.hourString(hour: hour))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: timeColumnWidth, alignment: .trailing)
                        .padding(.trailing, 4)
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 0.5)
                }
                .id("hour-\(hour)")
                .offset(y: CGFloat(hour) * hourHeight)
            }

            ForEach(Array(weekDates.indices), id: \.self) { idx in
                Rectangle()
                    .fill(Color.secondary.opacity(0.15))
                    .frame(width: 0.5, height: hourHeight * 24)
                    .offset(x: timeColumnWidth + CGFloat(idx) * dayWidth)
            }
        }
    }

    private func eventBlocks(dayWidth: CGFloat) -> some View {
        let weekDates = viewModel.selectedDate.weekDates
        return ForEach(Array(weekDates.enumerated()), id: \.element) { dayIdx, date in
            let dayEvents = viewModel.eventsForDate(date).filter { !$0.isAllDay }
            ForEach(dayEvents) { event in
                eventBlock(event, dayIndex: dayIdx, dayWidth: dayWidth)
            }
        }
    }

    private func eventBlock(_ event: CalendarEvent, dayIndex: Int, dayWidth: CGFloat) -> some View {
        let top = event.startDate.fractionalHour * hourHeight
        let height = max(hourHeight / 4, (event.endDate.fractionalHour - event.startDate.fractionalHour) * hourHeight)
        let xOffset = timeColumnWidth + CGFloat(dayIndex) * dayWidth + 2

        return Text(event.title)
            .font(.caption2)
            .fontWeight(.medium)
            .lineLimit(nil)
            .padding(4)
            .frame(width: dayWidth - 4, alignment: .topLeading)
            .frame(height: height, alignment: .top)
            .background(Color(cgColor: event.calendarColor).opacity(0.85))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .offset(x: xOffset, y: top)
            .onTapGesture { viewModel.selectedEvent = event }
    }

    @ViewBuilder
    private func nowIndicator(dayWidth: CGFloat) -> some View {
        if viewModel.selectedDate.weekDates.contains(where: \.isToday) {
            let now = Date()
            let yPos = now.fractionalHour * hourHeight
            let todayIdx = viewModel.selectedDate.weekDates.firstIndex(where: \.isToday) ?? 0
            let xPos = timeColumnWidth + CGFloat(todayIdx) * dayWidth

            HStack(spacing: 0) {
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
                Rectangle()
                    .fill(.red)
                    .frame(width: dayWidth, height: 1)
            }
            .offset(x: xPos - 4, y: yPos - 4)
        }
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
