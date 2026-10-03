//
//  SujudUITests.swift
//  SujudUITests
//
//  Created by Omar on 2026-09-30.
//

import XCTest

final class SujudUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Walks through both tabs. Needs location access, e.g.
    /// `xcrun simctl privacy booted grant location com.omarahmed.sujud`.
    @MainActor
    func testPrayerTimesAndQibla() throws {
        let app = XCUIApplication()
        app.launch()

        // The first launch asks for notification permission.
        let allow = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Allow"]
        if allow.waitForExistence(timeout: 5) {
            allow.tap()
        }

        for prayer in ["Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"] {
            let row = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", prayer)).firstMatch
            XCTAssertTrue(row.waitForExistence(timeout: 10), "\(prayer) row missing")
        }
        attachScreenshot(named: "Prayer Times")

        let qiblaTab = app.buttons["Qibla"]
        guard qiblaTab.exists else { return }
        qiblaTab.tap()
        XCTAssertTrue(qiblaTab.isSelected)
        sleep(2)
        attachScreenshot(named: "Qibla")
    }

    @MainActor
    private func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
