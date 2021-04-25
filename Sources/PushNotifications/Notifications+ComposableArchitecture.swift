//
//  Notifications+ComposableArchitecture.swift
//  NoughtyEnvironment
//
//  Created by Alex Culeva on 25.04.2021.
//

import ComposableArchitecture
import UserNotifications

public enum NotificationsAction {
    // call this to trigger status flow
    case check
    // call this to actually request authorization if it's not determined
    case request
    case registered(Bool)
    case authorization(UNAuthorizationStatus)
    case error(Error)
}

public struct NotificationsEnvironment {
    public let userNotifications: () -> UserNotificationClient
    public let remoteNotifications: () -> RemoteNotificationsClient

    public init(
        userNotifications: @escaping () -> UserNotificationClient,
        remoteNotifications: @escaping () -> RemoteNotificationsClient
    ) {
        self.userNotifications = userNotifications
        self.remoteNotifications = remoteNotifications
    }
}

//appDidBecomeActive -> getSettings -> |authorized    -> register
//                                     |notDetermined
//actuallyRequest    -> getSettings -> |authorized    -> register
//                                     |notDetermined -> requestAuthorization -> |true -> register
//                                                                               |false
public let notificationsReducer = Reducer<Void, NotificationsAction, NotificationsEnvironment> { _, action, environment in
    switch action {
    case .check:
        return environment.userNotifications().getNotificationSettings
            .map(\.authorizationStatus)
            .map(NotificationsAction.authorization)
    case .request:
        return environment.userNotifications().getNotificationSettings
            .map(\.authorizationStatus)
            .flatMap { status -> Effect<NotificationsAction, Never> in
                let authorization = Effect<NotificationsAction, Never>(value: .authorization(status))
                switch status {
                case .notDetermined:
                    let request = environment.userNotifications()
                        .requestAuthorization([.alert, .badge, .sound])
                        .map(NotificationsAction.registered)
                        .replaceError(with: .registered(false))
                        .eraseToEffect()
                    return .merge(authorization, request)
                default:
                    return authorization
                }
            }.eraseToEffect()
    case .authorization(.authorized):
        return Effect(value: .registered(true))
    case .registered(true):
        return environment.remoteNotifications().register()
            .subscribe(on: DispatchQueue.main)
            .eraseToEffect()
            .fireAndForget()
    case .registered(false), .authorization:
        return .none
    case .error:
        return .none
    }
}
