//
//  ConcurrentKVO.swift
//  

import Foundation

public class ConcurrentKVO<T> {

    public var value: T {
        get {
            // NSObject's KVO implementation calls the public getter to preserve the before and after values.
            // Don’t try to re-enter the queue if we are already inside a barrier/write operation.
            if let value = Thread.current.threadDictionary[keyThreadDictionary] as? T {
                return value
            } else {
                return queue.sync { () -> T in
                    return _value
                }
            }
        }

        set {
            let workItem = DispatchWorkItem(flags: .barrier) {
                Thread.current.threadDictionary[self.keyThreadDictionary] = self._value
                self.object.willChangeValue(forKey: self.keyKVO)

                self._value = newValue

                Thread.current.threadDictionary[self.keyThreadDictionary] = self._value
                self.object.didChangeValue(forKey: self.keyKVO)

                Thread.current.threadDictionary.removeObject(forKey: self.keyThreadDictionary)
            }

            if setSynchronously {
                queue.sync(execute: workItem)
            } else {
                queue.async(execute: workItem)
            }
        }
    }

    public init(_ value: T, object: NSObject, key keyKVO: String, setSynchronously: Bool = false) {
        self._value = value
        self.object = object
        self.keyKVO = keyKVO
        self.setSynchronously = setSynchronously
        self.queue = DispatchQueue(label: "ConcurrentKVO queue for \(keyKVO) (\(keyThreadDictionary)", attributes: .concurrent)
    }

    private var _value: T
    private unowned let object: NSObject
    private let keyKVO: String
    private let setSynchronously: Bool
    private let queue: DispatchQueue
    private let keyThreadDictionary = UUID().uuidString

}
