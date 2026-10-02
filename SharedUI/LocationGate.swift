//
//  LocationGate.swift
//  Sujud
//

import CoreLocation
import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Shows `content` once a location is known, otherwise a progress or
/// permission message.
struct LocationGate<Content: View>: View {
    @Environment(LocationService.self) private var locationService
    @ViewBuilder var content: (CLLocation) -> Content

    var body: some View {
        if let location = locationService.location {
            content(location)
        } else if locationService.access == .denied {
            LocationDeniedView()
        } else {
            ProgressView("Locating…")
        }
    }
}

private struct LocationDeniedView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        ContentUnavailableView {
            Label("Location Access Needed", systemImage: "location.slash")
        } description: {
            Text("Sujud needs your location to calculate prayer times and the Qibla direction. Your location never leaves your device.")
        } actions: {
            if let settingsURL {
                Button("Open Settings") {
                    openURL(settingsURL)
                }
            }
        }
    }

    private var settingsURL: URL? {
        #if os(iOS)
        URL(string: UIApplication.openSettingsURLString)
        #elseif os(macOS)
        URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices")
        #else
        nil
        #endif
    }
}
