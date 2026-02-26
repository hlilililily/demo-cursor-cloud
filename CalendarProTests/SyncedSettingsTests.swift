import XCTest
@testable import CalendarPro

final class SyncedSettingsTests: XCTestCase {

    func testDefaultViewMode_IsMonth() {
        let cloudKit = CloudKitManager()
        let settings = SyncedSettings(cloudKit: cloudKit)
        XCTAssertEqual(settings.defaultViewMode, "month")
    }

    func testVisibleCalendarIDs_DefaultsToEmpty() {
        let cloudKit = CloudKitManager()
        let settings = SyncedSettings(cloudKit: cloudKit)
        XCTAssertTrue(settings.visibleCalendarIDs.isEmpty)
    }

    func testShowWeekNumbers_DefaultsToFalse() {
        let cloudKit = CloudKitManager()
        let settings = SyncedSettings(cloudKit: cloudKit)
        XCTAssertFalse(settings.showWeekNumbers)
    }

    func testDefaultAlertOffset_DefaultsToNil() {
        let cloudKit = CloudKitManager()
        let settings = SyncedSettings(cloudKit: cloudKit)
        XCTAssertNil(settings.defaultAlertOffset)
    }

    func testPreferredCalendarID_DefaultsToNil() {
        let cloudKit = CloudKitManager()
        let settings = SyncedSettings(cloudKit: cloudKit)
        XCTAssertNil(settings.preferredCalendarID)
    }
}
