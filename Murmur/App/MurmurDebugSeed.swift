#if DEBUG
import Foundation
import SwiftData

/// Screenshot-friendly seed factory. Inserts hand-written CallEntities and a
/// believable mind-map graph the App Store carousel can show without the
/// MLX-heuristic placeholder summaries leaking through.
///
/// Activated only when the process was launched with `-MurmurSeedScreenshots`
/// (Snapfile passes this; the real app launch path never sees it). Skips work
/// if any CallEntity already exists so a developer running the seeded build a
/// second time doesn't end up with duplicate rows.
///
/// This file is gated `#if DEBUG` so it does not ship in the App Store IPA.
enum MurmurDebugSeed {
    static var isRequested: Bool {
        ProcessInfo.processInfo.arguments.contains("-MurmurSeedScreenshots")
    }

    static func seedIfRequested(container: ModelContainer) {
        guard isRequested else { return }
        let ctx = ModelContext(container)
        do {
            let existing = try ctx.fetch(FetchDescriptor<CallEntity>())
            guard existing.isEmpty else { return }
        } catch {
            return
        }
        seed(into: ctx)
    }

    private static func seed(into ctx: ModelContext) {
        let embedder = ContextualEmbedder()
        let topics = makeTopics(embedder: embedder)
        topics.forEach(ctx.insert)
        let calls = makeCalls()
        calls.forEach { (call, segments, topicLabels, edges) in
            ctx.insert(call)
            segments.forEach {
                $0.call = call
                ctx.insert($0)
            }
            call.topics = topicLabels.compactMap { label in topics.first(where: { $0.label == label }) }
            edges.forEach { ctx.insert($0) }
        }
        try? ctx.save()
    }

    // MARK: - Topics

    private static let topicLabels: [String] = [
        "Job search", "IBM interview", "Apartment hunt", "Family",
        "Wedding planning", "Therapy", "Travel", "Side project"
    ]

    private static func makeTopics(embedder: ContextualEmbedder) -> [TopicEntity] {
        topicLabels.enumerated().map { idx, label in
            TopicEntity(label: label,
                        embedding: embedder.embed(label),
                        importance: 5 - min(4, idx / 2))
        }
    }

    // MARK: - Calls

    private struct CallSpec {
        let id: UUID = UUID()
        let title: String
        let contactName: String
        let minutesAgo: Double
        let durationMinutes: Double
        let summary: String
        let keyPoints: [String]
        let actionItems: [ActionItem]
        let sentiment: SentimentLabel
        let topics: [String]
        let segments: [(label: String, text: String)]
    }

    private static func makeCalls() -> [(CallEntity, [TranscriptSegmentEntity], [String], [MindMapEdgeEntity])] {
        let specs: [CallSpec] = [
            CallSpec(
                title: "With Neera",
                contactName: "Neera Patel",
                minutesAgo: 12,
                durationMinutes: 18,
                summary: "Caught up with Neera about the IBM offer. She thinks the comp is fair but the team scope is narrower than what was pitched. Decided to ask for a one-week extension before signing.",
                keyPoints: [
                    "Comp lands at the top of the band Neera benchmarked.",
                    "Scope shrunk from platform to a single product surface.",
                    "Manager-of-managers role is open in 6-9 months if I want it.",
                    "Plan: ask for a one-week extension and a written scope document."
                ],
                actionItems: [
                    ActionItem(text: "Email Priya at IBM to request a one-week extension.", isCompleted: true),
                    ActionItem(text: "Draft the scope-clarification questions.", isCompleted: false),
                    ActionItem(text: "Compare against the Stripe and Notion offers.", isCompleted: false)
                ],
                sentiment: .mixed,
                topics: ["Job search", "IBM interview"],
                segments: [
                    ("You", "I think the IBM offer is solid but I want to talk through the timing before I commit."),
                    ("You", "The base is fine. The equity tranche feels light against where Stripe came in."),
                    ("Neera", "I'd ask for the scope doc in writing. That's the part you'll regret later if it's verbal.")
                ]
            ),
            CallSpec(
                title: "Mom",
                contactName: "Mom",
                minutesAgo: 4 * 60,
                durationMinutes: 22,
                summary: "Sunday call with Mom. She and Dad are flying in the second week of June. We talked through the rehearsal-dinner plan and the seating tangle with Dad's side.",
                keyPoints: [
                    "Flights confirmed for June 11-16.",
                    "Rehearsal dinner: Bar Primi, 6:30, 18 people.",
                    "Dad's cousins want to host a brunch the morning after.",
                    "Mom volunteered to handle the seating chart."
                ],
                actionItems: [
                    ActionItem(text: "Send Mom the venue confirmation PDF.", isCompleted: false),
                    ActionItem(text: "Loop the brunch into the welcome packet.", isCompleted: false)
                ],
                sentiment: .positive,
                topics: ["Family", "Wedding planning"],
                segments: [
                    ("Mom", "We were thinking we'd come in on the Wednesday before. Is that too early?"),
                    ("You", "Honestly Wednesday is perfect. The rehearsal is Friday so you'll have time to settle.")
                ]
            ),
            CallSpec(
                title: "Sam — work",
                contactName: "Sam Cohen",
                minutesAgo: 26 * 60,
                durationMinutes: 11,
                summary: "Standup follow-up with Sam. The migration is on track for Friday but the staging soak revealed a write-amplification issue on the new index. Pushing the cutover by 48 hours.",
                keyPoints: [
                    "Write amplification 3.4x on the new index, vs 1.2x estimated.",
                    "Cutover slipping from Friday → Monday.",
                    "Ops sign-off needed before we re-enable the dual-write.",
                    "No customer impact during the slip — the old path is still primary."
                ],
                actionItems: [
                    ActionItem(text: "File the index-redesign ticket and tag Sam.", isCompleted: false),
                    ActionItem(text: "Update the migration runbook in Notion.", isCompleted: false),
                    ActionItem(text: "Email ops about the new cutover window.", assignedTo: "Sam", isCompleted: false)
                ],
                sentiment: .neutral,
                topics: ["Side project"],
                segments: [
                    ("Sam", "Soak surfaced a write-amp issue. We're at 3.4x, which is a non-starter."),
                    ("You", "Slip the cutover. Tell ops we're holding the dual-write off until Monday.")
                ]
            ),
            CallSpec(
                title: "Dr. Patel — therapy",
                contactName: "Dr. Patel",
                minutesAgo: 2 * 24 * 60,
                durationMinutes: 50,
                summary: "Weekly session. Worked through the IBM decision and the underlying pull toward proving I belong somewhere prestigious. Homework: write the offer evaluation without ranking the brands at all.",
                keyPoints: [
                    "Pattern: brand-prestige bias overriding scope clarity.",
                    "Ask: what would make this offer good if the company were unknown?",
                    "Notice the urge to please Mom by picking IBM.",
                    "Sleep is the leading indicator — track it for two weeks."
                ],
                actionItems: [
                    ActionItem(text: "Write the brand-blind comparison sheet.", isCompleted: false),
                    ActionItem(text: "Track sleep daily through the decision.", isCompleted: true)
                ],
                sentiment: .positive,
                topics: ["Therapy", "Job search"],
                segments: [
                    ("You", "I keep coming back to the IBM logo. Like the prestige is doing something I'm not letting myself name."),
                    ("Dr. Patel", "Try the exercise where you remove the brand entirely. Just compare the work.")
                ]
            ),
            CallSpec(
                title: "Apartment broker",
                contactName: "Lena (broker)",
                minutesAgo: 3 * 24 * 60,
                durationMinutes: 14,
                summary: "Lena flagged a new listing on Carroll St — top floor, decent light, no W/D. We're going to see it Saturday. She thinks we can land $50 below ask.",
                keyPoints: [
                    "Carroll St listing — 1BR top floor, $3,150 ask.",
                    "No in-unit washer/dryer; building has a basement laundry.",
                    "Saturday 11am viewing.",
                    "Lena thinks $3,100 lands."
                ],
                actionItems: [
                    ActionItem(text: "Confirm Saturday 11am with Lena.", isCompleted: true),
                    ActionItem(text: "Re-pull the comps within 4 blocks.", isCompleted: false)
                ],
                sentiment: .positive,
                topics: ["Apartment hunt"],
                segments: [
                    ("Lena", "It's not glamorous but the light is real and the landlord is responsive."),
                    ("You", "If the comps support $3,100 I'm in. Saturday 11 works.")
                ]
            ),
            CallSpec(
                title: "Priya — IBM",
                contactName: "Priya Iyer",
                minutesAgo: 5 * 24 * 60,
                durationMinutes: 35,
                summary: "Final IBM round with Priya, the hiring manager. Talked through the platform team scope, the on-call expectations, and the path to staff. She'll send the formal offer tomorrow.",
                keyPoints: [
                    "Platform team is 8 engineers; growing to 14 in 12 months.",
                    "On-call: 1 week in 6.",
                    "Staff promotion path is documented; 18-24 months realistic.",
                    "Formal offer expected Wednesday."
                ],
                actionItems: [
                    ActionItem(text: "Reply with availability for the offer-review call.", isCompleted: true)
                ],
                sentiment: .positive,
                topics: ["IBM interview", "Job search"],
                segments: [
                    ("Priya", "I'd want you on the platform team. There's an internal staff opening in roughly 18 months that's a natural fit."),
                    ("You", "I appreciate you being concrete about the path. That's the thing I get hand-wavy answers about elsewhere.")
                ]
            ),
            CallSpec(
                title: "Maya — Lisbon",
                contactName: "Maya",
                minutesAgo: 9 * 24 * 60,
                durationMinutes: 27,
                summary: "Maya's locking dates for the Lisbon trip. Late October, 9 days, splitting between Lisbon and Sintra. She's mapping a day trip to Évora.",
                keyPoints: [
                    "Trip: October 18-27.",
                    "5 nights Lisbon, 3 nights Sintra.",
                    "Évora day trip on the 22nd.",
                    "Maya will draft the food list — you owe her the wine list."
                ],
                actionItems: [
                    ActionItem(text: "Block the dates with work and HR.", isCompleted: false),
                    ActionItem(text: "Draft the wine-bar shortlist.", isCompleted: false)
                ],
                sentiment: .positive,
                topics: ["Travel"],
                segments: [
                    ("Maya", "Évora is a stretch but worth it. Cork tree country, the bone chapel, all of it."),
                    ("You", "Sold. I'll block the dates this week.")
                ]
            ),
            CallSpec(
                title: "Standup",
                contactName: "Standup",
                minutesAgo: 15 * 24 * 60,
                durationMinutes: 9,
                summary: "Quick standup. Migration on track. Two design reviews shifted to Thursday. New hire starts Monday.",
                keyPoints: [
                    "Migration on track for Friday cutover (later slipped — see Sam — work).",
                    "Two design reviews moved to Thursday afternoon.",
                    "New hire onboarding Monday."
                ],
                actionItems: [
                    ActionItem(text: "Update the design-review calendar.", isCompleted: true)
                ],
                sentiment: .neutral,
                topics: ["Side project"],
                segments: [
                    ("You", "Migration's green. Design reviews are now Thursday. Anything else?")
                ]
            )
        ]

        var built: [(CallEntity, [TranscriptSegmentEntity], [String], [MindMapEdgeEntity])] = []
        for spec in specs {
            let call = CallEntity(
                id: spec.id,
                title: spec.title,
                contactName: spec.contactName,
                startedAt: Date.now.addingTimeInterval(-spec.minutesAgo * 60),
                endedAt: Date.now.addingTimeInterval(-spec.minutesAgo * 60 + spec.durationMinutes * 60),
                durationSeconds: spec.durationMinutes * 60,
                audioFileName: "seed-\(spec.id.uuidString).enc",
                audioDurationSeconds: spec.durationMinutes * 60,
                summary: spec.summary,
                keyPoints: spec.keyPoints,
                actionItems: spec.actionItems,
                sentimentLabel: spec.sentiment.rawValue,
                processingState: .complete,
                consentRecorded: true
            )
            let segments = spec.segments.enumerated().map { idx, seg in
                TranscriptSegmentEntity(
                    callId: spec.id,
                    startTimeSeconds: Double(idx) * 8,
                    endTimeSeconds: Double(idx) * 8 + 6,
                    speakerLabel: seg.label,
                    text: seg.text
                )
            }
            built.append((call, segments, spec.topics, []))
        }
        return built
    }
}
#endif
