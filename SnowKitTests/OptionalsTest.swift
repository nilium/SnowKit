//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Foundation
import XCTest
import SnowKit


class SKOptionalsTest: XCTestCase {

    enum EnumType { case Defined }
    struct StructType { let x: Int = 5 }
    class ClassType { }

    let definedEnum   = EnumType.Defined
    let definedStruct = StructType()
    let definedClass  = ClassType()

    var enumOpt: EnumType?
    var structOpt: StructType?
    var classOpt: ClassType?

    override func setUp() {
        enumOpt = nil
        structOpt = nil
        classOpt = nil
    }


    func testDefaultNil() {
        XCTAssert(!enumOpt, "enumOpt is nil on setup")
        XCTAssert(!structOpt, "structOpt is nil on setup")
        XCTAssert(!classOpt, "classOpt is nil on setup")
    }


    func testOptionalResolutionOpLiteral() {
        enumOpt = enumOpt ~| .Defined
        XCTAssert(
            enumOpt?,
            "enumOpt is defined after using the optional resolution operator (expression)"
        )

        structOpt = structOpt ~| StructType()
        XCTAssert(
            structOpt?,
            "structOpt is defined after using the optional resolution operator (expression)"
        )

        classOpt = classOpt ~| ClassType()
        XCTAssert(
            classOpt?,
            "classOpt is defined after using the optional resolution operator (expression)"
        )
    }


    func testOptionalResolutionOpDefined() {
        enumOpt = enumOpt ~| definedEnum
        XCTAssert(
            enumOpt?,
            "enumOpt is defined after using the optional resolution operator (defined value)"
        )

        structOpt = structOpt ~| definedStruct
        XCTAssert(
            structOpt?,
            "structOpt is defined after using the optional resolution operator (defined value)"
        )

        classOpt = classOpt ~| definedClass
        XCTAssert(
            classOpt?,
            "classOpt is defined after using the optional resolution operator (defined value)"
        )
    }


    func testOptionalResolutionOpAssignmentLiteral() {
        enumOpt ~|= .Defined
        XCTAssert(
            enumOpt?,
            "enumOpt is defined after using the optional resolution operator (expression)"
        )

        structOpt ~|= StructType()
        XCTAssert(
            structOpt?,
            "structOpt is defined after using the optional resolution operator (expression)"
        )

        classOpt ~|= ClassType()
        XCTAssert(
            classOpt?,
            "classOpt is defined after using the optional resolution operator (expression)"
        )
    }


    func testOptionalResolutionOpAssignmentDefined() {
        enumOpt ~|= definedEnum
        XCTAssert(
            enumOpt?,
            "enumOpt is defined after using the optional resolution operator (defined value)"
        )

        structOpt ~|= definedStruct
        XCTAssert(
            structOpt?,
            "structOpt is defined after using the optional resolution operator (defined value)"
        )

        classOpt ~|= definedClass
        XCTAssert(
            classOpt?,
            "classOpt is defined after using the optional resolution operator (defined value)"
        )
    }

}
