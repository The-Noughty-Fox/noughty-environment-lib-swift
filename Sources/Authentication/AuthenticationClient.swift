//
//  AuthenticationClient.swift
//
//
//  Created by S2dent on 03.06.2021.
//

import Combine
import UIKit

extension AnyPublisher {
    func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            
            cancellable = sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }

                    cancellable?.cancel()
                },
                receiveValue: { value in
                    continuation.resume(returning: value)
                }
            )
        }
    }
}

public struct Authentication<User> {
    public struct Environment {
        public struct API {
            let authenticateWithApple: (AppleClient.APICredentials) async throws -> User
            let authenticateWithGoogle: (GoogleClient.Credentials) async throws -> User
            let authenticateWithFacebook: (FacebookClient.Credentials) async throws -> User

            public init(
                authenticateWithApple: @escaping (AppleClient.APICredentials) async throws -> User,
                authenticateWithGoogle: @escaping (GoogleClient.Credentials) async throws -> User,
                authenticateWithFacebook: @escaping (FacebookClient.Credentials) async throws -> User
            ) {
                self.authenticateWithApple = authenticateWithApple
                self.authenticateWithGoogle = authenticateWithGoogle
                self.authenticateWithFacebook = authenticateWithFacebook
            }
        }
        public let api: () -> API
        public let appleClient: () -> AppleClient
        public let googleClient: () -> GoogleClient
        public let facebookClient: () -> FacebookClient

        public init(
            api: @escaping () -> API,
            appleClient: @escaping () -> AppleClient,
            googleClient: @escaping () -> GoogleClient,
            facebookClient: @escaping () -> FacebookClient
        ) {
            self.api = api
            self.appleClient = appleClient
            self.googleClient = googleClient
            self.facebookClient = facebookClient
        }
    }

    public let environment: Environment

    public init(environment: Environment) {
        self.environment = environment
    }

    public func authenticateWithApple() async throws -> User {
        let credentials = try await environment.appleClient().authenticate().async()
        return try await environment.api().authenticateWithApple(
            credentials.either(
                ifLeft: { credentials in
                    AppleClient.APICredentials.init(
                        userInfo: credentials.userInfo,
                        token: credentials.token,
                        authorizationCode: credentials.authorizationCode
                    )
                }, ifRight: { credentials in
                    AppleClient.APICredentials.init(
                        userInfo: nil,
                        token: credentials.token,
                        authorizationCode: credentials.authorizationCode
                    )
                }
            )
        )
    }

    public func authenticateWithGoogle(clientID: GoogleClient.ClientID, presenter: UIViewController) async throws -> User {
        let credential = try await environment.googleClient().authenticate(clientID, presenter).async()
        return try await environment.api().authenticateWithGoogle(credential)
    }

    public func authenticateWithFacebook(permissions: [String]) async throws -> User {
        let credential = try await environment.facebookClient().authenticate(permissions).async()
        return try await environment.api().authenticateWithFacebook(credential)
    }
}
