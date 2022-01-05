//
//  AuthenticationClient.swift
//
//
//  Created by S2dent on 03.06.2021.
//

//import ComposableArchitecture
import Combine
import UIKit

public struct Authentication<User> {
    public struct Environment {
        public struct API {
            let authenticateWithApple: (AppleClient.APICredentials) -> AnyPublisher<User, Error>
            let authenticateWithGoogle: (GoogleClient.Credentials) -> AnyPublisher<User, Error>

            public init(
                authenticateWithApple: @escaping (AppleClient.APICredentials) -> AnyPublisher<User, Error>,
                authenticateWithGoogle: @escaping (GoogleClient.Credentials) -> AnyPublisher<User, Error>
            ) {
                self.authenticateWithApple = authenticateWithApple
                self.authenticateWithGoogle = authenticateWithGoogle
            }
        }
        public let api: () -> API
        public let appleClient: () -> AppleClient
        public let googleClient: () -> GoogleClient
        public let keychain: () -> KeychainClient

        public init(
            api: @escaping () -> API,
            appleClient: @escaping () -> AppleClient,
            googleClient: @escaping () -> GoogleClient,
            keychain: @escaping () -> KeychainClient
        ) {
            self.api = api
            self.appleClient = appleClient
            self.googleClient = googleClient
            self.keychain = keychain
        }
    }

    public let environment: Environment

    public init(environment: Environment) {
        self.environment = environment
    }

    public func authenticateWithApple() -> AnyPublisher<User, Error> {
        environment
            .appleClient()
            .authenticate()
            .flatMap { [environment] credentials -> AnyPublisher<User, Error> in
                let authenticate: () -> AnyPublisher<User, Error>  = {
                    environment.api().authenticateWithApple(
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
                    .receive(on: DispatchQueue.main)
                    .eraseToAnyPublisher()
                }

                switch credentials {
                case .left(let signup):
                    return environment.keychain().storeUser(signup.userInfo)
                        .flatMap { _ in authenticate() }
                        .eraseToAnyPublisher()
                case .right(_):
                    return authenticate()
                }
            }.eraseToAnyPublisher()
    }

    public func authenticateWithGoogle(clientID: GoogleClient.ClientID, presenter: UIViewController) -> AnyPublisher<User, Error> {
        return environment.googleClient()
            .authenticate(clientID, presenter)
            .flatMap(environment.api().authenticateWithGoogle)
            .eraseToAnyPublisher()
    }
}
