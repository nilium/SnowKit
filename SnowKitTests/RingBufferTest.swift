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

        let x = <-buffer
        let y = <-buffer
        let z = <-buffer

        XCTAssertTrue(x?, "x = <-buffer is not nil")
        XCTAssertTrue(y?, "x = <-buffer is not nil")
        XCTAssertTrue(z?, "x = <-buffer is not nil")

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

}
