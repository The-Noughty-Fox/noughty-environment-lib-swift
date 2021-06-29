//
//  AuthenticationClient.swift
//
//
//  Created by S2dent on 03.06.2021.
//

import ComposableArchitecture
import Combine

public struct AuthenticationFeature<User> {
    public enum Action {
        case authenticateWithApple
        case appleAuthentication(Either<AppleClient.SignupCredentials, AppleClient.LoginCredentials>)
        case authenticated(User)
        case error(Error)
    }

    public struct Environment {
        public struct API {
            let authenticateWithApple: (AppleClient.APICredentials) -> Effect<User, Error>

            public init(
                authenticateWithApple: @escaping (AppleClient.APICredentials) -> Effect<User, Error>
            ) {
                self.authenticateWithApple = authenticateWithApple
            }
        }
        let api: () -> API
        let appleClient: () -> AppleClient
        let keychain: () -> KeychainClient

        public init(
            api: @escaping () -> API,
            appleClient: @escaping () -> AppleClient,
            keychain: @escaping () -> KeychainClient
        ) {
            self.api = api
            self.appleClient = appleClient
            self.keychain = keychain
        }
    }

    public init() {}

    public let reducer = Reducer<Void, Action, Environment> { _, action, environment in
        switch action {
        case .authenticateWithApple:
            return environment.appleClient()
                .authenticate()
                .map(Action.appleAuthentication)
        case .appleAuthentication(let credentials):
            let authenticate = {
                environment.api().authenticateWithApple(
                    credentials.either(
                        ifLeft: { credentials in
                            .init(
                                userInfo: credentials.userInfo,
                                token: credentials.token,
                                authorizationCode: credentials.authorizationCode
                            )
                        }, ifRight: { credentials in
                            .init(
                                userInfo: nil,
                                token: credentials.token,
                                authorizationCode: credentials.authorizationCode
                            )
                        }
                    )
                )
                .map(Action.authenticated)
                .catch { Just(Action.error($0)) }
                .receive(on: DispatchQueue.main)
                .eraseToEffect()
            }
            switch credentials {
            case .left(let signup):
                return environment.keychain().storeUser(signup.userInfo)
                    .flatMap { _ in authenticate() }
                    .catch { Just(.error($0)) }
                    .eraseToEffect()
            case .right(let login):
                return authenticate()
            }
        case .authenticated, .error:
            return .none
        }
    }
}
