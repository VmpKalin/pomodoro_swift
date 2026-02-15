//
//  PomodoroActivityAttributes.swift
//  PomodoroTimerWidgets
//
//  Shared model — must match the copy in the main app target.
//

#if canImport(ActivityKit)
import ActivityKit
import Foundation

struct PomodoroActivityAttributes: ActivityAttributes {
    var taskName: String
    var isBreak: Bool
    var totalSeconds: Int

    struct ContentState: Codable, Hashable {
        var endDate: Date
        var isPaused: Bool
        var remainingSeconds: Int
    }
}
#endif
