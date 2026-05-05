import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class CallsListViewModel {
    var query: String = ""
    var calls: [CallEntity] = []
    var sheetVisible: Bool = false
    var liveRecordingVisible: Bool = false
    var paywallVisible: Bool = false
    var processingCallId: UUID?
    var error: AppError?

    private let services: ServiceContainer

    init(services: ServiceContainer) {
        self.services = services
    }

    func load() {
        let ctx = ModelContext(services.modelContainer)
        let descriptor = FetchDescriptor<CallEntity>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        do {
            let all = try ctx.fetch(descriptor)
            calls = all.filter { c in
                guard !query.isEmpty else { return true }
                let needle = query.localizedLowercase
                return c.displayName.localizedLowercase.contains(needle)
                    || (c.summary ?? "").localizedLowercase.contains(needle)
                    || (c.title.localizedLowercase.contains(needle))
            }
        } catch {
            self.error = .persistenceFailed(error.localizedDescription)
        }
    }

    /// Tap "+". May open a sheet, or — for free-tier users at their cap — pop
    /// the paywall instead. Paywall is gated behind `MURMUR_PAYWALL_ENABLED`
    /// because StoreKit products aren't configured in App Store Connect for
    /// the v1 free-only launch — a reachable paywall with no products is an
    /// automatic Guideline 3.1.2 rejection.
    func tapAdd() {
        if !services.subscriptions.canStartNewRecording() {
            #if MURMUR_PAYWALL_ENABLED
            paywallVisible = true
            return
            #endif
        }
        sheetVisible = true
    }

    var thisWeekCount: Int {
        let weekAgo = Date.now.addingTimeInterval(-7 * 24 * 3600)
        return calls.filter { $0.startedAt > weekAgo }.count
    }
}

extension CallEntity {
    var relativeWhen: String {
        let elapsed = Date.now.timeIntervalSince(startedAt)
        if elapsed < 3600 { return "\(Int(elapsed/60))m" }
        if elapsed < 86400 { return "\(Int(elapsed/3600))h" }
        if elapsed < 7 * 86400 { return "\(Int(elapsed/86400))d" }
        return "\(Int(elapsed/(7 * 86400)))w"
    }

    var minutesString: String {
        let m = Int(durationSeconds / 60)
        let s = Int(durationSeconds.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", m, s)
    }
}
