//
//  VoidPath.swift
//  
//
//  Created by Alex Culeva on 25.04.2021.
//

import Foundation
import ComposableArchitecture

public struct VoidPath<Root>: ComposableArchitecture.Path {
    public init() {}

    public func extract(from root: Root) -> Void? { () }
    public func set(into root: inout Root, _ value: Void) {}
}
