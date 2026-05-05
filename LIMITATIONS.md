# LIMITATIONS

This is an honest log of every place we deferred, stubbed, or worked around a
platform constraint. Read it before you tell anyone "Murmur is done."

## Generation environment

- The scaffolding agent ran on **Windows**, with no Apple toolchain, no
  Xcode, and no iOS simulator. Source files were written from the PRD and
  the design package.
- Consequence: nothing in this repo has been compiled. Expect to fix
  small Swift compiler errors during the first Xcode build. The architecture
  and shapes are correct; expect the corrections to be local (missing
  imports, `@MainActor` mismatches the compiler will flag, optional binding
  patterns).
- We did not generate `Murmur.xcodeproj/project.pbxproj` by hand because
  hand-written pbxproj is fragile and impossible to review. Instead, the
  repo ships a `project.yml` for **XcodeGen**. Run `xcodegen generate` on a
  Mac and the project file appears.

## Cellular phone calls

- We cannot record cellular phone audio. iOS provides no entitlement for
  this. PRD §2.1 covers the workarounds. The product surfaces three
  supported sources (speakerphone, VoIP via share extension, manual record).
  The Share Extension target is **scaffolded but not implemented in v1** —
  see PRD §12. Adding it later is a target-level change; the recording
  pipeline already accepts arbitrary audio.

## Apple Intelligence / Foundation Models

- The `SummarizationService.runFoundationModels` call site is the only
  place that needs the iOS 26 SDK. The current code path:
  - Compiles against iOS 18 because the call is wrapped in
    `#if canImport(FoundationModels)` and `#available(iOS 26, *)`.
  - Returns `AppError.summarizationUnavailable` until the SDK is wired in.
- Once the SDK lands, the body becomes:
  ```swift
  let session = LanguageModelSession()
  let resp = try await session.respond(to: prompt)
  return resp.content
  ```
- Until then, the service falls back to the **Bundled MLX** engine, which is
  itself a heuristic stand-in (see below).

## Bundled MLX (Gemma 2 2B 4-bit)

- The PRD calls for `mlx-swift-examples` running a quantized Gemma. The
  current code path produces a **deterministic heuristic** that:
  - Pulls 2 mid-length sentences as a "summary"
  - Picks 4 short sentences as "key points"
  - Computes topic candidates by frequency
  - Returns sentiment `neutral` and zero action items
- This unblocks the rest of the pipeline (mind map, persistence, UI) so
  the app is end-to-end testable, but is **not real summarization**. The
  Settings screen labels the engine "Bundled (MLX)" without "preview" — fix
  that label before TestFlight ship if MLX isn't wired up.

## SpeechAnalyzer (iOS 26)

- The `TranscriptionService` always lands on `SFSpeechRecognizer` for the
  buffer-feed code path because `SpeechAnalyzer` has a different streaming
  shape and we don't want a path that compiles against the iOS 26 SDK only.
- Engine **selection** still surfaces SpeechAnalyzer as an option; on iOS 26
  hardware you can implement the streaming hookup behind the
  `#if canImport(Speech) && #available(iOS 26, *)` block.

## WhisperKit

- WhisperKit (argmaxinc) is referenced in Settings as a downloadable engine.
  The model download UI is wired ("Download Whisper Large V3" row) but the
  actual fetch + on-disk cache is **not implemented**. WhisperKit also runs
  in batch mode in the OSS package, so the streaming `feed(buffer:)` path
  no-ops while WhisperKit is selected — recordings will produce no live
  transcript and only get transcribed in `endStreaming`. We left a TODO at
  the call site.

## SpeakerKit / diarization

- Diarization is settings-exposed as Off / Heuristic / Pro. The heuristic
  path simply labels every segment "You" or "Speaker 2" by a placeholder
  rule. Real energy-and-pitch heuristics need to live in
  `TranscriptionService` next to the buffer feed.
- "SpeakerKit Pro" is a settings toggle that does not download or run a
  diarization model. Don't enable it in production until that work lands.

## Embeddings

- `ContextualEmbedder` uses `NLContextualEmbedding` (iOS 17+). When the
  model isn't available for the user's locale, it falls back to a
  hash-based "shape" vector so clustering doesn't crash. The fallback is
  intentionally low-quality; cosine similarity becomes meaningless when both
  vectors are hash vectors. Mind map merging will look strange in that
  state. If you ship to a locale `NLContextualEmbedding` doesn't support,
  bundle a Core ML `all-MiniLM-L6-v2` and replace the fallback.

## CallKit Share Extension

- Target is unscaffolded. PRD §12 says "scaffold but ship disabled if time is
  constrained." Time was constrained.

## Mind map

- Layout is Fruchterman-Reingold, runs synchronously inside an actor method.
  At 200+ nodes the first computation can spike CPU; subsequent loads use the
  cached positions. If perf is a problem, move the inner loop to a
  background `Task` and chunk the iterations.
- The PRD says "200 nodes at 60 fps on iPhone 13." We have not measured this.

## Encryption

- Audio at rest is AES-256-GCM via the keychain key. SwiftData store relies
  on `FileProtectionType.complete` — we set it on the store URL after
  creation, but if the process happens to run before the device is unlocked
  for the first boot, the protection class may not stick. Verify with
  `xattr -l` on a real device.

## Export

- We produce a **directory** of JSON files (and optionally decrypted WAVs)
  under `tmp/MurmurExport-*`. The PRD specifies a `.zip`. Building a real
  zip from Swift on iOS requires either `Compression`-based hand assembly or
  importing a small library. We hand off the directory URL to the system
  share sheet; the user can save a folder via Files / AirDrop. Adding
  zipping is a 30-line change with `Compression`'s `LZFSE` archive — wire
  it before the App Store submission for nicer ergonomics.

## Tests

- `RecordingService` has no tests. AVAudioEngine is hard to fake without
  mocking the entire AVFoundation surface, and Apple discourages it. The
  testing strategy here is integration-level on a device, per `TESTING.md`.

## Things the prototype shows that the app doesn't yet do

- **Pull quote** card on the call detail — design shows a quoted line
  attributed to a speaker. The summarization JSON schema doesn't ask for it,
  so we don't render it. Adding `pullQuote: { text, speaker, timestamp }` to
  the JSON contract is a one-field change.
- **Search via voice** — the search bar shows a mic glyph but tapping it does
  nothing. Wire it up to `SFSpeechRecognizer` for one-shot voice queries.
- **Recording bookmark button** — the live recording screen shows a
  bookmark glyph. Tapping it should mark the current timestamp on the call.
  We logged the button but didn't add the bookmark model field.
