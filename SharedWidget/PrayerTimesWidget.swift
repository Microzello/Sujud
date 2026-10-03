//
//  PrayerTimesWidget.swift
//  Sujud
//
//  All six times on the Home Screen, with the next prayer's countdown.
//

#if os(iOS)
import SwiftUI
import WidgetKit

struct PrayerTimesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PrayerTimes", provider: PrayerTimelineProvider()) { entry in
            PrayerTimesWidgetView(entry: entry)
                .containerBackground(.widgetBackground, for: .widget)
        }
        .configurationDisplayName("Prayer Times")
        .description("Today’s prayer times and the countdown to the next.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct PrayerTimesWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PrayerEntry

    var body: some View {
        if entry.next == nil {
            OpenAppView()
        } else {
            switch family {
            case .systemMedium:
                PrayerPairView(entry: entry)
            case .systemLarge:
                PrayerListView(entry: entry, isLarge: true)
            default:
                PrayerListView(entry: entry)
            }
        }
    }
}

#Preview("Small", as: .systemSmall) {
    PrayerTimesWidget()
} timeline: {
    PrayerEntry.sample
}

#Preview("Medium", as: .systemMedium) {
    PrayerTimesWidget()
} timeline: {
    PrayerEntry.sample
}

#Preview("Large", as: .systemLarge) {
    PrayerTimesWidget()
} timeline: {
    PrayerEntry.sample
}
#endif
