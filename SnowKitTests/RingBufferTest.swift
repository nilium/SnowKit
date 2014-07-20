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


    func testRingBufferMax() {
        XCTAssertEqual(
            buffer.capacity, testedCapacity,
            "Capacity is as initialized (\(testedCapacity))"
        )

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
        for i in 0 ..< 16 {
            let success = buffer.put(i)

            XCTAssert(
                success,
                "buffer.put(i) must succeed for the first 16 values"
            )
        }

        XCTAssertFalse(
            buffer.put(16),
            "buffer.put(16) must fail when it's at capacity"
        )

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

}
