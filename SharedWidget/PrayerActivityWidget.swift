//
//  PrayerActivityWidget.swift
//  Sujud
//
//  The Live Activity started by tapping a prayer in the app.
//

#if os(iOS)
import ActivityKit
import SwiftUI
import WidgetKit

struct PrayerActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PrayerActivityAttributes.self) { context in
            PrayerActivityLockScreenView(attributes: context.attributes)
        } dynamicIsland: { context in
            let attributes = context.attributes
            let prayer = attributes.prayerValue
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(prayer.localizedName)
                        .font(.headline)
                        .padding(.leading, 6)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(attributes.date, format: .dateTime.hour().minute())
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 6)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    PrayerActivityCountdown(attributes: attributes)
                        .font(.system(size: 40, weight: .semibold))
                        .multilineTextAlignment(.center)
                }
            } compactLeading: {
                Text(prayer.shortName)
            } compactTrailing: {
                PrayerActivityCountdown(attributes: attributes)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 64)
            } minimal: {
                Text(prayer.shortName)
                    .font(.caption2)
                    .minimumScaleFactor(0.5)
            }
        }
    }
}

/// Counts down to the prayer and stops at zero.
struct PrayerActivityCountdown: View {
    let attributes: PrayerActivityAttributes

    var body: some View {
        Text(timerInterval: attributes.startDate...max(attributes.startDate, attributes.date), countsDown: true)
            .monospacedDigit()
    }
}

/// Lock Screen and banner: the prayer and its time, with the countdown beside them.
struct PrayerActivityLockScreenView: View {
    let attributes: PrayerActivityAttributes

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(attributes.prayerValue.localizedName)
                    .font(.title2.bold())
                Text("at \(attributes.date, format: .dateTime.hour().minute())")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            PrayerActivityCountdown(attributes: attributes)
                .font(.system(size: 40, weight: .semibold))
                .multilineTextAlignment(.trailing)
        }
        .padding(20)
    }
}

#Preview("Lock Screen", as: .content, using: PrayerActivityAttributes(prayer: "maghrib", date: .now.addingTimeInterval(5025), startDate: .now)) {
    PrayerActivityWidget()
} contentStates: {
    PrayerActivityAttributes.ContentState()
}
#endif
