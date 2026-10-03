//
//  SujudWidgetsBundle.swift
//  SujudWidgets
//

import SwiftUI
import WidgetKit

@main
struct SujudWidgetsBundle: WidgetBundle {
    var body: some Widget {
        NextPrayerWidget()
        PrayerTimesWidget()
        PrayerActivityWidget()
    }
}
