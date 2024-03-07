@testable import CommonDependencies
import XCTest

final class CalendarTests: XCTestCase {
    func testCustomClosureMock() throws {
        // GIVEN
        let expectedReturnedCalendar: Calendar = .init(identifier: .iso8601)
        let notExpectedCalendar: Calendar = .init(identifier: .islamic)
        CommonDependencies.Calendars.nextMockedCalendar = notExpectedCalendar
        let mock = CommonDependencies.Calendars.mock(returning: { expectedReturnedCalendar })

        // WHEN
        let result = mock()

        // THEN
        XCTAssertEqual(result, expectedReturnedCalendar)
        XCTAssertNotEqual(result, notExpectedCalendar)
    }

    func testCustomClosureChangingMock() throws {
        // GIVEN
        let expectedReturnedCalendar1: Calendar = .init(identifier: .iso8601)
        let expectedReturnedCalendar2: Calendar = .init(identifier: .indian)
        let expectedReturnedCalendar3: Calendar = .init(identifier: .islamic)
        var calendar = expectedReturnedCalendar1
        let mock = CommonDependencies.Calendars.mock(returning: { calendar })

        // GIVEN
        calendar = expectedReturnedCalendar1

        // WHEN
        var result = mock()

        // THEN
        XCTAssertEqual(result, expectedReturnedCalendar1)

        // GIVEN
        calendar = expectedReturnedCalendar2

        // WHEN
        result = mock()

        // THEN
        XCTAssertEqual(result, expectedReturnedCalendar2)

        // GIVEN
        calendar = expectedReturnedCalendar3

        // WHEN
        result = mock()

        // THEN
        XCTAssertEqual(result, expectedReturnedCalendar3)
    }

    func testDefaultMock() throws {
        // GIVEN
        let expectedReturnedCalendar: Calendar = .init(identifier: .iso8601)
        CommonDependencies.Calendars.nextMockedCalendar = expectedReturnedCalendar
        let mock = CommonDependencies.Calendars.mock()

        // WHEN
        let result = mock()

        // THEN
        XCTAssertEqual(result, expectedReturnedCalendar)
    }

    func testDefaultChangingMock() throws {
        // GIVEN
        let expectedReturnedCalendar1: Calendar = .init(identifier: .iso8601)
        let expectedReturnedCalendar2: Calendar = .init(identifier: .indian)
        let expectedReturnedCalendar3: Calendar = .init(identifier: .islamic)
        let mock = CommonDependencies.Calendars.mock()

        // GIVEN
        CommonDependencies.Calendars.nextMockedCalendar = expectedReturnedCalendar1

        // WHEN
        var result = mock()

        // THEN
        XCTAssertEqual(result, expectedReturnedCalendar1)

        // GIVEN
        CommonDependencies.Calendars.nextMockedCalendar = expectedReturnedCalendar2

        // WHEN
        result = mock()

        // THEN
        XCTAssertEqual(result, expectedReturnedCalendar2)

        // GIVEN
        CommonDependencies.Calendars.nextMockedCalendar = expectedReturnedCalendar3

        // WHEN
        result = mock()

        // THEN
        XCTAssertEqual(result, expectedReturnedCalendar3)
    }
}
