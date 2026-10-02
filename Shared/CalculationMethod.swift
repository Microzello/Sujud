//
//  CalculationMethod.swift
//  Sujud
//

import Foundation

/// Calculation conventions from https://praytimes.org/docs/methods.
/// Raw values are stored in preferences and must stay stable.
nonisolated enum CalculationMethod: String, CaseIterable, Identifiable, Sendable {
    case mwl = "MWL"
    case isna = "ISNA"
    case egypt = "Egypt"
    case makkah = "Makkah"
    case karachi = "Karachi"
    case tehran = "Tehran"
    case jafari = "Jafari"
    case france = "France"
    case russia = "Russia"
    case singapore = "Singapore"

    static let `default` = CalculationMethod.mwl

    var id: String { rawValue }

    var fajrAngle: Double {
        switch self {
        case .mwl: 18
        case .isna: 15
        case .egypt: 19.5
        case .makkah: 18.5
        case .karachi: 18
        case .tehran: 17.7
        case .jafari: 16
        case .france: 12
        case .russia: 16
        case .singapore: 20
        }
    }

    var isha: TwilightParameter {
        switch self {
        case .mwl: .degrees(17)
        case .isna: .degrees(15)
        case .egypt: .degrees(17.5)
        case .makkah: .minutes(90)
        case .karachi: .degrees(18)
        case .tehran, .jafari: .degrees(14)
        case .france: .degrees(12)
        case .russia: .degrees(15)
        case .singapore: .degrees(18)
        }
    }

    var maghrib: TwilightParameter {
        switch self {
        case .tehran: .degrees(4.5)
        case .jafari: .degrees(4)
        default: .minutes(1)
        }
    }

    var localizedName: String {
        switch self {
        case .mwl: String(localized: "Muslim World League")
        case .isna: String(localized: "Islamic Society of North America")
        case .egypt: String(localized: "Egyptian General Authority of Survey")
        case .makkah: String(localized: "Umm al-Qura University, Makkah")
        case .karachi: String(localized: "University of Islamic Sciences, Karachi")
        case .tehran: String(localized: "Institute of Geophysics, University of Tehran")
        case .jafari: String(localized: "Leva Research Institute, Qom")
        case .france: String(localized: "Muslims of France")
        case .russia: String(localized: "Spiritual Administration of Muslims of Russia")
        case .singapore: String(localized: "Islamic Religious Council of Singapore")
        }
    }
}

/// Juristic convention for the start of Asr.
nonisolated enum AsrMethod: String, CaseIterable, Identifiable, Sendable {
    /// Shafi'i, Maliki, Hanbali and Ja'fari: shadow equals object length.
    case standard = "Standard"
    /// Hanafi: shadow equals twice the object length.
    case hanafi = "Hanafi"

    static let `default` = AsrMethod.standard

    var id: String { rawValue }

    var shadowFactor: Double {
        switch self {
        case .standard: 1
        case .hanafi: 2
        }
    }

    var localizedName: String {
        switch self {
        case .standard: String(localized: "Standard (Shafi‘i, Maliki, Hanbali)")
        case .hanafi: String(localized: "Hanafi")
        }
    }
}
