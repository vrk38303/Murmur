import SwiftUI

struct LiveRecordingView: View {
    var onDone: () -> Void
    @Environment(\.services) private var services
    @State private var vm: LiveRecordingViewModel?
    @State private var pulse = false

    var body: some View {
        ZStack {
            // Always show the dark warm-charcoal palette during recording per
            // the prototype default.
            MurmurTheme.dark.bg.ignoresSafeArea()

            if let vm {
                VStack(spacing: 0) {
                    if vm.state == .processing {
                        ProcessingView(progress: vm.processingProgress, onDone: onDone)
                    } else {
                        recordingBody(vm: vm)
                    }
                }
                .foregroundStyle(MurmurTheme.dark.ink)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            if vm == nil { vm = LiveRecordingViewModel(services: services) }
            if vm?.state == .idle {
                await vm?.start()
            }
        }
        .onDisappear { vm?.cleanup() }
    }

    @ViewBuilder
    private func recordingBody(vm: LiveRecordingViewModel) -> some View {
        let theme = MurmurTheme.dark
        VStack(spacing: 0) {
            // Recording header
            HStack(spacing: 8) {
                Circle().fill(theme.rec).frame(width: 10, height: 10)
                    .scaleEffect(pulse ? 1.4 : 1)
                    .opacity(pulse ? 0.6 : 1)
                    .animation(.easeInOut(duration: 0.7).repeatForever(),
                               value: pulse)
                Text("rec.live.label")
                    .font(.system(size: 14, weight: .semibold))
                    .tracking(0.4)
                    .textCase(.uppercase)
            }
            .padding(.top, 54)
            .onAppear { pulse = true }

            Text(timer(vm.elapsed))
                .font(MMType.timer)
                .tracking(-1.6)
                .padding(.top, 10)

            if let name = vm.contactName, !name.isEmpty {
                Text("With \(name)")
                    .font(.system(size: 12))
                    .tracking(1)
                    .textCase(.uppercase)
                    .foregroundStyle(theme.ink3)
                    .padding(.top, 4)
            }

            LiveWaveform(levels: vm.levels, color: theme.accent)
                .padding(.top, 60)
                .padding(.horizontal, 24)

            VStack(alignment: .leading, spacing: 8) {
                Text("rec.live.transcribing")
                    .mmKicker(color: theme.ink3)
                Text(vm.liveText.isEmpty
                     ? "Listening…"
                     : vm.liveText)
                    .font(.system(size: 19))
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 32)
            .padding(.top, 40)

            Spacer()

            // Controls
            HStack(spacing: 36) {
                circleButton(icon: .pause, fill: theme.bgGrouped) {
                    Task {
                        if vm.state == .recording { await vm.pause() }
                        else if vm.state == .paused { await vm.resume() }
                    }
                }
                Button {
                    Task { await vm.stop() }
                } label: {
                    ZStack {
                        Circle().fill(theme.rec)
                            .frame(width: 84, height: 84)
                            .overlay(Circle().stroke(theme.card, lineWidth: 4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6).fill(.white)
                                    .frame(width: 28, height: 28)
                            )
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Stop recording")
                circleButton(icon: .bookmark, fill: theme.bgGrouped) { /* bookmark */ }
            }
            .padding(.bottom, 56)
        }
        .alert("Recording problem", isPresented: Binding(
            get: { vm.error != nil },
            set: { if !$0 { vm.error = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(vm.error?.errorDescription ?? "")
        }
    }

    private func circleButton(icon: MMIcon,
                              fill: Color,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle().fill(fill)
                MMIconView(icon: icon, size: 26, color: MurmurTheme.dark.ink)
            }
            .frame(width: 64, height: 64)
        }
        .buttonStyle(.plain)
    }

    private func timer(_ s: TimeInterval) -> String {
        let total = Int(s)
        let m = total / 60, sec = total % 60
        return String(format: "%d:%02d", m, sec)
    }
}
