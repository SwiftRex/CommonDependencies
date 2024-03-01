#if canImport(Combine)
import Combine
import Foundation

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers {
    public typealias URLRequestPublisher = ((URLRequest) -> any Publisher<(data: Data, response: URLResponse), URLError>)
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension CommonDependencies {
    enum URLRequestPublishers { }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension CommonDependencies.URLRequestPublishers {
    public static func live(
        session: @escaping () -> URLSession = { CommonDependencies.URLSessions.live()() },
        requestSettings: @escaping (URLRequest) -> URLRequest = { $0 },
        responseMap: @escaping ((data: Data, response: URLResponse)) -> (data: Data, response: URLResponse) = { $0 },
        errorMap: @escaping (URLError) -> URLError = { $0 }
    ) -> Publishers.URLRequestPublisher {
        { request in session().dataTaskPublisher(for: requestSettings(request)).map(responseMap).mapError(errorMap) }
    }

    #if DEBUG
    static var nextRequestHandler: ((URLRequest) -> any Publisher<(data: Data, response: URLResponse), URLError>) = { request in
        CommonDependencies.URLSessions.nextRequestHandler(request).publisher
    }

    static func mock(returning mockedValue: @escaping () -> Publishers.URLRequestPublisher = { nextRequestHandler }) -> Publishers.URLRequestPublisher {
        { mockedValue()($0) }
    }
    #endif
}

#endif
