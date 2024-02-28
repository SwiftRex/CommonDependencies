#if canImport(Combine)
import Combine
import Foundation

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension CommonDependencies {
    public enum Decoders { }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public protocol TopLevelDecoderEx<Input>: TopLevelDecoder { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct AnyDecoder<Input>: TopLevelDecoderEx {
    private let innerDecoder: any TopLevelDecoderEx<Input>

    public init<D: TopLevelDecoderEx<Input>>(erasing decoder: D) where D.Input == Input {
        innerDecoder = decoder
    }

    public func decode<T>(_ type: T.Type, from: Input) throws -> T where T : Decodable {
        try innerDecoder.decode(type, from: from)
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension TopLevelDecoderEx {
    public func eraseToAnyDecoder() -> AnyDecoder<Input> {
        .init(erasing: self)
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension JSONDecoder: TopLevelDecoderEx { }

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension CommonDependencies.Decoders {
    public static func live<D: TopLevelDecoderEx>(
        innerDecoder: @escaping () -> D
    ) -> () -> AnyDecoder<D.Input> {
        { innerDecoder().eraseToAnyDecoder() }
    }

    public static func liveJSON(
        settings: @escaping (JSONDecoder) -> JSONDecoder = { $0 }
    ) -> () -> AnyDecoder<Data> {
        { settings(JSONDecoder()).eraseToAnyDecoder() }
    }
}

#if DEBUG
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension CommonDependencies.Decoders {
    static var dataDecoderMock = DataDecoderMock()
    static func mock<Input>(
        returning decoder: @escaping () -> any TopLevelDecoderEx<Input>
    ) -> () -> AnyDecoder<Input> {
        { decoder().eraseToAnyDecoder() }
    }

    static func mockJSON(returning jsonDecoder: @escaping () -> DataDecoderMock = { dataDecoderMock }) -> () -> AnyDecoder<Data> {
        { jsonDecoder().eraseToAnyDecoder() }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension CommonDependencies.Decoders {
    typealias DataDecoderMock = DecoderMock<Data>

    class DecoderMock<Input>: TopLevelDecoderEx {
        var nextDecode: ((Input) -> Result<Any, DecodingError>) = { _ in
            .failure(.dataCorrupted(.init(codingPath: [], debugDescription: "")))
        }

        func decode<T>(_ type: T.Type, from: Input) throws -> T where T : Decodable {
            let decoded = try nextDecode(from).get()
            return try decoded as? T ?? {
                throw DecodingError.typeMismatch(type, .init(codingPath: [], debugDescription: ""))
            }()
        }
    }
}
#endif

#endif
