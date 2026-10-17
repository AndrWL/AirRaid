//
//  DisplayTimeTests.swift
//  AirRaidTests
//

import Foundation
import Testing
@testable import AirRaid

/// Tests for ``DisplayTime/duration(_:)``: how long an alert has lasted, from minutes to the years-long alerts of
/// frontline oblasts.
@MainActor
@Suite
struct DisplayTimeTests {

    @Test(arguments: Constants.durations)
    func duration_whenIntervalGiven_returnsExpected(
        interval: TimeInterval,
        expected: String
    ) {
        #expect(DisplayTime.duration(interval) == expected)
    }
}

// MARK: - Constants

private enum Constants {
    static let minute: TimeInterval = 60
    static let hour: TimeInterval = 3_600
    static let day: TimeInterval = 86_400
    static let durations: [(TimeInterval, String)] = [
        (20 * minute, "20 хв"),
        (hour, "1 год"),
        (hour + 52 * minute, "1 год 52 хв"),
        (2 * day + 5 * hour, "2 д 5 год"),
        (12 * day, "12 д"),
        (95 * day, "понад 3 міс."),
        (1_655 * day, "понад 4 р.")
    ]
}
