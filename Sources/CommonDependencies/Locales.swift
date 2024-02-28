import Foundation

extension CommonDependencies {
    public enum Locales { }
}

extension CommonDependencies.Locales {
    public static func live() -> () -> Locale {
        { Locale.current }
    }

    #if DEBUG
    static let posix = Locale(identifier: "en_US_POSIX")
    static let us = Locale(identifier: "en_US")
    static let uk = Locale(identifier: "en_GB")
    static let germany = Locale(identifier: "de_DE")
    static let china = Locale(identifier: "zh_CN")
    static let japan = Locale(identifier: "ja_JP")
    static let brazil = Locale(identifier: "pt_BR")
    static let korea = Locale(identifier: "ko_KR")

    static var nextMockedLocale = { us }
    static func mock(returning mockedValue: @escaping () -> Locale = nextMockedLocale) -> () -> Locale {
        { mockedValue() }
    }
    #endif
}
