import XCTest
@testable import CalendarPro

final class EventRecurrenceTests: XCTestCase {

    func testDisplayText_Daily() {
        let rule = EventRecurrence(frequency: .daily)
        XCTAssertEqual(rule.displayText, "Every Day")
    }

    func testDisplayText_Weekly_NoDays() {
        let rule = EventRecurrence(frequency: .weekly)
        XCTAssertEqual(rule.displayText, "Every Week")
    }

    func testDisplayText_Weekly_WithDays() {
        let rule = EventRecurrence(frequency: .weekly, daysOfWeek: [.monday, .wednesday, .friday])
        XCTAssertEqual(rule.displayText, "Every Week on Mon, Wed, Fri")
    }

    func testDisplayText_Monthly() {
        let rule = EventRecurrence(frequency: .monthly)
        XCTAssertEqual(rule.displayText, "Every Month")
    }

    func testDisplayText_Yearly() {
        let rule = EventRecurrence(frequency: .yearly)
        XCTAssertEqual(rule.displayText, "Every Year")
    }

    func testDisplayText_CustomInterval() {
        let rule = EventRecurrence(frequency: .weekly, interval: 2)
        XCTAssertEqual(rule.displayText, "Every 2 weeks")
    }

    func testToEKRecurrenceRule() {
        let rule = EventRecurrence(
            frequency: .weekly,
            interval: 1,
            daysOfWeek: [.monday, .friday]
        )
        let ekRule = rule.toEKRecurrenceRule()
        XCTAssertEqual(ekRule.frequency, .weekly)
        XCTAssertEqual(ekRule.interval, 1)
        XCTAssertEqual(ekRule.daysOfTheWeek?.count, 2)
    }
}

final class EventAlarmTests: XCTestCase {

    func testDisplayText_Preset() {
        let alarm = EventAlarm(offset: -15 * 60)
        XCTAssertEqual(alarm.displayText, "15 minutes before")
    }

    func testDisplayText_AtTime() {
        let alarm = EventAlarm(offset: 0)
        XCTAssertEqual(alarm.displayText, "At time of event")
    }

    func testDisplayText_OneDayBefore() {
        let alarm = EventAlarm(offset: -86400)
        XCTAssertEqual(alarm.displayText, "1 day before")
    }

    func testDisplayText_OneHourBefore() {
        let alarm = EventAlarm(offset: -3600)
        XCTAssertEqual(alarm.displayText, "1 hour before")
    }

    func testToEKAlarm_Relative() {
        let alarm = EventAlarm(offset: -300)
        let ekAlarm = alarm.toEKAlarm()
        XCTAssertEqual(ekAlarm.relativeOffset, -300)
    }

    func testToEKAlarm_Absolute() {
        let date = Date()
        let alarm = EventAlarm(absoluteDate: date)
        let ekAlarm = alarm.toEKAlarm()
        XCTAssertNotNil(ekAlarm.absoluteDate)
    }
}
