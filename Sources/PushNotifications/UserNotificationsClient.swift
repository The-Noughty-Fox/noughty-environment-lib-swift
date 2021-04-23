import Combine
import ComposableArchitecture
import UserNotifications

public struct UserNotificationClient {
    public var add: (UNNotificationRequest) -> Effect<Void, Error>
    public var delegate: Effect<DelegateEvent, Never>
    public var getNotificationSettings: Effect<Notification.Settings, Never>
    public var removeDeliveredNotificationsWithIdentifiers: ([String]) -> Effect<Never, Never>
    public var removePendingNotificationRequestsWithIdentifiers: ([String]) -> Effect<Never, Never>
    public var requestAuthorization: (UNAuthorizationOptions) -> Effect<Bool, Error>

    public enum DelegateEvent: Equatable {
        case didReceiveResponse(Notification.Response, completionHandler: () -> Void)
        case openSettingsForNotification(Notification?)
        case willPresentNotification(
                Notification, completionHandler: (UNNotificationPresentationOptions) -> Void)

        public static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case let (.didReceiveResponse(lhs, _), .didReceiveResponse(rhs, _)):
                return lhs == rhs
            case let (.openSettingsForNotification(lhs), .openSettingsForNotification(rhs)):
                return lhs == rhs
            case let (.willPresentNotification(lhs, _), .willPresentNotification(rhs, _)):
                return lhs == rhs
            default:
                return false
            }
        }
    }

    public struct Notification: Equatable {
        public var date: Date
        public var request: UNNotificationRequest

        public init(
            date: Date,
            request: UNNotificationRequest
        ) {
            self.date = date
            self.request = request
        }

        public struct Response: Equatable {
            public var notification: Notification

            public init(notification: Notification) {
                self.notification = notification
            }
        }

        // TODO: should this be nested in UserNotificationClient instead of Notification?
        public struct Settings: Equatable {
            public var authorizationStatus: UNAuthorizationStatus

            public init(authorizationStatus: UNAuthorizationStatus) {
                self.authorizationStatus = authorizationStatus
            }
        }
    }
}

extension UserNotificationClient {
    public static let live = Self(
        add: { request in
            .future { callback in
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        callback(.failure(error))
                    } else {
                        callback(.success(()))
                    }
                }
            }
        },
        delegate:
            Effect
            .run { subscriber in
                var delegate: Optional = Delegate(subscriber: subscriber)
                UNUserNotificationCenter.current().delegate = delegate
                return AnyCancellable {
                    delegate = nil
                }
            }
            .share()
            .eraseToEffect(),
        getNotificationSettings: .future { callback in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                callback(.success(.init(rawValue: settings)))
            }
        },
        removeDeliveredNotificationsWithIdentifiers: { identifiers in
            .fireAndForget {
                UNUserNotificationCenter.current()
                    .removeDeliveredNotifications(withIdentifiers: identifiers)
            }
        },
        removePendingNotificationRequestsWithIdentifiers: { identifiers in
            .fireAndForget {
                UNUserNotificationCenter.current()
                    .removePendingNotificationRequests(withIdentifiers: identifiers)
            }
        },
        requestAuthorization: { options in
            .future { callback in
                UNUserNotificationCenter.current()
                    .requestAuthorization(options: options) { granted, error in
                        if let error = error {
                            callback(.failure(error))
                        } else {
                            callback(.success(granted))
                        }
                    }
            }
        }
    )
}

extension UserNotificationClient.Notification {
    public init(rawValue: UNNotification) {
        self.date = rawValue.date
        self.request = rawValue.request
    }
}

extension UserNotificationClient.Notification.Response {
    public init(rawValue: UNNotificationResponse) {
        self.notification = .init(rawValue: rawValue.notification)
    }
}

extension UserNotificationClient.Notification.Settings {
    public init(rawValue: UNNotificationSettings) {
        self.authorizationStatus = rawValue.authorizationStatus
    }
}

extension UserNotificationClient {
    fileprivate class Delegate: NSObject, UNUserNotificationCenterDelegate {
        let subscriber: Effect<UserNotificationClient.DelegateEvent, Never>.Subscriber

        init(subscriber: Effect<UserNotificationClient.DelegateEvent, Never>.Subscriber) {
            self.subscriber = subscriber
        }

        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            didReceive response: UNNotificationResponse,
            withCompletionHandler completionHandler: @escaping () -> Void
        ) {
            self.subscriber.send(
                .didReceiveResponse(.init(rawValue: response), completionHandler: completionHandler)
            )
        }

        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            openSettingsFor notification: UNNotification?
        ) {
            self.subscriber.send(
                .openSettingsForNotification(notification.map(Notification.init(rawValue:)))
            )
        }

        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            willPresent notification: UNNotification,
            withCompletionHandler completionHandler:
                @escaping (UNNotificationPresentationOptions) -> Void
        ) {
            self.subscriber.send(
                .willPresentNotification(
                    .init(rawValue: notification),
                    completionHandler: completionHandler
                )
            )
        }
    }
}

extension UserNotificationClient {
    public static let noop = Self(
        add: { _ in .none },
        delegate: .none,
        getNotificationSettings: .none,
        removeDeliveredNotificationsWithIdentifiers: { _ in .none },
        removePendingNotificationRequestsWithIdentifiers: { _ in .none },
        requestAuthorization: { _ in .none }
    )
}

