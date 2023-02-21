//
//  Reader-Writer Locked Value.swift
//

import Foundation

public class RWLockedValue<T> {
    
    private let queue = DispatchQueue(label: "RW Lock queue", attributes: .concurrent)

    private var _value: T

    public init(_ value: T) {
        _value = value
    }

    public var value: T {
        get {
            return queue.sync { () -> T in
                return _value
            }
        }

        set {
            queue.async(flags: .barrier) {
                self._value = newValue
            }
        }
    }

}
