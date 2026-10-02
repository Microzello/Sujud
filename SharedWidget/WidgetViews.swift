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

/// The next prayer, when it is, and how long until then, centered and large.
struct NextPrayerHomeView: View {
    let next: PrayerEvent
    var isLarge = false

    var body: some View {
        VStack(spacing: isLarge ? 10 : 2) {
            Text(next.prayer.localizedName)
                .font(.system(size: isLarge ? 64 : 34, weight: .bold))
                .widgetAccentable()
            Text("at \(next.date, format: .dateTime.hour().minute())")
                .font(.system(size: isLarge ? 32 : 18))
                .foregroundStyle(.secondary)
            Text("in \(Text(next.date, style: .timer))")
                .font(.system(size: isLarge ? 44 : 24, weight: .semibold))
                .monospacedDigit()
        }
        .multilineTextAlignment(.center)
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// The countdown in bold over two columns of names and times.
struct PrayerListView: View {
    let entry: PrayerEntry
    var isLarge = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let next = entry.next {
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

/// The countdown on top, then the six times side by side.
struct PrayerColumnsView: View {
    let entry: PrayerEntry
    @Environment(\.locale) private var locale
    @Environment(\.timeZone) private var timeZone

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let next = entry.next {
                NextPrayerStatus(next: next)
                    .font(.title.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .widgetAccentable()
            }
            Spacer(minLength: 8)
            HStack(alignment: .top, spacing: 4) {
                ForEach(Prayer.allCases) { prayer in
                    VStack(spacing: 4) {
                        Text(prayer.localizedName)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        if let date = entry.times[prayer] {
                            // The order of the day makes AM and PM clear, so leave them out to fit.
                            Text(TimeFormatting.hourMinute(date, locale: locale, timeZone: timeZone))
                                .font(.title2.weight(.medium))
                        } else {
                            Text(verbatim: "—")
                                .font(.title2)
                        }
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
