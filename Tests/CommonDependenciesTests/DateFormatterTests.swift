@testable import CommonDependencies
import XCTest

final class DateFormatterTests: XCTestCase {
    func testCustomClosureMock() throws {
        // GIVEN
        let expectedReturnedDateFormatter: DateFormatter = .init()
        let notExpectedDateFormatter: DateFormatter = .init()
        CommonDependencies.DateFormatters.nextMockedDateFormatter = notExpectedDateFormatter
        let mock = CommonDependencies.DateFormatters.mock(returning: { expectedReturnedDateFormatter })

        // WHEN
        let result = mock()

        // THEN
        XCTAssertTrue(result === expectedReturnedDateFormatter)
        XCTAssertFalse(result === notExpectedDateFormatter)
    }

    func testCustomClosureChangingMock() throws {
        // GIVEN
        let expectedReturnedDateFormatter1: DateFormatter = .init()
        let expectedReturnedDateFormatter2: DateFormatter = .init()
        let expectedReturnedDateFormatter3: DateFormatter = .init()
        var dateFormatter = expectedReturnedDateFormatter1
        let mock = CommonDependencies.DateFormatters.mock(returning: { dateFormatter })

        // GIVEN
        dateFormatter = expectedReturnedDateFormatter1

        // WHEN
        var result = mock()

        // THEN
        XCTAssertTrue(result === expectedReturnedDateFormatter1)

        // GIVEN
        dateFormatter = expectedReturnedDateFormatter2

        // WHEN
        result = mock()

        // THEN
        XCTAssertTrue(result === expectedReturnedDateFormatter2)

        // GIVEN
        dateFormatter = expectedReturnedDateFormatter3

        // WHEN
        result = mock()

        // THEN
        XCTAssertTrue(result === expectedReturnedDateFormatter3)
    }

    func testDefaultMock() throws {
        // GIVEN
        let expectedReturnedDateFormatter: DateFormatter = .init()
        CommonDependencies.DateFormatters.nextMockedDateFormatter = expectedReturnedDateFormatter
        let mock = CommonDependencies.DateFormatters.mock()

        // WHEN
        let result = mock()

        // THEN
        XCTAssertTrue(result === expectedReturnedDateFormatter)
    }

    func testDefaultChangingMock() throws {
        // GIVEN
        let expectedReturnedDateFormatter1: DateFormatter = .init()
        let expectedReturnedDateFormatter2: DateFormatter = .init()
        let expectedReturnedDateFormatter3: DateFormatter = .init()
        let mock = CommonDependencies.DateFormatters.mock()

        // GIVEN
        CommonDependencies.DateFormatters.nextMockedDateFormatter = expectedReturnedDateFormatter1

        // WHEN
        var result = mock()

        // THEN
        XCTAssertTrue(result === expectedReturnedDateFormatter1)

        // GIVEN
        CommonDependencies.DateFormatters.nextMockedDateFormatter = expectedReturnedDateFormatter2

        // WHEN
        result = mock()

        // THEN
        XCTAssertTrue(result === expectedReturnedDateFormatter2)

        // GIVEN
        CommonDependencies.DateFormatters.nextMockedDateFormatter = expectedReturnedDateFormatter3

        // WHEN
        result = mock()

        // THEN
        XCTAssertTrue(result === expectedReturnedDateFormatter3)
    }
}
