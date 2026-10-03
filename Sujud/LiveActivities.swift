//
//  LiveActivities.swift
//  Sujud
//

#if os(iOS)
import ActivityKit
import Foundation

/// Countdowns on the Lock Screen and in the Dynamic Island for a prayer the
/// user tapped. Only one runs at a time.
enum PrayerLiveActivity {
    static func start(for event: PrayerEvent) {
        guard event.date > .now, ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = PrayerActivityAttributes(prayer: event.prayer.rawValue, date: event.date, startDate: .now)
        let content = ActivityContent(state: PrayerActivityAttributes.ContentState(), staleDate: event.date)
        Task {
            for activity in Activity<PrayerActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            _ = try? Activity.request(attributes: attributes, content: content)
        }
    }

    /// Clears countdowns whose prayer time has already come.
    static func endFinished() {
        Task {
            for activity in Activity<PrayerActivityAttributes>.activities where activity.attributes.date <= .now {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
#endif
