//
//  GoogleClient.swift
//  
//
//  Created by S2dent on 05.01.2022.
//

import Combine
import UIKit
import GoogleSignIn

public struct GoogleClient {
    public typealias ClientID = String

    public let authenticate: (ClientID, UIViewController) -> AnyPublisher<Credentials, Error>
    public let handleURL: (URL) -> Bool
    public let restore: () -> AnyPublisher<Credentials, Error>
    public let signOut: () -> Void
}

public extension GoogleClient {
    struct Credentials: Equatable, Codable {
        let token: String
    }
}

public extension GoogleClient {
    static let live: Self = {
        typealias Subject = PassthroughSubject<Credentials, Error>
        let handleResponse: (GIDGoogleUser?, Error?, Subject) -> Void = { user, error, subject in
            guard let user = user else {
                return subject.send(completion: .failure(error!))
            }
            user.authentication.do { authentication, error in
                guard let auth = authentication else {
                    return subject.send(completion: .failure(error!))
                }
                subject.send(Credentials(token: auth.idToken!))
                subject.send(completion: .finished)
            }
        }
        return GoogleClient(
            authenticate: { clientID, presenter in
                let subject = Subject()
                return Deferred<Subject> {
                    GIDSignIn.sharedInstance.signIn(
                        with: GIDConfiguration(clientID: clientID),
                        presenting: presenter
                    ) { user, error in
                        handleResponse(user, error, subject)
                    }
                    return subject
                }.eraseToAnyPublisher()
            },
            handleURL: { GIDSignIn.sharedInstance.handle($0) },
            restore: {
                let subject = Subject()
                return Deferred<Subject> {
                    GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                        handleResponse(user, error, subject)
                    }
                    return subject
                }.eraseToAnyPublisher()
            },
            signOut: { GIDSignIn.sharedInstance.signOut() }
        )
    }()
}
