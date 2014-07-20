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
protocol FixedWriteQueue {
    typealias Element
    func put(element: Element) -> Bool
    var isFull: Bool { get }
}


/// Protocol to describe a read-able queue (or queue-like) that has a fixed
/// capacity. Must implement a get() that returns items in the queue or nil if
/// the isEmpty property returns true.
protocol FixedReadQueue {
    typealias Element
    func get() -> Element?
    var isEmpty: Bool { get }
}


/// Combined FixedWriteQueue and FixedReadQueue protocol.
protocol FixedReadWriteQueue: FixedWriteQueue, FixedReadQueue {}


/// A basic ring buffer of objects of type T with independent read/write heads.
/// Conforms to FixedReadWriteQueue.
class RingBuffer<T>: Sequence, FixedReadWriteQueue {

    typealias Element = T
    typealias GeneratorType = GeneratorOf<Element>


    // TODO: Add access qualifiers pending their addition to Swift.
    /* public */  let capacity: Int
    /* private */ var writePointer: Int = 0
    /* private */ var readPointer: Int  = 0
    /* private */ var elements: [Element]


    /// Default initializer -- inits the RingBuffer with a capacity of 256.
    convenience init() {
        self.init(capacity: 1024)
    }


    /// Initializes the RingBuffer with the given capacity. Does not initialize
    /// the contents of the RingBuffer with any default value.
    ///
    /// The maximum capacity of a RingBuffer is currently Int.max/2.
    /// Capacities < 0 are an error.
    init(capacity cap: Int) {
        assert(cap > 0, "Capacity may not be <= 0")
        assert(cap <= Int.max/2, "Capacity must be <= Int.max/2")

        capacity = cap
        elements = []
        elements.reserveCapacity(capacity)
    }


    /// Initializes the RingBuffer with the given capacity and fills the buffer
    /// with initValue as a default.
    ///
    /// The maximum capacity of a RingBuffer is currently Int.max/2.
    /// Capacities < 0 are an error.
    init(capacity cap: Int, initValue: Element) {
        assert(cap > 0, "Capacity may not be <= 0")
        assert(cap <= Int.max/2, "Capacity must be <= Int.max/2")

        capacity = cap
        elements = [Element](count: capacity, repeatedValue: initValue)
    }


    /// Puts an object in the RingBuffer, if there's space available. If the
    /// buffer is maxed out (i.e., the buffer's read pointer needs to be
    /// advanced), then this method will return false. Otherwise, if the object
    /// is placed in the buffer, it returns true.
    func put(item: Element) -> Bool {
        assert(
            readPointer <= writePointer,
            "Invalid RingBuffer state: readPointer > writePointer"
        )

        let delta = writePointer - readPointer

        if writePointer == Int.max {
            // Leave room to rewind
            readPointer = capacity + (readPointer % capacity)
            writePointer = readPointer + delta

            assert(
                writePointer < Int.max,
                "Cannot grow the RingBuffer any further or reset the access pointers."
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


    /// Discards any data currently in the RingBuffer and resets both the read
    /// and write pointers for the object.
    func discardObjects() {
        writePointer = 0
        readPointer = 0
        elements.removeAll(keepCapacity: true)
    }


    /// Reads an object from the RingBuffer, if there's one available. Returns
    /// nil if no object is in the buffer.
    func get() -> Element? {
        let next = peek()
        if readPointer < writePointer {
            ++readPointer
        }
        return next
    }


    /// Gets the next object in the RingBuffer without advancing the read
    /// pointer.
    func peek() -> Element? {
        assert(
            readPointer <= writePointer,
            "Invalid RingBuffer state: readPointer > writePointer"
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
    var canRewind: Bool {
        return self.count < capacity && readPointer > 0
    }


    /// Rewinds the read pointer by one element. If the buffer could be rewound,
    /// this method returns true. Otherwise, it returns false, and the read
    /// pointer was not rewound.
    func rewind() -> Bool {
        if canRewind {
            --readPointer
            return true
        }
        return false
    }


    /// Gets the number of unread objects currently in the RingBuffer.
    var count: Int {
        return writePointer - readPointer
    }


    /// Gets whether or not the buffer is empty (i.e., get() will fail if true).
    var isEmpty: Bool {
        return writePointer == readPointer
    }


    /// Gets whether or not the buffer is full (i.e., put() will fail if true).
    var isFull: Bool {
        return count == capacity
    }


    /// Returns a Generator that yields all objects available in the buffer.
    /// Using this Generator advances the RingBuffer's read pointer.
    func generate() -> GeneratorType {
        return GeneratorType() { self.get() }
    }

}


operator infix <- { associativity left }
operator prefix <- {}


/// Gets a value from the RingBuffer and returns it, if there is one.
@prefix func <- <T>(buffer: RingBuffer<T>) -> T? {
    return buffer.get()
}


/// Stores a value in the RingBuffer if there's space. Returns true if
/// successful, otherwise false.
@infix func <- <T>(buffer: RingBuffer<T>, value: T) -> Bool {
    return buffer.put(value)
}
