//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Foundation


/// Protocol to describe a write-able queue (or queue-like) that has a fixed
/// capacity. Must implement a put() that returns whether it succeeds. A put()
/// should only succeed if isFull is false (otherwise items in the queue must
/// be discarded somehow).
public protocol QFixedWriteQueue {
    typealias Element
    func put(element: Element) -> Bool
    var isFull: Bool { get }
}


/// Protocol to describe a read-able queue (or queue-like) that has a fixed
/// capacity. Must implement a get() that returns items in the queue or nil if
/// the isEmpty property returns true.
public protocol QFixedReadQueue {
    typealias Element
    func get() -> Element?
    var isEmpty: Bool { get }
}


/// Combined QFixedWriteQueue and QFixedReadQueue protocol.
public protocol QFixedReadWriteQueue: QFixedWriteQueue, QFixedReadQueue {}


/// A basic ring buffer of objects of type T with independent read/write heads.
/// Conforms to QFixedReadWriteQueue.
public class QRingBuffer<T>: SequenceType, QFixedReadWriteQueue {

    public typealias Element = T
    public typealias Generator = GeneratorOf<Element>


    // TODO: Add access qualifiers pending their addition to Swift.
    public let capacity: Int
    private var writePointer: Int = 0
    private var readPointer: Int  = 0
    private var elements: [Element]


    /// Default initializer -- inits the QRingBuffer with a capacity of 256.
    public convenience init() {
        self.init(capacity: 1024)
    }


    /// Initializes the QRingBuffer with the given capacity. Does not initialize
    /// the contents of the QRingBuffer with any default value.
    ///
    /// The maximum capacity of a QRingBuffer is currently Int.max/2.
    /// Capacities < 0 are an error.
    public init(capacity cap: Int) {
        assert(cap > 0, "Capacity may not be <= 0")
        assert(cap <= Int.max/2, "Capacity must be <= Int.max/2")

        capacity = cap
        elements = []
        elements.reserveCapacity(capacity)
    }


    /// Initializes the QRingBuffer with the given capacity and fills the buffer
    /// with initValue as a default.
    ///
    /// The maximum capacity of a QRingBuffer is currently Int.max/2.
    /// Capacities < 0 are an error.
    public init(capacity cap: Int, initValue: Element) {
        assert(cap > 0, "Capacity may not be <= 0")
        assert(cap <= Int.max/2, "Capacity must be <= Int.max/2")

        capacity = cap
        elements = [Element](count: capacity, repeatedValue: initValue)
    }


    /// Puts an object in the QRingBuffer, if there's space available. If the
    /// buffer is maxed out (i.e., the buffer's read pointer needs to be
    /// advanced), then this method will return false. Otherwise, if the object
    /// is placed in the buffer, it returns true.
    public func put(item: Element) -> Bool {
        assert(
            readPointer <= writePointer,
            "Invalid QRingBuffer state: readPointer > writePointer"
        )

        let delta = writePointer - readPointer

        if writePointer == Int.max {
            // Leave room to rewind
            readPointer = capacity + (readPointer % capacity)
            writePointer = readPointer + delta

            assert(
                writePointer < Int.max,
                "Cannot grow the QRingBuffer any further or reset the access pointers."
            )
        } else if delta == capacity {
            // Write pointer would overwrite unread objects.
            return false
        }

        if (elements.count == capacity) {
            let index = writePointer % capacity
            elements[index] = item
        } else {
            elements.append(item)
        }

        ++writePointer

        return true
    }


    /// Discards any data currently in the QRingBuffer and resets both the read
    /// and write pointers for the object.
    public func discardObjects() {
        writePointer = 0
        readPointer = 0
        elements.removeAll(keepCapacity: true)
    }


    /// Reads an object from the QRingBuffer, if there's one available. Returns
    /// nil if no object is in the buffer.
    public func get() -> Element? {
        let next = peek()
        if readPointer < writePointer {
            ++readPointer
        }
        return next
    }


    /// Gets the next object in the QRingBuffer without advancing the read
    /// pointer.
    public func peek() -> Element? {
        assert(
            readPointer <= writePointer,
            "Invalid QRingBuffer state: readPointer > writePointer"
        )

        if readPointer == writePointer {
            return nil
        }

        let index = readPointer % capacity
        assert(
            index < elements.count,
            "Read head has exceeded the size of the underlying array"
        )
        return elements[index]
    }


    /// Gets whether or not the buffer can be rewound. If true, calls to
    /// rewind() will succeed.
    public var canRewind: Bool {
        return self.count < capacity && readPointer > 0
    }


    /// Rewinds the read pointer by one element. If the buffer could be rewound,
    /// this method returns true. Otherwise, it returns false, and the read
    /// pointer was not rewound.
    public func rewind() -> Bool {
        if canRewind {
            --readPointer
            return true
        }
        return false
    }


    /// Gets the number of unread objects currently in the QRingBuffer.
    public var count: Int {
        return writePointer - readPointer
    }


    /// Gets whether or not the buffer is empty (i.e., get() will fail if true).
    public var isEmpty: Bool {
        return writePointer == readPointer
    }


    /// Gets whether or not the buffer is full (i.e., put() will fail if true).
    public var isFull: Bool {
        return count == capacity
    }


    /// Returns a Generator that yields all objects available in the buffer.
    /// Using this Generator advances the QRingBuffer's read pointer.
    public func generate() -> Generator {
        return Generator() { self.get() }
    }

}
