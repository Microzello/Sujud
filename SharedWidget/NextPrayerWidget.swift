//
//  NextPrayerWidget.swift
//  Sujud
//
//  Counts down to the next prayer: on the Lock Screen, the Home Screen
//  (small and large), and as Apple Watch complications.
//

import SwiftUI
import WidgetKit

struct NextPrayerWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NextPrayer", provider: PrayerTimelineProvider()) { entry in
            NextPrayerWidgetView(entry: entry)
                .containerBackground(.widgetBackground, for: .widget)
        }
        .configurationDisplayName("Next Prayer")
        .description("Counts down to the next prayer.")
        .supportedFamilies(Self.families)
    }

    #if os(watchOS)
    private static let families: [WidgetFamily] = [.accessoryCircular, .accessoryCorner, .accessoryRectangular, .accessoryInline]
    #else
    private static let families: [WidgetFamily] = [.accessoryCircular, .accessoryRectangular, .accessoryInline, .systemSmall, .systemLarge]
    #endif
}

struct NextPrayerWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PrayerEntry

    var body: some View {
        if let next = entry.next {
            switch family {
            case .accessoryCircular:
                // A ring that fills from the last prayer to the next.
                Gauge(value: entry.progress) {
                    Text(next.prayer.localizedName)
                } currentValueLabel: {
                    Text(next.date, style: .timer)
                        .monospacedDigit()
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.5)
                }
                .gaugeStyle(.accessoryCircular)
            case .accessoryInline:
                NextPrayerStatus(next: next)
            #if os(watchOS)
            case .accessoryCorner:
                Text(next.date, style: .timer)
                    .monospacedDigit()
                    .widgetCurvesContent()
                    .widgetLabel {
                        Text(next.prayer.localizedName)
                    }
            #else
            case .systemSmall:
                NextPrayerHomeView(next: next)
            case .systemLarge:
                NextPrayerHomeView(next: next, isLarge: true)
            #endif
            default:
                VStack(alignment: .leading, spacing: 0) {
                    Text(next.prayer.localizedName)
                        .font(.headline)
                        .widgetAccentable()
                    Text(next.date, style: .timer)
                        .font(.title2.weight(.semibold))
                        .monospacedDigit()
                    Text(next.date, format: .dateTime.hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            switch family {
            case .accessoryCircular:
                Image(systemName: "location.slash")
                    .font(.title2)
            case .accessoryInline:
                Text("Open Sujud")
            default:
                OpenAppView()
            }
        }
    }
}

#if os(iOS)
#Preview("Small", as: .systemSmall) {
    NextPrayerWidget()
} timeline: {
    PrayerEntry.sample
}

#Preview("Large", as: .systemLarge) {
    NextPrayerWidget()
} timeline: {
    PrayerEntry.sample
}
#endif

#Preview("Circular", as: .accessoryCircular) {
    NextPrayerWidget()
} timeline: {
    PrayerEntry.sample
}

#Preview("Rectangular", as: .accessoryRectangular) {
    NextPrayerWidget()
} timeline: {
    PrayerEntry.sample
}

#if os(watchOS)
#Preview("Corner", as: .accessoryCorner) {
    NextPrayerWidget()
} timeline: {
    PrayerEntry.sample
}
#endif
