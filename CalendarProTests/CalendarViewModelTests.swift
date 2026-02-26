import XCTest
@testable import CalendarPro

final class CalendarViewModelTests: XCTestCase {

    private func makeViewModel() -> CalendarViewModel {
        CalendarViewModel()
    }

    // MARK: - Navigation Title

    func testNavigationTitle_Month() {
        let vm = makeViewModel()
        vm.viewMode = .month
        vm.currentMonth = makeDate(year: 2025, month: 6, day: 1)
        XCTAssertEqual(vm.navigationTitle, "June 2025")
    }

    func testNavigationTitle_Year() {
        let vm = makeViewModel()
        vm.viewMode = .year
        vm.currentMonth = makeDate(year: 2025, month: 1, day: 1)
        XCTAssertEqual(vm.navigationTitle, "2025")
    }

    // MARK: - View Mode Switching

    func testSwitchToDay() {
        let vm = makeViewModel()
        let date = makeDate(year: 2025, month: 8, day: 20)
        vm.switchToDay(date)
        XCTAssertEqual(vm.viewMode, .day)
        XCTAssertTrue(vm.selectedDate.isSameDay(as: date))
    }

    func testSetViewMode_PersistsToSettings() {
        let vm = makeViewModel()
        vm.setViewMode(.week)
        XCTAssertEqual(vm.viewMode, .week)
        XCTAssertEqual(vm.syncedSettings.defaultViewMode, "week")
    }

    // MARK: - Navigation Forward/Backward

    func testNavigateForward_Month() {
        let vm = makeViewModel()
        vm.viewMode = .month
        vm.currentMonth = makeDate(year: 2025, month: 6, day: 1)
        vm.navigateForward()
        let month = Calendar.current.component(.month, from: vm.currentMonth)
        XCTAssertEqual(month, 7)
    }

    func testNavigateBackward_Month() {
        let vm = makeViewModel()
        vm.viewMode = .month
        vm.currentMonth = makeDate(year: 2025, month: 6, day: 1)
        vm.navigateBackward()
        let month = Calendar.current.component(.month, from: vm.currentMonth)
        XCTAssertEqual(month, 5)
    }

    func testGoToToday() {
        let vm = makeViewModel()
        vm.viewMode = .month
        vm.currentMonth = makeDate(year: 2020, month: 1, day: 1)
        vm.goToToday()
        XCTAssertTrue(vm.selectedDate.isToday)
    }

    // MARK: - Create New Event

    func testCreateNewEvent_SetsEditingEvent() {
        let vm = makeViewModel()
        vm.createNewEvent()
        XCTAssertNotNil(vm.editingEvent)
        XCTAssertTrue(vm.showingNewEvent)
        XCTAssertTrue(vm.editingEvent?.title.isEmpty ?? false)
    }

    // MARK: - iCloud Status

    func testICloudStatusExposed() {
        let vm = makeViewModel()
        // CloudKitManager starts with .idle status
        XCTAssertNotNil(vm.iCloudSyncStatus)
    }

    // MARK: - Helpers

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
