//
//  TimerViewModel.swift
//  PomodoroTimer
//
//  Created by Artur Holoiad on 15.02.26.
//

import SwiftUI

@Observable
class TimerViewModel {

    // MARK: - User Settings
    var workMinutesText: String = "25"
    var breakMinutesText: String = "5"
    var taskName: String = ""

    // MARK: - Timer State
    var totalSeconds: Int = 25 * 60
    var remainingSeconds: Int = 25 * 60
    var isRunning: Bool = false
    var isBreak: Bool = false
    var completedSessions: Int = 0

    // MARK: - Internal
    private var timer: Timer?

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
        isBreak ? Color(red: 0.35, green: 0.78, blue: 0.62) : Color(red: 0.95, green: 0.4, blue: 0.35)
    }

    var backgroundGradient: LinearGradient {
        if isBreak {
            return LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.12, blue: 0.14),
                    Color(red: 0.1, green: 0.18, blue: 0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.08, blue: 0.14),
                    Color(red: 0.14, green: 0.1, blue: 0.18)
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
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        pause()
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
        if !isBreak {
            completedSessions += 1
        }
        isBreak.toggle()
        totalSeconds = (isBreak ? breakMinutes : workMinutes) * 60
        remainingSeconds = totalSeconds
    }
}
