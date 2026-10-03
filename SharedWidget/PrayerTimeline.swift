//
//  PrayerTimeline.swift
//  Sujud
//
//  The timeline shared by every widget and complication.
//

import CoreLocation
import WidgetKit

struct PrayerEntry: TimelineEntry {
    let date: Date
    /// Nil when no location is available yet.
    let next: PrayerEvent?
    /// How much of the time since the previous prayer has elapsed.
    let progress: Double
    /// When each prayer next comes around, today or tomorrow, as in the app.
    let times: [Prayer: Date]

    static var sample: PrayerEntry {
        let now = Date.now
        let today = Calendar.current.startOfDay(for: now)
        func at(_ hour: Int, _ minute: Int) -> Date {
            today.addingTimeInterval(TimeInterval(hour * 3600 + minute * 60))
        }
        return PrayerEntry(
            date: now,
            next: PrayerEvent(prayer: .maghrib, date: now.addingTimeInterval(5025)),
            progress: 0.6,
            times: [
                .fajr: at(5, 38), .sunrise: at(7, 14), .dhuhr: at(13, 7),
                .asr: at(16, 24), .maghrib: at(19, 1), .isha: at(20, 30),
            ]
        )
    }

    static var needsLocation: PrayerEntry {
        PrayerEntry(date: .now, next: nil, progress: 0, times: [:])
    }
}

struct PrayerTimelineProvider: TimelineProvider {
    private static let horizon: TimeInterval = 6 * 60 * 60
    private static let step: TimeInterval = 5 * 60

    func placeholder(in context: Context) -> PrayerEntry {
        .sample
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
        // Snapshots must be quick, so use the location the system already has, if any.
        if let location = CLLocationManager().location {
            let timetable = Timetable(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            completion(Self.entry(at: .now, timetable: timetable))
        } else {
            completion(.sample)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
        Task {
            completion(await Self.timeline())
        }
    }

    /// An entry every few minutes to advance the gauges, plus one at each
    /// prayer time so countdowns switch exactly on time.
    private static func timeline() async -> Timeline<PrayerEntry> {
        guard let location = await WidgetLocation.current() else {
            return Timeline(entries: [.needsLocation], policy: .after(.now.addingTimeInterval(30 * 60)))
        }
        let timetable = Timetable(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let start = Date(timeIntervalSinceReferenceDate: (Date.now.timeIntervalSinceReferenceDate / 60).rounded(.down) * 60)
        let end = start.addingTimeInterval(horizon)

        var dates = Set(stride(from: start, to: end, by: step))
        for event in timetable.events(startingOn: start, days: 2) where event.date > start && event.date < end {
            dates.insert(event.date)
        }

        let entries = dates.sorted().map { entry(at: $0, timetable: timetable) }
        return Timeline(entries: entries, policy: .atEnd)
    }

    private static func entry(at date: Date, timetable: Timetable) -> PrayerEntry {
        let status = timetable.status(at: date)
        return PrayerEntry(
            date: date,
            next: status.next,
            progress: status.progress(at: date),
            times: timetable.upcoming(after: date).mapValues(\.date)
        )
    }
}
