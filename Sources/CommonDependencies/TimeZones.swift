import Foundation

extension CommonDependencies {
    public enum TimeZones { }
}

extension CommonDependencies.TimeZones {
    public static func live() -> () -> TimeZone {
        { TimeZone.current }
    }

    #if DEBUG
    static var nextMockedTimeZone = { TimeZone(secondsFromGMT: 0) ?? TimeZone.current }
    static func mock(returning mockedValue: @escaping () -> TimeZone = nextMockedTimeZone) -> () -> TimeZone {
        { mockedValue() }
    }
    #endif
}
