//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Foundation


/// Exception thrown when attempting to schedule a barrier block on a queue
/// that does not accept barrier blocks (i.e., NSOperatonQueue).
internal let QBarrierUnsupportedException = "QBarrierUnsupportedException"


/// Enumeration for Cocoa/Dispatch work queues. Wraps dispatch queues and
/// NSOperationQueue instances. Both permit scheduling of synchronous and
/// asynchronous execution of blocks, while dispatch queues also permit
/// scheduling barrier blocks as well.
///
/// A third case, the .Immediate queue, is for forcing execution of blocks
/// onto the calling thread to be performed immediately. This is only really
/// useful for debugging.
public enum QWorkQueue {

    /// A closure or function that takes no arguments and returns nothing.
    public typealias Work = () -> Void


    /// QWorkQueue for a dispatch_queue_t
    case DispatchQueue(dispatch_queue_t)

    /// QWorkQueue for an NSOperationQueue
    case OperationQueue(NSOperationQueue)

    /// QWorkQueue for the same thread of execution (just calls the block given
    /// for both sync and async).
    case Immediate


    /// Gets the main thread's dispatch queue.
    public static var MainDispatch: QWorkQueue {
        get {
            return DispatchQueue(dispatch_get_main_queue())
        }
    }


    /// Gets the main thread's NSOperationQueue.
    public static var MainOps: QWorkQueue {
        get {
            return OperationQueue(NSOperationQueue.mainQueue())
        }
    }


    /// Gets the high priority global dispatch queue.
    public static var HighPriority: QWorkQueue {
        get {
            let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
            return DispatchQueue(queue)
        }
    }


    /// Gets the default priority global dispatch queue.
    public static var DefaultPriority: QWorkQueue {
        get {
            let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
            return DispatchQueue(queue)
        }
    }


    /// Gets the low priority global dispatch queue.
    public static var LowPriority: QWorkQueue {
        get {
            let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
            return DispatchQueue(queue)
        }
    }


    /// Gets the background priority global dispatch queue.
    public static var Background: QWorkQueue {
        get {
            let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
            return DispatchQueue(queue)
        }
    }


    /// Attempts to get the current NSOperationQueue and return it as a
    /// QWorkQueue. Returns nothing if unsuccessful.
    public var CurrentOps: QWorkQueue? {
        get {
            if let queue = NSOperationQueue.currentQueue()? {
                return OperationQueue(queue)
            } else {
                return nil
            }
        }
    }


    /// Allocates a new concurrent dispatch queue with the given name.
    public static func concurrentDispatchQueue(named: String) -> QWorkQueue {
        return newDispatchQueue(named, attr: DISPATCH_QUEUE_CONCURRENT)
    }


    /// Allocates a new serial dispatch queue with the given name.
    public static func serialDispatchQueue(named: String) -> QWorkQueue {
        return newDispatchQueue(named, attr: DISPATCH_QUEUE_SERIAL)
    }


    /// Allocates a new dispatch queue with the given name and attributes.
    public static func newDispatchQueue(named: String, attr: dispatch_queue_attr_t) -> QWorkQueue {
        let queue = named.withCString { dispatch_queue_create($0, attr) }
        return DispatchQueue(queue)
    }


    /// Schedules the given block asynchronously on the QWorkQueue. This is your
    /// fire-and-forget work.
    public func async(block: Work) {
        switch (self) {
        case .Immediate:
            block()

        case let .DispatchQueue(queue):
            dispatch_async(queue, block)

        case let .OperationQueue(queue):
            queue.addOperationWithBlock(block)
        }
    }


    /// Schedules the given block on the QWorkQueue and attempts to wait until
    /// the block has run and finished.
    ///
    /// Be warned that attempting to run a synchronous task on a queue that you
    /// are already on will potentially deadlock or worse. Where possible,
    /// avoid synchronous tasks altogether or do not schedule them on the same
    /// queue currently executing the task.
    public func sync(block: Work) {
        switch (self) {
        case .Immediate:
            block()

        case let .DispatchQueue(queue):
            dispatch_sync(queue, block)

        case let .OperationQueue(queue):
            let blockOp = NSBlockOperation(block: block)
            queue.addOperation(blockOp)
            blockOp.waitUntilFinished()
        }
    }


    /// Schedules an async block on the given queue with a barrier to ensure
    /// other blocks do not execute concurrently.
    ///
    /// Only supported on dispatch queues. Attempting to schedule a barrier
    /// block on an NSOperationQueue will raise an exception because the
    /// operation is impossible and doing anything else could potentially
    /// compromise the program's state.
    ///
    /// Immediate queues continue to execute blocks
    /// immediately on the calling thread (i.e., same as just calling the block
    /// yourself).
    public func asyncWithBarrier(block: Work) {
        switch (self) {
        case .Immediate:
            // Would throw an exception for this as well, but this is already
            // sort of a barrier and mostly for the sake of debugging
            // (i.e., the chance of Immediate being useful in normal contexts
            // is really low).
            block()

        case let .DispatchQueue(queue):
            dispatch_barrier_async(queue, block)

        case let .OperationQueue(queue):
            NSException(
                name: QBarrierUnsupportedException,
                reason: "Async barrier operations are unsupported for NSOperationQueue",
                userInfo: nil
                ).raise()
        }
    }


    /// Schedules a sync block on the given queue with a barrier to ensure
    /// other blocks do not execute concurrently. Does not return until
    /// the block has finished executing.
    ///
    /// Only supported on dispatch queues. Attempting to schedule a barrier
    /// block on an NSOperationQueue will raise an exception because the
    /// operation is impossible and doing anything else could potentially
    /// compromise the program's state.
    ///
    /// Immediate queues continue to execute blocks immediately on the calling
    /// thread (i.e., same as just calling the block yourself).
    public func syncWithBarrier(block: Work) {
        switch (self) {
        case .Immediate:
            block()

        case let .DispatchQueue(queue):
            dispatch_barrier_sync(queue, block)

        case let .OperationQueue(queue):
            NSException(
                name: QBarrierUnsupportedException,
                reason: "Sync barrier operations are unsupported for NSOperationQueue",
                userInfo: nil
                ).raise()
        }
    }


    /// Runs the given block on the main thread asynchronously. This is
    /// short-hand for requesting the main dispatch thread and calling its
    /// async method.
    public static func runOnMain(block: Work) {
        MainDispatch.async(block)
    }

}
