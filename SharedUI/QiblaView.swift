//
//  QiblaView.swift
//  Sujud
//

import CoreLocation
import SwiftUI

/// A compass whose arrow points to the Kaaba.
struct QiblaView: View {
    let location: CLLocation
    @Environment(LocationService.self) private var locationService

    var body: some View {
        let qibla = Qibla.bearing(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let heading = locationService.heading ?? 0
        let isFacing = locationService.heading != nil
            && abs(Qibla.angleDifference(from: heading, to: qibla)) < 3

        VStack(spacing: Self.spacing) {
            CompassDial(heading: heading, qibla: qibla, isFacing: isFacing)
                .frame(maxWidth: 360, maxHeight: 360)
                .animation(.easeOut(duration: 0.25), value: heading)
            Text(Measurement(value: qibla.rounded(), unit: UnitAngle.degrees), format: .measurement(width: .narrow))
                .font(Self.font)
                .monospacedDigit()
        }
        .padding(Self.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sensoryFeedback(.success, trigger: isFacing) { _, facing in facing }
        .onAppear { locationService.startHeadingUpdates() }
        .onDisappear { locationService.stopHeadingUpdates() }
    }

    #if os(watchOS)
    private static let spacing = 4.0
    private static let padding = 4.0
    private static let font = Font.headline
    #else
    private static let spacing = 32.0
    private static let padding = 32.0
    private static let font = Font.title2.weight(.semibold)
    #endif
}

struct CompassDial: View {
    /// Degrees the device faces, from true north.
    let heading: Double
    /// Bearing to the Kaaba, from true north.
    let qibla: Double
    let isFacing: Bool

    private struct Cardinal: Identifiable {
        let angle: Double
        let label: LocalizedStringKey
        var id: Double { angle }
    }

    private let cardinals = [
        Cardinal(angle: 0, label: "N"),
        Cardinal(angle: 90, label: "E"),
        Cardinal(angle: 180, label: "S"),
        Cardinal(angle: 270, label: "W"),
    ]

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let radius = size / 2

            ZStack {
                // The dial turns so that its north always points north.
                ZStack {
                    ForEach(0..<72, id: \.self) { tick in
                        let isMajor = tick % 6 == 0
                        Rectangle()
                            .fill(tick == 0 ? Color.red : isMajor ? Color.primary : Color.secondary)
                            .frame(width: isMajor ? 2 : 1, height: size * (isMajor ? 0.05 : 0.025))
                            .offset(y: -radius + size * (isMajor ? 0.025 : 0.0125))
                            .rotationEffect(.degrees(Double(tick) * 5))
                    }

                    ForEach(cardinals) { cardinal in
                        Text(cardinal.label)
                            .font(.system(size: size * 0.07, weight: cardinal.angle == 0 ? .bold : .regular))
                            .rotationEffect(.degrees(heading - cardinal.angle))
                            .offset(y: -radius * 0.78)
                            .rotationEffect(.degrees(cardinal.angle))
                    }

                    Text(verbatim: "🕋")
                        .font(.system(size: size * 0.09))
                        .rotationEffect(.degrees(heading - qibla))
                        .offset(y: -radius * 0.56)
                        .rotationEffect(.degrees(qibla))
                }
                .rotationEffect(.degrees(-heading))

                Image(systemName: "location.north.fill")
                    .font(.system(size: size * 0.2))
                    .foregroundStyle(isFacing ? Color.green : Color.primary)
                    .rotationEffect(.degrees(qibla - heading))

                // Marks the direction the device is facing.
                Capsule()
                    .fill(isFacing ? Color.green : Color.primary)
                    .frame(width: 3, height: size * 0.07)
                    .offset(y: -radius - size * 0.02)
            }
            .frame(width: size, height: size)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel(Text("Qibla"))
        .accessibilityValue(Text(Measurement(value: qibla.rounded(), unit: UnitAngle.degrees), format: .measurement(width: .narrow)))
    }
}
