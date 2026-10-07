//
//  ContentView.swift
//  Sujud
//

import CoreLocation
import SwiftUI

struct ContentView: View {
    @Environment(LocationService.self) private var locationService
    @State private var choosingLocation = false

    var body: some View {
        screens
            .sheet(isPresented: pickerPresented) {
                LocationPicker(initialLocation: locationService.location)
                    // Until there's a location, there's nothing to go back to.
                    .interactiveDismissDisabled(locationService.location == nil)
            }
    }

    /// The picker also opens by itself while no location is known.
    private var pickerPresented: Binding<Bool> {
        Binding(
            get: { choosingLocation || locationService.location == nil },
            set: { choosingLocation = $0 }
        )
    }

    #if os(iOS)
    private enum Screen: Hashable {
        case prayerTimes, qibla, location
    }

    @State private var screen = Screen.prayerTimes

    /// Like Photos: the tabs on the left and, on its own on the right, a
    /// button that opens the location picker rather than a screen.
    private var screens: some View {
        TabView(selection: Binding(
            get: { screen },
            set: { newValue in
                if newValue == .location {
                    choosingLocation = true
                } else {
                    screen = newValue
                }
            }
        )) {
            Tab("Prayer Times", systemImage: "clock", value: .prayerTimes) {
                PrayerTimesScreen()
            }
            if LocationService.hasCompass {
                Tab("Qibla", systemImage: "location.north.line", value: .qibla) {
                    QiblaScreen()
                }
            }
            Tab("Location", systemImage: "map", value: .location, role: .search) {
                Color.clear
            }
        }
    }
    #else
    private var screens: some View {
        PrayerTimesScreen()
            .overlay(alignment: .bottomTrailing) {
                Button("Location", systemImage: "map") {
                    choosingLocation = true
                }
                .labelStyle(.iconOnly)
                .font(.title3)
                .buttonStyle(.borderless)
                .frame(width: 44, height: 44)
                .background(.regularMaterial, in: Circle())
                .padding(16)
            }
    }
    #endif
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
