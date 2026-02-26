import XCTest
@testable import CalendarPro

final class DateExtensionTests: XCTestCase {

    private var calendar: Calendar { Calendar.current }

    // MARK: - startOfDay / endOfDay

    func testStartOfDay() {
        let date = makeDate(year: 2025, month: 6, day: 15, hour: 14, minute: 30)
        let start = date.startOfDay
        let comps = calendar.dateComponents([.hour, .minute, .second], from: start)
        XCTAssertEqual(comps.hour, 0)
        XCTAssertEqual(comps.minute, 0)
        XCTAssertEqual(comps.second, 0)
    }

    func testEndOfDay() {
        let date = makeDate(year: 2025, month: 6, day: 15, hour: 8)
        let end = date.endOfDay
        let comps = calendar.dateComponents([.hour, .minute, .second], from: end)
        XCTAssertEqual(comps.hour, 23)
        XCTAssertEqual(comps.minute, 59)
        XCTAssertEqual(comps.second, 59)
    }

    // MARK: - startOfMonth / endOfMonth

    func testStartOfMonth() {
        let date = makeDate(year: 2025, month: 3, day: 20)
        let start = date.startOfMonth
        let comps = calendar.dateComponents([.year, .month, .day], from: start)
        XCTAssertEqual(comps.year, 2025)
        XCTAssertEqual(comps.month, 3)
        XCTAssertEqual(comps.day, 1)
    }

    func testEndOfMonth() {
        let date = makeDate(year: 2025, month: 2, day: 10)
        let end = date.endOfMonth
        let comps = calendar.dateComponents([.year, .month, .day], from: end)
        XCTAssertEqual(comps.month, 2)
        XCTAssertEqual(comps.day, 28)
    }

    // MARK: - numberOfDaysInMonth

    func testNumberOfDaysInMonth_February_NonLeapYear() {
        let date = makeDate(year: 2025, month: 2, day: 1)
        XCTAssertEqual(date.numberOfDaysInMonth, 28)
    }

    func testNumberOfDaysInMonth_February_LeapYear() {
        let date = makeDate(year: 2024, month: 2, day: 1)
        XCTAssertEqual(date.numberOfDaysInMonth, 29)
    }

    func testNumberOfDaysInMonth_July() {
        let date = makeDate(year: 2025, month: 7, day: 1)
        XCTAssertEqual(date.numberOfDaysInMonth, 31)
    }

    // MARK: - isSameDay / isSameMonth

    func testIsSameDay() {
        let a = makeDate(year: 2025, month: 6, day: 15, hour: 9)
        let b = makeDate(year: 2025, month: 6, day: 15, hour: 18)
        let c = makeDate(year: 2025, month: 6, day: 16, hour: 9)
        XCTAssertTrue(a.isSameDay(as: b))
        XCTAssertFalse(a.isSameDay(as: c))
    }

    func testIsSameMonth() {
        let a = makeDate(year: 2025, month: 6, day: 1)
        let b = makeDate(year: 2025, month: 6, day: 30)
        let c = makeDate(year: 2025, month: 7, day: 1)
        XCTAssertTrue(a.isSameMonth(as: b))
        XCTAssertFalse(a.isSameMonth(as: c))
    }

    // MARK: - calendarGridDates

    func testCalendarGridDatesCount() {
        let date = makeDate(year: 2025, month: 6, day: 1)
        let grid = date.calendarGridDates
        XCTAssertEqual(grid.count % 7, 0, "Grid should have complete rows of 7")
        XCTAssertTrue(grid.count >= 28 && grid.count <= 42)
    }

    // MARK: - monthsInYear

    func testMonthsInYear() {
        let date = makeDate(year: 2025, month: 1, day: 1)
        let months = date.monthsInYear
        XCTAssertEqual(months.count, 12)
        XCTAssertEqual(calendar.component(.month, from: months.first!), 1)
        XCTAssertEqual(calendar.component(.month, from: months.last!), 12)
    }

    // MARK: - weekDates

    func testWeekDates() {
        let date = makeDate(year: 2025, month: 6, day: 11) // Wednesday
        let weekDates = date.weekDates
        XCTAssertEqual(weekDates.count, 7)
    }

    // MARK: - fractionalHour

    func testFractionalHour() {
        let date = makeDate(year: 2025, month: 6, day: 15, hour: 9, minute: 30)
        XCTAssertEqual(date.fractionalHour, 9.5, accuracy: 0.01)
    }

    // MARK: - addingMonths / addingDays / addingWeeks

    func testAddingMonths() {
        let date = makeDate(year: 2025, month: 1, day: 15)
        let result = date.addingMonths(3)
        XCTAssertEqual(calendar.component(.month, from: result), 4)
    }

    func testAddingDays() {
        let date = makeDate(year: 2025, month: 6, day: 28)
        let result = date.addingDays(5)
        XCTAssertEqual(calendar.component(.month, from: result), 7)
        XCTAssertEqual(calendar.component(.day, from: result), 3)
    }

    // MARK: - Helpers

    private func makeDate(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}
