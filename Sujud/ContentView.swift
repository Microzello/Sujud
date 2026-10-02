//
//  ContentView.swift
//  Sujud
//

import CoreLocation
import SwiftUI

struct ContentView: View {
    var body: some View {
        if LocationService.hasCompass {
            TabView {
                Tab("Prayer Times", systemImage: "clock") {
                    PrayerTimesScreen()
                }
                Tab("Qibla", systemImage: "location.north.line") {
                    QiblaScreen()
                }
            }
        } else {
            PrayerTimesScreen()
        }
    }
}

private struct PrayerTimesScreen: View {
    var body: some View {
        LocationGate { location in
            PrayerTimesView(location: location)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.ignoresSafeArea())
    }
}

private struct QiblaScreen: View {
    var body: some View {
        LocationGate { location in
            QiblaView(location: location)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.ignoresSafeArea())
    }
}

#Preview {
    ContentView()
        .environment(LocationService(previewLocation: CLLocation(latitude: 43.6532, longitude: -79.3832)))
}
