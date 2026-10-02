//
//  Prayer.swift
//  Sujud
//

import Foundation

/// The six daily times shown in the app, in chronological order.
nonisolated enum Prayer: String, CaseIterable, Identifiable, Sendable {
    case fajr, sunrise, dhuhr, asr, maghrib, isha

    var id: String { rawValue }

    /// Sunrise marks the end of Fajr; it is not itself a prayer.
    var isPrayer: Bool { self != .sunrise }

    var localizedName: String {
        switch self {
        case .fajr: String(localized: "Fajr")
        case .sunrise: String(localized: "Sunrise")
        case .dhuhr: String(localized: "Dhuhr")
        case .asr: String(localized: "Asr")
        case .maghrib: String(localized: "Maghrib")
        case .isha: String(localized: "Isha")
        }
    }
}

/// A prayer at a specific moment.
nonisolated struct PrayerEvent: Hashable, Identifiable, Sendable {
    let prayer: Prayer
    let date: Date

    var id: Date { date }
}

/// The six times for one civil day.
nonisolated struct DaySchedule: Hashable, Sendable {
    let times: PrayerTimes

    func date(for prayer: Prayer) -> Date? {
        switch prayer {
        case .fajr: times.fajr
        case .sunrise: times.sunrise
        case .dhuhr: times.dhuhr
        case .asr: times.asr
        case .maghrib: times.maghrib
        case .isha: times.isha
        }
    }

    var events: [PrayerEvent] {
        Prayer.allCases.compactMap { prayer in
            date(for: prayer).map { PrayerEvent(prayer: prayer, date: $0) }
        }
    }
}

/// Where we are in the day: today's schedule, the period we're in, and what's next.
nonisolated struct PrayerStatus: Sendable {
    let today: DaySchedule
    /// The most recent time that has passed (yesterday's Isha before Fajr).
    let current: PrayerEvent?
    /// The next upcoming time (tomorrow's Fajr after Isha).
    let next: PrayerEvent?

    /// Fraction of the current period that has elapsed, for gauges.
    func progress(at date: Date) -> Double {
        guard let current, let next else { return 0 }
        let total = next.date.timeIntervalSince(current.date)
        guard total > 0 else { return 0 }
        return min(max(date.timeIntervalSince(current.date) / total, 0), 1)
    }
}

/// Produces schedules for a fixed location and calculation settings.
nonisolated struct Timetable: Sendable {
    let latitude: Double
    let longitude: Double
    var calculator: PrayTimes = Preferences.calculator
    var calendar: Calendar = .autoupdatingCurrent

    func schedule(for date: Date) -> DaySchedule {
        DaySchedule(times: calculator.times(on: date, calendar: calendar, latitude: latitude, longitude: longitude))
    }

    /// All events for `days` consecutive days starting with the day containing `date`.
    func events(startingOn date: Date, days: Int) -> [PrayerEvent] {
        (0..<days).flatMap { offset in
            calendar.date(byAdding: .day, value: offset, to: date).map { schedule(for: $0).events } ?? []
        }
    }

    /// The next time each prayer comes around after `date`: today's if it's
    /// still ahead, otherwise tomorrow's.
    func upcoming(after date: Date) -> [Prayer: PrayerEvent] {
        let today = schedule(for: date)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: date).map(schedule(for:))
        var events: [Prayer: PrayerEvent] = [:]
        for prayer in Prayer.allCases {
            if let time = today.date(for: prayer), time > date {
                events[prayer] = PrayerEvent(prayer: prayer, date: time)
            } else if let time = tomorrow?.date(for: prayer) {
                events[prayer] = PrayerEvent(prayer: prayer, date: time)
            }
        }
        return events
    }

    func status(at date: Date) -> PrayerStatus {
        let today = schedule(for: date)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: date).map(schedule(for:))
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: date).map(schedule(for:))
        let events = (yesterday?.events ?? []) + today.events + (tomorrow?.events ?? [])
        return PrayerStatus(
            today: today,
            current: events.last { $0.date <= date },
            next: events.first { $0.date > date }
        )
    }
}
