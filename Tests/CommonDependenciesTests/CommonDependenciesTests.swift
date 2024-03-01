import Combine
import XCTest
@testable import CommonDependencies

final class CommonDependenciesTests: XCTestCase {
    func testUsage() throws {
        // if test {
        let world = World.mock
        // } else {
        //     let world = World.live
        // }

        let defaultCalendar = world.calendar()
        // This can only be done in tests:
        CommonDependencies.Calendars.nextMockedCalendar = .init(identifier: .buddhist)
        let mockedCalendar = world.calendar()

        let defaultDateFormatter = world.dateFormatter()
        // This can only be done in tests:
        CommonDependencies.DateFormatters.nextMockedDateFormatter = {
            let dateFormatter = DateFormatter()
            dateFormatter.timeZone = .init(secondsFromGMT: 0)
            dateFormatter.locale = CommonDependencies.Locales.china
            dateFormatter.calendar = .init(identifier: .chinese)
            return dateFormatter
        }()
        let mockedDateFormatter = world.dateFormatter()

        let jsonDecoder = world.decoder()
        // This can only be done in tests:
        CommonDependencies.Decoders.dataDecoderMock.nextDecode = { _ in
            .success("Mocked Reeturn")
        }
        let mockedDecoder = world.decoder()
        _ = Just(Data())
            .decode(type: String.self, decoder: mockedDecoder)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in }
            )

        let jsonEncoder = world.encoder()
        // This can only be done in tests:
        CommonDependencies.Encoders.dataEncoderMock.nextEncode = { _ in
            .success(Data())
        }
        let mockedEncoder = world.encoder()

        let defaultLocale = world.locale()
        // This can only be done in tests:
        CommonDependencies.Locales.nextMockedLocale = CommonDependencies.Locales.germany
        let mockedLocale = world.locale()

        let defaultDate = world.now()
        // This can only be done in tests:
        CommonDependencies.Now.nextMockedDate = Date(timeIntervalSince1970: 1234)
        let mockedDate = world.now()

        let defaultNumberFormatter = world.numberFormatter()
        // This can only be done in tests:
        CommonDependencies.NumberFormatters.nextMockedNumberFormatter = {
            let numberFormatter = NumberFormatter()
            numberFormatter.locale = CommonDependencies.Locales.china
            numberFormatter.numberStyle = .currency
            return numberFormatter
        }()
        let mockedNumberFormatter = world.numberFormatter()

        let defaultTimeZone = world.timeZone()
        // This can only be done in tests:
        CommonDependencies.TimeZones.nextMockedTimeZone = .init(secondsFromGMT: 3600) ?? .current
        let mockedTimeZone = world.timeZone()

        let scheduler = world.mainScheduler
        // This can only be done in tests:
        CommonDependencies.Schedulers.dispatchQueueMock.advance(to: .init(.now()))
        scheduler.schedule(after: .init(.now() + .seconds(3))) {
            print("3 seconds later...")
        }
        CommonDependencies.Schedulers.dispatchQueueMock.advance(by: .seconds(3))

        let defaultUrlSession = world.urlSession()
        // This can only be done in tests:
        CommonDependencies.URLSessions.nextRequestHandler = { request in
            CommonDependencies.URLSessions.MockedResponses
                .http404(from: URL(string: "https://github.com")!)
        }
        defaultUrlSession
            .dataTask(with: URLRequest(url: URL(string: "https://github.com")!))
            .resume()

        let defaultUrlRequester = world.urlRequestPublisher
        // This can only be done in tests:
        CommonDependencies.URLRequestPublishers.nextRequestHandler = { request in
            CommonDependencies.URLSessions.MockedResponses
                .http404(from: URL(string: "https://github.com")!)
                .publisher
        }
        _ = defaultUrlRequester(URLRequest(url: URL(string: "https://github.com")!))
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in }
            )
    }
}

public struct World {
    public let calendar: () -> Calendar
    public let dateFormatter: () -> DateFormatter
    public let decoder: () -> AnyDecoder<Data>
    public let encoder: () -> AnyEncoder<Data>
    public let locale: () -> Locale
    public let now: () -> Date
    public let numberFormatter: () -> NumberFormatter
    public let mainScheduler: CommonDependencies.Schedulers.DispatchQueueScheduler
    public let timeZone: () -> TimeZone
    public let urlRequestPublisher: Publishers.URLRequestPublisher
    public let urlSession: () -> URLSession
}

extension World {
    public static let live: World = {
        let urlSession = CommonDependencies.URLSessions.live()

        return World(
            calendar: CommonDependencies.Calendars.live(),
            dateFormatter: CommonDependencies.DateFormatters.live { $0.dateStyle = .full; return $0 },
            decoder: CommonDependencies.Decoders.liveJSON { $0.keyDecodingStrategy = .convertFromSnakeCase; return $0 },
            encoder: CommonDependencies.Encoders.liveJSON { $0.keyEncodingStrategy = .convertToSnakeCase; return $0 },
            locale: CommonDependencies.Locales.live(),
            now: CommonDependencies.Now.live(),
            numberFormatter: CommonDependencies.NumberFormatters.live { $0.numberStyle = .currency; return $0 },
            mainScheduler: CommonDependencies.Schedulers.liveDispatch(queue: .main),
            timeZone: CommonDependencies.TimeZones.live(),
            urlRequestPublisher: CommonDependencies.URLRequestPublishers.live(session: urlSession),
            urlSession: urlSession
        )
    }()

    #if DEBUG
    static let mock = World(
        calendar: CommonDependencies.Calendars.mock(),
        dateFormatter: CommonDependencies.DateFormatters.mock(),
        decoder: CommonDependencies.Decoders.mockJSON(),
        encoder: CommonDependencies.Encoders.mockJSON(),
        locale: CommonDependencies.Locales.mock(),
        now: CommonDependencies.Now.mock(),
        numberFormatter: CommonDependencies.NumberFormatters.mock(),
        mainScheduler: CommonDependencies.Schedulers.mockDispatch(),
        timeZone: CommonDependencies.TimeZones.mock(),
        urlRequestPublisher: CommonDependencies.URLRequestPublishers.mock(),
        urlSession: CommonDependencies.URLSessions.mock()
    )
    #endif
}
