//
//  KeychainClient.swift
//  Enclaves
//
//  Created by Alex Culeva on 12.04.2021.
//

import KeychainSwift
import Foundation
import Combine
import ComposableArchitecture

public struct KeychainClient {
    public enum Key: String {
        case user
    }

    public let storeUser: (AppleClient.SignupCredentials.User) -> Effect<Key, Error>
}

public extension KeychainClient {
    static let inMemory: Self = {
        var storedUser: AppleClient.SignupCredentials.User?

        return Self(
            storeUser: { user in
                storedUser = user
                return Effect(value: .user)
            }
        )
    }()
}

public extension KeychainClient {
    static let live: KeychainClient = {
        let keychain = KeychainSwift()

        return KeychainClient(
            storeUser: { user -> Effect<Key, Error> in
                .result {
                    do {
                        let data = try JSONEncoder().encode(user)
                        keychain.set(data, forKey: Key.user.rawValue)

                        return .success(.user)
                    } catch {
                        return .failure(error)
                    }
                }
            }
        )
    }()
}
