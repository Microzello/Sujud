//
//  SujudApp.swift
//  Sujud
//
//  Created by Omar on 2026-09-30.
//

import CoreLocation
import SwiftUI
import WidgetKit

@main
struct SujudApp: App {
    @State private var locationService = LocationService()
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage(Preferences.methodKey, store: Preferences.store)
    private var method = CalculationMethod.default.rawValue
    @AppStorage(Preferences.asrKey, store: Preferences.store)
    private var asr = AsrMethod.default.rawValue

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(locationService)
                .onChange(of: scenePhase, initial: true) { _, phase in
                    guard phase == .active else { return }
                    // Settings may have changed in the Settings app while we were away.
                    locationService.refresh()
                    settingsDidChange()
                }
                .onChange(of: "\(method)/\(asr)") {
                    settingsDidChange()
                }
                .onChange(of: locationService.location) {
                    rescheduleNotifications()
                }
        }
        #if os(macOS)
        .defaultSize(width: 440, height: 720)
        // A seamless window, like the Clock app.
        .windowStyle(.hiddenTitleBar)
        .windowBackgroundDragBehavior(.enabled)
        #endif
        #if os(iOS)
        .backgroundTask(.appRefresh(NotificationScheduler.refreshTaskIdentifier)) {
            await NotificationScheduler.refreshInBackground()
        }
        #endif

        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }

    private func settingsDidChange() {
        #if os(iOS)
        PrayerLiveActivity.endFinished()
        WatchSync.shared.activate()
        WatchSync.shared.push()
        WidgetCenter.shared.reloadAllTimelines()
        #endif
        rescheduleNotifications()
    }

    private func rescheduleNotifications() {
        guard let location = locationService.location else { return }
        Task { await NotificationScheduler.reschedule(for: location) }
    }
}
