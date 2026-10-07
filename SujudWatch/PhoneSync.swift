//
//  PhoneSync.swift
//  SujudWatch
//
//  Receives the calculation settings from the iPhone's Settings app, and the
//  iPhone's location for when the watch can't find its own.
//

import CoreLocation
import WatchConnectivity
import WidgetKit

final class PhoneSync: NSObject, WCSessionDelegate {
    static let shared = PhoneSync()

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    private func apply(_ context: PhoneSettings) {
        var changed = false
        if context.method != Preferences.method.rawValue || context.asr != Preferences.asr.rawValue {
            Preferences.update(method: context.method, asr: context.asr)
            changed = true
        }
        if let coordinate = context.coordinate, coordinate.latitude != Preferences.savedLocation?.coordinate.latitude
            || coordinate.longitude != Preferences.savedLocation?.coordinate.longitude {
            Preferences.save(coordinate)
            changed = true
        }
        if changed {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        let settings = PhoneSettings(session.receivedApplicationContext)
        Task { @MainActor in apply(settings) }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        let settings = PhoneSettings(applicationContext)
        Task { @MainActor in apply(settings) }
    }
}

/// What the iPhone sends, read from its application context.
private nonisolated struct PhoneSettings: Sendable {
    let method: String?
    let asr: String?
    let coordinate: CLLocationCoordinate2D?

    init(_ context: [String: Any]) {
        method = context[Preferences.methodKey] as? String
        asr = context[Preferences.asrKey] as? String
        if let latitude = context[Preferences.latitudeKey] as? Double,
           let longitude = context[Preferences.longitudeKey] as? Double {
            coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        } else {
            coordinate = nil
        }
    }
}
