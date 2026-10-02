//
//  SujudTests.swift
//  SujudTests
//
//  Created by Omar on 2026-09-30.
//

import Foundation
import Testing
@testable import Sujud

/// Expected values were produced by the reference praytime.js v3.2.
struct ReferenceCase: Sendable, CustomTestStringConvertible {
    let name: String
    let latitude: Double
    let longitude: Double
    let method: CalculationMethod
    let asr: AsrMethod
    let year: Int, month: Int, day: Int
    /// Fajr, sunrise, Dhuhr, Asr, sunset, Maghrib, Isha in ms since 1970.
    let expected: [Int64?]

    var testDescription: String { name }

    static let all = [
        ReferenceCase(name: "Toronto MWL summer", latitude: 43.65, longitude: -79.38, method: .mwl, asr: .standard,
                      year: 2026, month: 6, day: 15,
                      expected: [1781507580000, 1781516100000, 1781543880000, 1781558640000, 1781571660000, 1781571720000, 1781579520000]),
        ReferenceCase(name: "London ISNA Hanafi winter", latitude: 51.5074, longitude: -0.1278, method: .isna, asr: .hanafi,
                      year: 2026, month: 12, day: 15,
                      expected: [1797315360000, 1797321600000, 1797335760000, 1797343500000, 1797349920000, 1797349980000, 1797356100000]),
        ReferenceCase(name: "Makkah Umm al-Qura", latitude: 21.4225, longitude: 39.8262, method: .makkah, asr: .standard,
                      year: 2026, month: 4, day: 15,
                      expected: [1776217380000, 1776222120000, 1776244860000, 1776257100000, 1776267600000, 1776267660000, 1776273060000]),
        ReferenceCase(name: "Tehran with Maghrib angle", latitude: 35.69, longitude: 51.39, method: .tehran, asr: .standard,
                      year: 2026, month: 9, day: 28,
                      expected: [1790557380000, 1790562420000, 1790583900000, 1790596140000, 1790605380000, 1790606460000, 1790609280000]),
        ReferenceCase(name: "Tromsø midnight sun", latitude: 69.65, longitude: 18.96, method: .mwl, asr: .standard,
                      year: 2026, month: 6, day: 15,
                      expected: [nil, nil, 1781520300000, 1781538960000, nil, nil, nil]),
    ]
}

struct PrayTimesTests {
    private func milliseconds(_ date: Date?) -> Int64? {
        date.map { Int64(($0.timeIntervalSince1970 * 1000).rounded()) }
    }

    @Test(arguments: ReferenceCase.all)
    func matchesReferenceImplementation(_ reference: ReferenceCase) {
        let times = PrayTimes(method: reference.method, asr: reference.asr).times(
            year: reference.year, month: reference.month, day: reference.day,
            latitude: reference.latitude, longitude: reference.longitude
        )
        let actual = [times.fajr, times.sunrise, times.dhuhr, times.asr, times.sunset, times.maghrib, times.isha]
        #expect(actual.map(milliseconds) == reference.expected)
    }

    @Test func ummAlQuraIshaIsLaterDuringRamadan() throws {
        // 1 March 2026 falls in Ramadan 1447.
        let times = PrayTimes(method: .makkah).times(year: 2026, month: 3, day: 1, latitude: 21.4225, longitude: 39.8262)
        let maghrib = try #require(times.maghrib)
        let isha = try #require(times.isha)
        #expect(isha.timeIntervalSince(maghrib) == 120 * 60)
    }
}

struct TimetableTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Toronto")!
        return calendar
    }

    private var timetable: Timetable {
        Timetable(latitude: 43.65, longitude: -79.38, calculator: PrayTimes(), calendar: calendar)
    }

    private func date(_ hour: Int, _ minute: Int, day: Int = 15) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 6, day: day, hour: hour, minute: minute))!
    }

    @Test func afternoonIsAsrWithMaghribNext() {
        let status = timetable.status(at: date(18, 0))
        #expect(status.current?.prayer == .asr)
        #expect(status.next?.prayer == .maghrib)
    }

    @Test func beforeFajrIsStillIsha() {
        let status = timetable.status(at: date(1, 0))
        #expect(status.current?.prayer == .isha)
        #expect(status.next?.prayer == .fajr)
        #expect(calendar.component(.day, from: status.next!.date) == 15)
    }

    @Test func afterIshaCountsDownToTomorrowsFajr() {
        let status = timetable.status(at: date(23, 30))
        #expect(status.current?.prayer == .isha)
        #expect(status.next?.prayer == .fajr)
        #expect(calendar.component(.day, from: status.next!.date) == 16)
    }

    @Test func upcomingUsesTomorrowForPrayersThatHavePassed() throws {
        let now = date(18, 0)
        let upcoming = timetable.upcoming(after: now)
        #expect(upcoming.count == 6)
        // Fajr through Asr have passed at 6 PM; Maghrib and Isha are still ahead.
        for prayer in [Prayer.fajr, .sunrise, .dhuhr, .asr] {
            let event = try #require(upcoming[prayer])
            #expect(calendar.component(.day, from: event.date) == 16)
        }
        for prayer in [Prayer.maghrib, .isha] {
            let event = try #require(upcoming[prayer])
            #expect(calendar.component(.day, from: event.date) == 15)
        }
    }

    @Test func progressIsBetweenZeroAndOne() {
        let now = date(18, 0)
        let progress = timetable.status(at: now).progress(at: now)
        #expect(progress > 0 && progress < 1)
    }

    @Test func eventsCoverConsecutiveDays() {
        let events = timetable.events(startingOn: date(12, 0), days: 3)
        #expect(events.count == 18)
        #expect(events == events.sorted { $0.date < $1.date })
    }
}

struct QiblaTests {
    @Test func bearingsMatchKnownValues() {
        #expect(abs(Qibla.bearing(latitude: 40.7128, longitude: -74.0060) - 58.5) < 0.5)
        #expect(abs(Qibla.bearing(latitude: 51.5074, longitude: -0.1278) - 119.0) < 0.5)
    }

    @Test func angleDifferenceTakesShortestPath() {
        #expect(Qibla.angleDifference(from: 350, to: 10) == 20)
        #expect(Qibla.angleDifference(from: 10, to: 350) == -20)
        #expect(Qibla.angleDifference(from: 90, to: 90) == 0)
    }
}

struct TimeFormattingTests {
    private let utc = TimeZone(identifier: "UTC")!

    private var morning: Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utc
        return calendar.date(from: DateComponents(year: 2026, month: 9, day: 30, hour: 5, minute: 39))!
    }

    @Test func twelveHourTimesDropAMPMWithoutPaddingTheHour() {
        let locale = Locale(identifier: "en_US")
        #expect(TimeFormatting.hourMinute(morning, locale: locale, timeZone: utc) == "5:39")
        #expect(TimeFormatting.dayPeriod(morning, locale: locale, timeZone: utc) == "AM")
    }

    @Test func twentyFourHourTimesHaveNoDayPeriod() {
        let locale = Locale(identifier: "en_GB")
        #expect(TimeFormatting.hourMinute(morning, locale: locale, timeZone: utc) == "05:39")
        #expect(TimeFormatting.dayPeriod(morning, locale: locale, timeZone: utc) == nil)
    }
}
