//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Foundation


/// Asynchronous WorkQueue scheduling operator.
operator infix <- { associativity left }

/// Synchronous WorkQueue scheduling operator.
operator infix <+ { associativity left }

/// Asynchronous with barrier WorkQueue scheduling operator.
operator infix |<- { associativity left }

/// Synchronous with barrier WorkQueue scheduling operator.
operator infix |<+ { associativity left }


/// Exception thrown when attempting to schedule a barrier block on a queue
/// that does not accept barrier blocks (i.e., NSOperatonQueue).
let QBarrierUnsupportedException = "QBarrierUnsupportedException"


/// Enumeration for Cocoa/Dispatch work queues. Wraps dispatch queues and
/// NSOperationQueue instances. Both permit scheduling of synchronous and
/// asynchronous execution of blocks, while dispatch queues also permit
/// scheduling barrier blocks as well.
///
/// A third case, the .Immediate queue, is for forcing execution of blocks
/// onto the calling thread to be performed immediately. This is only really
/// useful for debugging.
enum WorkQueue {

    /// A closure or function that takes no arguments and returns nothing.
    typealias Work = () -> Void


    /// WorkQueue for a dispatch_queue_t
    case DispatchQueue(dispatch_queue_t)

    /// WorkQueue for an NSOperationQueue
    case OperationQueue(NSOperationQueue)

    /// WorkQueue for the same thread of execution (just calls the block given
    /// for both sync and async).
    case Immediate


    /// Gets the main thread's dispatch queue.
    static var MainDispatch: WorkQueue {
        get {
            return DispatchQueue(dispatch_get_main_queue())
        }
    }


    /// Gets the main thread's NSOperationQueue.
    static var MainOps: WorkQueue {
        get {
            return OperationQueue(NSOperationQueue.mainQueue())
        }
    }


    /// Gets the high priority global dispatch queue.
    static var HighPriority: WorkQueue {
        get {
            let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
            return DispatchQueue(queue)
        }
    }


    /// Gets the default priority global dispatch queue.
    static var DefaultPriority: WorkQueue {
        get {
            let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
            return DispatchQueue(queue)
        }
    }


    /// Gets the low priority global dispatch queue.
    static var LowPriority: WorkQueue {
        get {
            let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
            return DispatchQueue(queue)
        }
    }


    /// Gets the background priority global dispatch queue.
    static var Background: WorkQueue {
        get {
            let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
            return DispatchQueue(queue)
        }
    }


    /// Attempts to get the current NSOperationQueue and return it as a
    /// WorkQueue. Returns nothing if unsuccessful.
    var CurrentOps: WorkQueue? {
        get {
            if let queue = NSOperationQueue.currentQueue()? {
                return OperationQueue(queue)
            } else {
                return nil
            }
        }
    }


    /// Allocates a new concurrent dispatch queue with the given name.
    static func concurrentDispatchQueue(named: String) -> WorkQueue {
        return newDispatchQueue(named, attr: DISPATCH_QUEUE_CONCURRENT)
    }


    /// Allocates a new serial dispatch queue with the given name.
    static func serialDispatchQueue(named: String) -> WorkQueue {
        return newDispatchQueue(named, attr: DISPATCH_QUEUE_SERIAL)
    }


    /// Allocates a new dispatch queue with the given name and attributes.
    static func newDispatchQueue(named: String, attr: dispatch_queue_attr_t) -> WorkQueue {
        let queue = named.withCString { dispatch_queue_create($0, attr) }
        return DispatchQueue(queue)
    }


    /// Schedules the given block asynchronously on the WorkQueue. This is your
    /// fire-and-forget work.
    func async(block: Work) {
        switch (self) {
        case .Immediate:
            block()

        case let .DispatchQueue(queue):
            dispatch_async(queue, block)

        case let .OperationQueue(queue):
            queue.addOperationWithBlock(block)
        }
    }


    /// Schedules the given block on the WorkQueue and attempts to wait until
    /// the block has run and finished.
    ///
    /// Be warned that attempting to run a synchronous task on a queue that you
    /// are already on will potentially deadlock or worse. Where possible,
    /// avoid synchronous tasks altogether or do not schedule them on the same
    /// queue currently executing the task.
    func sync(block: Work) {
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
    func asyncWithBarrier(block: Work) {
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
    func syncWithBarrier(block: Work) {
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
    static func runOnMain(block: Work) {
        MainDispatch.async(block)
    }

}


/// Short-hand operator for scheduling a block for asynchronous execution on a
/// WorkQueue.
///
/// Returns the queue to permit chaining.
@infix func <- (queue: WorkQueue, block: WorkQueue.Work) -> WorkQueue {
    queue.async(block)
    return queue
}


/// Short-hand operator for scheduling a block for synchronous execution on a
/// WorkQueue (i.e., this will not return until the block has finished).
///
/// Returns the queue to permit chaining.
@infix func <+ (queue: WorkQueue, block: WorkQueue.Work) -> WorkQueue {
    queue.sync(block)
    return queue
}


/// Short-hand operator for scheduling a block for asynchronous execution with
/// a barrier on a WorkQueue.
///
/// Returns the queue to permit chaining.
@infix func |<- (queue: WorkQueue, block: WorkQueue.Work) -> WorkQueue {
    queue.asyncWithBarrier(block)
    return queue
}


/// Short-hand operator for scheduling a block for synchronous execution with a
/// barrier on a WorkQueue (i.e., this will not return until the block has
/// finished).
///
/// Returns the queue to permit chaining.
@infix func |<+ (queue: WorkQueue, block: WorkQueue.Work) -> WorkQueue {
    queue.syncWithBarrier(block)
    return queue
}
