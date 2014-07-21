//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Foundation
import XCTest
import SnowKit


class SKRingBufferTest: XCTestCase {

    let testedCapacity = 16
    var buffer: RingBuffer<Int> = RingBuffer()


    override func setUp() {
        buffer = RingBuffer(capacity: testedCapacity)
        super.setUp()
    }


    func testFillBuffer() {
        XCTAssertTrue(buffer.isEmpty, "buffer.isEmpty should be true")
        XCTAssertNil(buffer.get(), "buffer.get() must return nil when empty")

        for i in 0 ..< 16 {
            XCTAssertLessThanOrEqual(buffer.count, buffer.capacity, "buffer.count <= buffer.capacity")
            XCTAssertFalse(buffer.isFull, "buffer.isFull should be false when count < capacity")
            let success = buffer.put(i)
            XCTAssertFalse(buffer.isEmpty, "buffer.isEmpty should be false when count > 0")

            XCTAssert(
                success,
                "buffer.put(\(i)) must succeed for the first 16 values"
            )
        }

        XCTAssertTrue(buffer.isFull, "buffer.isFull should be true")
        XCTAssertEqual(buffer.count, buffer.capacity, "buffer.count must == buffer.capacity when buffer.isFull is true")
        XCTAssertFalse(buffer.put(16), "buffer.put(16) must fail when buffer.isFull")
    }


    func testInitState() {
        XCTAssertNil(buffer.get(), "buffer.get() must return nil on init")
        XCTAssertFalse(buffer.isFull, "buffer.isFull must return false on init")
        XCTAssertTrue(buffer.isEmpty, "buffer.isEmpty must return true on init")
        XCTAssertEqual(buffer.count, 0, "buffer.count must be 0 on init")
        XCTAssertFalse(buffer.canRewind, "buffer.canRewind must be false on init")
        XCTAssertFalse(buffer.rewind(), "buffer.rewind() must fail on init")
    }


    func testWriteToCapacity() {
        testFillBuffer()
    }


    func testCapacity() {
        XCTAssertEqual(buffer.capacity, testedCapacity, "buffer.capacity should be the requested capacity")
    }


    func testDiscard() {
        testFillBuffer()

        buffer.discardObjects()

        XCTAssertTrue(buffer.elements.isEmpty, "buffer.elements.isEmpty must be true after buffer.discardObjects()")
        XCTAssertTrue(buffer.isEmpty, "buffer.isEmpty must be true after buffer.discardObjects()")
        XCTAssertFalse(buffer.isFull, "buffer.isFull must be false if buffer.isEmpty is true")
        XCTAssertNil(buffer.get(), "buffer.get() must return nil after discard")
    }


    func testRingBufferGeneratorEnum() {
        testFillBuffer()

        var gen = buffer.generate()
        var i = 0
        while let j = gen.next() {
            XCTAssertEqual(i, j, "gen.next() from buffer should be \(i)")
            ++i
        }

        XCTAssertTrue(buffer.isEmpty, "buffer.isEmpty should be true after completely using a generator")
    }


    func testRingBufferGeneratorValues() {
        testFillBuffer()

        XCTAssertTrue(
            equal(0 ..< buffer.count, buffer),
            "Buffer contents are as expected for first 16 elements"
        )

        XCTAssertTrue(buffer.isEmpty, "buffer.isEmpty should be true after completely using a generator")
    }


    func testBufferPartialRead() {
        testFillBuffer()

        for expected in 0 ..< 8 {
            let yielded = buffer.get()
            XCTAssertNotNil(yielded, "buffer.get() should yield a non-nil value")
            XCTAssertEqual(expected, yielded!, "buffer.get() should yield \(expected)")
        }

        XCTAssertFalse(buffer.isEmpty, "buffer.isEmpty must not be true after only a partial read")
    }


    func testBufferPartialReadAndWrite() {
        testBufferPartialRead()

        XCTAssertFalse(buffer.isFull, "buffer.isFull should be true")

        for var x = 16; !buffer.isFull; ++x {
            buffer.put(x)
        }

        XCTAssertEqual(buffer.count, buffer.capacity, "buffer.count should be buffer.capacity")
        XCTAssertTrue(buffer.isFull, "buffer.isFull should be true")
    }


    func testRewind() {
        testFillBuffer()

        let x = buffer.get()
        let y = buffer.get()
        let z = buffer.get()

        XCTAssertNotNil(x?, "x = buffer.get() is not nil")
        XCTAssertNotNil(y?, "y = buffer.get() is not nil")
        XCTAssertNotNil(z?, "z = buffer.get() is not nil")

        XCTAssertTrue(buffer.canRewind, "buffer.canRewind is true")
        XCTAssertTrue(buffer.rewind(), "buffer.rewind() succeeds")
        XCTAssert(z == buffer.peek(), "buffer.peek() returns z after rewind")

        XCTAssertTrue(buffer.canRewind, "buffer.canRewind is true")
        XCTAssertTrue(buffer.rewind(), "buffer.rewind() succeeds")
        XCTAssert(y == buffer.peek(), "buffer.peek() returns y after rewind")

        XCTAssertTrue(buffer.canRewind, "buffer.canRewind is true")
        XCTAssertTrue(buffer.rewind(), "buffer.rewind() succeeds")
        XCTAssert(x == buffer.peek(), "buffer.peek() returns x after rewind")

        XCTAssertFalse(buffer.canRewind, "buffer.canRewind is false")
        XCTAssertFalse(buffer.rewind(), "buffer.rewind() fails")
        XCTAssert(x == buffer.peek(), "buffer.peek() continues to return x")
    }


    // Several functions to test for protocol conformance by relying on generic
    // type constraints.
    func isWriteQueue<T>(q: T) -> Bool { return false }
    func isWriteQueue<T: FixedWriteQueue>(q: T) -> Bool { return true }
    func isReadQueue<T>(q: T) -> Bool { return false }
    func isReadQueue<T: FixedReadQueue>(q: T) -> Bool { return true }
    func isReadWriteQueue<T>(q: T) -> Bool { return false }
    func isReadWriteQueue<T: FixedReadWriteQueue>(q: T) -> Bool { return true }


    func testReadWriteQueueCompliance() {
        // A few assertions to ensure the isRWQueue() functions behave as expected
        let ary = [Int]()
        XCTAssertFalse(isWriteQueue(ary), "An array should not be a fixed write queue")
        XCTAssertFalse(isReadQueue(ary), "An array should not be a fixed read queue")
        XCTAssertFalse(isReadWriteQueue(ary), "An array should not be a fixed read-write queue")

        XCTAssertTrue(isWriteQueue(buffer), "Queue is a fixed write queue")
        XCTAssertTrue(isReadQueue(buffer), "Queue is a fixed read queue")
        XCTAssertTrue(isReadWriteQueue(buffer), "Queue is a fixed read-write queue")
    }


    func testReadWriteQueueOperators() {
        let putLimit = buffer.capacity

        XCTAssertTrue(buffer.isEmpty, "buffer.isEmpty should be true initially")

        var putTotal = 0
        while !buffer.isFull && buffer <- putTotal {
            ++putTotal

            XCTAssertLessThanOrEqual(putTotal, putLimit, "putTotal has exceeded its possible capacity")
        }
        XCTAssertTrue(buffer.isFull, "buffer.isFull should be true after buffer<-E returns false")
        XCTAssertFalse(buffer <- putTotal, "buffer <- total should return false when buffer.isFull")

        var getTotal = 0
        while let read = <-buffer {
            XCTAssertEqual(read, getTotal, "<-buffer should return the values put in its buffer, in order")
            ++getTotal
        }

        XCTAssertEqual(putTotal, getTotal, "The number of items added and read should be equal")
        XCTAssertTrue(buffer.isEmpty, "buffer.isEmpty should be true after reading all elements in the queue")
        XCTAssertNil(<-buffer, "<-buffer should be nil after reading all elements in the queue")
    }

}
