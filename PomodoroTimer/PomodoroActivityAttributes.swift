//
//  PomodoroActivityAttributes.swift
//  PomodoroTimer
//
//  Created by Artur Holoiad on 15.02.26.
//

#if canImport(ActivityKit)
import ActivityKit
import Foundation

struct PomodoroActivityAttributes: ActivityAttributes {
    // Static data — set when the activity starts
    var taskName: String
    var isBreak: Bool
    var totalSeconds: Int

    // Dynamic data — updated during the activity
    struct ContentState: Codable, Hashable {
        var endDate: Date
        var isPaused: Bool
        var remainingSeconds: Int
    }
}
#endif
