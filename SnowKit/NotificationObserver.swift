//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Foundation


/// NSNotificationCenter observer wrapper.
enum NotificationObserver {

    /// Wraps a block-based observer and center.
    case Block(ref: AnyObject, center: NSNotificationCenter)
    /// Wraps an object-based observer and sender.
    case Object(object: AnyObject, name: String?, sender: AnyObject?, center: NSNotificationCenter)
    /// Specifies that this is not currently observing anything. Disconnecting
    /// this is a no-op.
    case None


    func disconnect() {
        switch self {
        case let .Block(ref, center):
            center.removeObserver(ref)
        case let .Object(obj, name, sender, center):
            center.removeObserver(obj, name: name, object: sender)
        case .None:
            return
        }
    }

}


/// Observe notifications with the given name. The queue to respond on, the
/// sender to watch for, and the center used may also be provided. By default,
/// no queue is provided, the sender is AnyObject, and the default notification
/// center is used.
func observeNotification(
    sentBy sender: AnyObject? = nil,
    onQueue queue: NSOperationQueue? = nil,
    center: NSNotificationCenter = NSNotificationCenter.defaultCenter(),
    named name: String,
    block: (NSNotification!) -> Void
    ) -> NotificationObserver
{
    let ref = center.addObserverForName(name, object: sender, queue: queue, usingBlock: block)
    return NotificationObserver.Block(ref: ref, center: center)
}


/// Disconnects the given observer, if possible, and sets it to .None.
func disconnectObserver(inout observer: NotificationObserver) {
    observer.disconnect()
    observer = .None
}


/// Disconnects the given observer.
func disconnectObserver(var observer: NotificationObserver) {
    observer.disconnect()
}


/// Shorthand for posting a notification with a given name, sender, and info
/// dictionary through a notification center. By default, the notification
/// sender and info dictionary are nil and the default notification center
/// is used.
func notify(
    name: String,
    from sender: AnyObject? = nil,
    info: [NSObject: AnyObject]? = nil,
    center: NSNotificationCenter = NSNotificationCenter.defaultCenter()
    )
{
    center.postNotificationName(name, object: sender, userInfo: info)
}
