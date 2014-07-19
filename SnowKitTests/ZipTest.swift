//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Foundation
import XCTest
import SnowKit


class SKZipTest: XCTestCase {

    let lhsSome = ["Foo", "Bar", "Baz"]
    let lhsNone = [String]()

    let rhsSome = [1, 2, 3, 4, 5]
    let rhsNone = [Int]()

    let lhsEven = ["Foo", "Bar", "Baz", "Quux", "Woop"]
    let rhsEven = [2, 4, 6, 8, 10]

    func testEmptyResults() {
        XCTAssert(
            zip(lhsSome, rhsNone).isEmpty,
            "zip(some, none) is empty"
        )

        XCTAssert(
            zip(lhsNone, rhsSome).isEmpty,
            "zip(none, some) is empty"
        )

        XCTAssert(
            zip(lhsNone, rhsNone).isEmpty,
            "zip(none, none) is empty"
        )
    }


    func testUnevenResults() {
        let unevenResult = [("Foo", 1), ("Bar", 2), ("Baz", 3)]
        let zipped = zip(lhsSome, rhsSome)

        XCTAssert(
            equal(unevenResult, zipped) { r, l in r.0 == l.0 && r.1 == l.1 },
            "uneven zip(some, some) has the same elements as unevenResult"
        )

        XCTAssertEqual(
            zipped.count, unevenResult.count,
            "uneven zip(some, some) has 3 elements"
        )
    }


    func testSameLengthResults() {
        let sameLengthResult = [("Foo", 2), ("Bar", 4), ("Baz", 6), ("Quux", 8), ("Woop", 10)]
        let zipped = zip(lhsEven, rhsEven)

        XCTAssert(
            equal(sameLengthResult, zipped) { r, l in r.0 == l.0 && r.1 == l.1 },
            "same-length zip(some, some) has the same elements as sameLengthResult"
        )
        
        XCTAssertEqual(
            zipped.count, sameLengthResult.count,
            "same-length zip(some, some) has 5 elements"
        )
    }
    
}
