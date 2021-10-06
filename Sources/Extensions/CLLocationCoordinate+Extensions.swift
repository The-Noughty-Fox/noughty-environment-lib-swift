//
//  CLLocationCoordinate+Extensions.swift
//  
//
//  Created by Lisnic Victor on 22.09.2021.
//

import Foundation
import CoreLocation

extension CLLocationCoordinate2D: Hashable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
}
