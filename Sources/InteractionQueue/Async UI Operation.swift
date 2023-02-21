//
//  Async UI Operation.swift
//

import Foundation
import AsyncOperation

public class AsyncUIOperation: AsyncBlockOperation {

    public override func main() {
        OperationQueue.main.addOperation(withDelay: .seconds(0.25)) {
            super.main()
        }
    }

}


public extension OperationQueue {

    func addOperation(withDelay delay: OperationQueue.SchedulerTimeType.Stride, _ block: @escaping () -> Void) {
        self.schedule(after: self.now.advanced(by: delay), block)
    }

}
