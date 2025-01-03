//
//  Defaults.swift
//  NoughtyEnvironment
//
//  Created by Dmitrii Sorochin on 03.01.2025.
//
import Foundation
import Combine

@propertyWrapper
struct Defaults<T: Codable> where T: Equatable {
    let defaultValue: T
    let key: String

    init(wrappedValue defaultValue: T, _ key: String) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: T {
        get {
            guard let data = UserDefaults.standard.data(forKey: key) else { return defaultValue }
            do {
                let item = try JSONDecoder().decode(T.self, from: data)
                return item
            } catch {
                return defaultValue
            }
        }
        set {
            let data = try! JSONEncoder().encode(newValue)
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    var projectedValue: AnyPublisher<T, Never> {
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .map { _ in UserDefaults.standard.data(forKey: key) }
            .compactMap { $0 }
            .compactMap { try? JSONDecoder().decode(T.self, from: $0) }
            .removeDuplicates()
            .prepend(wrappedValue)
            .eraseToAnyPublisher()
    }
}
