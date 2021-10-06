//
//  Publisher+Extensions.swift
//  Enclaves
//
//  Created by Lisnic Victor on 09.09.2021.
//

import Combine
import Foundation

public extension Publisher {
    func optional() -> AnyPublisher<Output?, Failure> {
        map {
            Optional.some($0)
        }.eraseToAnyPublisher()
    }

    func filterNil<T>() -> AnyPublisher<T, Failure> where Output == Optional<T> {
        filter({ $0 != nil })
            .map { $0! }
            .eraseToAnyPublisher()
    }

    func result() -> AnyPublisher<Result<Output, Failure>, Never> {
        map { Result.success($0) }
            .catch({ Just(Result.failure($0)) })
            .eraseToAnyPublisher()
    }

    func onSuccess<O, F>(_ block: @escaping (O) -> Void) -> some Publisher where Output == Result<O, F>, Failure == Never {
        map { $0.map(block) }
    }

    func onFailure<O, F>(_ block: @escaping (F) -> Void) -> some Publisher where Output == Result<O, F>, Failure == Never {
        map {
            $0.mapError { error -> F in
                block(error)
                return error
            }
        }
    }

    func run() -> AnyCancellable {
        sink(receiveCompletion: {_ in}, receiveValue: {_ in})
    }

    func recieveOnMain() -> AnyPublisher<Output, Failure> {
        receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
