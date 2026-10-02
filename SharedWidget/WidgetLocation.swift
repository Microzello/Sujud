//
//  WidgetLocation.swift
//  Sujud
//
//  Widgets get the location straight from the system rather than from
//  anything the app saved.
//

import CoreLocation

enum WidgetLocation {
    static func current() async -> CLLocation? {
        let manager = CLLocationManager()
        if let location = manager.location {
            return location
        }
        #if os(iOS)
        guard manager.isAuthorizedForWidgetUpdates else { return nil }
        #endif
        return await freshLocation(timeout: .seconds(10))
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
