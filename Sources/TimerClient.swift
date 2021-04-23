//
//  TimerClient.swift
//  CityCaptor
//
//  Created by Alex Culeva on 17/11/2020.
//

import Foundation
import ComposableArchitecture

public struct TimerClient {
    public let timer: (TimeInterval) -> Effect<Void, Never>

    public init(timer: @escaping (TimeInterval) -> Effect<Void, Never>) {
        self.timer = timer
    }
}

public extension TimerClient {
    static let live = Self(
        timer: { interval in
            Timer.publish(every: interval, on: .current, in: .default)
                .autoconnect()
                .map { _ in }
                .eraseToEffect()
        }
    )
}
