import SwiftUI

/// Single-day timeline view with hour slots and event blocks.
struct DayView: View {
    @Bindable var viewModel: CalendarViewModel

    private let hourHeight: CGFloat = 60
    private let timeColumnWidth: CGFloat = 56
    private let hours = Date.hourSlots

    var body: some View {
        VStack(spacing: 0) {
            dayHeader
            Divider()
            allDaySection
            Divider()
            timelineGrid
        }
        .gesture(swipeGesture)
    }

    // MARK: - Day Header

    private var dayHeader: some View {
        VStack(spacing: 2) {
            Text(viewModel.selectedDate.shortWeekday.uppercased())
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(viewModel.selectedDate.dayNumber)
                .font(.system(.title, design: .rounded))
                .fontWeight(.bold)
                .frame(width: 44, height: 44)
                .background(viewModel.selectedDate.isToday ? Color.accentColor : Color.clear)
                .foregroundStyle(viewModel.selectedDate.isToday ? .white : .primary)
                .clipShape(Circle())
        }
        .padding(.vertical, 8)
    }

    // MARK: - All-Day Events

    @ViewBuilder
    private var allDaySection: some View {
        let allDayEvents = viewModel.eventsForDate(viewModel.selectedDate).filter(\.isAllDay)
        if !allDayEvents.isEmpty {
            VStack(spacing: 4) {
                ForEach(allDayEvents) { event in
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(cgColor: event.calendarColor))
                            .frame(width: 4)
                        Text(event.title)
                            .font(.subheadline)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    .background(Color(cgColor: event.calendarColor).opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .onTapGesture { viewModel.selectedEvent = event }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Timeline

    private var timelineGrid: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                ZStack(alignment: .topLeading) {
                    hourLines
                    eventBlocks
                    nowIndicator
                }
                .frame(height: hourHeight * 24)
                .contentShape(Rectangle())
                .onTapGesture { location in
                    let hour = Int(location.y / hourHeight)
                    let cal = Calendar.current
                    if let tappedDate = cal.date(bySettingHour: hour, minute: 0, second: 0, of: viewModel.selectedDate) {
                        viewModel.createNewEvent(at: tappedDate)
                    }
                }
            }
            .onAppear {
                scrollToCurrentTime(proxy: proxy)
            }
        }
    }

    private var hourLines: some View {
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
    }

    private var eventBlocks: some View {
        let timedEvents = viewModel.eventsForDate(viewModel.selectedDate).filter { !$0.isAllDay }
        return ForEach(timedEvents) { event in
            dayEventBlock(event)
        }
    }

    private func dayEventBlock(_ event: CalendarEvent) -> some View {
        let top = event.startDate.fractionalHour * hourHeight
        let duration = event.endDate.fractionalHour - event.startDate.fractionalHour
        let height = max(hourHeight / 4, duration * hourHeight)

        return HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(cgColor: event.calendarColor))
                .frame(width: 4)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                if let location = event.location, !location.isEmpty {
                    Text(location)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Text(timeRangeText(event))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: height)
        .background(Color(cgColor: event.calendarColor).opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .padding(.leading, timeColumnWidth + 4)
        .padding(.trailing, 8)
        .offset(y: top)
        .onTapGesture { viewModel.selectedEvent = event }
    }

    @ViewBuilder
    private var nowIndicator: some View {
        if viewModel.selectedDate.isToday {
            let yPos = Date().fractionalHour * hourHeight
            HStack(spacing: 0) {
                Circle()
                    .fill(.red)
                    .frame(width: 10, height: 10)
                Rectangle()
                    .fill(.red)
                    .frame(height: 1.5)
            }
            .padding(.leading, timeColumnWidth - 5)
            .offset(y: yPos - 5)
        }
    }

    private func timeRangeText(_ event: CalendarEvent) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: event.startDate)) – \(formatter.string(from: event.endDate))"
    }

    private func scrollToCurrentTime(proxy: ScrollViewProxy) {
        let hour = max(0, Calendar.current.component(.hour, from: Date()) - 2)
        proxy.scrollTo("hour-\(hour)", anchor: .top)
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
