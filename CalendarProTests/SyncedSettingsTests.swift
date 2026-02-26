import XCTest
@testable import CalendarPro

final class SyncedSettingsTests: XCTestCase {

    func testDefaultViewMode_IsMonth() {
        let settings = SyncedSettings()
        XCTAssertEqual(settings.defaultViewMode, "month")
    }

    func testVisibleCalendarIDs_DefaultsToEmpty() {
        let settings = SyncedSettings()
        XCTAssertTrue(settings.visibleCalendarIDs.isEmpty)
    }

    func testShowWeekNumbers_DefaultsToFalse() {
        let settings = SyncedSettings()
        XCTAssertFalse(settings.showWeekNumbers)
    }

    func testDefaultAlertOffset_DefaultsToNil() {
        let settings = SyncedSettings()
        XCTAssertNil(settings.defaultAlertOffset)
    }

    func testPreferredCalendarID_DefaultsToNil() {
        let settings = SyncedSettings()
        XCTAssertNil(settings.preferredCalendarID)
    }
}
