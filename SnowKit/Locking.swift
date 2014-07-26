//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Foundation


public class QSpinLock: NSLocking {

    private var _lock: OSSpinLock = OS_SPINLOCK_INIT

    public func lock() {
        withUnsafePointer(&_lock, OSSpinLockLock)
    }


    public func unlock() {
        withUnsafePointer(&_lock, OSSpinLockUnlock)
    }


    public func tryLock() -> Bool {
        return withUnsafePointer(&_lock, OSSpinLockTry)
    }

}


public func withLock<T>(lock: NSLocking, block: () -> T) -> T {
    lock.lock()
    let result = block()
    lock.unlock()
    return result
}


public func withLock<T>(lock: NSLocking, block: () -> Void) {
    lock.lock()
    block()
    lock.unlock()
}
