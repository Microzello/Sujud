//
//  PrayerActivityAttributes.swift
//  Sujud
//

#if os(iOS)
import ActivityKit
import Foundation

/// A Live Activity counting down to one prayer, started by tapping it in the app.
nonisolated struct PrayerActivityAttributes: ActivityAttributes {
    nonisolated struct ContentState: Codable, Hashable {}

    /// The `Prayer` raw value.
    let prayer: String
    let date: Date
    /// When the countdown began; timers run from here to `date`.
    let startDate: Date

    var prayerValue: Prayer {
        Prayer(rawValue: prayer) ?? .fajr
    }
}
#endif
