//
//  ContentView.swift
//  PomodoroTimer
//
//  Created by Artur Holoiad on 15.02.26.
//

import SwiftUI

struct ContentView: View {
    @State private var vm = TimerViewModel()
    @State private var showSettings = false

    var body: some View {
        ZStack {
            // MARK: - Background
            backgroundLayer

            // MARK: - Main Content
            VStack(spacing: 0) {
                topBar
                    .padding(.top, 12)
                    .padding(.horizontal, 28)

                Spacer(minLength: 20)

                // Center cluster: badge + timer + controls
                VStack(spacing: 28) {
                    modeBadge
                    timerRing
                    controlButtons
                }

                Spacer(minLength: 16)

                bottomBar
                    .padding(.horizontal, 28)
                    .padding(.bottom, 24)
            }

            // MARK: - Settings Sheet
            if showSettings {
                settingsOverlay
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: showSettings)
        .onAppear {
            vm.notificationManager.requestPermission()
        }
    }

    // ──────────────────────────────────────
    // MARK: - Background
    // ──────────────────────────────────────

    private var backgroundLayer: some View {
        vm.backgroundGradient
            .ignoresSafeArea()
    }

    // ──────────────────────────────────────
    // MARK: - Top Bar (left-aligned)
    // ──────────────────────────────────────

    private var topBar: some View {
        HStack(alignment: .top) {
            // Left: title + task
            VStack(alignment: .leading, spacing: 4) {
                Text("Pomodoro")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.white)

                if !vm.taskName.isEmpty {
                    Text(vm.taskName)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.45))
                        .lineLimit(1)
                        .transition(.opacity)
                } else {
                    Text(vm.statusText)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.35))
                }
            }

            Spacer()

            // Right: settings gear
            Button {
                showSettings.toggle()
            } label: {
                Image(systemName: showSettings ? "xmark" : "gearshape")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                    )
            }
        }
    }

    // ──────────────────────────────────────
    // MARK: - Mode Badge (centered)
    // ──────────────────────────────────────

    private var modeBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: vm.isBreak ? "leaf.fill" : "flame.fill")
                .font(.system(size: 11, weight: .bold))
            Text(vm.isBreak ? "BREAK" : "FOCUS")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .tracking(2.5)
        }
        .foregroundStyle(vm.accentColor)
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(vm.accentColor.opacity(0.12))
                .overlay(
                    Capsule()
                        .strokeBorder(vm.accentColor.opacity(0.2), lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.5), value: vm.isBreak)
    }

    // ──────────────────────────────────────
    // MARK: - Timer Ring (centered)
    // ──────────────────────────────────────

    private var timerRing: some View {
        ZStack {
            // Outer glow ring (static, no blur)
            Circle()
                .stroke(vm.accentColor.opacity(0.06), lineWidth: 24)
                .frame(width: 260, height: 260)

            // Background track
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 8)
                .frame(width: 240, height: 240)

            // Progress arc
            Circle()
                .trim(from: 0, to: vm.progress)
                .stroke(
                    vm.accentColor,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 240, height: 240)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: vm.progress)

            // Tip dot
            Circle()
                .fill(Color.white)
                .frame(width: 12, height: 12)
                .shadow(color: vm.accentColor.opacity(0.6), radius: 4)
                .offset(y: -120)
                .rotationEffect(.degrees(360 * vm.progress))
                .animation(.linear(duration: 1), value: vm.progress)
                .opacity(vm.progress > 0 ? 1 : 0)

            // Center time display
            VStack(spacing: 6) {
                Text(vm.timeString)
                    .font(.system(size: 52, weight: .ultraLight, design: .rounded))
                    .foregroundStyle(Color.white)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.linear(duration: 0.3), value: vm.remainingSeconds)

                Text(vm.isRunning ? "remaining" : "ready")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .textCase(.uppercase)
                    .tracking(3)
            }
        }
    }

    // ──────────────────────────────────────
    // MARK: - Control Buttons (centered)
    // ──────────────────────────────────────

    private var controlButtons: some View {
        HStack(spacing: 28) {
            // Reset
            controlButton(icon: "arrow.counterclockwise", size: 17) {
                vm.reset()
            }

            // Play / Pause (hero button)
            Button {
                vm.startPause()
            } label: {
                ZStack {
                    Circle()
                        .fill(vm.accentColor.opacity(0.15))
                        .frame(width: 80, height: 80)

                    Circle()
                        .fill(vm.accentColor)
                        .frame(width: 66, height: 66)

                    Image(systemName: vm.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .offset(x: vm.isRunning ? 0 : 2)
                }
            }

            // Skip
            controlButton(icon: "forward.fill", size: 17) {
                vm.skip()
            }
        }
    }

    private func controlButton(icon: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.55))
                .frame(width: 48, height: 48)
                .background(Color.white.opacity(0.07))
                .clipShape(Circle())
        }
    }

    // ──────────────────────────────────────
    // MARK: - Bottom Bar (left-aligned info)
    // ──────────────────────────────────────

    private var bottomBar: some View {
        let sessionsPerSet = 4
        let filledInSet = vm.completedSessions % sessionsPerSet
        let completedSets = vm.completedSessions / sessionsPerSet

        return HStack(alignment: .center) {
            // Left: session info
            VStack(alignment: .leading, spacing: 6) {
                Text("Current set")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.3))
                    .textCase(.uppercase)
                    .tracking(1.5)

                // Fixed 4 indicators per set
                HStack(spacing: 6) {
                    ForEach(0..<sessionsPerSet, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(i < filledInSet ? vm.accentColor : Color.white.opacity(0.1))
                            .frame(width: 20, height: 6)
                    }
                }

                if completedSets > 0 {
                    Text("\(completedSets) set\(completedSets == 1 ? "" : "s") done")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.2))
                }
            }

            Spacer()

            // Right: total count
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(vm.completedSessions)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.15))
                Text("total")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.15))
                    .textCase(.uppercase)
                    .tracking(1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    // ──────────────────────────────────────
    // MARK: - Settings Overlay
    // ──────────────────────────────────────

    private var settingsOverlay: some View {
        ZStack(alignment: .bottom) {
            // Dimmed backdrop — ignores all safe areas
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    #if os(iOS)
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    #endif
                    showSettings = false
                }

            // Card — respects keyboard safe area so it slides up
            VStack(spacing: 0) {
                // Drag handle
                Capsule()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 36, height: 4)
                    .padding(.top, 14)
                    .padding(.bottom, 20)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 1) {
                        // Title
                        HStack {
                            Text("Settings")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.white)
                            Spacer()
                        }
                        .padding(.bottom, 24)

                        // Input fields
                        VStack(spacing: 16) {
                            // Task Name
                            settingsField(
                                label: "Task Name",
                                icon: "text.cursor"
                            ) {
                                TextField("What are you working on?", text: $vm.taskName)
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.white)
                                    .tint(vm.accentColor)
                            }

                            // Duration row
                            HStack(spacing: 12) {
                                settingsField(label: "Focus", icon: "flame.fill") {
                                    HStack(spacing: 6) {
                                        TextField("25", text: $vm.workMinutesText)
                                            .font(.system(size: 22, weight: .bold, design: .rounded))
                                            .foregroundStyle(Color.white)
                                            .multilineTextAlignment(.center)
                                            #if os(iOS)
                                            .keyboardType(.numberPad)
                                            #endif
                                            .tint(vm.accentColor)
                                        Text("min")
                                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                                            .foregroundStyle(Color.white.opacity(0.3))
                                    }
                                }

                                settingsField(label: "Break", icon: "leaf.fill") {
                                    HStack(spacing: 6) {
                                        TextField("5", text: $vm.breakMinutesText)
                                            .font(.system(size: 22, weight: .bold, design: .rounded))
                                            .foregroundStyle(Color.white)
                                            .multilineTextAlignment(.center)
                                            #if os(iOS)
                                            .keyboardType(.numberPad)
                                            #endif
                                            .tint(vm.accentColor)
                                        Text("min")
                                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                                            .foregroundStyle(Color.white.opacity(0.3))
                                    }
                                }
                            }
                        }

                        // Sound & Notifications
                        VStack(spacing: 16) {
                            // Notification toggle
                            settingsField(label: "Notifications", icon: "bell.badge.fill") {
                                HStack {
                                    if vm.notificationManager.isAuthorized {
                                        Text(vm.notificationManager.notificationsEnabled ? "Enabled" : "Disabled")
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                            .foregroundStyle(Color.white.opacity(0.6))
                                    } else {
                                        Text("Not allowed")
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                            .foregroundStyle(Color.white.opacity(0.4))
                                    }
                                    Spacer()
                                    if vm.notificationManager.isAuthorized {
                                        Toggle("", isOn: $vm.notificationManager.notificationsEnabled)
                                            .labelsHidden()
                                            .tint(vm.accentColor)
                                    } else {
                                        Button("Allow") {
                                            vm.notificationManager.requestPermission()
                                        }
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundStyle(vm.accentColor)
                                    }
                                }
                            }

                            // Sound picker
                            settingsField(label: "Alert Sound", icon: "speaker.wave.2.fill") {
                                soundPicker
                            }
                        }
                        .padding(.top, 16)

                        // Presets
                        VStack(spacing: 10) {
                            Text("PRESETS")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .tracking(2)
                                .foregroundStyle(Color.white.opacity(0.3))

                            HStack(spacing: 10) {
                                presetChip(label: "Short", work: "15", breakTime: "3")
                                presetChip(label: "Classic", work: "25", breakTime: "5")
                                presetChip(label: "Long", work: "50", breakTime: "10")
                            }
                        }
                        .padding(.top, 24)

                        // Apply
                        Button {
                            vm.reset()
                            showSettings = false
                        } label: {
                            Text("Apply Settings")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(vm.accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: vm.accentColor.opacity(0.3), radius: 12, y: 4)
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 32)
                    }
                    .padding(.horizontal, 24)
                }
                #if os(iOS)
                .scrollDismissesKeyboard(.interactively)
                #endif
                .onTapGesture {
                    #if os(iOS)
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    #endif
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .ignoresSafeArea(.container)
    }

    // Reusable settings field container
    private func settingsField<Content: View>(
        label: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                Text(label)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1)
            }
            .foregroundStyle(Color.white.opacity(0.4))
            .textCase(.uppercase)

            // Input area
            content()
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
        }
    }

    // Sound picker grid
    private var soundPicker: some View {
        let columns = [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]

        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(AlertSound.allCases) { sound in
                Button {
                    vm.selectedSound = sound
                    sound.playPreview()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: sound.icon)
                            .font(.system(size: 14, weight: .semibold))
                        Text(sound.rawValue)
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .lineLimit(1)
                    }
                    .foregroundStyle(
                        vm.selectedSound == sound
                            ? Color.white
                            : Color.white.opacity(0.4)
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        vm.selectedSound == sound
                            ? vm.accentColor.opacity(0.3)
                            : Color.white.opacity(0.04)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(
                                vm.selectedSound == sound
                                    ? vm.accentColor.opacity(0.5)
                                    : Color.clear,
                                lineWidth: 1
                            )
                    )
                }
            }
        }
    }

    private func presetChip(label: String, work: String, breakTime: String) -> some View {
        Button {
            vm.workMinutesText = work
            vm.breakMinutesText = breakTime
            vm.reset()
            showSettings = false
        } label: {
            VStack(spacing: 3) {
                Text(label)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.8))
                Text("\(work)/\(breakTime)m")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.3))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
    }
}

#Preview {
    ContentView()
}
