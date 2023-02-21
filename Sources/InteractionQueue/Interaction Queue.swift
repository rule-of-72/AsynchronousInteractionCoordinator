//
//  Interaction Queue.swift
//

import Foundation
import AsyncOperation

public class InteractionQueue {

    public typealias MarkInteractionFinished = AsyncBlockOperation.FinishCallback
    public typealias Block = AsyncBlockOperation.Block

    public init() { }

    public func onViewDidAppear() {
        viewDoesAppear = true
        if asyncUIQueue.isSuspended {
            OperationQueue.main.addOperation(withDelay: .seconds(0.5)) { [weak self] in
                guard let self = self else { return }

                if self.viewDoesAppear {
                    self.asyncUIQueue.isSuspended = false
                }
            }
        }
    }

    public func onViewWillDisappear() {
        asyncUIQueue.isSuspended = true
        viewDoesAppear = false
    }

    public func add(_ block: @escaping Block) {
        let asyncUIOperation = AsyncUIOperation(block: block)
        self.asyncUIQueue.addOperation(asyncUIOperation)
    }

    private let asyncUIQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "UI Interaction queue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
        queue.isSuspended = true
        return queue
    } ()

    private var viewDoesAppear: Bool = false

}
