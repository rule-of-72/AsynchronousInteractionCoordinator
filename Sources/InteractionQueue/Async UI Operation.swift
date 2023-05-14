//
//  Async UI Operation.swift
//

import Foundation
import AsyncOperation

public class AsyncUIOperation: AsyncBlockOperation {

    public override func main() {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Timing.delayBetweenItems,
            execute: DispatchWorkItem(block: {
                OperationQueue.main.addOperation {
                    guard !self.isCancelled else {
                        self.finish()
                        return
                    }

                    super.main()
                }
            } )
        )
    }

}


@available(iOS 13.0, *)
public extension OperationQueue {

    func addOperation(withDelay delay: OperationQueue.SchedulerTimeType.Stride, _ block: @escaping () -> Void) {
        self.schedule(after: self.now.advanced(by: delay), block)
    }

}
