//
//  WidgetViews.swift
//  Sujud
//
//  Home Screen widget layouts, kept as plain as the app.
//

import SwiftUI
import WidgetKit

/// "Maghrib in 1:23:45", counting down live.
struct NextPrayerStatus: View {
    let next: PrayerEvent

    var body: some View {
        Text("\(next.prayer.localizedName) in \(Text(next.date, style: .timer))")
            .monospacedDigit()
    }
}

/// The next prayer, how long until then, and when it is, centered and large.
struct NextPrayerHomeView: View {
    let next: PrayerEvent
    var isLarge = false

    var body: some View {
        VStack(spacing: isLarge ? 10 : 2) {
            Text(next.prayer.localizedName)
                .font(.system(size: isLarge ? 64 : 34, weight: .bold))
                .widgetAccentable()
            Text("in \(Text(next.date, style: .timer))")
                .font(.system(size: isLarge ? 44 : 24, weight: .semibold))
                .monospacedDigit()
            Text("at \(next.date, format: .dateTime.hour().minute())")
                .font(.system(size: isLarge ? 32 : 18))
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Two columns of names and times, under the countdown in bold.
struct PrayerListView: View {
    let entry: PrayerEntry
    var isLarge = false
    var showsStatus = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showsStatus, let next = entry.next {
                NextPrayerStatus(next: next)
                    .font(isLarge ? .title.bold() : .subheadline.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .widgetAccentable()
                    .frame(maxHeight: .infinity, alignment: .top)
            }
            ForEach(Prayer.allCases) { prayer in
                HStack {
                    Text(prayer.localizedName)
                    Spacer(minLength: 4)
                    if let date = entry.times[prayer] {
                        Text(date, format: .dateTime.hour().minute())
                    } else {
                        Text(verbatim: "—")
                    }
                }
                .font(isLarge ? .title2 : .footnote)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxHeight: .infinity)
            }
        }
    }
}

/// The two small widgets side by side. The countdown appears once, on the left.
struct PrayerPairView: View {
    let entry: PrayerEntry

    var body: some View {
        HStack(spacing: 16) {
            if let next = entry.next {
                NextPrayerHomeView(next: next)
            }
            PrayerListView(entry: entry, showsStatus: false)
        }
    }
}


/// Shown until the app has been opened and location allowed.
struct OpenAppView: View {
    var body: some View {
        Text("Open Sujud")
            .font(.headline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// White in light mode, black in dark mode, like the app.
extension ShapeStyle where Self == Color {
    static var widgetBackground: Color {
        #if os(iOS)
        Color(uiColor: .systemBackground)
        #else
        .black
        #endif
    }
}
