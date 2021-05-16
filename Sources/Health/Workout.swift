//
//  Workout.swift
//  
//
//  Created by Alex Culeva on 14.05.2021.
//

import HealthKit
import CoreLocation

public struct Workout: Equatable, Identifiable {
    public enum ActivityType: Equatable {
        case running, walking, other

        init(_ activityType: HKWorkoutActivityType) {
            switch activityType {
            case .running: self = .running
            case .walking: self = .walking
            default: self = .other
            }
        }

        public var localized: String {
            switch self {
            case .running: return "Running"
            case .walking: return "Walking"
            case .other: return "Other"
            }
        }
    }

    public typealias Meters = Double

    public var id: UUID
    public var activityType: ActivityType
    public var duration: TimeInterval
    public var startDate: Date
    public var endDate: Date
    public var distance: Meters
    public var locations: [CLLocation]

    public init(
        id: UUID,
        activityType: ActivityType,
        duration: TimeInterval,
        startDate: Date,
        endDate: Date,
        distance: Meters,
        locations: [CLLocation] = []
    ) {
        self.id = id
        self.activityType = activityType
        self.duration = duration
        self.startDate = startDate
        self.endDate = endDate
        self.distance = distance
        self.locations = locations
    }
}

public extension Workout {
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        return formatter.string(from: startDate)
    }

    var formattedDistance: String {
        let length = Measurement<UnitLength>(value: distance, unit: .meters)
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .short

        return formatter.string(from: length)
    }
}

extension Workout {
    init(hkWorkout: HKWorkout, locations: [CLLocation] = []) {
        self.init(
            id: hkWorkout.uuid,
            activityType: ActivityType(hkWorkout.workoutActivityType),
            duration: hkWorkout.duration,
            startDate: hkWorkout.startDate,
            endDate: hkWorkout.endDate,
            distance: hkWorkout.totalDistance?.doubleValue(for: .meter()) ?? 0,
            locations: locations
        )
    }
}
