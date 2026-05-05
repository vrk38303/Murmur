import SwiftUI
import SwiftData

@main
struct MurmurApp: App {
    @State private var services: ServiceContainer = .live()
    @AppStorage("onboardingCompleted") private var onboardingCompleted: Bool = false

    var body: some Scene {
        WindowGroup {
            Group {
                if effectiveOnboardingCompleted {
                    RootShellView()
                } else {
                    OnboardingFlowView {
                        onboardingCompleted = true
                    }
                }
            }
            .environment(\.services, services)
            .modelContainer(services.modelContainer)
            .task {
                await services.subscriptions.bootstrap()
                // Privacy: wipe any plaintext audio left behind by a prior
                // crash before the user has a chance to start a new recording.
                await EncryptedFileStore.shared.cleanStagingOnLaunch()
                #if DEBUG
                // Hand-written seed calls for App Store screenshots; no-op
                // unless launched with `-MurmurSeedScreenshots`.
                MurmurDebugSeed.seedIfRequested(container: services.modelContainer)
                #endif
            }
            .preferredColorScheme(nil) // honor system; user can override in Settings
        }
    }

    /// Honor UI-test launch args that flip the onboarding gate without
    /// touching the persistent `@AppStorage` value. Lets the screenshot run
    /// land directly on RootShell, and lets the dedicated onboarding shot
    /// force the welcome screen even if the dev's debug install completed it.
    private var effectiveOnboardingCompleted: Bool {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-MurmurUITestSkipOnboarding") { return true }
        if args.contains("-MurmurUITestForceOnboarding") { return false }
        return onboardingCompleted
    }
}
