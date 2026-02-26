import Foundation

extension Date {
    /// Start of the current day.
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// End of the current day (23:59:59).
    var endOfDay: Date {
        Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: self) ?? self
    }

    /// Start of the month containing this date.
    var startOfMonth: Date {
        let comps = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: comps) ?? self
    }

    /// End of the month containing this date.
    var endOfMonth: Date {
        guard let next = Calendar.current.date(byAdding: .month, value: 1, to: startOfMonth) else { return self }
        return Calendar.current.date(byAdding: .second, value: -1, to: next) ?? self
    }

    /// Start of the week containing this date.
    var startOfWeek: Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return cal.date(from: comps) ?? self
    }

    /// End of the week containing this date.
    var endOfWeek: Date {
        guard let end = Calendar.current.date(byAdding: .day, value: 6, to: startOfWeek) else { return self }
        return end.endOfDay
    }

    /// Start of the year containing this date.
    var startOfYear: Date {
        let comps = Calendar.current.dateComponents([.year], from: self)
        return Calendar.current.date(from: comps) ?? self
    }

    /// All dates in the month of this date.
    var daysInMonth: [Date] {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: self) else { return [] }
        return range.compactMap { day -> Date? in
            var comps = cal.dateComponents([.year, .month], from: self)
            comps.day = day
            return cal.date(from: comps)
        }
    }

    /// Number of days in the month of this date.
    var numberOfDaysInMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: self)?.count ?? 30
    }

    /// Weekday index (1 = Sunday … 7 = Saturday).
    var weekday: Int {
        Calendar.current.component(.weekday, from: self)
    }

    /// Zero-based column offset for a calendar grid.
    var weekdayOffset: Int {
        let first = startOfMonth.weekday
        let firstWeekday = Calendar.current.firstWeekday
        return (first - firstWeekday + 7) % 7
    }

    /// All dates visible in a month grid (including leading/trailing dates).
    var calendarGridDates: [Date] {
        let cal = Calendar.current
        let offset = weekdayOffset
        let start = cal.date(byAdding: .day, value: -offset, to: startOfMonth)!
        let totalCells = offset + numberOfDaysInMonth
        let rows = (totalCells + 6) / 7
        return (0 ..< rows * 7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    /// Week dates for the week containing this date.
    var weekDates: [Date] {
        let cal = Calendar.current
        let start = startOfWeek
        return (0 ..< 7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    /// Hour slots for a day (0-23).
    static var hourSlots: [Int] { Array(0...23) }

    /// Months in a year.
    var monthsInYear: [Date] {
        let cal = Calendar.current
        let year = cal.component(.year, from: self)
        return (1...12).compactMap { month -> Date? in
            cal.date(from: DateComponents(year: year, month: month, day: 1))
        }
    }

    /// Whether this date is today.
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Whether this date is in the same month as another date.
    func isSameMonth(as other: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: other, toGranularity: .month)
    }

    /// Whether this date is in the same day as another date.
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    /// Whether this date is in the same year as another.
    func isSameYear(as other: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: other, toGranularity: .year)
    }

    /// Formatted hour string (e.g. "9 AM").
    func hourString(hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let cal = Calendar.current
        let date = cal.date(bySettingHour: hour, minute: 0, second: 0, of: self) ?? self
        return formatter.string(from: date)
    }

    /// Short weekday name (e.g. "Mon").
    var shortWeekday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }

    /// Day number string.
    var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: self)
    }

    /// Full month name.
    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: self)
    }

    /// Short month name.
    var shortMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: self)
    }

    /// Year string.
    var yearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: self)
    }

    /// "Month Year" format.
    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self)
    }

    /// Fractional hour (e.g. 9:30 → 9.5).
    var fractionalHour: Double {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: self)
        let minute = cal.component(.minute, from: self)
        return Double(hour) + Double(minute) / 60.0
    }

    /// Create a date by adding/subtracting months.
    func addingMonths(_ months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }

    /// Create a date by adding/subtracting days.
    func addingDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// Create a date by adding/subtracting weeks.
    func addingWeeks(_ weeks: Int) -> Date {
        Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: self) ?? self
    }
}
