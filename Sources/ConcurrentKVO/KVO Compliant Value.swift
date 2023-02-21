//
//  KVO Compliant Value.swift
//

import Foundation

public class KVOCompliantValue<T> {

    private var _value: T
    private unowned let object: NSObject
    private let key: String

    public init(_ value: T, object: NSObject, key: String) {
        _value = value
        self.object = object
        self.key = key
    }

    public var value: T {
        get {
            return _value
        }

        set {
            object.willChangeValue(forKey: key)
            _value = newValue
            object.didChangeValue(forKey: key)
        }
    }
    
}
