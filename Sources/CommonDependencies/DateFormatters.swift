import Foundation

extension CommonDependencies {
    public enum DateFormatters { }
}

extension CommonDependencies.DateFormatters {
    public static func live(
        settings: @escaping (DateFormatter) -> DateFormatter = { $0 }
    ) -> () -> DateFormatter {
        { settings(DateFormatter()) }
    }

    #if DEBUG
    static var nextMockedDateFormatter = {
        var dateFormatter = DateFormatter()
        dateFormatter.timeZone = CommonDependencies.TimeZones.mock()()
        dateFormatter.locale = CommonDependencies.Locales.mock()()
        dateFormatter.calendar = CommonDependencies.Calendars.mock()()
        return dateFormatter
    }()
    static func mock(returning mockedValue: @escaping () -> DateFormatter = { nextMockedDateFormatter }) -> () -> DateFormatter {
        { mockedValue() }
    }
    #endif
}
