import Combine
import UserNotifications
import CombineExt
import ComposableArchitecture

//TODO: Add pending and delivered notifications management
public struct UserNotificationClient {
    public var add: (UNNotificationRequest) -> AnyPublisher<Void, Error>
    public var delegate: AnyPublisher<DelegateEvent, Never>
    public var getNotificationSettings: AnyPublisher<Notification.Settings, Never>
    public var removeDeliveredNotificationsWithIdentifiers: ([String]) -> Void
    public var removePendingNotificationRequestsWithIdentifiers: ([String]) -> Void
    public var requestAuthorization: (UNAuthorizationOptions) -> AnyPublisher<Bool, Error>

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
            Deferred {
                Future { callback in
                    UNUserNotificationCenter.current().add(request) { error in
                        if let error = error {
                            callback(.failure(error))
                        } else {
                            callback(.success(()))
                        }
                    }
                }
            }
            .eraseToAnyPublisher()
        },
        delegate: {
            AnyPublisher.create { subscriber in
                var delegate: Optional = Delegate()
                UNUserNotificationCenter.current().delegate = delegate
                let cancellable = delegate?.subject.sink(receiveCompletion: subscriber.send(completion:), receiveValue: subscriber.send(_:))

                return AnyCancellable {
                    cancellable?.cancel()
                    delegate = nil
                }
            }
        }(),
        getNotificationSettings:
            Deferred {
                Future { callback in
                    UNUserNotificationCenter.current().getNotificationSettings { settings in
                        callback(.success(.init(rawValue: settings)))
                    }
                }
            }
            .eraseToAnyPublisher()
        ,
        removeDeliveredNotificationsWithIdentifiers: { identifiers in
            UNUserNotificationCenter.current()
                .removeDeliveredNotifications(withIdentifiers: identifiers)
        },
        removePendingNotificationRequestsWithIdentifiers: { identifiers in
            UNUserNotificationCenter.current()
                .removePendingNotificationRequests(withIdentifiers: identifiers)
        },
        requestAuthorization: { options in
            Deferred {
                Future { callback in
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
            .eraseToAnyPublisher()
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
        let subject = PassthroughSubject<UserNotificationClient.DelegateEvent, Never>()

        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            didReceive response: UNNotificationResponse,
            withCompletionHandler completionHandler: @escaping () -> Void
        ) {
            subject.send(
                .didReceiveResponse(.init(rawValue: response), completionHandler: completionHandler)
            )
        }

        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            openSettingsFor notification: UNNotification?
        ) {
            subject.send(
                .openSettingsForNotification(notification.map(Notification.init(rawValue:)))
            )
        }

        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            willPresent notification: UNNotification,
            withCompletionHandler completionHandler:
                @escaping (UNNotificationPresentationOptions) -> Void
        ) {
            subject.send(
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
        add: { _ in Empty().eraseToAnyPublisher() },
        delegate: Empty().eraseToAnyPublisher(),
        getNotificationSettings: Empty().eraseToAnyPublisher(),
        removeDeliveredNotificationsWithIdentifiers: { _ in  },
        removePendingNotificationRequestsWithIdentifiers: { _ in },
        requestAuthorization: { _ in Empty().eraseToAnyPublisher() }
    )
}

