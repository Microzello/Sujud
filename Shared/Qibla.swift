//
//  Qibla.swift
//  Sujud
//

import Foundation

nonisolated enum Qibla {
    static let kaabaLatitude = 21.422487
    static let kaabaLongitude = 39.826206

    /// Initial great-circle bearing from the given point to the Kaaba,
    /// in degrees clockwise from true north (0..<360).
    static func bearing(latitude: Double, longitude: Double) -> Double {
        let phi1 = latitude * .pi / 180
        let phi2 = kaabaLatitude * .pi / 180
        let deltaLambda = (kaabaLongitude - longitude) * .pi / 180
        let y = sin(deltaLambda)
        let x = cos(phi1) * tan(phi2) - sin(phi1) * cos(deltaLambda)
        let degrees = atan2(y, x) * 180 / .pi
        return (degrees + 360).truncatingRemainder(dividingBy: 360)
    }

    /// Signed smallest difference `to - from` in degrees, in -180...180.
    static func angleDifference(from: Double, to: Double) -> Double {
        let diff = (to - from).truncatingRemainder(dividingBy: 360)
        if diff > 180 { return diff - 360 }
        if diff < -180 { return diff + 360 }
        return diff
    }
}
