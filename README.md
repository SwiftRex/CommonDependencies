# CommonDependencies
Several abstractions for Foundation entities that normally trigger side-effects, and their respective mocks

## Motivations
I often see myself creating these mocks over and over again for each new project that I start. Besides, it's very easy to oversee some implicit side-effects that happen in Foundation types. For example, a humble `DateFormatter` implicitly uses the `Calendar.current`, `Locale.current` and `TimeZone.current` every time you ask to format a date. If you think of a date formatter as a pure function `(String) -> Date` or `(Date) -> String`, you may not realise that, depending on the iOS Simulator you run this code, the behaviour may differ dramatically. And this is a side-effect, or, to be more precise, a co-effect, it's when a "function" is aware of the context outside of its scope, or even worse, outside of the program scope such as device settings, sensors, IO.

In Functional Programming we seek transparency about the behaviour of our functions, and for that, we need an honest function signature that makes obvious what's happening in there, including side-effects. Even if you don't apply FP, you still benefit from that when you are writing tests. How often you have failing unit tests because the iOS Simulator was set to a different Locale or TimeZone? The solution for that should not be changing your CI machines to match the same simulator settings, but instead, to write more reliable unit tests, after all, they are not supposed to have dependency on the hardware beneath. Furthermore, in a global world is increasingly important to write tests that cover different cultures, which includes, but is not limited to, different calendars, text orientation (LTR/RTL), time zones, languages.

Another problem we often face is controlling time. Countless times I saw a production codebase with flaky unit tests and where the solution was to increase the "wait for something to happen" from 300ms to 800ms, or something like that. The test will still fail if the CI machine is having a bad Monday, or, if it doesn't, your CI pipeline will be much slower than it should be, as these "waits" will make the computer idle for such period of time. If you use cloud-based CI, this costs you money, if not, you will eventually spend money on new CI machines because the devs are waiting too much for the pipeline to complete. The solution for that relies upon Schedulers, a concept introduced with Combine but that can be used independent from the reactive framework. Instead of writing `DispatchQueue.main.asyncAfter` you use the abstract form `Scheduler.asyncAfter`, which may use `DispatchQueue` behind the hood for the real world implementation, but in tests will be replaced by a custom Scheduler that doesn't follow the world clock, but has a completely controllable time, that will stay still if you want, or advance 1 full hour immediately.

Finally, `URLSession`. It's not very obvious how we can mock its results, but it's possible. Without Combine, we can use a custom `URLProtocol` inside the `URLSessionConfiguration` used when the `URLSession` is created. That `URLProtocol` controls the result of a request without triggering the request. This should be a bit easier to use. When using Combine you can also approach with the same technique as above, or simply abstract a request as being a function `(URLRequest) -> any Publisher<(data: Data, response: URLResponse), URLError>` and you either use the real `URLSession.dataTaskPublisher` or a custom `Result<(data: Data, response: URLResponse), URLError>.publisher` that you control exactly the behaviour.

The idea is to expand this tiny library to support the most common Foundation effectful structures, as long as no third-party library is required.

This library is MIT licensed, and if you don't want to add it as dependency, feel free to copy the file, or files, that suits your need.

## Examples

For all examples, let's suppose we have a central place to declare all our dependencies:

```swift
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
```

Yes, closures everywhere, but you can a use protocol `World` instead, if you come from OOP/POP background and feel more comfortable with that approach.

Now, let's create the real world, which runs real side-effects. In OOP that would be a class implementing your `World` protocol, with the closure approach we have something live that:

```swift
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
}
```

Please notice how we could reuse `urlSession` in two different parts. This is how you make a dependency that has another dependency. In some Dependency Injection frameworks you have to take care of declaring things in the correct order, or they will explode in runtime. Using the approach above, the compiler warns you in build-time.

In your `AppDelegate` or `main.swift` file, create a variable for the live world:
```swift
let world = World.live // or static let, if you don't fancy initialiser injection and prefer something like `AppDelegate.world.urlSession()` instead.
```

Now you pass that instance of `World` everywhere, or you can create subsets of it. For example, if you have an API module, you may want to create the following subset:

```swift
public struct APIDependencies {
    public let decoder: () -> AnyDecoder<Data>
    public let encoder: () -> AnyEncoder<Data>
    public let mainScheduler: CommonDependencies.Schedulers.DispatchQueueScheduler
    public let urlSession: () -> URLSession
}
```

Then you derive the whole World to this subset:

```swift
func moduleDependencies(world: World) -> APIDependencies {
    let dependencies = APIDependencies(
        decoder: world.decoder,
        encoder: world.encoder,
        mainScheduler: world.mainScheduler,
        urlSession: world.urlSession
    )
    return dependencies
}
```

Again, this can be done with protocols and classes, it doesn't change much. Give your API Module the `APIDependencies` subset and that's it! Let's use it.

```swift
func performRequest(urlRequest: URLRequest, dependencies: APIDependencies) {
    let jsonDecoder = dependencies.decoder()
    let mainQueue = dependencies.mainScheduler()
    let task = dependencies.urlSession().dataTask(with: urlRequest) { _, _, _ in
        // let user = Result { try jsonDecoder.decode(User.self, from: data) }
        // mainQueue.async { 
        // }
    }
    task.resume()
}
```

The example above illustrates how you can abstract all these side-effects and have multiple possibilities for mocking. For example, you can mock how `URLSession` behaves, what it should return in a specific test, what it should return in another test (so you don't forget to account for server errors and all the unhappy paths you may encounter), the same for `JSONDecoder` successfully or not decoding a JSON from the server. The `DispatchQueue.async` can be replaced in tests by a mocked Scheduler, and that async will actually happen immediately (not on the next RunLoop cycle), therefore you don't need "expectation" or "wait" times, simply advance your custom Scheduler to the next beat and the block will be called.

In tests you may have the following version of the World:

```swift
#if DEBUG
extension World {
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
}
#endif
```

All these mocks are provided with this library, as long as you build in DEBUG mode (so they won't be shipped to the AppStore). Another thing is that these mocks are created with internal visibility. This was intentional and the reasons are: you don't use mistakenly use them in production code, as they would fail the RELEASE build anyway, you don't see them in your code completion suggestions and you necessarily use `@testable import CommonDependencies` in your tests to access them. If you are not happy with this decision, please let me know in the Github issues and I'll consider changing it, as long as there's enough reason for that. Otherwise, you can fork or copy the files you need and change them.

### Calendar
```swift
// In tests use: `let world = World.mock`
let defaultCalendar = world.calendar()
// This can only be done in tests:
CommonDependencies.Calendars.nextMockedCalendar = .init(identifier: .buddhist)
let mockedCalendar = world.calendar()
```

### DateFormatter
```swift
// In tests use: `let world = World.mock`
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
```

### JSONDecoder
```swift
// In tests use: `let world = World.mock`
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
``` 

### JSONEncoder
```swift
// In tests use: `let world = World.mock`
let jsonEncoder = world.encoder()
// This can only be done in tests:
CommonDependencies.Encoders.dataEncoderMock.nextEncode = { _ in
    .success(Data())
}
let mockedEncoder = world.encoder()
``` 

### Locale
```swift
// In tests use: `let world = World.mock`
let defaultLocale = world.locale()
// This can only be done in tests:
CommonDependencies.Locales.nextMockedLocale = CommonDependencies.Locales.germany
let mockedLocale = world.locale()
``` 

### Current Date
```swift
// In tests use: `let world = World.mock`
let defaultDate = world.now()
// This can only be done in tests:
CommonDependencies.Now.nextMockedDate = Date(timeIntervalSince1970: 1234)
let mockedDate = world.now()
``` 

### NumberFormatter
```swift
// In tests use: `let world = World.mock`
let defaultNumberFormatter = world.numberFormatter()
// This can only be done in tests:
CommonDependencies.NumberFormatters.nextMockedNumberFormatter = {
    let numberFormatter = NumberFormatter()
    numberFormatter.locale = CommonDependencies.Locales.china
    numberFormatter.numberStyle = .currency
    return numberFormatter
}()
let mockedNumberFormatter = world.numberFormatter()
``` 

### TimeZone
```swift
// In tests use: `let world = World.mock`
let defaultTimeZone = world.timeZone()
// This can only be done in tests:
CommonDependencies.TimeZones.nextMockedTimeZone = .init(secondsFromGMT: 3600) ?? .current
let mockedTimeZone = world.timeZone()
``` 

### Scheduler
```swift
// In tests use: `let world = World.mock`
let scheduler = world.mainScheduler
// This can only be done in tests:
CommonDependencies.Schedulers.dispatchQueueMock.advance(to: .init(.now()))
scheduler.schedule(after: .init(.now() + .seconds(3))) {
    print("3 seconds later...")
}
CommonDependencies.Schedulers.dispatchQueueMock.advance(by: .seconds(3))
``` 

### URLSession
```swift
// In tests use: `let world = World.mock`
let defaultUrlSession = world.urlSession()
// This can only be done in tests:
CommonDependencies.URLSessions.nextRequestHandler = { request in
    CommonDependencies.URLSessions.MockedResponses
        .http404(from: URL(string: "https://github.com")!)
}
defaultUrlSession
    .dataTask(with: URLRequest(url: URL(string: "https://github.com")!))
    .resume()
``` 

### URLSessionPublisher (Request using Combine)
```swift
// In tests use: `let world = World.mock`
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
``` 
