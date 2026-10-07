//
//  LocationService.swift
//  Sujud
//

import CoreLocation
import Observation
#if os(iOS)
import UIKit
#endif

/// The location prayer times are calculated for: the device's own when
/// Location Services are allowed, otherwise the last one saved (a place
/// chosen on the map, or synced from the iPhone on the watch). Also reports
/// the compass heading while the Qibla screen is visible.
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
    @ObservationIgnored private var deviceLocationWaiters: [CheckedContinuation<CLLocation?, Never>] = []

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
        // The system's last known fix, if allowed, so times appear instantly on launch.
        location = (access == .authorized ? manager.location : nil) ?? Preferences.savedLocation
        NotificationCenter.default.addObserver(
            self, selector: #selector(savedLocationDidChange),
            name: Preferences.locationDidChange, object: nil
        )
    }

    /// A fixed location for SwiftUI previews, which can't use Location Services.
    init(previewLocation: CLLocation) {
        super.init()
        location = previewLocation
        access = .authorized
    }

    /// Updates the location from the device, if allowed, in case the user
    /// is travelling. On iPhone and Mac permission is only ever requested
    /// from the location picker.
    func refresh() {
        switch manager.authorizationStatus {
        case .notDetermined:
            #if os(watchOS)
            // The watch has no map, so it asks straight away; the place
            // chosen on the iPhone is the fallback.
            manager.requestWhenInUseAuthorization()
            #endif
        case .denied, .restricted:
            break
        default:
            manager.requestLocation()
        }
    }

    /// Asks for permission if needed, then waits for the device's location
    /// and uses it. Nil if permission is denied or the location can't be found.
    func requestDeviceLocation() async -> CLLocation? {
        await withCheckedContinuation { continuation in
            deviceLocationWaiters.append(continuation)
            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .denied, .restricted:
                resolveDeviceLocationWaiters(with: nil)
            default:
                manager.requestLocation()
            }
        }
    }

    /// Uses a place chosen on the map.
    func choose(_ coordinate: CLLocationCoordinate2D) {
        use(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
    }

    private func use(_ newLocation: CLLocation) {
        location = newLocation
        Preferences.save(newLocation.coordinate)
    }

    private func resolveDeviceLocationWaiters(with result: CLLocation?) {
        let waiters = deviceLocationWaiters
        deviceLocationWaiters.removeAll()
        for waiter in waiters {
            waiter.resume(returning: result)
        }
    }

    /// The iPhone synced a new location to the watch.
    @objc private func savedLocationDidChange() {
        guard access != .authorized || location == nil, let saved = Preferences.savedLocation,
              saved.coordinate.latitude != location?.coordinate.latitude
                || saved.coordinate.longitude != location?.coordinate.longitude else { return }
        location = saved
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
            switch access {
            case .authorized: manager.requestLocation()
            case .denied: resolveDeviceLocationWaiters(with: nil)
            case .undetermined: break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        MainActor.assumeIsolated {
            use(latest)
            resolveDeviceLocationWaiters(with: latest)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        // Keep the current location; the next refresh will try again.
        MainActor.assumeIsolated {
            resolveDeviceLocationWaiters(with: nil)
        }
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
