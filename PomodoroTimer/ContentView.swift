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
            // Background
            vm.backgroundGradient
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.8), value: vm.isBreak)

            VStack(spacing: 0) {
                // Top Bar
                topBar

                Spacer()

                // Status
                statusSection

                // Timer Circle
                timerCircle
                    .padding(.top, 8)

                Spacer()

                // Controls
                controlButtons
                    .padding(.bottom, 12)

                // Session Counter
                sessionCounter
                    .padding(.bottom, 30)
            }
            .padding(.horizontal, 24)

            // Settings Sheet
            if showSettings {
                settingsOverlay
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showSettings)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Pomodoro")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Timer")
                    .font(.system(size: 28, weight: .light, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            Button {
                showSettings.toggle()
            } label: {
                Image(systemName: showSettings ? "xmark" : "slider.horizontal.3")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(spacing: 8) {
            // Mode Badge
            Text(vm.isBreak ? "BREAK" : "FOCUS")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .tracking(3)
                .foregroundStyle(vm.accentColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(vm.accentColor.opacity(0.15))
                .clipShape(Capsule())
                .animation(.easeInOut, value: vm.isBreak)

            // Task Name
            if !vm.taskName.isEmpty {
                Text(vm.taskName)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
            }

            // Status Text
            Text(vm.statusText)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    // MARK: - Timer Circle

    private var timerCircle: some View {
        ZStack {
            // Outer glow
            Circle()
                .stroke(vm.accentColor.opacity(0.08), lineWidth: 24)
                .frame(width: 260, height: 260)

            // Track
            Circle()
                .stroke(.white.opacity(0.06), lineWidth: 8)
                .frame(width: 260, height: 260)

            // Progress Arc
            Circle()
                .trim(from: 0, to: vm.progress)
                .stroke(
                    AngularGradient(
                        colors: [vm.accentColor.opacity(0.4), vm.accentColor],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 260, height: 260)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: vm.progress)

            // Dot at progress tip
            Circle()
                .fill(vm.accentColor)
                .frame(width: 14, height: 14)
                .shadow(color: vm.accentColor.opacity(0.6), radius: 6)
                .offset(y: -130)
                .rotationEffect(.degrees(360 * vm.progress))
                .animation(.linear(duration: 1), value: vm.progress)

            // Time Display
            VStack(spacing: 4) {
                Text(vm.timeString)
                    .font(.system(size: 56, weight: .thin, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.linear(duration: 0.3), value: vm.remainingSeconds)

                Text(vm.isRunning ? "remaining" : "tap play")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.3))
                    .textCase(.uppercase)
                    .tracking(2)
            }
        }
    }

    // MARK: - Controls

    private var controlButtons: some View {
        HStack(spacing: 32) {
            // Reset
            Button {
                withAnimation(.spring(response: 0.4)) {
                    vm.reset()
                }
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 52, height: 52)
                    .background(.white.opacity(0.08))
                    .clipShape(Circle())
            }

            // Play / Pause
            Button {
                withAnimation(.spring(response: 0.4)) {
                    vm.startPause()
                }
            } label: {
                Image(systemName: vm.isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 72, height: 72)
                    .background(vm.accentColor)
                    .clipShape(Circle())
                    .shadow(color: vm.accentColor.opacity(0.4), radius: 12, y: 4)
            }
            .scaleEffect(vm.isRunning ? 1.0 : 1.05)
            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: vm.isRunning)

            // Skip
            Button {
                withAnimation(.spring(response: 0.4)) {
                    vm.skip()
                }
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 52, height: 52)
                    .background(.white.opacity(0.08))
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Session Counter

    private var sessionCounter: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                ForEach(0..<max(4, vm.completedSessions + 1), id: \.self) { i in
                    Circle()
                        .fill(i < vm.completedSessions ? vm.accentColor : Color.white.opacity(0.15))
                        .frame(width: 8, height: 8)
                        .animation(.spring(response: 0.4), value: vm.completedSessions)
                }
            }

            Text("\(vm.completedSessions) session\(vm.completedSessions == 1 ? "" : "s") completed")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.3))
        }
    }

    // MARK: - Settings Overlay

    private var settingsOverlay: some View {
        ZStack(alignment: .bottom) {
            // Dimmed background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    showSettings = false
                }

            // Settings Card
            VStack(spacing: 24) {
                // Handle
                Capsule()
                    .fill(.white.opacity(0.3))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)

                Text("Settings")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                // Task Name Input
                VStack(alignment: .leading, spacing: 8) {
                    Label("Task Name", systemImage: "pencil.line")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))

                    TextField("What are you working on?", text: $vm.taskName)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(14)
                        .background(.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .tint(vm.accentColor)
                }

                // Duration Inputs
                HStack(spacing: 16) {
                    // Work Duration
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Focus", systemImage: "flame.fill")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))

                        HStack(spacing: 8) {
                            TextField("25", text: $vm.workMinutesText)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                #if os(iOS)
                                .keyboardType(.numberPad)
                                #endif
                                .frame(height: 52)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .tint(vm.accentColor)

                            Text("min")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }

                    // Break Duration
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Break", systemImage: "cup.and.saucer.fill")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))

                        HStack(spacing: 8) {
                            TextField("5", text: $vm.breakMinutesText)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                #if os(iOS)
                                .keyboardType(.numberPad)
                                #endif
                                .frame(height: 52)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .tint(vm.accentColor)

                            Text("min")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                }

                // Apply Button
                Button {
                    vm.reset()
                    showSettings = false
                } label: {
                    Text("Apply & Reset Timer")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(vm.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Preset Buttons
                VStack(spacing: 8) {
                    Text("Quick Presets")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))

                    HStack(spacing: 10) {
                        presetButton(label: "Short", work: "15", breakTime: "3")
                        presetButton(label: "Classic", work: "25", breakTime: "5")
                        presetButton(label: "Long", work: "50", breakTime: "10")
                    }
                }

                Spacer().frame(height: 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
        }
        .ignoresSafeArea()
    }

    private func presetButton(label: String, work: String, breakTime: String) -> some View {
        Button {
            vm.workMinutesText = work
            vm.breakMinutesText = breakTime
            vm.reset()
            showSettings = false
        } label: {
            VStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("\(work)/\(breakTime)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    ContentView()
}
