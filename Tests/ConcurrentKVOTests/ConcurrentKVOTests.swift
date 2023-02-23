//
//  ConcurrentKVOTests.swift
//  


import XCTest
@testable import ConcurrentKVO

final class ConcurrentKVOTests: XCTestCase {

    func testUniqueThreadDictionaryKeys() throws {

        class ReentrantObserver: NSObject {
            @objc var observed1 = MyObjectToObserve(setSynchronously: true)
            @objc var observed2 = MyObjectToObserve(setSynchronously: true)

            var observation1: NSKeyValueObservation?
            var observation2: NSKeyValueObservation?
            var reentrant_value1: Int = 0

            override init() {
                super.init()

                observation1 = observe( \.observed1.value, options: [.old, .new] ) { object, change in
                    NSLog("Value of object 1 changed from %d to %d", (change.oldValue!), (change.newValue!))
                }

                observation2 = observe( \.observed2.value, options: [.old, .new] ) { object, change in
                    NSLog("Value of object 2 changed from %d to %d", (change.oldValue!), (change.newValue!))
                    self.reentrant_value1 = self.observed1.value
                }

            }

            deinit {
                print("MyObserver is deiniting!")
            }
        }

        let reentrantObserver = ReentrantObserver()

        let correctValue1 = 100
        reentrantObserver.observed1.value = correctValue1
        reentrantObserver.observed2.value = 2 * correctValue1

        XCTAssertEqual(reentrantObserver.observed1.value, correctValue1, "observed1 read externally is \(reentrantObserver.observed1.value) but should be \(correctValue1)")
        XCTAssertEqual(reentrantObserver.reentrant_value1, correctValue1, "observed1 read re-entrantly is \(reentrantObserver.reentrant_value1) but should be \(correctValue1)")
    }

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
