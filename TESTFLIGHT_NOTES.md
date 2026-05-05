# Murmur — TestFlight Notes

Welcome, and thanks for testing. This is an early build. Below is what
to try, what's intentionally not done yet, and how to report bugs that
will actually help us fix things.

## What is Murmur?

A private on-device voice-note recorder that transcribes your
conversations and weaves the topics across calls into a mind map.
Everything stays on your phone. No cloud. No account.

## What to test

In rough priority order — top of list = most important.

### 1. First-launch flow

- Install from TestFlight, open the app fresh.
- Walk through the 3-step onboarding. **Allow microphone and speech
  recognition** when prompted (Contacts is optional).
- Confirm the consent education screen makes sense.

### 2. Record a call

- Tap the blue **+** in the Calls list.
- The "Ask first, then tap" sheet appears.
- Tap the red dot.
- The Live Recording screen takes over (dark UI, pulsing red dot,
  monospaced timer).
- **Speak for at least 30 seconds.** Watch the live transcript fill
  in as you talk.
- Hit Pause, then Resume — confirm the timer freezes during pause.
- Hit the red Stop button.
- Watch the Processing screen tick through "Transcribed", "Summarized",
  "Linked to map".
- Tap **Done**.
- The new call should appear at the top of the Calls list.

### 3. Open a call's detail

- Tap a call row.
- Switch between **Summary**, **Transcript**, and **Map** segments at
  the top.
- Check an action item box (if any). Leave the screen, come back, the
  check should persist.

### 4. View the mind map

- Tap the **Mind Map** tab.
- The graph should settle into place. Tap a node — a peek card slides
  in from the bottom-left.
- Try the **All / People / Topics** filter pills.

### 5. Settings

- Try **Export library** under Privacy. A `.zip` should be created and
  the share sheet should let you save it to Files / send via AirDrop.
- Try **Reset map positions** under Mind map — next time you open the
  Mind Map tab, the layout should re-compute from scratch.
- Try toggling **Dark mode** under Appearance.
- Move the **Auto-connect threshold** slider; the value display updates.
- **Delete all data** prompts Face ID / passcode and wipes everything
  if you confirm. *Use cautiously — there's no undo.*

### 6. Background recording

- Start a recording.
- Lock the device.
- Wait 5+ minutes.
- Unlock — recording should still be running, transcript still
  growing.

### 7. Interruption recovery

- Start a recording.
- Have someone call you (a real phone call). Murmur should pause.
- After the call, Murmur should resume automatically (or finalise
  the partial recording gracefully).

---

## Known limitations — please don't report these

These are intentionally not done in this build. We'd love feedback on
your *desire* for them, but bug reports will be closed.

### Transcription quality

- We use Apple's on-device speech recogniser. It's good but not
  perfect, and quality varies by accent, background noise, and the
  speaker model installed on your locale.
- **Speaker labels are always "You"** for now. Real multi-speaker
  diarization is coming. The Settings picker shows "Multi-speaker
  (coming soon)" — selecting it just bounces back to single-speaker.
- **Whisper Large V3** is listed as a transcription engine but the
  download isn't shipping in this build. Tapping it surfaces an
  honest "unavailable in this build" notice.

### Summarization

- The Summarization engine picker shows **"Bundled (MLX) — preview"**.
  This is honest: the current "Bundled" path is a *deterministic
  heuristic stand-in*, not a real LLM. It picks 2 sentences as a
  summary, 4 short sentences as key points, frequency-counts topic
  candidates, and returns sentiment "neutral" with no action items.
- **Apple Intelligence** is listed and selected automatically on iOS 26
  hardware. The actual `LanguageModelSession` call site is stubbed
  pending Apple's iOS 26 SDK GA — it currently returns
  "summarization unavailable" if you select it before the SDK ships.
- **Cloud summarization** is in the picker but disabled by default
  and will not function without explicit opt-in. We don't recommend
  enabling it in this build.

### Cellular phone calls

- Murmur **does not** and **cannot** record the audio of a regular
  cellular phone call. iOS provides no entitlement for that. To record
  a call: put it on speakerphone and start a Murmur recording, or use
  a separate recording device.
- A planned Share Extension for VoIP apps is scaffolded but not
  shipping in this build.

### Mind map

- Layout runs with a synchronous force-directed algorithm. Up to
  ~100-150 nodes is smooth; beyond that, the first layout may take a
  beat. (Subsequent loads use the cached positions; "Reset map
  positions" forces a recompute.)
- "Search via voice" mic glyph in the search bar is visible but does
  nothing yet.
- "Bookmark" button on the live recording screen is visible but does
  nothing yet.

### Subscriptions

- Free tier caps you at 3 recordings per month and gates Mind Map +
  AI Summary + Export.
- The paywall sheet **isn't fully wired to StoreKit products in this
  build**. Internal testers should use the developer-provisioned tier
  override (TestFlight builds default you to the paid tier so you can
  exercise everything).

### Cross-call search → "value moment" paywall

- PRD §15.5.3 specifies a soft paywall when a free user searches and
  finds matches across ≥2 calls. This trigger isn't wired yet. Don't
  expect it.

### Pull-quote card

- The design package shows a "Pull quote" card on the call detail page.
  It's not in this build because the summarization JSON doesn't yet
  produce the field. Coming once real summarization lands.

---

## What WILL look broken on your test device

- **iOS Simulator (if you're testing in it)**: live transcription
  doesn't work in the simulator. The simulator also routes the Mac
  mic, which AVAudioSession negotiation handles unreliably. **Use a
  real iPhone** for any audio-quality bug report.
- **Pre-iPhone-15-Pro devices**: Apple Intelligence won't run. The
  app falls back to the heuristic summarizer, which produces
  unimpressive summaries. This is expected.
- **iOS 17.x devices**: build target is iOS 18, won't install. Update
  the device or use a different one.
- **First-time launch right after install**: the consent education
  sheet may briefly appear behind a permission prompt. Tap through —
  it sorts itself on the next launch.

---

## How to record a useful bug report

Use the **TestFlight app** → Murmur → tap the **screenshot button**
(or send feedback). Or email <vrkalavapalli@gmail.com> with:

1. **Device + iOS version** (Settings → General → About → Model Name +
   Software Version).
2. **TestFlight build number** (visible at the top of the Murmur
   listing in the TestFlight app).
3. **What you did** — three to five bullet points reproducing the
   problem from launch.
4. **What you expected** vs **what happened**.
5. **Screenshot or screen recording** if visual.
6. **Specifically: was the device on Wi-Fi, on cellular, in
   airplane mode, with VPN, with Bluetooth headphones?** Audio bugs
   often correlate with peripheral state.

### What's a good bug

- "Recording stopped 3 minutes in when I switched to Safari" —
  reproducible audio-engine issue, very useful.
- "Tapping the Pause icon does nothing on second tap" — UI state bug,
  useful.
- "After deleting all data and recording a new call, the call's title
  was wrong" — persistence/state bug, useful.

### What's not a useful bug

- "The summary doesn't sound human" — known, see Limitations above.
- "Recording phone call audio doesn't work" — impossible by Apple's
  rules, see Limitations above.
- "Screenshot looks slightly different from the design" — unless it's
  unreadable or unusable, low priority.

---

## What we're specifically watching for

If you only have time to test a few things, we most want signal on:

1. **Does recording survive 30 minutes locked + backgrounded?**
   PRD § 14 calls this out as the smoke test we can't run remotely.
2. **Does the encrypted audio actually stay encrypted?** If you have
   a Mac and can `idevicebackup2` the sandbox out, the `.enc` files
   in `Application Support/Murmur/audio/` should be opaque bytes.
3. **Does action-item check-state persist** across leaving the call
   detail screen and coming back? (Was a real bug, fixed; want
   confirmation.)
4. **Does the new mind map layout actually reflect "Reset map
   positions"** — i.e. does it visibly re-flow on the next load?

Thanks for testing. If something feels off and you can't tell whether
it's a bug or a known limitation, send the report anyway and we'll
sort it.
