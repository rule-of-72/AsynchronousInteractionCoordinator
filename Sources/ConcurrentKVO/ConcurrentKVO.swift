//
//  ConcurrentKVO.swift
//  

import Foundation

public class ConcurrentKVO<T> {

    public var value: T {
        get {
            // NSObject's KVO implementation calls the public getter to preserve the before and after values.
            // Don’t try to re-enter the queue if we are already inside a barrier/write operation.
            if let value = Thread.current.threadDictionary["ConcurrentKVO"] as? T {
                return value
            } else {
                return queue.sync { () -> T in
                    return _value
                }
            }
        }

        set {
            let workItem = DispatchWorkItem(flags: .barrier) {
                Thread.current.threadDictionary["ConcurrentKVO"] = self._value
                self.object.willChangeValue(forKey: self.key)

                self._value = newValue

                Thread.current.threadDictionary["ConcurrentKVO"] = self._value
                self.object.didChangeValue(forKey: self.key)

                Thread.current.threadDictionary.removeObject(forKey: "ConcurrentKVO")
            }

            if setSynchronously {
                queue.sync(execute: workItem)
            } else {
                queue.async(execute: workItem)
            }
        }
    }

    public init(_ value: T, object: NSObject, key: String, setSynchronously: Bool = false) {
        self._value = value
        self.object = object
        self.key = key
        self.setSynchronously = setSynchronously
        self.queue = DispatchQueue(label: "ConcurrentKVO queue for \(key)", attributes: .concurrent)
    }

    private var _value: T
    private unowned let object: NSObject
    private let key: String
    private let setSynchronously: Bool
    private let queue: DispatchQueue

}
