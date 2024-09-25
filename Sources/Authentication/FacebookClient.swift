import Foundation
import FacebookLogin
import FacebookCore
import Combine

public struct FacebookClient {
    public let authenticate: ([String]) -> AnyPublisher<Credentials, Swift.Error>
    public let signOut: () -> Void
    public let handleURL: (URL) -> Bool
}

public extension FacebookClient {
    struct Credentials: Equatable, Codable {
        public let token: String
    }

    enum Error: Swift.Error {
        case noResult
        case cancelled
        case noToken
    }
}

extension FacebookClient {
    public static let live: Self = {
        typealias Subject = PassthroughSubject<Credentials, Swift.Error>
        let loginManager = LoginManager()

        return .init() { permissions in
            let subject = Subject()

            loginManager.logIn(
                permissions: permissions,
                from: (UIApplication.shared.connectedScenes.first! as! UIWindowScene).windows.first!.rootViewController
            ) { result, error in
                if let error {
                    subject.send(completion: .failure(error))
                    return
                }

                guard let result else {
                    subject.send(completion: .failure(Error.noResult))
                    return
                }

                if result.isCancelled {
                    subject.send(completion: .failure(Error.cancelled))
                    return
                }

                guard let token = result.token else {
                    subject.send(completion: .failure(Error.noToken))
                    return
                }

                subject.send(.init(token: token.tokenString))
                subject.send(completion: .finished)
            }

            return subject.eraseToAnyPublisher()
        } signOut: {
            loginManager.logOut()
        } handleURL: { url in
            ApplicationDelegate.shared.application(
                UIApplication.shared,
                open: url,
                sourceApplication: nil,
                annotation: [UIApplication.OpenURLOptionsKey.annotation]
            )
        }
    }()
}
