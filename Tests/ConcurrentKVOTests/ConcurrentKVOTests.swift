//
//  ConcurrentKVOTests.swift
//  


import XCTest
@testable import ConcurrentKVO

final class ConcurrentKVOTests: XCTestCase {

    func testConcurrentKVO_AsyncSet() throws {
        let observed = MyObjectToObserve(setSynchronously: false)
        try testWorker(observed)
        XCTAssertTrue(true)
    }

    func testConcurrentKVO_SynchronousSet() throws {
        let observed = MyObjectToObserve(setSynchronously: true)
        try testWorker(observed)
        XCTAssertTrue(true)
    }

    private func testWorker(_ observed: MyObjectToObserve) throws {
        print("Starting value: \(observed.value)")

        let observer = MyObserver(object: observed)

        let cores = ProcessInfo.processInfo.activeProcessorCount

        let concurrentQueue = OperationQueue()
        concurrentQueue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
        concurrentQueue.name = "Test case concurrent queue"
        concurrentQueue.isSuspended = true

        for i in 1 ... (5 * cores) {
            concurrentQueue.addOperation {
                observed.value = i
            }
        }

        concurrentQueue.isSuspended = false
        concurrentQueue.waitUntilAllOperationsAreFinished()
        concurrentQueue.addOperation {
            print("Final value: \(observed.value)")
        }
        concurrentQueue.waitUntilAllOperationsAreFinished()

        Thread.sleep(forTimeInterval: 0.1)

        // Force observer not to deinit until we get here.
        observer.foo()
    }

    private class MyObjectToObserve: NSObject {
        init(setSynchronously: Bool) {
            self.setSynchronously = setSynchronously
        }

        @objc var value: Int {
            get {
                return _value.value
            }

            set {
                _value.value = newValue
            }
        }

        private let setSynchronously: Bool
        private lazy var _value = ConcurrentKVO<Int>(0, object: self, key: #keyPath(value), setSynchronously: setSynchronously)
    }

    private class MyObserver: NSObject {
        @objc var objectToObserve: MyObjectToObserve
        var observation: NSKeyValueObservation?

        init(object: MyObjectToObserve) {
            objectToObserve = object
            super.init()

            observation = observe(
                \.objectToObserve.value,
                 options: [.old, .new]
            ) { object, change in
                NSLog("Value changed from %d to %d", (change.oldValue!), (change.newValue!))
            }
        }

        deinit {
            print("MyObserver is deiniting!")
        }

        func foo() {

        }
    }

}
