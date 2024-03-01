import Foundation

extension CommonDependencies {
    public enum Calendars { }
}

extension CommonDependencies.Calendars {
    public static func live() -> () -> Calendar {
        { Calendar.current }
    }

    #if DEBUG
    static var nextMockedCalendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = CommonDependencies.TimeZones.mock()()
        calendar.locale = CommonDependencies.Locales.mock()()
        return calendar
    }()
    static func mock(returning mockedValue: @escaping () -> Calendar = { nextMockedCalendar }) -> () -> Calendar {
        { mockedValue() }
    }
    #endif
}
