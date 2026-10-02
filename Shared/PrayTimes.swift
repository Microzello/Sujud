//
//  PrayTimes.swift
//  Sujud
//
//  Swift port of praytime.js v3.2 by Hamid Zarrabi-Zadeh (MIT License).
//  https://praytimes.org/docs/calculation
//

import Foundation

/// A twilight parameter is either an angle of the sun below the horizon
/// or a fixed number of minutes after the preceding event.
nonisolated enum TwilightParameter: Hashable, Sendable {
    case degrees(Double)
    case minutes(Double)

    var value: Double {
        switch self {
        case .degrees(let value), .minutes(let value): value
        }
    }

    var isMinutes: Bool {
        if case .minutes = self { true } else { false }
    }
}

/// How Fajr and Isha are estimated when twilight persists all night.
nonisolated enum HighLatitudeRule: String, Sendable {
    case none, nightMiddle, oneSeventh, angleBased
}

/// Raw prayer times for one day. A value is nil when the sun never
/// reaches the required position on that day (e.g. polar day or night).
nonisolated struct PrayerTimes: Hashable, Sendable {
    var fajr: Date?
    var sunrise: Date?
    var dhuhr: Date?
    var asr: Date?
    var sunset: Date?
    var maghrib: Date?
    var isha: Date?
}

nonisolated struct PrayTimes: Sendable {
    var method: CalculationMethod = .mwl
    var asr: AsrMethod = .standard
    var highLatitudeRule: HighLatitudeRule = .nightMiddle

    /// Computes prayer times for the given civil date at the given coordinates.
    func times(year: Int, month: Int, day: Int, latitude: Double, longitude: Double) -> PrayerTimes {
        var isha = method.isha
        // Umm al-Qura: Isha is 120 minutes after Maghrib during Ramadan.
        if method == .makkah, Self.isRamadan(year: year, month: month, day: day) {
            isha = .minutes(120)
        }

        let engine = Engine(
            latitude: latitude,
            longitude: longitude,
            utcDay: Self.utcMidnight(year: year, month: month, day: day),
            fajr: method.fajrAngle,
            isha: isha,
            maghrib: method.maghrib,
            dhuhrMinutes: 0,
            shadowFactor: asr.shadowFactor,
            highLats: highLatitudeRule
        )
        return engine.computeTimes()
    }

    /// Computes prayer times for the day containing `date` in `calendar`'s time zone.
    func times(on date: Date, calendar: Calendar = .current, latitude: Double, longitude: Double) -> PrayerTimes {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return times(year: parts.year!, month: parts.month!, day: parts.day!, latitude: latitude, longitude: longitude)
    }

    private static func utcMidnight(year: Int, month: Int, day: Int) -> Double {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let date = calendar.date(from: DateComponents(year: year, month: month, day: day))!
        return date.timeIntervalSince1970
    }

    private static func isRamadan(year: Int, month: Int, day: Int) -> Bool {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(identifier: "UTC")!
        var hijri = Calendar(identifier: .islamicUmmAlQura)
        hijri.timeZone = TimeZone(identifier: "UTC")!
        guard let noon = gregorian.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) else {
            return false
        }
        return hijri.component(.month, from: noon) == 9
    }
}

// MARK: - Engine

/// Mirrors the computation pipeline of praytime.js. All intermediate times are
/// hours of local solar time (UTC + longitude / 15) on the given day.
private nonisolated struct Engine {
    let latitude: Double
    let longitude: Double
    let utcDay: Double
    let fajr: Double
    let isha: TwilightParameter
    let maghrib: TwilightParameter
    let dhuhrMinutes: Double
    let shadowFactor: Double
    let highLats: HighLatitudeRule

    private static let horizon = 0.833

    private struct Times {
        var fajr = 5.0
        var sunrise = 6.0
        var dhuhr = 12.0
        var asr = 13.0
        var sunset = 18.0
        var maghrib = 18.0
        var isha = 18.0
    }

    func computeTimes() -> PrayerTimes {
        var times = processTimes(Times())
        adjustHighLats(&times)
        updateTimes(&times)
        return PrayerTimes(
            fajr: convert(times.fajr),
            sunrise: convert(times.sunrise),
            dhuhr: convert(times.dhuhr),
            asr: convert(times.asr),
            sunset: convert(times.sunset),
            maghrib: convert(times.maghrib),
            isha: convert(times.isha)
        )
    }

    private func processTimes(_ times: Times) -> Times {
        Times(
            fajr: angleTime(fajr, times.fajr, direction: -1),
            sunrise: angleTime(Self.horizon, times.sunrise, direction: -1),
            dhuhr: midDay(times.dhuhr),
            asr: angleTime(asrAngle(times.asr), times.asr),
            sunset: angleTime(Self.horizon, times.sunset),
            maghrib: angleTime(maghrib.value, times.maghrib),
            isha: angleTime(isha.value, times.isha)
        )
    }

    private func updateTimes(_ times: inout Times) {
        if maghrib.isMinutes {
            times.maghrib = times.sunset + maghrib.value / 60
        }
        if isha.isMinutes {
            times.isha = times.maghrib + isha.value / 60
        }
        times.dhuhr += dhuhrMinutes / 60
    }

    /// Converts local solar hours to an absolute date, rounded to the nearest minute.
    private func convert(_ time: Double) -> Date? {
        guard time.isFinite else { return nil }
        let milliseconds = utcDay * 1000 + ((time - longitude / 15) * 3_600_000).rounded(.down)
        let rounded = (milliseconds / 60_000).rounded(.toNearestOrAwayFromZero) * 60_000
        return Date(timeIntervalSince1970: rounded / 1000)
    }

    // MARK: Sun position

    private func sunPosition(_ time: Double) -> (declination: Double, equation: Double) {
        let d = utcDay / 86_400 - 10_957.5 + time / 24 - longitude / 360

        let g = mod(357.529 + 0.98560028 * d, 360)
        let q = mod(280.459 + 0.98564736 * d, 360)
        let l = mod(q + 1.915 * dsin(g) + 0.020 * dsin(2 * g), 360)
        let e = 23.439 - 0.00000036 * d
        let ra = mod(darctan2(dcos(e) * dsin(l), dcos(l)) / 15, 24)

        return (darcsin(dsin(e) * dsin(l)), q / 15 - ra)
    }

    private func midDay(_ time: Double) -> Double {
        mod(12 - sunPosition(time).equation, 24)
    }

    /// Time at which the sun reaches `angle` degrees below the horizon.
    private func angleTime(_ angle: Double, _ time: Double, direction: Double = 1) -> Double {
        let declination = sunPosition(time).declination
        let numerator = -dsin(angle) - dsin(latitude) * dsin(declination)
        let diff = darccos(numerator / (dcos(latitude) * dcos(declination))) / 15
        return midDay(time) + diff * direction
    }

    private func asrAngle(_ time: Double) -> Double {
        let declination = sunPosition(time).declination
        return -darccot(shadowFactor + dtan(abs(latitude - declination)))
    }

    // MARK: Higher latitudes

    private func adjustHighLats(_ times: inout Times) {
        guard highLats != .none else { return }
        let night = 24 + times.sunrise - times.sunset
        times.fajr = adjustTime(times.fajr, base: times.sunrise, angle: fajr, night: night, direction: -1)
        times.isha = adjustTime(times.isha, base: times.sunset, angle: isha.value, night: night)
        times.maghrib = adjustTime(times.maghrib, base: times.sunset, angle: maghrib.value, night: night)
    }

    private func adjustTime(_ time: Double, base: Double, angle: Double, night: Double, direction: Double = 1) -> Double {
        let factor: Double = switch highLats {
        case .nightMiddle: 1.0 / 2
        case .oneSeventh: 1.0 / 7
        case .angleBased: angle / 60
        case .none: .nan
        }
        let portion = factor * night
        let timeDiff = (time - base) * direction
        if time.isNaN || timeDiff > portion {
            return base + portion * direction
        }
        return time
    }

    // MARK: Math

    private func mod(_ a: Double, _ b: Double) -> Double {
        let r = a.truncatingRemainder(dividingBy: b)
        return r < 0 ? r + b : r
    }

    private func dsin(_ d: Double) -> Double { sin(d * .pi / 180) }
    private func dcos(_ d: Double) -> Double { cos(d * .pi / 180) }
    private func dtan(_ d: Double) -> Double { tan(d * .pi / 180) }
    private func darcsin(_ x: Double) -> Double { asin(x) * 180 / .pi }
    private func darccos(_ x: Double) -> Double { acos(x) * 180 / .pi }
    private func darccot(_ x: Double) -> Double { atan(1 / x) * 180 / .pi }
    private func darctan2(_ y: Double, _ x: Double) -> Double { atan2(y, x) * 180 / .pi }
}
