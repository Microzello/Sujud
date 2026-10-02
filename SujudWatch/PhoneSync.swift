//
//  PhoneSync.swift
//  SujudWatch
//
//  Receives the calculation settings from the iPhone's Settings app.
//

import WatchConnectivity
import WidgetKit

final class PhoneSync: NSObject, WCSessionDelegate {
    static let shared = PhoneSync()

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    private func apply(method: String?, asr: String?) {
        guard method != Preferences.method.rawValue || asr != Preferences.asr.rawValue else { return }
        Preferences.update(method: method, asr: asr)
        WidgetCenter.shared.reloadAllTimelines()
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        let context = session.receivedApplicationContext
        let method = context[Preferences.methodKey] as? String
        let asr = context[Preferences.asrKey] as? String
        Task { @MainActor in apply(method: method, asr: asr) }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        let method = applicationContext[Preferences.methodKey] as? String
        let asr = applicationContext[Preferences.asrKey] as? String
        Task { @MainActor in apply(method: method, asr: asr) }
    }
}
