import Foundation
import StoreKit

/// Tier model maps to PRD §15.5.1.
enum SubscriptionTier: String, Codable, Sendable, CaseIterable {
    case free
    case plus
    case pro
    case lifetimeFounder

    var displayName: String {
        switch self {
        case .free:             return "Free"
        case .plus:             return "Murmur Plus"
        case .pro:              return "Murmur Pro"
        case .lifetimeFounder:  return "Lifetime Founder"
        }
    }

    var monthlyRecordingLimit: Int? {
        switch self {
        case .free: return 3
        default:    return nil
        }
    }

    var maxRecordingMinutes: Int? {
        switch self {
        case .free: return 30
        default:    return nil
        }
    }

    var unlocksMindMap: Bool { self != .free }
    var unlocksAISummary: Bool { self != .free }
    var unlocksExport: Bool { self != .free }
    var unlocksWhisperKit: Bool { self == .pro || self == .lifetimeFounder }
    var unlocksDiarization: Bool { self == .pro || self == .lifetimeFounder }

    /// Explicit ranking — never compare on string length.
    /// Lifetime > Pro > Plus > Free.
    var priority: Int {
        switch self {
        case .free:             return 0
        case .plus:             return 1
        case .pro:              return 2
        case .lifetimeFounder:  return 3
        }
    }
}

enum SubscriptionProductID: String, CaseIterable {
    case plusMonthly       = "app.murmur.plus.monthly"
    case plusYearly        = "app.murmur.plus.yearly"
    case proMonthly        = "app.murmur.pro.monthly"
    case proYearly         = "app.murmur.pro.yearly"
    case lifetimeFounder   = "app.murmur.lifetime.founder"

    var tier: SubscriptionTier {
        switch self {
        case .plusMonthly, .plusYearly: return .plus
        case .proMonthly, .proYearly:   return .pro
        case .lifetimeFounder:          return .lifetimeFounder
        }
    }
}

@MainActor
@Observable
final class SubscriptionService {
    private(set) var tier: SubscriptionTier = .free
    private(set) var products: [Product] = []
    private(set) var purchaseInProgress: Bool = false
    private(set) var monthlyRecordingsUsed: Int = 0

    private var updatesTask: Task<Void, Never>?

    init() {
        loadUsage()
    }

    /// Wire up StoreKit 2: load products + subscribe to transaction updates.
    func bootstrap() async {
        await loadProducts()
        await refreshEntitlements()
        updatesTask?.cancel()
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update: update)
            }
        }
    }

    func loadProducts() async {
        let ids = SubscriptionProductID.allCases.map(\.rawValue)
        do {
            products = try await Product.products(for: ids)
        } catch {
            products = []
        }
    }

    func purchase(_ productID: SubscriptionProductID) async throws {
        guard let product = products.first(where: { $0.id == productID.rawValue }) else {
            throw AppError.subscriptionFailed("Product unavailable")
        }
        purchaseInProgress = true
        defer { purchaseInProgress = false }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let tx = try checkVerified(verification)
            await tx.finish()
            await refreshEntitlements()
        case .userCancelled:
            return
        case .pending:
            throw AppError.subscriptionFailed("Purchase pending")
        @unknown default:
            throw AppError.subscriptionFailed("Unknown purchase state")
        }
    }

    func restore() async throws {
        try await AppStore.sync()
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        var resolved: SubscriptionTier = .free
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let tx) = entitlement,
               let id = SubscriptionProductID(rawValue: tx.productID),
               id.tier.priority > resolved.priority {
                resolved = id.tier
            }
        }
        tier = resolved
    }

    private func handle(update: VerificationResult<Transaction>) async {
        if case .verified(let tx) = update {
            await tx.finish()
            await refreshEntitlements()
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value): return value
        case .unverified: throw AppError.subscriptionFailed("Receipt verification failed")
        }
    }

    // MARK: - Free tier metering

    /// Decide whether the user can start another recording right now. Pulls
    /// the cap from `tier.monthlyRecordingLimit`.
    func canStartNewRecording() -> Bool {
        guard let cap = tier.monthlyRecordingLimit else { return true }
        rolloverIfNeeded()
        return monthlyRecordingsUsed < cap
    }

    func recordRecordingStart() {
        rolloverIfNeeded()
        monthlyRecordingsUsed += 1
        UserDefaults.standard.set(monthlyRecordingsUsed, forKey: "sub.monthlyUsed")
        UserDefaults.standard.set(currentMonthKey(), forKey: "sub.monthKey")
    }

    private func loadUsage() {
        let stored = UserDefaults.standard.string(forKey: "sub.monthKey")
        if stored == currentMonthKey() {
            monthlyRecordingsUsed = UserDefaults.standard.integer(forKey: "sub.monthlyUsed")
        } else {
            monthlyRecordingsUsed = 0
        }
    }

    private func rolloverIfNeeded() {
        let stored = UserDefaults.standard.string(forKey: "sub.monthKey")
        if stored != currentMonthKey() {
            monthlyRecordingsUsed = 0
            UserDefaults.standard.set(0, forKey: "sub.monthlyUsed")
            UserDefaults.standard.set(currentMonthKey(), forKey: "sub.monthKey")
        }
    }

    private func currentMonthKey() -> String {
        let comps = Calendar.current.dateComponents([.year, .month], from: .now)
        return "\(comps.year ?? 0)-\(comps.month ?? 0)"
    }
}
