//
//  HealthClient.swift
//  
//
//  Created by Alex Culeva on 12.05.2021.
//

import HealthKit
import ComposableArchitecture
import Combine

public struct HealthClient {
    public let shouldAuthorize: () -> Effect<Bool, Error>
    public let authorize: () -> Effect<Bool, Error>
    public let workouts: () -> Effect<[Workout], Error>
    public let workoutsWithRoutes: () -> Effect<[Workout], Error>
    public let workoutDetails: (Workout) -> Effect<Workout, Error>
}

public extension HealthClient {
    static let live: Self = {
        let store = HKHealthStore()

        return HealthClient(
            shouldAuthorize: { store.shouldAuthorize().receive(on: DispatchQueue.main).eraseToEffect() },
            authorize: { store.authorize().receive(on: DispatchQueue.main).eraseToEffect() },
            workouts: { store.workouts(100_000).map { $0.map { Workout(hkWorkout: $0) } }.eraseToEffect() },
            workoutsWithRoutes: {
                store.workoutsWithRoutes(100_000).eraseToEffect()
            },
            workoutDetails: { store.workout($0.id).flatMap(store.workoutWithDetails).eraseToEffect() }
        )
    }()
}

public struct HealthEnvironment {
    let health: () -> HealthClient

    public init(health: @escaping () -> HealthClient) {
        self.health = health
    }
}

public enum HealthAction {
    case request
    case authorize
    case authorized(Bool)
    case error(Error)
}

public let healthReducer = Reducer<Void, HealthAction, HealthEnvironment> { _, action, environment in
    switch action {
    case .request:
        return environment.health().shouldAuthorize()
            .map { $0 ? HealthAction.authorize : .authorized(true) }
            .catch { Just(.error($0)) }
            .eraseToEffect()
    case .authorize:
        return environment.health().authorize()
            .map(HealthAction.authorized)
            .catch { Just(.error($0)) }
            .eraseToEffect()
    case .authorized, .error:
        return .none
    }
}

public extension HealthClient {
    static let authorized = Self(
        shouldAuthorize: { Effect(value: false) },
        authorize: { Effect(value: true) },
        workouts: {
            Effect(
                value: [
                    Workout(
                        id: UUID(),
                        activityType: .running,
                        duration: 60 * 67,
                        startDate: DateComponents(
                            calendar: .init(identifier: .gregorian),
                            year: 2021,
                            month: 4,
                            day: 8,
                            hour: 7,
                            minute: 15
                        ).date!,
                        endDate: DateComponents(
                            calendar: .init(identifier: .gregorian),
                            year: 2021,
                            month: 4,
                            day: 8,
                            hour: 8,
                            minute: 22
                        ).date!,
                        distance: 12_345
                    )
                ]
            )
        },
        workoutsWithRoutes: { .none },
        workoutDetails: Effect.init
    )
}
