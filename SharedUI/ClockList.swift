//
//  ClockList.swift
//  Sujud
//
//  A list laid out like the Clock app's World Clock page: a bold large
//  title, then rows with a grey caption over a name and a large thin time.
//  Metrics were measured from a screenshot of the Clock app.
//

import SwiftUI

struct ClockRow: Identifiable {
    let id: String
    let caption: String
    let name: String
    let date: Date?
}

/// The title and rows, without scrolling.
struct ClockListContent: View {
    let title: String
    let rows: [ClockRow]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(ClockMetrics.titleFont)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.top, ClockMetrics.titleTop)
                .padding(.bottom, ClockMetrics.titleBottom)
            RowSeparator()
            ForEach(rows) { row in
                ClockRowView(row: row)
                RowSeparator()
            }
        }
        .padding(.horizontal, ClockMetrics.margin)
    }
}

struct ClockRowView: View {
    let row: ClockRow

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: ClockMetrics.captionSpacing) {
                Text(row.caption)
                    .font(ClockMetrics.captionFont)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Text(row.name)
                    .font(ClockMetrics.nameFont)
            }
            .lineLimit(1)
            Spacer(minLength: 8)
            if let date = row.date {
                ClockTime(date: date)
            } else {
                Text(verbatim: "—")
                    .font(.system(size: ClockMetrics.timeSize, weight: ClockMetrics.timeWeight))
            }
        }
        .padding(.top, ClockMetrics.rowTop)
        .padding(.bottom, ClockMetrics.rowBottom)
        .accessibilityElement(children: .combine)
    }
}

/// "21:30", or "9:30" with a smaller "PM" when the device uses 12-hour time.
struct ClockTime: View {
    let date: Date
    @Environment(\.locale) private var locale
    @Environment(\.timeZone) private var timeZone

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 4) {
            Text(TimeFormatting.hourMinute(date, locale: locale, timeZone: timeZone))
                .font(.system(size: ClockMetrics.timeSize, weight: ClockMetrics.timeWeight))
            if let dayPeriod = TimeFormatting.dayPeriod(date, locale: locale, timeZone: timeZone) {
                Text(dayPeriod)
                    .font(.system(size: ClockMetrics.timeSize * 0.4, weight: .light))
            }
        }
    }
}

/// A two-pixel line, so it stays visible in scaled previews.
struct RowSeparator: View {
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        Rectangle()
            .fill(.separator)
            .frame(height: 2 / displayScale)
    }
}

enum ClockMetrics {
    static let margin: CGFloat = 20
    /// From the top of the safe area to the top of the title. On iPhone this
    /// leaves room where the navigation bar's buttons would be.
    #if os(macOS)
    static let titleTop: CGFloat = 12
    #else
    static let titleTop: CGFloat = 58
    #endif
    static let titleBottom: CGFloat = 8
    static let rowTop: CGFloat = 7.5
    static let rowBottom: CGFloat = 12.25
    static let captionSpacing: CGFloat = 0
    static let timeSize: CGFloat = 60
    static let timeWeight: Font.Weight = .thin

    #if os(iOS)
    static let titleFont = Font.largeTitle.bold()
    static let captionFont = Font.subheadline
    static let nameFont = Font.title
    #else
    static let titleFont = Font.system(size: 34, weight: .bold)
    static let captionFont = Font.system(size: 15)
    static let nameFont = Font.system(size: 28)
    #endif
}
