import Foundation

extension CommonDependencies {
    public enum DateFormatters { }
}

extension CommonDependencies.DateFormatters {
    public static func live(value: @escaping () -> DateFormatter = { DateFormatter() }) -> () -> DateFormatter {
        { value() }
    }

    #if DEBUG
    static var nextMockedDateFormatter = {
        var dateFormatter = DateFormatter()
        dateFormatter.timeZone = CommonDependencies.TimeZones.mock()()
        dateFormatter.locale = CommonDependencies.Locales.mock()()
        dateFormatter.calendar = CommonDependencies.Calendars.mock()()
        return dateFormatter
    }
    static func mock(returning mockedValue: @escaping () -> DateFormatter = nextMockedDateFormatter) -> () -> DateFormatter {
        { mockedValue() }
    }
    #endif
}
