import SwiftUI

@MainActor
@Observable
final class OnboardingViewModel {
    enum Step: Int, CaseIterable { case welcome, permissions, consent }

    var step: Step = .welcome
    var micGranted: Bool = false
    var speechGranted: Bool = false
    var contactsGranted: Bool = false

    let permissions = PermissionsManager.shared

    func advance() {
        if let next = Step(rawValue: step.rawValue + 1) {
            step = next
        }
    }

    func requestMic() async {
        let s = await permissions.requestMicrophone()
        micGranted = (s == .granted)
    }

    func requestSpeech() async {
        let s = await permissions.requestSpeech()
        speechGranted = (s == .granted)
    }

    func requestContacts() async {
        let s = await permissions.requestContacts()
        contactsGranted = (s == .granted)
    }
}

struct OnboardingFlowView: View {
    var onComplete: () -> Void
    @State private var vm = OnboardingViewModel()

    var body: some View {
        ScreenShell(topInset: 54) {
            switch vm.step {
            case .welcome:     WelcomeView { vm.advance() }
            case .permissions: PermissionsView(vm: vm) { vm.advance() }
            case .consent:     ConsentEducationView { onComplete() }
            }
        }
        .animation(.smooth, value: vm.step)
    }
}

private struct WelcomeView: View {
    var onContinue: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        VStack {
            Spacer(minLength: 0)
            // Mark — concentric arcs ("murmur" radiating outward).
            ZStack {
                RoundedRectangle(cornerRadius: 24).fill(theme.ink)
                Canvas { ctx, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    for i in 0..<4 {
                        let r = CGFloat(i + 1) * 5
                        var p = Path()
                        p.addArc(center: center, radius: r,
                                 startAngle: .degrees(180), endAngle: .degrees(0),
                                 clockwise: false)
                        ctx.stroke(p,
                                   with: .color(theme.bg.opacity(1 - Double(i) * 0.18)),
                                   style: StrokeStyle(lineWidth: 2.2,
                                                      lineCap: .round))
                    }
                }
                .frame(width: 56, height: 56)
            }
            .frame(width: 96, height: 96)
            .shadow(color: .black.opacity(0.20), radius: 20, y: 12)

            Text("Murmur")
                .font(MMType.display)
                .tracking(-1.2)
                .padding(.top, 32)

            Text("onb.welcome.tagline")
                .font(.system(size: 20))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .foregroundStyle(theme.ink2)
                .padding(.top, 18)

            Text("onb.welcome.footer")
                .font(MMType.callout)
                .foregroundStyle(theme.ink3)
                .padding(.top, 24)

            Spacer(minLength: 0)
            PrimaryButton(title: "onb.welcome.cta", action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
        }
        .padding(.horizontal, 32)
    }
}

private struct PermissionsView: View {
    @Bindable var vm: OnboardingViewModel
    var onContinue: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                Text("onb.perms.step")
                    .mmKicker(color: theme.ink3)
                Text("onb.perms.title")
                    .font(.system(size: 30, weight: .bold))
                    .tracking(-0.8)
                    .lineLimit(2)
                Text("onb.perms.body")
                    .font(MMType.callout)
                    .foregroundStyle(theme.ink2)
                    .lineSpacing(3)
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)

            VStack(spacing: 10) {
                permRow(title: "onb.perms.mic.title",
                        sub: "onb.perms.mic.sub",
                        icon: .mic,
                        granted: vm.micGranted) {
                    Task { await vm.requestMic() }
                }
                permRow(title: "onb.perms.speech.title",
                        sub: "onb.perms.speech.sub",
                        icon: .waveform,
                        granted: vm.speechGranted) {
                    Task { await vm.requestSpeech() }
                }
                permRow(title: "onb.perms.contacts.title",
                        sub: "onb.perms.contacts.sub",
                        icon: .person,
                        granted: vm.contactsGranted) {
                    Task { await vm.requestContacts() }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 32)

            Spacer()
            // Mic is non-negotiable per PRD §9. Speech is required for the
            // app to do anything useful but the user can technically skip.
            // Contacts is optional. Gate Continue on mic at minimum.
            PrimaryButton(title: vm.micGranted ? "onb.welcome.cta" : "Allow microphone to continue",
                          action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
                .opacity(vm.micGranted ? 1 : 0.5)
                .disabled(!vm.micGranted)
        }
    }

    private func permRow(title: LocalizedStringKey,
                         sub: LocalizedStringKey,
                         icon: MMIcon,
                         granted: Bool,
                         tap: @escaping () -> Void) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(theme.bgGrouped)
                MMIconView(icon: icon, size: 22, color: theme.accent)
            }
            .frame(width: 42, height: 42)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 16, weight: .semibold)).tracking(-0.2)
                Text(sub).font(MMType.footnote).foregroundStyle(theme.ink2).lineSpacing(2)
            }
            Spacer(minLength: 8)
            Button(action: tap) {
                Text(granted ? "Allowed" : "Allow")
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .foregroundStyle(.white)
                    .background(granted ? theme.success : theme.accent,
                                in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(granted)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(theme.card)
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(theme.cardEdge, lineWidth: 0.5))
        )
    }
}

private struct ConsentEducationView: View {
    var onContinue: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                Text("onb.consent.step").mmKicker(color: theme.ink3)
                Text("onb.consent.title")
                    .font(.system(size: 30, weight: .bold))
                    .tracking(-0.8)
                Text("onb.consent.body")
                    .font(.system(size: 16))
                    .foregroundStyle(theme.ink2)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)

            VStack(alignment: .leading, spacing: 12) {
                bubble(text: "Hey — mind if I record this so I can take notes after?", mine: true)
                bubble(text: "Sure, that's fine.", mine: false)
                bubble(text: "Cool, recording now.", mine: true)
            }
            .padding(.horizontal, 24)
            .padding(.top, 36)

            Spacer()
            PrimaryButton(title: "onb.consent.cta", action: onContinue)
                .padding(.horizontal, 24)
            Text("onb.consent.guide")
                .font(MMType.footnote)
                .foregroundStyle(theme.ink3)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 14)
                .padding(.bottom, 50)
        }
    }

    private func bubble(text: String, mine: Bool) -> some View {
        HStack {
            if mine { Spacer(minLength: 60) }
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(mine ? .white : theme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    UnevenRoundedRectangle(cornerRadii: .init(
                        topLeading: 18,
                        bottomLeading: mine ? 18 : 6,
                        bottomTrailing: mine ? 6 : 18,
                        topTrailing: 18))
                    .fill(mine ? theme.accent : theme.card)
                )
                .overlay(
                    UnevenRoundedRectangle(cornerRadii: .init(
                        topLeading: 18,
                        bottomLeading: mine ? 18 : 6,
                        bottomTrailing: mine ? 6 : 18,
                        topTrailing: 18))
                    .stroke(theme.cardEdge, lineWidth: mine ? 0 : 0.5)
                )
            if !mine { Spacer(minLength: 60) }
        }
    }
}

#Preview { OnboardingFlowView { } }
