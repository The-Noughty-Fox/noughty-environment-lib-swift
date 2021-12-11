//
//  Notifications+ComposableArchitecture.swift
//  NoughtyEnvironment
//
//  Created by Alex Culeva on 25.04.2021.
//


import UserNotifications
import CasePaths
import Combine
import CombineExt
//appDidBecomeActive -> getSettings -> |authorized    -> register
//                                     |notDetermined
//actuallyRequest    -> getSettings -> |authorized    -> register
//                                     |notDetermined -> requestAuthorization -> |true -> register
//                                                                               |false

@dynamicMemberLookup
public class NotificationsService {
    public struct NotificationsEnvironment {
        public let userNotifications: () -> UserNotificationClient
        public let remoteNotifications: () -> RemoteNotificationsClient
        public let registerToken: (String?) -> AnyPublisher<Void, Error>

        public init(
            userNotifications: @escaping () -> UserNotificationClient,
            remoteNotifications: @escaping () -> RemoteNotificationsClient,
            registerToken: @escaping (String?) -> AnyPublisher<Void, Error>
        ) {
            self.userNotifications = userNotifications
            self.remoteNotifications = remoteNotifications
            self.registerToken = registerToken
        }
    }

    let environment: NotificationsEnvironment

    public subscript<T>(dynamicMember keyPath: KeyPath<RemoteNotificationsClient, T>) -> T {
        environment.remoteNotifications()[keyPath: keyPath]
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<UserNotificationClient, T>) -> T {
        environment.userNotifications()[keyPath: keyPath]
    }

    public init(environment: NotificationsEnvironment) {
        self.environment = environment

        // connect delegate methods

    }

    public func check() -> AnyPublisher<UNAuthorizationStatus, Never> {
        environment.userNotifications().getNotificationSettings.map(\.authorizationStatus).eraseToAnyPublisher()
    }

    public func requestPermissions() -> AnyPublisher<Bool, Error> {
        check()
            .flatMap { [unowned self] status -> AnyPublisher<Bool, Error> in
                switch status {
                case .notDetermined:
                    return self.environment.userNotifications()
                        .requestAuthorization([.alert, .badge, .sound])
                        .receiveOnMain()
                        .map { [unowned self] in
                            if $0 {
                                self.environment.remoteNotifications().register()
                            }
                            return $0
                        }
                        .eraseToAnyPublisher()
                case .authorized:
                    return Just(true)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                default: // TODO: add provisional case
                    return Just(false)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    public func registerToken(token: String?) -> AnyPublisher<Void, Error> {
        environment.registerToken(token)
    }
}
