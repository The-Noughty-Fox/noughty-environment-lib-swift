//
//  NotificationCenterClient.swift
//  Enclaves
//
//  Created by Alex Culeva on 21.04.2021.
//

import Foundation
import ComposableArchitecture

public struct NotificationCenterClient {
    public let subscribe: (Notification.Name) -> Effect<Notification, Never>
}

public extension NotificationCenterClient {
    static let live: Self = {
        let nc = NotificationCenter.default
        return Self(
            subscribe: { nc.publisher(for: $0).eraseToEffect() }
        )
    }()
}
