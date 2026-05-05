import SwiftUI

struct CallDetailView: View {
    let callId: UUID
    @Environment(\.services) private var services
    @Environment(\.dismiss) private var dismiss
    @State private var vm: CallDetailViewModel?

    var body: some View {
        ScreenShell(topInset: 54) {
            if let vm, let call = vm.call {
                content(vm: vm, call: call)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if vm == nil { vm = CallDetailViewModel(callId: callId, services: services) }
            vm?.load()
        }
    }

    @ViewBuilder
    private func content(vm: CallDetailViewModel, call: CallEntity) -> some View {
        VStack(spacing: 0) {
            navRow
            heroSection(call: call)
            segmentedControl(vm: vm)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    switch vm.segment {
                    case .summary:
                        SummaryContent(call: call) { vm.toggleActionItem($0) }
                    case .transcript:
                        TranscriptContent(segments: vm.segments)
                    case .map:
                        MiniMapContent(call: call)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 200)
            }
            .overlay(alignment: .bottom) {
                PlayBar(durationSeconds: call.audioDurationSeconds)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 86) // above tab bar
            }
        }
    }

    @ViewBuilder
    private var navRow: some View {
        HStack {
            Button { dismiss() } label: {
                HStack(spacing: 2) {
                    MMIconView(icon: .chevronL, size: 22, weight: 2.4)
                        .foregroundStyle(.tint)
                    Text("detail.back").font(.system(size: 16))
                }
            }
            Spacer()
            Button { } label: {
                MMIconView(icon: .dots, size: 22)
            }
        }
        .tint(.accentColor)
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func heroSection(call: CallEntity) -> some View {
        VStack(spacing: 16) {
            StaticWaveform(
                samples: StaticWaveform.seeded(call.id.hashValue, count: 140),
                color: .accentColor,
                barWidth: 1.5, gap: 1.5,
                opacity: 0.7
            )
            .frame(height: 96)

            HStack(spacing: 14) {
                Avatar(name: call.displayName, size: 52)
                VStack(alignment: .leading, spacing: 4) {
                    Text(call.displayName)
                        .font(.system(size: 26, weight: .bold))
                        .tracking(-0.6)
                    Text(detailTimestamp(call: call))
                        .font(MMType.footnote)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    @ViewBuilder
    private func segmentedControl(vm: CallDetailViewModel) -> some View {
        HStack(spacing: 0) {
            ForEach(CallDetailSegment.allCases, id: \.self) { seg in
                Button {
                    withAnimation(.snappy) { vm.segment = seg }
                } label: {
                    Text(seg.label)
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 32)
                        .background(
                            Group {
                                if vm.segment == seg {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.background)
                                        .shadow(color: .black.opacity(0.06), radius: 1, y: 1)
                                }
                            }
                        )
                        .foregroundStyle(vm.segment == seg ? .primary : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(.tertiary, in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private func detailTimestamp(call: CallEntity) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d · h:mm a"
        let m = Int(call.durationSeconds / 60)
        return "\(f.string(from: call.startedAt)) · \(m) min"
    }
}

// MARK: - Summary segment

private struct SummaryContent: View {
    let call: CallEntity
    var onToggleAction: (UUID) -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        Card(title: "detail.summary.kicker", accent: theme.accent) {
            Text(call.summary ?? "No summary yet.")
                .font(.system(size: 16))
                .foregroundStyle(theme.ink)
                .lineSpacing(4)
        }
        if !call.keyPoints.isEmpty {
            Card(title: "detail.keypoints.kicker", accent: theme.accent) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(call.keyPoints, id: \.self) { p in
                        HStack(alignment: .top, spacing: 10) {
                            Circle().fill(theme.ink3)
                                .frame(width: 4, height: 4)
                                .padding(.top, 8)
                            Text(p)
                                .font(.system(size: 15))
                                .lineSpacing(2)
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
        }
        if !call.actionItems.isEmpty {
            Card(title: "detail.actions.kicker", accent: theme.success) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(call.actionItems, id: \.id) { a in
                        Button { onToggleAction(a.id) } label: {
                            HStack(alignment: .center, spacing: 10) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(a.isCompleted ? theme.success : theme.ink3,
                                                lineWidth: 1.5)
                                    if a.isCompleted {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(theme.success)
                                        MMIconView(icon: .check, size: 14, color: .white,
                                                   weight: 2.6)
                                    }
                                }
                                .frame(width: 20, height: 20)
                                Text(a.text)
                                    .font(.system(size: 15))
                                    .strikethrough(a.isCompleted)
                                    .foregroundStyle(a.isCompleted ? theme.ink3 : theme.ink)
                                Spacer()
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        if !call.topics.isEmpty {
            Card(title: "detail.connections.kicker", accent: theme.accent) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(call.topics.enumerated()), id: \.element.id) { i, topic in
                        HStack(spacing: 10) {
                            ZStack {
                                Circle().fill(theme.ink)
                                Text("·")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(theme.bg)
                            }
                            .frame(width: 28, height: 28)
                            Text(topic.label).font(.system(size: 15))
                            Spacer()
                            MMIconView(icon: .chevron, size: 14, color: theme.ink3)
                        }
                        .padding(.vertical, 7)
                        if i < call.topics.count - 1 {
                            Rectangle().fill(theme.sep).frame(height: 0.5)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Transcript segment

private struct TranscriptContent: View {
    let segments: [TranscriptSegmentEntity]
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(segments, id: \.id) { seg in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(seg.speakerLabel)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(seg.speakerLabel == "You"
                                             ? theme.accent : theme.ink)
                        Text(timeStamp(seconds: seg.startTimeSeconds))
                            .font(.system(size: 11))
                            .monospacedDigit()
                            .foregroundStyle(theme.ink3)
                    }
                    Text(seg.text)
                        .font(.system(size: 16))
                        .lineSpacing(4)
                }
            }
            if segments.isEmpty {
                Text("Transcript not yet available.")
                    .font(.system(size: 15))
                    .foregroundStyle(theme.ink3)
                    .padding(.top, 40)
            }
        }
    }

    private func timeStamp(seconds: Double) -> String {
        let m = Int(seconds / 60)
        let s = Int(seconds.truncatingRemainder(dividingBy: 60))
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Mini map segment

private struct MiniMapContent: View {
    let call: CallEntity
    @Environment(\.theme) private var theme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14).fill(theme.card)
            Canvas { ctx, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2 - 10)
                let nodes: [(CGPoint, String)] = call.topics.prefix(6).enumerated().map { i, t in
                    let angle = (Double(i) / 6.0) * .pi * 2
                    let r = min(size.width, size.height) * 0.35
                    return (CGPoint(x: center.x + cos(angle) * r,
                                    y: center.y + sin(angle) * r),
                            t.label)
                }
                // edges
                for (p, _) in nodes {
                    var path = Path()
                    path.move(to: center)
                    path.addLine(to: p)
                    ctx.stroke(path, with: .color(theme.edge), lineWidth: 1)
                }
                // center node
                let centerW: CGFloat = 110
                let centerRect = CGRect(x: center.x - centerW/2,
                                        y: center.y - 18,
                                        width: centerW, height: 36)
                ctx.fill(Path(roundedRect: centerRect, cornerRadius: 18),
                         with: .color(theme.node))
                ctx.stroke(Path(roundedRect: centerRect, cornerRadius: 18),
                           with: .color(theme.accent), lineWidth: 2)
                let label = Text(call.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(theme.nodeText)
                ctx.draw(label, in: centerRect.insetBy(dx: 6, dy: 8))

                for (p, name) in nodes {
                    let w = CGFloat(name.count) * 7 + 16
                    let r = CGRect(x: p.x - w/2, y: p.y - 13, width: w, height: 26)
                    ctx.fill(Path(roundedRect: r, cornerRadius: 13),
                             with: .color(theme.node))
                    let txt = Text(name).font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.nodeText)
                    ctx.draw(txt, in: r.insetBy(dx: 4, dy: 5))
                }
            }
            .padding(8)
        }
        .frame(height: 320)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(theme.cardEdge, lineWidth: 0.5)
        )
    }
}

// MARK: - Play bar

private struct PlayBar: View {
    let durationSeconds: Double
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .leading) {
                Capsule().fill(theme.bgGrouped).frame(height: 4)
                Capsule().fill(theme.ink).frame(width: 80, height: 4)
            }
            HStack {
                Text("0:00").font(.system(size: 11)).monospacedDigit()
                Spacer()
                Text(format(durationSeconds))
                    .font(.system(size: 11)).monospacedDigit()
            }
            .foregroundStyle(theme.ink3)

            HStack(spacing: 36) {
                MMIconView(icon: .skipB, size: 22, color: theme.ink2)
                Button { } label: {
                    ZStack {
                        Circle().fill(theme.ink)
                        MMIconView(icon: .play, size: 22, color: theme.bg)
                            .offset(x: 1)
                    }
                    .frame(width: 50, height: 50)
                }
                .buttonStyle(.plain)
                MMIconView(icon: .skipF, size: 22, color: theme.ink2)
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(theme.cardEdge, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.10), radius: 16, y: 8)
    }

    private func format(_ s: Double) -> String {
        let m = Int(s / 60), sec = Int(s.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", m, sec)
    }
}
