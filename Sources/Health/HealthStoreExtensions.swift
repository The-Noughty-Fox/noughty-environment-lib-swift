//
//  HealthStoreExtensions.swift
//  
//
//  Created by S2dent on 16.05.2021.
//

import HealthKit
import CoreLocation
import Combine

public extension HealthClient {
    enum Error: Swift.Error {
        case notAvailableOnDevice
        case noData(type: String)
        case noWorkout(UUID)
        case healthKit(Swift.Error)

        var localizedDescription: String {
            switch self {
            case .notAvailableOnDevice: return "Not available on device"
            case .noData(let type): return "No data of type \(type) found"
            case .noWorkout(let id): return "No workout with id: \(id) found"
            case .healthKit(let error): return error.localizedDescription
            }
        }
    }
}

// MARK: - Authorization

extension HKHealthStore {
    typealias Error = HealthClient.Error

    func shouldAuthorize() -> AnyPublisher<Bool, Error> {
        shouldAuthorize(includeSharePermission: false)
    }

    func shouldAuthorize(includeSharePermission: Bool) -> AnyPublisher<Bool, Error> {
        performRequest(
            getRequestStatusForAuthorization,
            predicate: { $0 == .shouldRequest },
            includeSharePermission: includeSharePermission
        )
    }

    func authorize() -> AnyPublisher<Bool, Error> {
        authorize(requestSharePermission: false)
    }

    func authorize(requestSharePermission: Bool = false) -> AnyPublisher<Bool, Error> {
        performRequest(
            requestAuthorization,
            predicate: { $0 },
            includeSharePermission: requestSharePermission
        )
    }

    private func performRequest<T>(
        _ request: @escaping (
            _ toShare: Set<HKSampleType>,
            _ toRead: Set<HKObjectType>,
            _ completion: @escaping (T, Swift.Error?) -> Void
        ) -> Void,
        predicate: @escaping (T) -> Bool,
        includeSharePermission: Bool
    ) -> AnyPublisher<Bool, Error> {
        let subject = PassthroughSubject<Bool, Error>()
        let callback: (Bool, Error?) -> Void = { result, error in
            if let error = error {
                subject.send(completion: .failure(error))
            } else {
                subject.send(result)
                subject.send(completion: .finished)
            }
        }

        return Deferred<PassthroughSubject<Bool, Error>> {
            guard HKHealthStore.isHealthDataAvailable() else {
                callback(false, .notAvailableOnDevice)
                return subject
            }
            var healthKitTypesToRead: Set<HKObjectType> = [
                HKObjectType.workoutType(),
                HKSeriesType.workoutRoute()
            ]
            _ = HKQuantityType.quantityType(forIdentifier: .heartRate).map { healthKitTypesToRead.insert($0) }

            var healthKitTypesToShare: Set<HKSampleType> = [HKObjectType.workoutType()]
            _ = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned).map { healthKitTypesToShare.insert($0) }
            _ = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning).map { healthKitTypesToShare.insert($0) }

            request(
                includeSharePermission ? healthKitTypesToShare : [],
                healthKitTypesToRead
            ) { result, error in
                callback(predicate(result), error.map(Error.healthKit))
            }
            return subject
        }.eraseToAnyPublisher()
    }
}

// MARK: - Workouts

extension HKHealthStore {
    func workouts(_ limit: Int) -> AnyPublisher<[HKWorkout], Error> {
        requestWorkouts(
            limit: limit,
            sortDescriptors: [
                NSSortDescriptor(
                    key: HKSampleSortIdentifierEndDate,
                    ascending: false
                )
            ]
        )
    }

    func workout(_ id: UUID) -> AnyPublisher<HKWorkout, Error> {
        requestWorkouts(
            predicate: HKQuery.predicateForObject(with: id),
            limit: 1
        ).tryMap { workouts in
            guard let workout = workouts.first else {
                throw Error.noWorkout(id)
            }
            return workout
        }.mapError { $0 as? Error ?? .healthKit($0) }
        .eraseToAnyPublisher()
    }

    private func requestWorkouts(
        predicate: NSPredicate? = nil,
        limit: Int = 0,
        sortDescriptors: [NSSortDescriptor] = []
    ) -> AnyPublisher<[HKWorkout], Error> {
        executeQuery(
            sampleType: HKObjectType.workoutType(),
            predicate: predicate,
            limit: limit,
            sortDescriptors: sortDescriptors
        )
    }
}

// MARK: - Workout Details

extension HKHealthStore {
    func workoutWithDetails(from workout: HKWorkout) -> AnyPublisher<Workout, Error> {
        let routes: AnyPublisher<[HKWorkoutRoute], Error> = executeQuery(
            sampleType: HKSeriesType.workoutRoute(),
            predicate: HKQuery.predicateForObjects(from: workout),
            limit: HKObjectQueryNoLimit
        )
        return routes
            .flatMap { Publishers.MergeMany($0.map(self.locations)) }
            .collect()
            .map { Workout(hkWorkout: workout, locations: $0.flatMap { $0 }) }
            .eraseToAnyPublisher()
    }

    private func locations(from workout: HKWorkoutRoute) -> AnyPublisher<[CLLocation], Error> {
        let subject = PassthroughSubject<[CLLocation], Error>()
        var routeLocations = [CLLocation]()

        let query = HKWorkoutRouteQuery(route: workout) { (routeQuery, locations, done, error) in
            if let error = error {
                return subject.send(completion: .failure(.healthKit(error)))
            }
            guard let locations = locations else {
                return subject.send(completion: .failure(.noData(type: "CLLocation")))
            }

            routeLocations.append(contentsOf: locations)
            if done {
                subject.send(routeLocations)
                subject.send(completion: .finished)
            }
        }

        return Deferred<PassthroughSubject<[CLLocation], Error>> {
            self.execute(query)
            return subject
        }.eraseToAnyPublisher()
    }
}

private extension HKHealthStore {
    func executeQuery<T>(
        sampleType: HKSampleType,
        predicate: NSPredicate? = nil,
        limit: Int = 0,
        sortDescriptors: [NSSortDescriptor] = []
    ) -> AnyPublisher<[T], Error> {
        let subject = PassthroughSubject<[T], Error>()

        let query = HKSampleQuery(
            sampleType: sampleType,
            predicate: predicate,
            limit: limit,
            sortDescriptors: sortDescriptors
        ) { query, samples, error in
            if let error = error {
                return subject.send(completion: .failure(.healthKit(error)))
            }
            guard let typedSamples = samples as? [T] else {
                return subject.send(completion: .failure(.noData(type: sampleType.description)))
            }
            subject.send(typedSamples)
            subject.send(completion: .finished)
        }
        return Deferred<PassthroughSubject<[T], Error>> {
            self.execute(query)
            return subject
        }.eraseToAnyPublisher()
    }
}
