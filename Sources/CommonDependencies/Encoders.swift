#if canImport(Combine)
import Combine
import Foundation

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension CommonDependencies {
    public enum Encoders { }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public protocol TopLevelEncoderEx<Output>: TopLevelEncoder { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct AnyEncoder<Output>: TopLevelEncoderEx {
    private let innerEncoder: any TopLevelEncoderEx<Output>

    public init<E: TopLevelEncoderEx<Output>>(erasing encoder: E) where E.Output == Output {
        innerEncoder = encoder
    }

    public func encode<T>(_ value: T) throws -> Output where T : Encodable {
        try innerEncoder.encode(value)
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension TopLevelEncoderEx {
    public func eraseToAnyEncoder() -> AnyEncoder<Output> {
        .init(erasing: self)
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension JSONEncoder: TopLevelEncoderEx { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension CommonDependencies.Encoders {
    public static func live<E: TopLevelEncoderEx>(
        innerEncoder: @escaping () -> E
    ) -> () -> AnyEncoder<E.Output> {
        { innerEncoder().eraseToAnyEncoder() }
    }

    public static func liveJSON(
        settings: @escaping (JSONEncoder) -> JSONEncoder = { $0 }
    ) -> () -> AnyEncoder<Data> {
        { settings(JSONEncoder()).eraseToAnyEncoder() }
    }
}

#if DEBUG
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension CommonDependencies.Encoders {
    static var dataEncoderMock = DataEncoderMock()
    static func mock<Output>(
        returning encoder: @escaping () -> any TopLevelEncoderEx<Output>
    ) -> () -> AnyEncoder<Output> {
        { encoder().eraseToAnyEncoder() }
    }

    static func mockJSON(returning jsonEncoder: @escaping () -> DataEncoderMock = { dataEncoderMock }) -> () -> AnyEncoder<Data> {
        { jsonEncoder().eraseToAnyEncoder() }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension CommonDependencies.Encoders {
    typealias DataEncoderMock = EncoderMock<Data>

    class EncoderMock<Output>: TopLevelEncoderEx {
        var nextEncode: ((Any) -> Result<Output, EncodingError>) = { instance in
            .failure(.invalidValue(instance, .init(codingPath: [], debugDescription: "")))
        }

        func encode<T>(_ value: T) throws -> Output where T : Encodable {
            return try nextEncode(value).get()
        }
    }
}
#endif

#endif
