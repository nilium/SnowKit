//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Foundation


/// An enum wrapping possible key-value observers (or a lack thereof).
enum KeyValueObserver {

    public typealias Block = (String, AnyObject, NSDictionary) -> Void


    /// A standard object-based observer for a single object.
    case Object(path: String, sender: NSObject, receiver: NSObject, context: UnsafePointer<Void>)
    /// A standard object-based observer for objects in an array at the given
    /// indices.
    case ArrayObject(path: String, array: NSArray, indices: NSIndexSet, receiver: NSObject, context: UnsafePointer<Void>)
    /// No defined observer. Disconnecting this is a no-op.
    case None


    /// Disconnects this observer. Returns true if the observer is defined,
    /// otherwise false (in the case of .None).
    func disconnect() -> Bool {
        switch (self) {
        case let .Object(path, sender, receiver, ctx):
            sender.removeObserver(receiver, forKeyPath: path, context: ctx)
        case let .ArrayObject(path, array, indices, receiver, ctx):
            array.removeObserver(receiver, fromObjectsAtIndexes: indices, forKeyPath: path, context: ctx)
        case .None:
            return false
        }

        return true
    }

}


/// Extension for NSKeyValueObservingOptions to simplify the use of its flags
/// in Swift.
extension NSKeyValueObservingOptions {

    /// Returns the given flags combined by bitwise-or.
    static func combined(opts: [NSKeyValueObservingOptions]) -> NSKeyValueObservingOptions {
        return self(opts.reduce(0) { $0 | $1.toRaw() })
    }

}


/// Block-based key-value observing forwarding object. Recieves key-value
/// observation updates and forwards them to a block. If provided with a queue
/// on initialization, the update's response is scheduled on that queue rather
/// than being executed on the calling thread.
class KeyValueObservationForwarder: NSObject {

    let block: KeyValueObserver.Block
    let queue: NSOperationQueue?


    init(block: KeyValueObserver.Block, queue: NSOperationQueue? = nil) {
        self.block = block
        self.queue = queue
    }


    override func observeValueForKeyPath(
        keyPath: String!,
        ofObject object: AnyObject!,
        change: [NSObject : AnyObject]!,
        context: UnsafePointer<Void> /* unused */
        )
    {
        if let queue = self.queue? {
            queue.addOperationWithBlock {
                self.block(keyPath, object, change)
            }
        } else {
            block(keyPath, object, change)
        }
    }

}


/// Observes the given key path on an object and returns the resulting
/// observer. Updates to the observed key path are forwarded to the provided
/// closure.
func observeKeyPath(
    path: String,
    ofObject object: NSObject,
    onQueue queue: NSOperationQueue? = nil,
    #options: [NSKeyValueObservingOptions],
    block: KeyValueObserver.Block
    ) -> KeyValueObserver
{
    let opts = NSKeyValueObservingOptions.combined(options)
    let forwarder = KeyValueObservationForwarder(block: block, queue: queue)
    object.addObserver(forwarder, forKeyPath: path, options: opts, context: nil)
    return KeyValueObserver.Object(path: path, sender: object, receiver: forwarder, context: nil)
}


/// Observes the given key path on an array's objects and returns the resulting
/// observer. Updates to the observed key path are forwarded to the provided
/// closure. If no indices are specified, all objects in the array are observed,
/// otherwise only those at the indices marked by the index set are observed.
func observeKeyPath(
    path: String,
    ofObjectsInArray array: NSArray,
    atIndices indices: NSIndexSet? = nil,
    onQueue queue: NSOperationQueue? = nil,
    #options: [NSKeyValueObservingOptions],
    block: KeyValueObserver.Block
    ) -> KeyValueObserver
{
    let forwarder = KeyValueObservationForwarder(block: block, queue: queue)
    let opts = NSKeyValueObservingOptions.combined(options)
    let indicesFinal: NSIndexSet = indices
        ? indices!
        : NSIndexSet(indexesInRange: NSRange(0 ..< array.count))

    array.addObserver(forwarder, toObjectsAtIndexes: indices, forKeyPath: path, options: opts, context: nil)
    return KeyValueObserver.ArrayObject(path: path, array: array, indices: indicesFinal, receiver: forwarder, context: nil)
}


/// Disconnects the given key-value observer and sets it to .None.
func disconnectObserver(inout observer: KeyValueObserver) {
    observer.disconnect()
    observer = .None
}


/// Disconnects the given key-value observer.
func disconnectObserver(var observer: KeyValueObserver) {
    observer.disconnect()
}

