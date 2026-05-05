import SwiftUI
import SwiftData

struct CallsListView: View {
    @Environment(\.services) private var services
    @Environment(\.colorScheme) private var scheme
    @State private var vm: CallsListViewModel?
    @State private var openCall: CallEntity?

    var body: some View {
        ScreenShell(topInset: 54) {
            if let vm {
                content(vm: vm)
            }
        }
        .task {
            if vm == nil {
                vm = CallsListViewModel(services: services)
            }
            vm?.load()
        }
        .sheet(isPresented: Binding(
            get: { vm?.sheetVisible == true },
            set: { vm?.sheetVisible = $0 }
        )) {
            if let vm {
                StartRecordingSheet(
                    onCancel: { vm.sheetVisible = false },
                    onStart: {
                        vm.sheetVisible = false
                        vm.liveRecordingVisible = true
                    }
                )
                .presentationDetents([.height(380)])
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { vm?.liveRecordingVisible == true },
            set: { vm?.liveRecordingVisible = $0 }
        )) {
            if let vm {
                LiveRecordingView { vm.liveRecordingVisible = false; vm.load() }
            }
        }
        .navigationDestination(item: $openCall) { call in
            CallDetailView(callId: call.id)
        }
    }

    @ViewBuilder
    private func content(vm: CallsListViewModel) -> some View {
        VStack(spacing: 0) {
            header(vm: vm)
            searchBar(vm: vm)
            if vm.calls.isEmpty {
                EmptyStateView()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 8) {
                        ForEach(vm.calls, id: \.id) { call in
                            Button { openCall = call } label: {
                                CallRow(call: call)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
        }
    }

    @ViewBuilder
    private func header(vm: CallsListViewModel) -> some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text("calls.thisweek").mmKicker(color: themeFromScheme.ink3)
                Text("calls.title")
                    .font(MMType.largeTitle)
                    .tracking(-0.8)
            }
            Spacer()
            AccentCircleButton(icon: .plus) { vm.tapAdd() }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private func searchBar(vm: CallsListViewModel) -> some View {
        HStack(spacing: 8) {
            MMIconView(icon: .search, size: 16, color: themeFromScheme.ink3)
            TextField("calls.search", text: Binding(
                get: { vm.query },
                set: { vm.query = $0; vm.load() }
            ))
            .font(.system(size: 16))
            .foregroundStyle(themeFromScheme.ink)
            Spacer()
            MMIconView(icon: .mic, size: 16, color: themeFromScheme.ink3)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(themeFromScheme.bgGrouped, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private var themeFromScheme: MurmurTheme {
        scheme == .dark ? .dark : .light
    }
}

private struct CallRow: View {
    let call: CallEntity
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Avatar(name: call.displayName, size: 42)
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(call.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .tracking(-0.2)
                        .foregroundStyle(theme.ink)
                    if call.processingState == .transcribing
                        || call.processingState == .summarizing {
                        Text("· processing")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(0.4)
                            .textCase(.uppercase)
                            .foregroundStyle(theme.accent)
                    }
                    Spacer()
                    Text(call.relativeWhen)
                        .font(MMType.footnote)
                        .foregroundStyle(theme.ink3)
                }
                if let summary = call.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.system(size: 14))
                        .foregroundStyle(theme.ink2)
                        .lineLimit(1)
                }
                HStack(spacing: 6) {
                    StaticWaveform(
                        samples: StaticWaveform.seeded(call.id.hashValue, count: 22),
                        color: theme.ink3, barWidth: 1.5, gap: 1.5,
                        opacity: 0.55
                    )
                    .frame(width: 64, height: 12)
                    Text(call.minutesString)
                        .font(.system(size: 11))
                        .monospacedDigit()
                        .foregroundStyle(theme.ink3)
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(theme.card, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(theme.cardEdge, lineWidth: 0.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(call.displayName), \(call.minutesString), \(call.relativeWhen) ago"))
    }
}

private struct EmptyStateView: View {
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle().fill(theme.bgGrouped)
                MMIconView(icon: .waveform, size: 40, color: theme.ink3, weight: 1.6)
            }
            .frame(width: 84, height: 84)
            Text("calls.empty.title")
                .font(.system(size: 22, weight: .semibold))
                .tracking(-0.4)
            Text("calls.empty.body")
                .font(.system(size: 15))
                .foregroundStyle(theme.ink2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 260)
                .lineSpacing(3)
            Spacer()
        }
        .padding(40)
    }
}

#Preview { CallsListView().environment(\.services, .preview()) }
