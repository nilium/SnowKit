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


    func fillTestBuffer() {
        XCTAssertTrue(buffer.isEmpty, "buffer.isEmpty should be true")

        for i in 0 ..< 16 {
            XCTAssertFalse(buffer.isFull, "buffer.isFull should be false")
            let success = buffer.put(i)
            XCTAssertFalse(buffer.isEmpty, "buffer.isEmpty should be false")

            XCTAssert(
                success,
                "buffer.put(\(i)) must succeed for the first 16 values"
            )
        }

        XCTAssertTrue(buffer.isFull, "buffer.isFull should be true")
        XCTAssertFalse(buffer.put(16), "buffer.put(16) must fail when buffer.isFull")
    }


    func testRingBufferMax() {
        XCTAssertEqual(
            buffer.capacity, testedCapacity,
            "Capacity is as initialized (\(testedCapacity))"
        )

        XCTAssertTrue(buffer.isEmpty, "buffer.isEmpty should be true")
        XCTAssertFalse(buffer.isFull, "buffer.isFull should be false")

        XCTAssertFalse(
            buffer.get(),
            "buffer.get() returns nil (is empty) on init"
        )

        var count = 0
        while buffer.put(count) {
            ++count
        }

        XCTAssertEqual(
            buffer.capacity, count,
            "buffer.capacity should be the same as manual count (\(count))"
        )

        XCTAssertEqual(
            buffer.count, count,
            "buffer.count is the same as manual count (\(count))"
        )

        let expected = [Int]((0 ..< 16).generate())
        XCTAssertTrue(
            equal(expected, buffer),
            "Buffer has expected contents"
        )

        XCTAssertTrue(
            equal(expected, buffer),
            "Buffer contents survive a generator loop (i.e., looping over " +
            "its contents is not taking the contents out of the buffer)"
        )

        buffer.discardObjects()
        XCTAssertEqual(
            buffer.count, 0,
            "buffer.discardObjects() makes the buffer empty"
        )
    }


    func testRingBufferContents() {
        // TODO: Break this test up into something more.. sane.
        fillTestBuffer()

        XCTAssertTrue(
            equal(0 ..< 16, buffer),
            "Buffer contents are as expected for first 16 elements"
        )

        for expected in 0 ..< 8 {
            let yielded = buffer.get()
            println("Got \(yielded)")

            XCTAssertTrue(
                yielded?,
                "buffer.get() must yield a non-nil value when there are still " +
                "\(buffer.count) elements in it"
            )

            XCTAssertEqual(
                yielded!, expected,
                "buffer.get() must yield the expected elements in order"
            )
        }

        for i in 16 ..< 24 {
            XCTAssertTrue(
                buffer.put(i),
                "buffer.put(\(i)) must pass when the buffer is not at capacity " +
                "(count: \(buffer.count); capacity: \(buffer.capacity))"
            )
        }

        XCTAssertEqual(
            buffer.count, 16,
            "buffer.count should be 16 after adding 8 elements"
        )

        XCTAssertTrue(buffer.isFull, "buffer.isFull should be true")

        XCTAssertFalse(
            buffer.put(24),
            "buffer.put(24) must fail when at capacity (given capacity: 16)"
        )

        var i = 8
        var count = 15
        while let x = <-buffer {
            XCTAssertEqual(
                buffer.count, count,
                "buffer.count should be \(count)"
            )
            XCTAssertEqual(
                x, i,
                "<-buffer result should be \(i)"
            )
            ++i
            --count
        }

        XCTAssertFalse(
            <-buffer,
            "<-buffer should yield nil"
        )
    }


    func testRewind() {
        fillTestBuffer()

        let x = buffer.get()
        let y = buffer.get()
        let z = buffer.get()

        XCTAssertTrue(x?, "x = buffer.get() is not nil")
        XCTAssertTrue(y?, "y = buffer.get() is not nil")
        XCTAssertTrue(z?, "z = buffer.get() is not nil")

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
        XCTAssertTrue(buffer.isEmpty, "buffer.isEmpty should be true initially")

        var total = 0
        while buffer <- total { ++total }
        XCTAssertTrue(buffer.isFull, "buffer.isFull should be true after buffer<-E returns false")
        XCTAssertFalse(buffer <- total, "buffer <- total should return false when buffer.isFull")

        var readTotal = 0
        while let read = <-buffer {
            XCTAssertEqual(read, readTotal, "<-buffer should return the values put in its buffer, in order")
            ++readTotal
        }

        XCTAssertEqual(total, readTotal, "The number of items added and read should be equal")
        XCTAssertTrue(buffer.isEmpty, "buffer.isEmpty should be true after reading all elements in the queue")
        XCTAssertFalse(<-buffer, "<-buffer should be nil after reading all elements in the queue")
    }

}
