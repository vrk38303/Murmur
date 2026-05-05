# NEXT — top 5 before TestFlight, in priority order

These are the things that matter most before you let any user touch this
build. Anything below the cut line in `LIMITATIONS.md` can wait.

## 1. Wire up real summarization

The whole product is "AI summary + mind map." A heuristic summary plus
empty action items is dishonest in a paid app. Pick one of:

- **Apple Intelligence** — implement the
  `SummarizationService.runFoundationModels` body. Test on iPhone 15 Pro
  and 16 family. Confirm the JSON schema parses on first try at least 80%
  of the time; the retry path costs latency users will feel.
- **Bundled MLX (Gemma 2 2B 4-bit)** — pull `mlx-swift-examples`, wire the
  runner into `runBundledMLX`. Install size goes up ~1.5GB; gate the
  download behind a Settings prompt rather than bundling.

Acceptance: a 5-minute conversation produces a 2–3 sentence summary, 3–7
key points, ≥1 plausible action item, and 2–4 topic labels. Run on 10
real conversations and eyeball the quality.

## 2. Encryption verification round-trip

The `EncryptedFileStoreTests` round-trip is in-memory. Before TestFlight,
verify that:

- Recording produces an `.enc` blob in `Application Support/Murmur/audio/`
- Pulling that blob off the device (e.g. via `idevicebackup2` or Xcode's
  device window) gives you opaque bytes
- `FileProtectionType.complete` is set; lock the device and confirm the
  store can't be opened by a backup tool
- Delete-all wipes the keychain key — running the app again should fail to
  decrypt previous blobs (which is the intended behavior)

If any of those fail, we are lying about "everything stays on this device."

## 3. Recording survives 30 minutes of background

PRD §14 calls this out explicitly. Test cases:

- Lock the device immediately after starting → 30-min file
- Recording while another VoIP app is foregrounded → no audio loss
- Memory pressure: open Safari with 30 tabs, switch back; engine should
  still be running

Watch for the `AVAudioSession` interruption notification path; we may need
a `voip` background mode after all if backgrounded recording dies on real
devices, despite PRD §5.3 saying we don't.

## 4. Paywall conversion moments

PRD §15.5.3 is specific about *when* to present the paywall. Right now we
gate at the limit (3rd recording, opening Mind Map, etc.) but we don't
trigger the **value moment** sheet on cross-call search. Add:

- A `SearchService` that runs across all transcripts and surfaces hits
- When a free user gets a hit across ≥2 calls, present the soft sheet with
  the wording from the PRD: "You have N conversations connected here.
  Murmur Plus unlocks all of them."

This is the conversion lever. Wire telemetry for "search returned N
results" → "paywall shown" → "purchase" while you're in there.

## 5. App Review messaging

The reviewer will assume you're building a phone-call recorder. PRD §15.6
says you must:

- Submit a 30-second demo video showing permission flow, consent reminder,
  recording start, live transcription, summary generation, mind map view
- Include the exact note: "Murmur records audio only when the user
  explicitly taps record. Transcription and summarization are on-device. We
  do not access cellular call audio. We do not transmit user data."
- Privacy nutrition label: **Data Not Collected** for everything (true if
  cloud features stay off, which they do by default)

Expect 1–3 rounds of review. Rejections in this category are usually about
language ("phone call" → "audio recording") and clear demonstration that
you don't tap the cellular call audio stream.

---

After these five, the next tier is: WhisperKit download flow, real
diarization, the `.zip` export, the share extension target, and Live
Activities / Dynamic Island for the recording state. None of those block
TestFlight.
