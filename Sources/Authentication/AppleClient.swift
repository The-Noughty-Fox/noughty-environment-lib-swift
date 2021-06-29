//
//  AuthenticationClient.swift
//  CityCaptor
//
//  Created by Alex Culeva on 12.04.2021.
//

import AuthenticationServices
import Combine
import ComposableArchitecture

public struct AppleClient {
    public let authenticate: () -> Effect<Either<SignupCredentials, LoginCredentials>, Never>
}

public extension AppleClient {
    // API-friendly structure to be consumed as either login or signup depending if there's 'userInfo'
    struct APICredentials: Codable {
        public let userInfo: AppleClient.SignupCredentials.User?
        public let token: String
        public let authorizationCode: String
    }

    struct SignupCredentials: Codable {
        public struct User: Codable {
            public struct Name: Codable {
                public let given: String?
                public let family: String?
                public let nickname: String?
                public let middle: String?
            }
            public let email: String
            public let name: Name
            public let identifier: String
        }
        public let userInfo: User
        public let token: String
        public let authorizationCode: String
    }

    struct LoginCredentials: Codable {
        public let token: String
        public let authorizationCode: String
    }
}


public extension AppleClient {
    static var live: Self = {
        enum Event {
            case signup(SignupCredentials)
            case login(LoginCredentials)
            case error(Error)
        }
        class Delegate: NSObject, ASAuthorizationControllerDelegate {
            let subject: PassthroughSubject<Event, Never>

            init(subject: PassthroughSubject<Event, Never>) {
                self.subject = subject
            }

            func authorizationController(
                controller: ASAuthorizationController,
                didCompleteWithAuthorization authorization: ASAuthorization
            ) {
                guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                      let token = appleIDCredential.identityToken.flatMap({ String(data: $0, encoding: .utf8) }),
                      let authorizationCode = appleIDCredential.authorizationCode.flatMap({ String(data: $0, encoding: .utf8) }) else {
                    fatalError("authorization not with apple id")
                }
                guard let fullName = appleIDCredential.fullName, let email = appleIDCredential.email else {
                    return subject.send(.login(.init(token: token, authorizationCode: authorizationCode)))
                }
                subject.send(
                    .signup(
                        SignupCredentials(
                            userInfo: .init(
                                email: email,
                                name: .init(
                                    given: fullName.givenName,
                                    family: fullName.familyName,
                                    nickname: fullName.nickname,
                                    middle: fullName.middleName
                                ),
                                identifier: appleIDCredential.user
                            ),
                            token: token,
                            authorizationCode: authorizationCode
                        )
                    )
                )
            }

            func authorizationController(
                controller: ASAuthorizationController,
                didCompleteWithError error: Error
            ) {
                subject.send(.error(error))
            }
        }

        let subject = PassthroughSubject<Event, Never>()
        let delegate = Delegate(subject: subject)

        return AppleClient(
            authenticate: {
                _ = delegate // capture
                let request = ASAuthorizationAppleIDProvider()
                    .createRequest()
                    .set(\.requestedScopes, [.fullName, .email])
                let controller = ASAuthorizationController(authorizationRequests: [request])
                controller.delegate = delegate
                controller.performRequests()

                return subject.compactMap { event -> Either<SignupCredentials, LoginCredentials>? in
                    switch event {
                    case .signup(let creds): return .left(creds)
                    case .login(let creds): return .right(creds)
                    case .error(let error): return nil // TODO(alex): handle error
                    }
                }.first().eraseToEffect()
            }
        )
    }()
}
