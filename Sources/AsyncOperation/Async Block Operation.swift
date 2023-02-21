//
//  Async Block Operation.swift
//

import Foundation

/*
 Usage:

    let operation = AsyncBlockOperation { markOperationAsFinished in
        doSomethingWithEscapingCompletionBlock {
            [weak self] in
            defer { markOperationAsFinished() }
            guard let self = self else { return }

            // Rest of the completion block...
        }
    }
    myOperationQueue.addOperation(operation)

 ALWAYS mark the operation as finished, even if your "self" has disappeared.
 */

open class AsyncBlockOperation: AsyncOperation {

    public typealias FinishCallback = () -> ()
    public typealias Block = (@escaping FinishCallback) -> ()

    private let block: Block

    public init(block: @escaping Block) {
        self.block = block
        super.init()
    }

    open override func main() {
        block { [weak self] in
            self?.finish()
        }
    }

}
