//
//  TimeFormatting.swift
//  Sujud
//

import Foundation

/// Splits a time into its digits and its AM/PM marker, so the marker can be
/// drawn smaller (as the Clock app does) or left out where space is tight.
/// `Date.FormatStyle` pads the hour ("05:39") once AM/PM is omitted, so this
/// works from the locale's own pattern instead.
nonisolated enum TimeFormatting {
    /// "5:39" with a 12-hour clock, "05:39" with a 24-hour clock.
    static func hourMinute(_ date: Date, locale: Locale, timeZone: TimeZone) -> String {
        formatter(pattern: digitsPattern(locale: locale), locale: locale, timeZone: timeZone).string(from: date)
    }

    /// "PM" when the locale uses a 12-hour clock, otherwise nil.
    static func dayPeriod(_ date: Date, locale: Locale, timeZone: TimeZone) -> String? {
        guard fullPattern(locale: locale).contains(where: dayPeriodLetters.contains) else { return nil }
        let formatter = formatter(pattern: "", locale: locale, timeZone: timeZone)
        formatter.setLocalizedDateFormatFromTemplate("a")
        return formatter.string(from: date)
    }

    private static let dayPeriodLetters: Set<Character> = ["a", "b", "B"]

    private static func fullPattern(locale: Locale) -> String {
        DateFormatter.dateFormat(fromTemplate: "jmm", options: 0, locale: locale) ?? "HH:mm"
    }

    /// The locale's hour-and-minute pattern with any day period removed,
    /// leaving quoted literals alone.
    private static func digitsPattern(locale: Locale) -> String {
        var result = ""
        var isQuoted = false
        for character in fullPattern(locale: locale) {
            if character == "'" { isQuoted.toggle() }
            if !isQuoted, dayPeriodLetters.contains(character) { continue }
            result.append(character)
        }
        return result.trimmingCharacters(in: .whitespaces.union(CharacterSet(charactersIn: "\u{200E}\u{200F}")))
    }

    private static func formatter(pattern: String, locale: Locale, timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateFormat = pattern
        return formatter
    }
}
