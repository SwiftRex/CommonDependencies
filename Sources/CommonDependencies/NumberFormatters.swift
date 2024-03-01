import Foundation

extension CommonDependencies {
    public enum NumberFormatters { }
}

extension CommonDependencies.NumberFormatters {
    public static func live(
        settings: @escaping (NumberFormatter) -> NumberFormatter = { $0 }
    ) -> () -> NumberFormatter {
        { settings(NumberFormatter()) }
    }

    #if DEBUG
    static var nextMockedNumberFormatter = {
        var numberFormatter = NumberFormatter()
        numberFormatter.locale = CommonDependencies.Locales.mock()()
        return numberFormatter
    }()
    static func mock(returning mockedValue: @escaping () -> NumberFormatter = { nextMockedNumberFormatter }) -> () -> NumberFormatter {
        { mockedValue() }
    }
    #endif
}
