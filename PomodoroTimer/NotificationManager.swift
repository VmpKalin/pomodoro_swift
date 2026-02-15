//
//  NotificationManager.swift
//  PomodoroTimer
//
//  Created by Artur Holoiad on 15.02.26.
//

import UserNotifications
import SwiftUI

#if os(iOS)
import AudioToolbox
#endif

// MARK: - Alert Sound

enum AlertSound: String, CaseIterable, Identifiable {
    case chime      = "Chime"
    case bloom      = "Bloom"
    case calypso    = "Calypso"
    case anticipate = "Anticipate"
    case fanfare    = "Fanfare"
    case descent    = "Descent"
    case telegraph  = "Telegraph"
    case bell       = "Bell"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .chime:      return "bell.fill"
        case .bloom:      return "sparkle"
        case .calypso:    return "tropicalstorm"
        case .anticipate: return "waveform"
        case .fanfare:    return "megaphone.fill"
        case .descent:    return "arrow.down.circle.fill"
        case .telegraph:  return "dot.radiowaves.right"
        case .bell:       return "bell.circle.fill"
        }
    }

    #if os(iOS)
    var systemSoundID: SystemSoundID {
        switch self {
        case .chime:      return 1007
        case .bloom:      return 1323
        case .calypso:    return 1324
        case .anticipate: return 1322
        case .fanfare:    return 1327
        case .descent:    return 1326
        case .telegraph:  return 1335
        case .bell:       return 1013
        }
    }
    #endif

    /// Play a preview of this sound in-app
    func playPreview() {
        #if os(iOS)
        AudioServicesPlaySystemSound(systemSoundID)
        #elseif os(macOS)
        NSSound.beep()
        #endif
    }

    /// Play the full alert (with vibration on iOS)
    func playAlert() {
        #if os(iOS)
        AudioServicesPlayAlertSound(systemSoundID)
        #elseif os(macOS)
        NSSound.beep()
        #endif
    }
}

// MARK: - Notification Manager

@Observable
class NotificationManager {

    var isAuthorized: Bool = false
    var notificationsEnabled: Bool = true

    init() {
        checkAuthorization()
    }

    func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
        }
    }

    /// Send an immediate local notification (shows on lock screen)
    func sendTimerFinished(isBreak: Bool, taskName: String) {
        guard notificationsEnabled, isAuthorized else { return }

        let content = UNMutableNotificationContent()

        if isBreak {
            content.title = "Break is over!"
            content.body = "Time to focus again."
        } else {
            content.title = "Focus session complete!"
            content.body = taskName.isEmpty
                ? "Great work! Time for a break."
                : "\"\(taskName)\" — time for a break."
        }

        content.sound = .default
        content.interruptionLevel = .timeSensitive

        // Fire immediately (1 second trigger)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "pomodoroFinished-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }
}
