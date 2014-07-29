//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Foundation


/// NSNotificationCenter observer wrapper.
public enum QNotificationObserver: QObserver {

    /// Wraps a block-based observer and center.
    case Block(ref: AnyObject, center: NSNotificationCenter)
    /// Wraps an object-based observer and sender.
    case Object(object: AnyObject, name: String?, sender: AnyObject?, center: NSNotificationCenter)
    /// Specifies that this is not currently observing anything. Disconnecting
    /// this is a no-op.
    case None


    /// Disconnects the notification observer if defined. Returns true if
    /// defined, otherwise false.
    mutating public func disconnect() -> Bool {
        switch self {
        case let .Block(ref, center):
            center.removeObserver(ref)
        case let .Object(obj, name, sender, center):
            center.removeObserver(obj, name: name, object: sender)
        case .None:
            return false
        }

        self = .None

        return true
    }


    public var isConnected: Bool {
        get {
            // For some reason, `return self != .None` doesn't work.
            switch self {
            case .None: return false
            default: return true
            }
        }
    }

}


/// Observe notifications with the given name. The queue to respond on, the
/// sender to watch for, and the center used may also be provided. By default,
/// no queue is provided, the sender is AnyObject, and the default notification
/// center is used.
public func observeNotification(
    sentBy sender: AnyObject? = nil,
    onQueue queue: NSOperationQueue? = nil,
    center: NSNotificationCenter = NSNotificationCenter.defaultCenter(),
    named name: String,
    block: (NSNotification!) -> Void
    ) -> QNotificationObserver
{
    let ref = center.addObserverForName(name, object: sender, queue: queue, usingBlock: block)
    return QNotificationObserver.Block(ref: ref, center: center)
}


/// Shorthand for posting a notification with a given name, sender, and info
/// dictionary through a notification center. By default, the notification
/// sender and info dictionary are nil and the default notification center
/// is used.
public func notify(
    name: String,
    from sender: AnyObject? = nil,
    info: [NSObject: AnyObject]? = nil,
    center: NSNotificationCenter = NSNotificationCenter.defaultCenter()
    )
{
    center.postNotificationName(name, object: sender, userInfo: info)
}
