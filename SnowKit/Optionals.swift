//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Foundation


/// Optional resolution operator.
operator infix ~| { associativity left precedence 100 }
/// Optional resolution assignment operator.
operator infix ~|= { associativity right precedence 90 }


/// Optional resolution operator -- returns lhs if defined, otherwise the
/// result of the rhs expression.
@infix func ~| <T>(lhs: T?, rhs: @auto_closure () -> T) -> T {
    return (lhs?) ? (lhs!) : (rhs())
}


/// Optional resolution assignment operator -- if lhs is undefined, assigns the
/// result of the rhs expression to it, otherwise does nothing.
@assignment func ~|= <T>(inout lhs: T?, rhs: @auto_closure () -> T) {
    if !lhs {
        lhs = rhs()
    }
}
