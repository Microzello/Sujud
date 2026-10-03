//
//  NotificationScheduler.swift
//  Sujud
//
//  Prayer alerts are local notifications computed on device, so they work
//  offline. iOS allows 64 pending notifications, so we keep the next 12 days
//  queued and top them up whenever the app runs or refreshes in the background.
//

import CoreLocation
import Foundation
import UserNotifications
#if os(iOS)
import BackgroundTasks
#endif

enum NotificationScheduler {
    static let refreshTaskIdentifier = "com.omarahmed.sujud.refresh"
    private static let days = 12

    static func reschedule(for location: CLLocation) async {
        let center = UNUserNotificationCenter.current()
        guard await isAuthorized(center) else { return }

        let timetable = Timetable(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let now = Date.now
        let events = timetable.events(startingOn: now, days: days)
            .filter { $0.prayer.isPrayer && $0.date > now }

        center.removeAllPendingNotificationRequests()
        for event in events {
            try? await center.add(request(for: event))
        }

        #if os(iOS)
        scheduleBackgroundRefresh()
        #endif
    }

    private static func isAuthorized(_ center: UNUserNotificationCenter) async -> Bool {
        var status = await center.notificationSettings().authorizationStatus
        if status == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
            status = await center.notificationSettings().authorizationStatus
        }
        switch status {
        case .authorized, .provisional, .ephemeral: return true
        default: return false
        }
    }

    private static func request(for event: PrayerEvent) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "\(event.prayer.localizedName) prayer time")
        content.body = event.date.formatted(date: .omitted, time: .shortened)
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: event.date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let identifier = "prayer.\(event.prayer.rawValue).\(Int(event.date.timeIntervalSince1970))"
        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }

    #if os(iOS)
    private static func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: refreshTaskIdentifier)
        request.earliestBeginDate = .now.addingTimeInterval(24 * 60 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    /// Runs occasionally in the background to keep alerts queued even if
    /// the app isn't opened for a while.
    static func refreshInBackground() async {
        // The system's last known fix; background tasks can't wait for a new one.
        guard let location = CLLocationManager().location else {
            scheduleBackgroundRefresh()
            return
        }
        await reschedule(for: location)
    }
    #endif
}
