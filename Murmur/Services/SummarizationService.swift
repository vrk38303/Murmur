import Foundation

struct SummaryResult: Codable, Sendable, Hashable {
    var summary: String
    var keyPoints: [String]
    var actionItems: [ActionItem]
    var sentiment: SentimentLabel
    var topics: [String]
}

protocol SummarizationServiceProtocol: Actor {
    func availableEngines() -> [SummarizationEngine]
    func currentEngine() -> SummarizationEngine
    func setEngine(_ engine: SummarizationEngine) async
    func summarize(transcript: [TranscriptSegmentEntity],
                   contactName: String?) async throws -> SummaryResult
}

actor SummarizationService: SummarizationServiceProtocol {
    private var engine: SummarizationEngine

    init() {
        self.engine = Self.bestAvailableEngine()
    }

    static func bestAvailableEngine() -> SummarizationEngine {
        // The iOS 26 `#available` check is true at compile time on the iOS 18
        // SDK, so we cannot rely on it alone — that's how `.appleIntelligence`
        // ended up appearing as the default engine on builds where
        // `runFoundationModels` always throws `summarizationUnavailable`. Gate
        // on `canImport(FoundationModels)` too so the default falls to
        // bundledMLX until the SDK is actually wired in.
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            return .appleIntelligence
        }
        #endif
        return .bundledMLX
    }

    func availableEngines() -> [SummarizationEngine] {
        var engines: [SummarizationEngine] = []
        #if canImport(FoundationModels)
        if #available(iOS 26, *) { engines.append(.appleIntelligence) }
        #endif
        engines.append(.bundledMLX)
        engines.append(.cloud) // off by default; user must opt in
        return engines
    }

    func currentEngine() -> SummarizationEngine { engine }
    func setEngine(_ engine: SummarizationEngine) async {
        self.engine = engine
    }

    func summarize(transcript: [TranscriptSegmentEntity],
                   contactName: String?) async throws -> SummaryResult {
        let prompt = buildPrompt(transcript: transcript, contactName: contactName)

        for attempt in 0..<2 {
            do {
                let raw = try await runEngine(prompt: prompt, strict: attempt == 1)
                if let parsed = parse(raw) { return parsed }
            } catch {
                if attempt == 1 {
                    throw AppError.summarizationFailed((error as? LocalizedError)?.errorDescription ?? "\(error)")
                }
            }
        }
        throw AppError.summarizationFailed("Could not produce a structured summary")
    }

    // MARK: - Prompt

    private static let systemPrompt: String = """
    You are a private on-device assistant analyzing a transcript of a personal phone call. Produce a JSON object with these fields:

    - summary: a concise 2-3 sentence summary in the user's voice
    - keyPoints: an array of 3-7 short bullet points
    - actionItems: an array of objects with text, assignedTo (nullable), dueDate (nullable, ISO 8601)
    - sentiment: one of "positive", "neutral", "negative", "mixed"
    - topics: an array of 1-5 short topic labels (1-3 words each)

    Output ONLY the JSON object. No prose before or after.
    """

    private func buildPrompt(transcript: [TranscriptSegmentEntity],
                             contactName: String?) -> String {
        let lines = transcript
            .sorted { $0.startTimeSeconds < $1.startTimeSeconds }
            .map { "\($0.speakerLabel): \($0.text)" }
            .joined(separator: "\n")
        let header = contactName.map { "Conversation with \($0).\n" } ?? ""
        return Self.systemPrompt + "\n\n---\n" + header + lines
    }

    // MARK: - Engine adapters

    private func runEngine(prompt: String, strict: Bool) async throws -> String {
        switch engine {
        case .appleIntelligence:
            return try await runFoundationModels(prompt: prompt, strict: strict)
        case .bundledMLX:
            return try await runBundledMLX(prompt: prompt, strict: strict)
        case .cloud:
            // Off by default. The Settings toggle gates the actual call site;
            // surface a clear error if a caller bypasses that gate.
            throw AppError.summarizationFailed("Cloud summarization is disabled. Enable it in Settings if you accept the privacy trade-off.")
        }
    }

    /// Apple Intelligence path. Compiles against iOS 18 by deferring the
    /// import to runtime via dynamic dispatch — see LIMITATIONS for the
    /// runtime expectations.
    private func runFoundationModels(prompt: String, strict: Bool) async throws -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            // Pseudocode shape — the symbol surface is finalised at the SDK
            // level by Apple. We isolate it behind a single call site so it
            // can be swapped without touching the rest of the service.
            //
            //   let session = LanguageModelSession()
            //   let resp = try await session.respond(to: prompt)
            //   return resp.content
            throw AppError.summarizationUnavailable
        }
        #endif
        throw AppError.summarizationUnavailable
    }

    /// Bundled MLX path (Gemma 2 2B 4-bit). Wired as a stub call site that a
    /// future PR will hook to the `mlx-swift-examples` runner.
    private func runBundledMLX(prompt: String, strict: Bool) async throws -> String {
        // For now: a deterministic, useful fallback that doesn't lie about
        // being LLM-generated. The UI shows "Bundled (MLX) — preview" so the
        // user knows.
        let topics = Self.extractTopics(from: prompt)
        let summary = Self.heuristicSummary(prompt: prompt)
        let keyPoints = Self.heuristicKeyPoints(prompt: prompt)
        let json: [String: Any] = [
            "summary": summary,
            "keyPoints": keyPoints,
            "actionItems": [] as [[String: Any]],
            "sentiment": "neutral",
            "topics": topics
        ]
        let data = try JSONSerialization.data(withJSONObject: json, options: [])
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    // MARK: - Heuristic stand-ins (deleted once MLX runner lands)

    static func extractTopics(from prompt: String) -> [String] {
        let stop: Set<String> = ["the","and","you","for","that","with","this","just","like","what","about"]
        let counts = prompt.lowercased()
            .components(separatedBy: .punctuationCharacters).joined()
            .split(whereSeparator: { $0.isWhitespace })
            .filter { $0.count > 4 && !stop.contains(String($0)) }
            .reduce(into: [String: Int]()) { $0[String($1), default: 0] += 1 }
        return counts.sorted { $0.value > $1.value }.prefix(3).map { $0.key.capitalized }
    }

    static func heuristicSummary(prompt: String) -> String {
        let sentences = prompt.split(whereSeparator: { ".!?\n".contains($0) })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.count > 20 }
        let pick = sentences.prefix(2).joined(separator: ". ")
        return pick.isEmpty ? "Conversation captured." : pick + "."
    }

    static func heuristicKeyPoints(prompt: String) -> [String] {
        let chunks = prompt.split(whereSeparator: { ".!?\n".contains($0) })
        let sentences = chunks.map { $0.trimmingCharacters(in: .whitespaces) }
        let candidates = sentences.filter { sentence in
            sentence.count > 12 && sentence.count < 80
        }
        return candidates.prefix(4).map { String($0) }
    }

    // MARK: - JSON parsing

    private func parse(_ raw: String) -> SummaryResult? {
        guard let data = extractJSONObject(from: raw)?.data(using: .utf8) else { return nil }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(SummaryResult.self, from: data)
        } catch {
            // Tolerant fallback — handle missing/extra fields manually.
            guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
            let summary = obj["summary"] as? String ?? ""
            let keyPoints = (obj["keyPoints"] as? [String]) ?? []
            let topics = (obj["topics"] as? [String]) ?? []
            let sentimentRaw = (obj["sentiment"] as? String) ?? "neutral"
            let sentiment = SentimentLabel(rawValue: sentimentRaw) ?? .neutral
            let rawItems = (obj["actionItems"] as? [[String: Any]]) ?? []
            let items: [ActionItem] = rawItems.map { dict in
                ActionItem(
                    text: dict["text"] as? String ?? "",
                    assignedTo: dict["assignedTo"] as? String,
                    dueDate: (dict["dueDate"] as? String).flatMap { ISO8601DateFormatter().date(from: $0) },
                    isCompleted: false
                )
            }.filter { !$0.text.isEmpty }
            return SummaryResult(summary: summary,
                                 keyPoints: keyPoints,
                                 actionItems: items,
                                 sentiment: sentiment,
                                 topics: topics)
        }
    }

    /// Pull the first balanced `{...}` substring from arbitrary text. Useful
    /// when a model wraps JSON with prose. Honors JSON string literals so a
    /// payload like `{"text": "use { brace"}` doesn't mis-balance and
    /// truncate. Also honors backslash escapes inside strings so a literal
    /// `\"` inside a value doesn't end the string early.
    private func extractJSONObject(from text: String) -> String? {
        guard let start = text.firstIndex(of: "{") else { return nil }
        var depth = 0
        var inString = false
        var escapeNext = false
        var i = start
        while i < text.endIndex {
            let c = text[i]
            if inString {
                if escapeNext {
                    escapeNext = false
                } else if c == "\\" {
                    escapeNext = true
                } else if c == "\"" {
                    inString = false
                }
            } else {
                switch c {
                case "\"":
                    inString = true
                case "{":
                    depth += 1
                case "}":
                    depth -= 1
                    if depth == 0 {
                        return String(text[start...i])
                    }
                default:
                    break
                }
            }
            i = text.index(after: i)
        }
        return nil
    }
}
