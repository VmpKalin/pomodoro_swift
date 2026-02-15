//
//  PomodoroTimerLiveActivity.swift
//  PomodoroTimerWidgets
//
//  Created by Artur Holoiad on 15.02.26.
//

#if canImport(ActivityKit)
import ActivityKit
import WidgetKit
import SwiftUI

struct PomodoroTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroActivityAttributes.self) { context in
            // ─── Lock Screen / Banner ───
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // ─── Expanded Region ───
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Label(
                            context.attributes.isBreak ? "Break" : "Focus",
                            systemImage: context.attributes.isBreak ? "leaf.fill" : "flame.fill"
                        )
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(accentColor(isBreak: context.attributes.isBreak))

                        if !context.attributes.taskName.isEmpty {
                            Text(context.attributes.taskName)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        if context.state.isPaused {
                            Text("Paused")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)
                        } else {
                            Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                                .multilineTextAlignment(.trailing)
                        }

                        Text(formattedTotal(context.attributes.totalSeconds))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.tertiary)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    // Progress bar
                    progressBar(context: context)
                        .padding(.top, 4)
                }
            } compactLeading: {
                // ─── Compact Leading ───
                Image(systemName: context.attributes.isBreak ? "leaf.fill" : "flame.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(accentColor(isBreak: context.attributes.isBreak))
            } compactTrailing: {
                // ─── Compact Trailing ───
                if context.state.isPaused {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                } else {
                    Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .frame(minWidth: 36)
                }
            } minimal: {
                // ─── Minimal ───
                Image(systemName: context.attributes.isBreak ? "leaf.fill" : "flame.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(accentColor(isBreak: context.attributes.isBreak))
            }
        }
    }

    // MARK: - Lock Screen View

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<PomodoroActivityAttributes>) -> some View {
        VStack(spacing: 12) {
            HStack {
                // Left: mode + task
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Image(systemName: context.attributes.isBreak ? "leaf.fill" : "flame.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text(context.attributes.isBreak ? "BREAK" : "FOCUS")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .tracking(2)
                    }
                    .foregroundStyle(accentColor(isBreak: context.attributes.isBreak))

                    if !context.attributes.taskName.isEmpty {
                        Text(context.attributes.taskName)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Right: timer
                if context.state.isPaused {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatTime(context.state.remainingSeconds))
                            .font(.system(size: 28, weight: .light, design: .rounded))
                            .monospacedDigit()
                        Text("Paused")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
                        .font(.system(size: 28, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .multilineTextAlignment(.trailing)
                }
            }

            // Progress bar
            progressBar(context: context)
        }
        .padding(16)
        .activityBackgroundTint(Color.black.opacity(0.6))
        .activitySystemActionForegroundColor(.white)
    }

    // MARK: - Progress Bar

    private func progressBar(context: ActivityViewContext<PomodoroActivityAttributes>) -> some View {
        let total = context.attributes.totalSeconds
        let remaining = context.state.remainingSeconds
        let progress = total > 0 ? Double(total - remaining) / Double(total) : 0

        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.15))
                    .frame(height: 5)

                Capsule()
                    .fill(accentColor(isBreak: context.attributes.isBreak))
                    .frame(width: max(0, geo.size.width * progress), height: 5)
            }
        }
        .frame(height: 5)
    }

    // MARK: - Helpers

    private func accentColor(isBreak: Bool) -> Color {
        isBreak
            ? Color(red: 0.3, green: 0.82, blue: 0.65)
            : Color(red: 0.96, green: 0.38, blue: 0.42)
    }

    private func formatTime(_ totalSeconds: Int) -> String {
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func formattedTotal(_ totalSeconds: Int) -> String {
        let m = totalSeconds / 60
        return "of \(m) min"
    }
}
#endif
