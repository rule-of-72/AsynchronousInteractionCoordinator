//
//  Async Operation.swift
//

import Foundation
import ConcurrentKVO

open class AsyncOperation: Operation {

    public func finish() {
        isExecuting = false
        isFinished = true
    }

    public override func start() {
        guard !isExecuting else {
            NSException(name: .invalidArgumentException, reason: "Operation is already executing", userInfo: nil)
                .raise()

            return
        }

        guard !isFinished else {
            return
        }

        guard !isCancelled else {
            finish()
            return
        }

        isExecuting = true
        main()
    }

    public override var isAsynchronous: Bool {
        return true
    }

    // Should init with "super.isFinished" but can't due to SR-9795.
    // See: https://github.com/apple/swift/issues/52220
    private lazy var _finished = KVOCompliantValue(false, object: self, key: #keyPath(isFinished))
    public override private(set) var isFinished: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }

            return _finished.value
        }

        set {
            lock.lock()
            defer { lock.unlock() }

            _finished.value = newValue
        }
    }

    private lazy var _executing = KVOCompliantValue(false, object: self, key: #keyPath(isExecuting))
    public override private(set) var isExecuting: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }

            return _executing.value
        }

        set {
            lock.lock()
            defer { lock.unlock() }

            _executing.value = newValue
        }
    }

    private let lock = NSRecursiveLock()

}
