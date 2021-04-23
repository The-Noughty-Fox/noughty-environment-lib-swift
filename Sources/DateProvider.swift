//
//  DateProvider.swift
//  CityCaptor
//
//  Created by Alex Culeva on 17.03.2021.
//

import Foundation

public struct DateProvider {
    public let current: () -> Date

    public init(current: @escaping () -> Date) {
        self.current = current
    }
}

public extension DateProvider {
    static let live = DateProvider(
        current: Date.init
    )
}
