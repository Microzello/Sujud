//
//  PrayerTimesView.swift
//  Sujud
//

import CoreLocation
import SwiftUI

/// Today's prayer times. On iPhone, iPad and Mac they're laid out like the
/// Clock app's World Clock page, titled with the countdown to the next prayer.
struct PrayerTimesView: View {
    let location: CLLocation

    var body: some View {
        // Ticks on whole seconds so the countdowns never skip a digit.
        let start = Date(timeIntervalSinceReferenceDate: Date.now.timeIntervalSinceReferenceDate.rounded(.down))
        TimelineView(.periodic(from: start, by: 1)) { context in
            let timetable = Timetable(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            content(timetable: timetable, now: context.date)
        }
    }

    @ViewBuilder
    private func content(timetable: Timetable, now: Date) -> some View {
        let status = timetable.status(at: now)
        #if os(watchOS)
        ScrollView {
            VStack(spacing: 8) {
                NextPrayerHeader(next: status.next, now: now)
                PrayerTable(schedule: status.today, current: status.current?.prayer)
            }
            .scenePadding(.horizontal)
        }
        #else
        let upcoming = timetable.upcoming(after: now)
        ScrollView {
            ClockListContent(
                title: status.next.map { next in
                    String(localized: "\(next.prayer.localizedName) in \(Countdown.string(from: now, to: next.date))")
                } ?? String(localized: "Prayer Times"),
                rows: Prayer.allCases.map { prayer in
                    ClockRow(
                        id: prayer.rawValue,
                        caption: Self.caption(for: upcoming[prayer], now: now),
                        name: prayer.localizedName,
                        date: upcoming[prayer]?.date
                    )
                }
            )
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        #endif
    }

    /// "Today, in 1:23:45" or "Tomorrow, in 20:12:05".
    private static func caption(for event: PrayerEvent?, now: Date) -> String {
        // A non-empty placeholder keeps rows the same height when a time can't be calculated.
        guard let event else { return " " }
        let countdown = Countdown.string(from: now, to: event.date)
        return Calendar.autoupdatingCurrent.isDate(event.date, inSameDayAs: now)
            ? String(localized: "Today, in \(countdown)")
            : String(localized: "Tomorrow, in \(countdown)")
    }
}

enum Countdown {
    /// "1:23:45", rounded up so it reaches 0:00:00 exactly on time.
    static func string(from now: Date, to date: Date) -> String {
        let seconds = max(Int(date.timeIntervalSince(now).rounded(.up)), 0)
        return Duration.seconds(seconds).formatted(.time(pattern: .hourMinuteSecond))
    }
}

#if os(watchOS)
/// "Maghrib in 1:23:45"
struct NextPrayerHeader: View {
    let next: PrayerEvent?
    let now: Date

    var body: some View {
        if let next {
            Text("\(next.prayer.localizedName) in \(Countdown.string(from: now, to: next.date))")
                .font(.headline)
                .monospacedDigit()
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }
}

struct PrayerTable: View {
    let schedule: DaySchedule
    let current: Prayer?

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Prayer.allCases) { prayer in
                if prayer != .fajr {
                    RowSeparator()
                }
                PrayerRow(prayer: prayer, date: schedule.date(for: prayer), isCurrent: prayer == current)
            }
        }
    }
}

struct PrayerRow: View {
    let prayer: Prayer
    let date: Date?
    let isCurrent: Bool

    var body: some View {
        HStack {
            Text(prayer.localizedName)
            Spacer()
            if let date {
                Text(date, format: .dateTime.hour().minute())
            } else {
                Text(verbatim: "—")
            }
        }
        .font(.body)
        .fontWeight(isCurrent ? .bold : .regular)
        .monospacedDigit()
        .padding(.vertical, 5)
        .accessibilityElement(children: .combine)
    }
}
#endif

extension Color {
    /// White in light mode, black in dark mode, like the Clock app.
    static var appBackground: Color {
        #if os(iOS)
        Color(uiColor: .systemBackground)
        #elseif os(macOS)
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? .black : .white
        })
        #else
        .black
        #endif
    }
}
