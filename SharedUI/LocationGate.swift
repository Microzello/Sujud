//
//  LocationGate.swift
//  Sujud
//

import CoreLocation
import SwiftUI

/// Shows `content` once a location is known. On iPhone, iPad and Mac the
/// location picker covers the screen until then.
struct LocationGate<Content: View>: View {
    @Environment(LocationService.self) private var locationService
    @ViewBuilder var content: (CLLocation) -> Content

    var body: some View {
        if let location = locationService.location {
            content(location)
        } else {
            #if os(watchOS)
            if locationService.access == .denied {
                ContentUnavailableView {
                    Label("Location Access Needed", systemImage: "location.slash")
                } description: {
                    Text("Allow location access, or choose a location in Sujud on your iPhone.")
                }
            } else {
                ProgressView("Locating…")
            }
            #else
            Color.clear
            #endif
        }
    }
}
