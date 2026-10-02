//
//  WatchSync.swift
//  Sujud
//
//  Sends the calculation settings chosen in the iPhone's Settings app to
//  the Apple Watch, which calculates its own times from its own location.
//

#if os(iOS)
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
        try? session.updateApplicationContext([
            Preferences.methodKey: Preferences.method.rawValue,
            Preferences.asrKey: Preferences.asr.rawValue,
        ])
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
