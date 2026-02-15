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
            totalSeconds = (isBreak ? breakMinutes : workMinutes) * 60
            remainingSeconds = totalSeconds
        }
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        // Live Activity on background — don't block the tap
        Task.detached { [weak self] in self?.startOrUpdateLiveActivity() }
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        Task.detached { [weak self] in self?.updateLiveActivityPaused() }
    }

    func reset() {
        pause()
        Task.detached { [weak self] in self?.endLiveActivity() }
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
        Task.detached { [weak self] in self?.endLiveActivity() }

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

    @MainActor
    private func startOrUpdateLiveActivity() {
        #if canImport(ActivityKit)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let remaining = remainingSeconds
        let state = PomodoroActivityAttributes.ContentState(
            endDate: Date.now.addingTimeInterval(TimeInterval(remaining)),
            isPaused: false,
            remainingSeconds: remaining
        )

        if let activity = currentActivity {
            let content = ActivityContent(state: state, staleDate: nil)
            Task.detached {
                await activity.update(content)
            }
        } else {
            let attributes = PomodoroActivityAttributes(
                taskName: taskName,
                isBreak: isBreak,
                totalSeconds: totalSeconds
            )
            do {
                currentActivity = try Activity.request(
                    attributes: attributes,
                    content: ActivityContent(state: state, staleDate: nil),
                    pushType: nil
                )
            } catch {
                print("Live Activity error: \(error.localizedDescription)")
            }
        }
        #endif
    }

    @MainActor
    private func updateLiveActivityPaused() {
        #if canImport(ActivityKit)
        guard let activity = currentActivity else { return }

        let remaining = remainingSeconds
        let state = PomodoroActivityAttributes.ContentState(
            endDate: Date.now.addingTimeInterval(TimeInterval(remaining)),
            isPaused: true,
            remainingSeconds: remaining
        )
        let content = ActivityContent(state: state, staleDate: nil)
        Task.detached {
            await activity.update(content)
        }
        #endif
    }

    @MainActor
    private func endLiveActivity() {
        #if canImport(ActivityKit)
        guard let activity = currentActivity else { return }
        currentActivity = nil

        let finalState = PomodoroActivityAttributes.ContentState(
            endDate: Date.now,
            isPaused: true,
            remainingSeconds: 0
        )
        let content = ActivityContent(state: finalState, staleDate: nil)
        Task.detached {
            await activity.end(content, dismissalPolicy: .immediate)
        }
        #endif
    }
}
