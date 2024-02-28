#if canImport(Combine)
import Combine
import Foundation

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension CommonDependencies {
    public enum Schedulers { }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension CommonDependencies.Schedulers {
    public typealias DispatchQueueScheduler = any Scheduler<DispatchQueue.SchedulerTimeType>

    public static func live<S: Scheduler>(innerScheduler: S) -> () -> any Scheduler<S.SchedulerTimeType> {
        { innerScheduler }
    }

    public static func liveDispatch(queue: DispatchQueue = .main) -> () -> DispatchQueueScheduler {
        { queue }
    }
}

#if DEBUG
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension CommonDependencies.Schedulers {
    static var dispatchQueueMock = DispatchQueueMock()
    static func mock<S: Scheduler>(
        ofType: S.Type,
        returning scheduler: @escaping () -> SchedulerMock<S.SchedulerTimeType, S.SchedulerOptions>
    ) -> () -> SchedulerMock<S.SchedulerTimeType, S.SchedulerOptions> {
        { scheduler() }
    }
    static func mockDispatch(returning scheduler: @escaping () -> DispatchQueueScheduler = { dispatchQueueMock }) -> () -> DispatchQueueScheduler {
        { scheduler() }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension CommonDependencies.Schedulers {
    typealias DispatchQueueMock = SchedulerMock<DispatchQueue.SchedulerTimeType, DispatchQueue.SchedulerOptions>

    class SchedulerMock<SchedulerTimeType, SchedulerOptions>: Scheduler
    where SchedulerTimeType: Strideable, SchedulerTimeType.Stride: SchedulerTimeIntervalConvertible {
        private var pendingTasks: [(sequence: UInt, date: SchedulerTimeType, perform: () -> Void)] = []
        private let lock = NSRecursiveLock()

        internal private(set) var now: SchedulerTimeType
        internal var minimumTolerance: SchedulerTimeType.Stride = .zero

        init(now: SchedulerTimeType) {
            self.now = now
        }

        init() where SchedulerTimeType == DispatchQueue.SchedulerTimeType, SchedulerOptions == DispatchQueue.SchedulerOptions {
            self.now = .init(.init(uptimeNanoseconds: 1))
        }

        func advance(by timeSpan: SchedulerTimeType.Stride) {
            self.advance(to: now.advanced(by: timeSpan))
        }

        func advance(to time: SchedulerTimeType) {
            while lock.use(operation: { self.now }) <= time {
                lock.lock()
                pendingTasks.sort { ($0.date, $0.sequence) < ($1.date, $1.sequence) }

                guard pendingTasks.first.map({ task in time >= task.date }) ?? false
                else {
                    now = time
                    lock.unlock()
                    return
                }

                let task = pendingTasks.removeFirst()
                now = task.date
                lock.unlock()
                task.perform()
            }
        }

        func schedule(
            options: SchedulerOptions?,
            _ action: @escaping () -> Void
        ) {
            lock.use { pendingTasks.append((nextSequence(), now, action)) }
        }

        func schedule(
            after date: SchedulerTimeType,
            tolerance: SchedulerTimeType.Stride,
            options: SchedulerOptions?,
            _ action: @escaping () -> Void
        ) {
            lock.use { pendingTasks.append((nextSequence(), date, action)) }
        }

        private func nextSequence() -> UInt {
            1 +
            (pendingTasks.lazy.map(\.sequence).max() ?? 0)
        }

        func schedule(
            after date: SchedulerTimeType,
            interval: SchedulerTimeType.Stride,
            tolerance: SchedulerTimeType.Stride,
            options: SchedulerOptions?,
            _ action: @escaping () -> Void
        ) -> Cancellable {
            let sequence = lock.use { nextSequence() }

            func scheduleAction(for date: SchedulerTimeType) -> () -> Void {
                { [weak self] in
                    guard let self else { return }

                    let nextDate = date.advanced(by: interval)
                    lock.use {
                        self.pendingTasks.append((sequence, nextDate, scheduleAction(for: nextDate)))
                    }

                    action()
                }
            }

            lock.use { pendingTasks.append((sequence, date, scheduleAction(for: date))) }

            return AnyCancellable { [weak self] in
                guard let self else { return }
                lock.use { self.pendingTasks.removeAll(where: { $0.sequence == sequence }) }
            }
        }

        func waitForAllTasks() {
            while let date = lock.use(operation: { pendingTasks.first?.date }) {
                advance(by: lock.use { now.distance(to: date) })
            }
        }
    }
}

extension NSRecursiveLock {
    fileprivate func use<A>(operation: () -> A) -> A {
        self.lock()
        defer { self.unlock() }
        return operation()
    }
}
#endif

#endif
