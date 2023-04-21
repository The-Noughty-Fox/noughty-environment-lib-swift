//
//  RemoteNotificationsClient.swift
//  CityCaptor
//
//  Created by Alex Culeva on 18.04.2021.
//

public struct RemoteNotificationsClient {
    public var isRegistered: () -> Bool
    public var register: () -> Void
    public var unregister: () -> Void
}

extension RemoteNotificationsClient {
    public static let noop = Self(
        isRegistered: { true },
        register: {  },
        unregister: {  }
    )
}

import UIKit

extension RemoteNotificationsClient {
    public static let live = Self(
        isRegistered: { UIApplication.shared.isRegisteredForRemoteNotifications
        },
        register: {
            UIApplication.shared.registerForRemoteNotifications()
        },
        unregister: {
            UIApplication.shared.unregisterForRemoteNotifications()
        }
    )
}
