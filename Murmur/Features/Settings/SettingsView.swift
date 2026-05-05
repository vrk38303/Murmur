import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(\.services) private var services
    @State private var vm: SettingsViewModel?

    var body: some View {
        ScreenShell(topInset: 54) {
            if let vm {
                content(vm: vm)
            }
        }
        .task {
            if vm == nil { vm = SettingsViewModel(services: services) }
            await vm?.loadAvailableEngines()
        }
    }

    @ViewBuilder
    private func content(vm: SettingsViewModel) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Text("settings.title")
                    .font(MMType.largeTitle)
                    .tracking(-0.8)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                section(title: "settings.section.privacy") {
                    row(icon: .lock,
                        label: "settings.privacy.label",
                        value: Text("settings.privacy.value"))
                    row(icon: .download,
                        label: "settings.export") {
                        Task { await vm.exportLibrary(includeAudio: false) }
                    }
                    row(icon: .square,
                        label: "settings.deleteall",
                        destructive: true) {
                        vm.deleteConfirmVisible = true
                    }
                }

                section(title: "settings.section.recording") {
                    toggle(icon: .mic,
                           label: "settings.consent.label",
                           on: Binding(
                            get: { vm.consentAlwaysRemind },
                            set: { vm.consentAlwaysRemind = $0 }
                           ))
                    toggle(icon: .bookmark,
                           label: "Auto-bookmark questions",
                           on: .constant(true))
                    pickerRow(icon: .waveform,
                              label: "Audio quality",
                              selection: Binding(
                                get: { vm.audioQuality },
                                set: { vm.audioQuality = $0 }
                              ),
                              options: ["standard", "high"])
                }

                section(title: "settings.section.transcription") {
                    pickerRow(icon: .cpu,
                              label: "Engine",
                              selection: Binding(
                                get: { vm.transcriptionEngine.rawValue },
                                set: { vm.transcriptionEngine = TranscriptionEngine(rawValue: $0) ?? .appleSpeechAnalyzer }
                              ),
                              options: TranscriptionEngine.allCases.map(\.rawValue),
                              displayLabel: { TranscriptionEngine(rawValue: $0)?.displayName ?? $0 })
                    rowVerbatim(icon: .download,
                                label: vm.whisperKitDownloadLabel,
                                action: { Task { await vm.downloadWhisperKitModel() } })
                    pickerRow(icon: .person,
                              label: "Speaker labels",
                              selection: Binding(
                                get: { vm.diarizationMode.rawValue },
                                set: { vm.diarizationMode = DiarizationMode(rawValue: $0) ?? .single }
                              ),
                              options: DiarizationMode.allCases.map(\.rawValue),
                              displayLabel: { DiarizationMode(rawValue: $0)?.displayName ?? $0 })
                }

                section(title: "settings.section.summarization") {
                    pickerRow(icon: .sparkle,
                              label: "Engine",
                              selection: Binding(
                                get: { vm.summarizationEngine.rawValue },
                                set: { vm.summarizationEngine = SummarizationEngine(rawValue: $0) ?? .bundledMLX }
                              ),
                              options: vm.availableSummarizationEngines.map(\.rawValue),
                              displayLabel: { SummarizationEngine(rawValue: $0)?.displayName ?? $0 })
                    toggle(icon: .download,
                           label: "Cloud summarization (off by default)",
                           on: Binding(
                            get: { vm.cloudOptIn },
                            set: { vm.cloudOptIn = $0 }
                           ))
                }

                section(title: "settings.section.mindmap") {
                    sliderRow(icon: .map,
                              label: "Auto-connect threshold",
                              value: Binding(
                                get: { vm.threshold },
                                set: { vm.setThreshold($0) }
                              ),
                              range: 0.7...0.95,
                              step: 0.01,
                              valueLabel: String(format: "%.2f", vm.threshold))
                    row(icon: .map,
                        label: "Reset map positions",
                        destructive: true) {
                        Task { await vm.resetMapPositions() }
                    }
                }

                section(title: "settings.section.appearance") {
                    toggle(icon: .sparkle,
                           label: "settings.darkmode",
                           on: Binding(
                            get: { vm.darkModeOverride == "dark" },
                            set: { vm.darkModeOverride = $0 ? "dark" : "light" }
                           ))
                }

                Text("settings.footer")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 12)
                    .padding(.bottom, 100)
            }
        }
        .alert("Delete all data?", isPresented: Binding(
            get: { vm.deleteConfirmVisible },
            set: { vm.deleteConfirmVisible = $0 }
        )) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task { await vm.deleteEverything() }
            }
        } message: {
            Text("settings.deleteall.confirm")
        }
        .sheet(isPresented: Binding(
            get: { vm.shareItem != nil },
            set: { if !$0 { vm.shareItem = nil } }
        )) {
            if let url = vm.shareItem { ShareSheet(items: [url]) }
        }
        .alert("Multi-speaker labels coming soon", isPresented: Binding(
            get: { vm.diarizationUnavailableNotice },
            set: { vm.diarizationUnavailableNotice = $0 }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Murmur doesn't yet detect different speakers automatically. Every segment is labeled with the recorder until the on-device speaker model ships.")
        }
        .alert("Whisper Large V3", isPresented: Binding(
            get: { vm.whisperKitNotice != nil },
            set: { if !$0 { vm.whisperKitNotice = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(vm.whisperKitNotice ?? "")
        }
    }

    // MARK: - Section / row primitives

    @ViewBuilder
    private func section<Content: View>(title: LocalizedStringKey,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title).mmKicker(color: .secondary).tracking(1.2)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            VStack(spacing: 0) { content() }
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(.separator, lineWidth: 0.5))
                .padding(.horizontal, 16)
                .padding(.bottom, 22)
        }
    }

    private func row(icon: MMIcon,
                     label: LocalizedStringKey,
                     value: Text? = nil,
                     destructive: Bool = false,
                     action: (() -> Void)? = nil) -> some View {
        Button(action: { action?() }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(.tertiary)
                    MMIconView(icon: icon, size: 16, color: destructive ? .red : .secondary)
                }
                .frame(width: 30, height: 30)
                Text(label)
                    .font(.system(size: 16))
                    .foregroundStyle(destructive ? Color.red : .primary)
                Spacer()
                if let value { value.font(.system(size: 14)).foregroundStyle(.secondary) }
                if action != nil { MMIconView(icon: .chevron, size: 14, color: .secondary) }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(Divider().padding(.leading, 56), alignment: .top)
    }

    /// Like `row(...)` but takes a runtime `String` (no localization lookup).
    /// Used for labels that interpolate dynamic values (e.g. download progress).
    private func rowVerbatim(icon: MMIcon,
                             label: String,
                             destructive: Bool = false,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(.tertiary)
                    MMIconView(icon: icon, size: 16, color: destructive ? .red : .secondary)
                }
                .frame(width: 30, height: 30)
                Text(verbatim: label)
                    .font(.system(size: 16))
                    .foregroundStyle(destructive ? Color.red : .primary)
                Spacer()
                MMIconView(icon: .chevron, size: 14, color: .secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(Divider().padding(.leading, 56), alignment: .top)
    }

    private func toggle(icon: MMIcon,
                        label: LocalizedStringKey,
                        on: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(.tertiary)
                MMIconView(icon: icon, size: 16, color: .secondary)
            }
            .frame(width: 30, height: 30)
            Text(label).font(.system(size: 16))
            Spacer()
            Toggle("", isOn: on).labelsHidden()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .overlay(Divider().padding(.leading, 56), alignment: .top)
    }

    private func pickerRow(icon: MMIcon,
                           label: String,
                           selection: Binding<String>,
                           options: [String],
                           displayLabel: ((String) -> String)? = nil) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(.tertiary)
                MMIconView(icon: icon, size: 16, color: .secondary)
            }
            .frame(width: 30, height: 30)
            Text(label).font(.system(size: 16))
            Spacer()
            Picker("", selection: selection) {
                ForEach(options, id: \.self) { opt in
                    Text(displayLabel?(opt) ?? opt.capitalized).tag(opt)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .overlay(Divider().padding(.leading, 56), alignment: .top)
    }

    private func sliderRow(icon: MMIcon,
                           label: String,
                           value: Binding<Double>,
                           range: ClosedRange<Double>,
                           step: Double,
                           valueLabel: String) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(.tertiary)
                    MMIconView(icon: icon, size: 16, color: .secondary)
                }
                .frame(width: 30, height: 30)
                Text(label).font(.system(size: 16))
                Spacer()
                Text(valueLabel).font(.system(size: 13)).foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: step)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .overlay(Divider().padding(.leading, 56), alignment: .top)
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
