//
//  LocationService.swift
//  Sujud
//

import CoreLocation
import Observation
#if os(iOS)
import UIKit
#endif

/// Asks the device for its location (and compass heading when the Qibla
/// screen is visible). Nothing is persisted.
@MainActor
@Observable
final class LocationService: NSObject {
    enum Access {
        case undetermined, denied, authorized
    }

    private(set) var location: CLLocation?
    private(set) var access: Access = .undetermined
    /// Degrees from true north, unwrapped so that animations never spin
    /// the long way around when crossing north.
    private(set) var heading: Double?

    @ObservationIgnored private let manager = CLLocationManager()
    @ObservationIgnored private var headingClients = 0

    /// Whether this device has a compass. The simulator has none, so it
    /// pretends to face north to keep the Qibla screen previewable.
    static var hasCompass: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        CLLocationManager.headingAvailable()
        #endif
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        updateAccess()
        if access == .authorized {
            // The system's last known fix, so times appear instantly on launch.
            location = manager.location
        }
    }

    /// A fixed location for SwiftUI previews, which can't use Location Services.
    init(previewLocation: CLLocation) {
        super.init()
        location = previewLocation
        access = .authorized
    }

    /// Requests permission if needed, then a fresh one-shot location fix.
    func refresh() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            break
        default:
            manager.requestLocation()
        }
    }

    // Macs have no compass, so heading updates are iOS and watchOS only.
    func startHeadingUpdates() {
        #if !os(macOS)
        headingClients += 1
        guard headingClients == 1, CLLocationManager.headingAvailable() else { return }
        #if os(iOS)
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        updateHeadingOrientation()
        NotificationCenter.default.addObserver(
            self, selector: #selector(deviceOrientationDidChange),
            name: UIDevice.orientationDidChangeNotification, object: nil
        )
        #endif
        manager.headingFilter = 1
        manager.startUpdatingHeading()
        #endif
    }

    func stopHeadingUpdates() {
        #if !os(macOS)
        headingClients = max(headingClients - 1, 0)
        guard headingClients == 0 else { return }
        #if os(iOS)
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        #endif
        manager.stopUpdatingHeading()
        #endif
    }

    private func updateAccess() {
        switch manager.authorizationStatus {
        case .notDetermined: access = .undetermined
        case .denied, .restricted: access = .denied
        default: access = .authorized
        }
    }

    private func apply(heading newValue: Double) {
        guard let heading else {
            self.heading = newValue
            return
        }
        let current = heading.truncatingRemainder(dividingBy: 360)
        self.heading = heading + Qibla.angleDifference(from: current, to: newValue)
    }

    #if os(iOS)
    @objc private func deviceOrientationDidChange() {
        updateHeadingOrientation()
    }

    /// Headings are reported relative to the top of the interface.
    private func updateHeadingOrientation() {
        let orientation = UIDevice.current.orientation
        guard orientation.isPortrait || orientation.isLandscape,
              let value = CLDeviceOrientation(rawValue: Int32(orientation.rawValue)) else { return }
        manager.headingOrientation = value
    }
    #endif
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        MainActor.assumeIsolated {
            updateAccess()
            if access == .authorized {
                manager.requestLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        MainActor.assumeIsolated {
            location = latest
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        // A transient failure; the next refresh will try again.
    }

    #if !os(macOS)
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0 else { return }
        let degrees = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        MainActor.assumeIsolated {
            apply(heading: degrees)
        }
    }

    nonisolated func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        true
    }
    #endif
}
