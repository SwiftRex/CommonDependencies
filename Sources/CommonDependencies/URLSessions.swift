import Foundation

extension CommonDependencies {
    public enum URLSessions { }
}

extension CommonDependencies.URLSessions {
    public static func live(value: @escaping () -> URLSession = { .shared }) -> () -> URLSession {
        { value() }
    }
}

fileprivate extension Result {
    func fold<T>(success: (Success) -> T, failure: (Failure) -> T) -> T {
        switch self {
        case let .success(value): success(value)
        case let .failure(error): failure(error)
        }
    }
}

#if DEBUG
extension CommonDependencies.URLSessions {
    static var nextRequestHandler: ((URLRequest) -> Result<(data: Data, response: URLResponse), URLError>) = { _ in
        MockedResponses.failure(error: .badServerResponse)
    }

    static var nextMockedURLSessionConfiguration = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolMock.self]
        return configuration
    }

    static var nextMockedURLSession = { URLSession(configuration: nextMockedURLSessionConfiguration()) }

    static func mock(returning mockedValue: @escaping () -> URLSession = nextMockedURLSession) -> () -> URLSession {
        { mockedValue() }
    }
}

extension CommonDependencies.URLSessions {
    class URLProtocolMock: URLProtocol {
        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canInit(with task: URLSessionTask) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
        override func startLoading() {
            nextRequestHandler(request)
                .fold(
                    success: { (data, response) in
                        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                        client?.urlProtocol(self, didLoad: data)
                        client?.urlProtocolDidFinishLoading(self)
                    },
                    failure: { error in
                        client?.urlProtocol(self, didFailWithError: error)
                    }
                )
        }
        override func stopLoading() { }
    }
}

extension CommonDependencies.URLSessions {
    enum MockedResponses { }
}

extension CommonDependencies.URLSessions.MockedResponses {
    static func successful(
        from url: URL,
        with data: Data = Data(),
        headers: [String: String]? = nil
    ) -> Result<(data: Data, response: URLResponse), URLError> {
        Self.custom(from: url, statusCode: 200, with: data, headers: headers)
    }

    static func http403(
        from url: URL,
        with data: Data = Data(),
        headers: [String: String]? = nil
    ) -> Result<(data: Data, response: URLResponse), URLError> {
        Self.custom(from: url, statusCode: 403, with: data, headers: headers)
    }

    static func http404(
        from url: URL,
        with data: Data = Data(),
        headers: [String: String]? = nil
    ) -> Result<(data: Data, response: URLResponse), URLError> {
        Self.custom(from: url, statusCode: 404, with: data, headers: headers)
    }

    static func http500(
        from url: URL,
        with data: Data = Data(),
        headers: [String: String]? = nil
    ) -> Result<(data: Data, response: URLResponse), URLError> {
        Self.custom(from: url, statusCode: 500, with: data, headers: headers)
    }

    static func custom(
        from url: URL,
        statusCode: Int,
        with data: Data = Data(),
        headers: [String: String]? = nil
    ) -> Result<(data: Data, response: URLResponse), URLError> {
        .success(
            (
                data: data,
                response: HTTPURLResponse(
                    url: url,
                    statusCode: statusCode,
                    httpVersion: "1.1",
                    headerFields: headers
                ) ?? HTTPURLResponse()
            )
        )
    }

    static func failure(
        error: URLError.Code
    ) -> Result<(data: Data, response: URLResponse), URLError> {
        .failure(.init(error))
    }
}
#endif
