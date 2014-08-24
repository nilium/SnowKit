//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Foundation


/// Zips two sequences together and returns the result as an array tuples
/// containing (lhs.Type, rhs.Type). E.g., given a [String] and [Int], the
/// result is [(String, Int)]. The resulting array is only as long as the
/// smallest input sequence (so if lhs is 50 elements and rhs is 25 elements,
/// the result only contains a zipped array of the first 25 elements of each).
public func zip<
    Sx: SequenceType, Sy: SequenceType, T, U
    where T == Sx.Generator.Element, U == Sy.Generator.Element
    >(lhs: Sx, rhs: Sy) -> [(T, U)]
{
    typealias ResultItem = (T, U)
    var result = [ResultItem]()
    var lGen = lhs.generate()
    var rGen = rhs.generate()

    for ;; {
        let lm = lGen.next()
        let rm = rGen.next()

        if lm != nil && rm != nil {
            result.append((lm!, rm!))
        } else {
            return result
        }
    }
}
