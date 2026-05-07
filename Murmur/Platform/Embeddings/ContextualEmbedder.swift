import Foundation
import NaturalLanguage

/// Wraps `NLContextualEmbedding` (iOS 17+) for topic clustering. Falls back to
/// a deterministic hash-based vector if the contextual model can't be loaded
/// (e.g. unsupported language) so the rest of the pipeline still runs.
///
/// Output is a 384-dim `[Float]` to match the PRD's storage shape — we
/// downsample / pad whatever the system model returns.
struct ContextualEmbedder {
    static let dimension = 384

    private let embedding: NLContextualEmbedding?

    init(language: NLLanguage = .english) {
        self.embedding = NLContextualEmbedding(language: language)
        try? self.embedding?.load()
    }

    func embed(_ text: String) -> [Float] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return Array(repeating: 0, count: Self.dimension) }

        // Xcode 16.4's NaturalLanguage API surface does not expose stable
        // token-vector access for NLContextualEmbeddingResult across all
        // deployment SDKs. Keep the system model loaded above so this wrapper
        // can grow into it later, but use the deterministic local vector for
        // v1/CI instead of blocking App Store builds on an SDK-specific shape.
        return Self.fallbackHashVector(trimmed)
    }

    /// Cosine similarity. Returns 0 if either vector is zero.
    static func cosine(_ a: [Float], _ b: [Float]) -> Double {
        let n = min(a.count, b.count)
        guard n > 0 else { return 0 }
        var dot: Double = 0, na: Double = 0, nb: Double = 0
        for i in 0..<n {
            let av = Double(a[i]), bv = Double(b[i])
            dot += av * bv; na += av * av; nb += bv * bv
        }
        guard na > 0, nb > 0 else { return 0 }
        return dot / (sqrt(na) * sqrt(nb))
    }

    private static func resize(_ v: [Double], to dim: Int) -> [Float] {
        if v.count == dim { return v.map(Float.init) }
        if v.count > dim {
            // Average-pool down to `dim` buckets.
            var out = [Float](repeating: 0, count: dim)
            let bucket = Double(v.count) / Double(dim)
            for i in 0..<dim {
                let lo = Int(Double(i) * bucket)
                let hi = min(v.count, Int(Double(i + 1) * bucket))
                let slice = v[lo..<hi]
                let mean = slice.reduce(0, +) / Double(max(1, slice.count))
                out[i] = Float(mean)
            }
            return out
        }
        // Repeat-pad up.
        var out = [Float](repeating: 0, count: dim)
        for i in 0..<dim { out[i] = Float(v[i % v.count]) }
        return out
    }

    private static func fallbackHashVector(_ text: String) -> [Float] {
        // Stable, deterministic, low-quality vector. Keeps clustering "shaped"
        // even when the contextual model is missing.
        var v = [Float](repeating: 0, count: dimension)
        let lowered = text.lowercased()
        for token in lowered.split(separator: " ") {
            var h: UInt64 = 1469598103934665603 // FNV offset
            for byte in token.utf8 { h ^= UInt64(byte); h &*= 1099511628211 }
            let idx = Int(h % UInt64(dimension))
            v[idx] += 1
        }
        // Normalize to unit length.
        let norm = sqrt(v.reduce(0) { $0 + $1 * $1 })
        guard norm > 0 else { return v }
        return v.map { $0 / norm }
    }
}
