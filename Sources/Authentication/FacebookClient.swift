//
//  File.swift
//  
//
//  Created by Lisnic Victor on 21.04.2023.
//

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
    }
}

extension FacebookClient {
    public static let live: Self = {
        typealias Subject = PassthroughSubject<Credentials, Swift.Error>
        let loginManager = LoginManager()

        return .init() { permissions in
            let subject = Subject()

            loginManager.logIn(
                configuration: .init(permissions: permissions, tracking: .limited)) { result in
                    switch result {
                    case .cancelled:
                        subject.send(completion: .failure(Error.cancelled))
                    case .failed(let error):
                        subject.send(completion: .failure(error))
                    case .success(granted: _, declined: _, token: let token):
                        subject.send(.init(token: token?.tokenString ?? ""))
                    }
                }

            return subject.eraseToAnyPublisher()
        } signOut: {
            loginManager.logOut()
        } handleURL: { url in
            loginManager.application(
                UIApplication.shared,
                open: url,
                sourceApplication: nil,
                annotation: [UIApplication.OpenURLOptionsKey.annotation]
            )
        }
    }()
}
