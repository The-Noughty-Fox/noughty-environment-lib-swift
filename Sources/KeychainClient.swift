//
//  KeychainClient.swift
//  Enclaves
//
//  Created by Alex Culeva on 12.04.2021.
//

import KeychainSwift
import Foundation
import Combine

public struct KeychainClient {
    public enum Key: String {
        case user
    }

    public let storeUser: (AppleClient.SignupCredentials.User) -> AnyPublisher<Key, Error>
}

public extension KeychainClient {
    static let inMemory: Self = {
        var storedUser: AppleClient.SignupCredentials.User?

        return Self(
            storeUser: { user in
                storedUser = user
                return Just(.user).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
        )
    }()
}

public extension KeychainClient {
    static let live: KeychainClient = {
        let keychain = KeychainSwift()

        return KeychainClient(
            storeUser: { user -> AnyPublisher<Key, Error> in
                    .create { subscriber in
                        do {
                            let data = try JSONEncoder().encode(user)
                            keychain.set(data, forKey: Key.user.rawValue)

                            subscriber.send(.user)
                            subscriber.send(completion: .finished)
                        } catch {
                            subscriber.send(completion: .failure(error))
                        }

                        return AnyCancellable {}
                    }
            }
        )
    }()
}
