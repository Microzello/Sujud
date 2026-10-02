//
//  SujudWatchApp.swift
//  SujudWatch
//

import CoreLocation
import SwiftUI
import WidgetKit

@main
struct SujudWatchApp: App {
    @State private var locationService = LocationService()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        PhoneSync.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environment(locationService)
                .onChange(of: scenePhase, initial: true) { _, phase in
                    if phase == .active {
                        locationService.refresh()
                    }
                }
                .onChange(of: locationService.location) {
                    WidgetCenter.shared.reloadAllTimelines()
                }
        }
    }
}

struct WatchContentView: View {
    var body: some View {
        if LocationService.hasCompass {
            TabView {
                LocationGate { PrayerTimesView(location: $0) }
                LocationGate { QiblaView(location: $0) }
            }
            .tabViewStyle(.verticalPage)
        } else {
            LocationGate { PrayerTimesView(location: $0) }
        }
    }
}

#Preview {
    WatchContentView()
        .environment(LocationService(previewLocation: CLLocation(latitude: 43.6532, longitude: -79.3832)))
}
