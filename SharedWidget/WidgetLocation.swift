//
//  WidgetLocation.swift
//  Sujud
//
//  Widgets get the location from the system when they're allowed to, so
//  they follow the user while travelling, and otherwise use the one the
//  app saved.
//

import CoreLocation

enum WidgetLocation {
    static func current() async -> CLLocation? {
        let manager = CLLocationManager()
        if let location = manager.location {
            return location
        }
        if canUpdate(manager), let location = await freshLocation(timeout: .seconds(10)) {
            return location
        }
        return Preferences.savedLocation
    }

    private static func canUpdate(_ manager: CLLocationManager) -> Bool {
        #if os(iOS)
        manager.isAuthorizedForWidgetUpdates
        #else
        manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways
        #endif
    }

    private static func freshLocation(timeout: Duration) async -> CLLocation? {
        await withTaskGroup(of: CLLocation?.self) { group in
            group.addTask {
                do {
                    for try await update in CLLocationUpdate.liveUpdates() {
                        if let location = update.location {
                            return location
                        }
                        if update.authorizationDenied || update.authorizationRestricted {
                            return nil
                        }
                    }
                } catch {}
                return nil
            }
            group.addTask {
                try? await Task.sleep(for: timeout)
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }
}
