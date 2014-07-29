//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Foundation


public protocol QObserver {
    /// Disconnects self and returns whether the observer was successfully
    /// disconnected.
    ///
    /// :To Conform:
    /// - If successfully disconnected, the observer's isConencted property
    ///   must return false. Subsequent disconnect() calls must be no-ops and
    ///   return false.
    mutating func disconnect() -> Bool

    var isConnected: Bool { get }
}


/// Disconnects a single observer, returning whether the observer was
/// successfully disconnected.
public func disconnectObserver<T: QObserver>(inout observer: T) -> Bool {
    return observer.disconnect()
}


/// Disconnects an array of observers, filtering out any disconnected observers.
public func disconnectObservers<T: QObserver>(inout observers: [T]) {
    observers = observers.filter { (var o) in
        o.isConnected && !o.disconnect()
    }
}
