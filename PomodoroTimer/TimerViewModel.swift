//
//  TimerViewModel.swift
//  PomodoroTimer
//
//  Created by Artur Holoiad on 15.02.26.
//

import SwiftUI
#if canImport(ActivityKit)
import ActivityKit
#endif

@Observable
class TimerViewModel {

    // MARK: - User Settings
    var workMinutesText: String = "25"
    var breakMinutesText: String = "5"
    var taskName: String = ""
    var selectedSound: AlertSound = .chime

    // MARK: - Notifications
    var notificationManager = NotificationManager()

    // MARK: - Timer State
    var totalSeconds: Int = 25 * 60
    var remainingSeconds: Int = 25 * 60
    var isRunning: Bool = false
    var isBreak: Bool = false
    var completedSessions: Int = 0

    // MARK: - Internal
    private var timer: Timer?

    #if canImport(ActivityKit)
    private var currentActivity: Activity<PomodoroActivityAttributes>?
    #endif

    // MARK: - Computed Properties

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }

    var timeString: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var minutesRemaining: Int {
        remainingSeconds / 60
    }

    var secondsRemaining: Int {
        remainingSeconds % 60
    }

    var statusText: String {
        if !isRunning && remainingSeconds == totalSeconds {
            return "Ready to focus"
        } else if isRunning && !isBreak {
            return "Stay focused..."
        } else if isRunning && isBreak {
            return "Take a breather"
        } else if !isRunning && remainingSeconds < totalSeconds {
            return "Paused"
        }
        return ""
    }

    var accentColor: Color {
        isBreak
            ? Color(red: 0.3, green: 0.82, blue: 0.65)   // soft mint green
            : Color(red: 0.96, green: 0.38, blue: 0.42)   // warm coral
    }

    var backgroundGradient: LinearGradient {
        if isBreak {
            return LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.08, blue: 0.12),
                    Color(red: 0.05, green: 0.12, blue: 0.11),
                    Color(red: 0.07, green: 0.1, blue: 0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.06, blue: 0.12),
                    Color(red: 0.1, green: 0.06, blue: 0.13),
                    Color(red: 0.08, green: 0.07, blue: 0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Parsed Values

    private var workMinutes: Int {
        max(1, Int(workMinutesText) ?? 25)
    }

    private var breakMinutes: Int {
        max(1, Int(breakMinutesText) ?? 5)
    }

    // MARK: - Actions

    func startPause() {
        if isRunning {
            pause()
        } else {
            start()
        }
    }

    func start() {
        if remainingSeconds == totalSeconds || remainingSeconds == 0 {
            // Fresh start
            totalSeconds = (isBreak ? breakMinutes : workMinutes) * 60
            remainingSeconds = totalSeconds
        }
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.tick()
            }
        }
        startOrUpdateLiveActivity()
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        updateLiveActivityPaused()
    }

    func reset() {
        pause()
        endLiveActivity()
        isBreak = false
        totalSeconds = workMinutes * 60
        remainingSeconds = totalSeconds
    }

    func skip() {
        pause()
        finishSession()
    }

    private func tick() {
        guard remainingSeconds > 0 else { return }
        remainingSeconds -= 1
        if remainingSeconds == 0 {
            finishSession()
        }
    }

    private func finishSession() {
        pause()
        endLiveActivity()

        // Play alert sound
        selectedSound.playAlert()

        // Send lock screen notification (isBreak is current state, before toggle)
        notificationManager.sendTimerFinished(isBreak: isBreak, taskName: taskName)

        if !isBreak {
            completedSessions += 1
        }
        isBreak.toggle()
        totalSeconds = (isBreak ? breakMinutes : workMinutes) * 60
        remainingSeconds = totalSeconds
    }

    // MARK: - Live Activity

    private func startOrUpdateLiveActivity() {
        #if canImport(ActivityKit)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = PomodoroActivityAttributes(
            taskName: taskName,
            isBreak: isBreak,
            totalSeconds: totalSeconds
        )

        let state = PomodoroActivityAttributes.ContentState(
            endDate: Date.now.addingTimeInterval(TimeInterval(remainingSeconds)),
            isPaused: false,
            remainingSeconds: remainingSeconds
        )

        // If there's already an activity, update it; otherwise start new
        if let activity = currentActivity {
            Task {
                await activity.update(
                    ActivityContent(state: state, staleDate: nil)
                )
            }
        } else {
            do {
                let activity = try Activity.request(
                    attributes: attributes,
                    content: ActivityContent(state: state, staleDate: nil),
                    pushType: nil
                )
                currentActivity = activity
            } catch {
                print("Failed to start Live Activity: \(error.localizedDescription)")
            }
        }
        #endif
    }

    private func updateLiveActivityPaused() {
        #if canImport(ActivityKit)
        guard let activity = currentActivity else { return }

        let state = PomodoroActivityAttributes.ContentState(
            endDate: Date.now.addingTimeInterval(TimeInterval(remainingSeconds)),
            isPaused: true,
            remainingSeconds: remainingSeconds
        )

        Task {
            await activity.update(
                ActivityContent(state: state, staleDate: nil)
            )
        }
        #endif
    }

    private func endLiveActivity() {
        #if canImport(ActivityKit)
        guard let activity = currentActivity else { return }

        let finalState = PomodoroActivityAttributes.ContentState(
            endDate: Date.now,
            isPaused: true,
            remainingSeconds: 0
        )

        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }
        currentActivity = nil
        #endif
    }
}
