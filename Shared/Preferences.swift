//
//  Preferences.swift
//  Sujud
//
//  The calculation settings live in the system Settings app on iOS
//  (Settings.bundle), in the Settings window on macOS, and are synced
//  from the iPhone on watchOS. Only these few preferences are ever stored.
//

import Foundation

nonisolated enum Preferences {
    static let appGroup = "group.com.omarahmed.sujud"
    static let methodKey = "calculationMethod"
    static let asrKey = "asrMethod"

    /// Shared with widgets through the app group. Settings.bundle writes
    /// here via its `ApplicationGroupContainerIdentifier`.
    static var store: UserDefaults {
        #if os(macOS)
        .standard
        #else
        UserDefaults(suiteName: appGroup) ?? .standard
        #endif
    }

    static var method: CalculationMethod {
        value(forKey: methodKey).flatMap(CalculationMethod.init(rawValue:)) ?? .default
    }

    static var asr: AsrMethod {
        value(forKey: asrKey).flatMap(AsrMethod.init(rawValue:)) ?? .default
    }

    /// Falls back to the app's own defaults in case the Settings app wrote
    /// there (e.g. when the app group isn't provisioned).
    private static func value(forKey key: String) -> String? {
        store.string(forKey: key) ?? UserDefaults.standard.string(forKey: key)
    }

    static var calculator: PrayTimes {
        PrayTimes(method: method, asr: asr)
    }

    static func update(method: String?, asr: String?) {
        let store = store
        if let method, CalculationMethod(rawValue: method) != nil {
            store.set(method, forKey: methodKey)
        }
        if let asr, AsrMethod(rawValue: asr) != nil {
            store.set(asr, forKey: asrKey)
        }
    }
}
