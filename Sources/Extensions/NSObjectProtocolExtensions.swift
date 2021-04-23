//
//  NSObjectProtocolExtensions.swift
//  CityCaptor
//
//  Created by Alex Culeva on 31/10/2020.
//

import Foundation

public extension NSObjectProtocol {
    func set<T>(_ keyPath: WritableKeyPath<Self, T>, _ value: T) -> Self {
        var melf = self
        melf[keyPath: keyPath] = value

        return self
    }
}
