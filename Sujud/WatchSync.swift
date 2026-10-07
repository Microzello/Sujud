//
//  WatchSync.swift
//  Sujud
//
//  Sends the calculation settings chosen in the iPhone's Settings app to
//  the Apple Watch, along with the iPhone's location, which the watch uses
//  when it can't find its own.
//

#if os(iOS)
import CoreLocation
import WatchConnectivity

final class WatchSync: NSObject, WCSessionDelegate {
    static let shared = WatchSync()

    func activate() {
        guard WCSession.isSupported(), WCSession.default.activationState == .notActivated else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func push() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated, session.isPaired, session.isWatchAppInstalled else { return }
        var context: [String: Any] = [
            Preferences.methodKey: Preferences.method.rawValue,
            Preferences.asrKey: Preferences.asr.rawValue,
        ]
        if let location = Preferences.savedLocation {
            context[Preferences.latitudeKey] = location.coordinate.latitude
            context[Preferences.longitudeKey] = location.coordinate.longitude
        }
        try? session.updateApplicationContext(context)
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        Task { @MainActor in push() }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Switching to another watch; start talking to the new one.
        session.activate()
    }
}
#endif
