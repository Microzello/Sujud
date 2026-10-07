//
//  LocationPicker.swift
//  Sujud
//
//  An Apple Maps map with a pin fixed in the middle: move the map to choose
//  where prayer times are calculated for, or use the device's location.
//

import CoreLocation
import MapKit
import SwiftUI

struct LocationPicker: View {
    @Environment(LocationService.self) private var locationService
    @Environment(\.dismiss) private var dismiss
    @State private var position: MapCameraPosition
    @State private var center: CLLocationCoordinate2D?
    @State private var cameraChanges = 0
    @State private var isMoving = false
    @State private var isLocating = false

    /// Opens on `initialLocation`, the place currently in use, if there is one.
    init(initialLocation: CLLocation?) {
        if let coordinate = initialLocation?.coordinate {
            _position = State(initialValue: .camera(MapCamera(centerCoordinate: coordinate, distance: 4000)))
            _center = State(initialValue: coordinate)
        } else {
            _position = State(initialValue: .automatic)
        }
    }

    var body: some View {
        NavigationStack {
            Map(position: $position) {
                if locationService.access == .authorized {
                    UserAnnotation()
                }
            }
            .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .all))
            .onMapCameraChange(frequency: .continuous) { context in
                center = context.region.center
                cameraChanges += 1
            }
            .task(id: cameraChanges) {
                // The pin lifts while the map moves and drops once it stops.
                guard cameraChanges > 0 else { return }
                isMoving = true
                do {
                    try await Task.sleep(for: .milliseconds(200))
                    isMoving = false
                } catch {}
            }
            .overlay {
                CenterPin(isLifted: isMoving)
            }
            .ignoresSafeArea()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Current Location", systemImage: locationSymbol) {
                        Task { await useDeviceLocation() }
                    }
                    .disabled(locationService.access == .denied || isLocating)
                }
                ToolbarItem(placement: .confirmationAction) {
                    confirmButton
                        .disabled(center == nil)
                }
            }
            .labelStyle(.iconOnly)
        }
        .task {
            // The first time Sujud opens, this is when it asks for Location Services.
            if locationService.location == nil, locationService.access == .undetermined {
                await useDeviceLocation()
            }
        }
        #if os(macOS)
        // Fits inside the default window.
        .frame(width: 400, height: 600)
        #endif
    }

    private var locationSymbol: String {
        if locationService.access == .denied {
            "location.slash"
        } else if isLocating {
            "location.fill"
        } else {
            "location"
        }
    }

    @ViewBuilder
    private var confirmButton: some View {
        #if os(iOS)
        Button("Set Location", systemImage: "checkmark", role: .confirm, action: confirm)
        #else
        Button("Set Location", systemImage: "checkmark", action: confirm)
            .keyboardShortcut(.defaultAction)
        #endif
    }

    private func confirm() {
        guard let center else { return }
        locationService.choose(center)
        dismiss()
    }

    /// Uses the device's location and closes, asking for permission first if needed.
    private func useDeviceLocation() async {
        isLocating = true
        let location = await locationService.requestDeviceLocation()
        isLocating = false
        if location != nil {
            dismiss()
        }
    }
}

/// Marks the middle of the map, lifting while the map moves like the pin in Maps.
private struct CenterPin: View {
    let isLifted: Bool

    var body: some View {
        // The pin's point sits exactly on the middle of the map.
        Ellipse()
            .fill(.black.opacity(0.3))
            .frame(width: 8, height: 4)
            .overlay(alignment: .bottom) {
                Image(systemName: "mappin")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 44)
                    .foregroundStyle(.red)
                    .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                    .offset(y: isLifted ? -12 : -2)
            }
            .animation(.spring(duration: 0.25), value: isLifted)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

#Preview {
    LocationPicker(initialLocation: CLLocation(latitude: 43.6532, longitude: -79.3832))
        .environment(LocationService(previewLocation: CLLocation(latitude: 43.6532, longitude: -79.3832)))
}
