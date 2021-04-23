//
//  RemoteNotificationsClient.swift
//  CityCaptor
//
//  Created by Alex Culeva on 18.04.2021.
//

import ComposableArchitecture

public struct RemoteNotificationsClient {
    public var isRegistered: () -> Bool
    public var register: () -> Effect<Never, Never>
    public var unregister: () -> Effect<Never, Never>
}

extension RemoteNotificationsClient {
    public static let noop = Self(
        isRegistered: { true },
        register: { .none },
        unregister: { .none }
    )
}

import UIKit

extension RemoteNotificationsClient {
    public static let live = Self(
        isRegistered: { UIApplication.shared.isRegisteredForRemoteNotifications },
        register: {
            .fireAndForget {
                UIApplication.shared.registerForRemoteNotifications()
            }
        },
        unregister: {
            .fireAndForget {
                UIApplication.shared.unregisterForRemoteNotifications()
            }
        }
    )
}
