import Foundation

extension CommonDependencies {
    public enum Now { }
}

extension CommonDependencies.Now {
    public static func live() -> () -> Date {
        { Date() }
    }

    #if DEBUG
    static var nextMockedDate = { Date(timeIntervalSinceReferenceDate: 0) }
    static func mock(returning mockedValue: @escaping () -> Date = nextMockedDate) -> () -> Date {
        { mockedValue() }
    }
    #endif
}
