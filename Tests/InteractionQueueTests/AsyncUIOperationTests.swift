//
//  AsyncUIOperationTests.swift
//  

import XCTest
import InteractionQueue

final class AsyncUIOperationTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAsyncUIOperations() {
        let queue = InteractionQueue()
        let expectation = XCTestExpectation(description: "InteractionQueue has completed all operations")

        queue.add { finished in
            defer { expectation.fulfill() }
            defer { finished() }
            XCTAssert(OperationQueue.current === OperationQueue.main)
        }

        queue.onViewDidAppear()

        wait(for: [expectation], timeout: 10.0)
    }

}
