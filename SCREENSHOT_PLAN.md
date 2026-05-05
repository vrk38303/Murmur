# Murmur — Screenshot Plan (iPhone 6.9", iPhone 16 Pro Max)

Apple requires screenshots in at least one device size. The 6.9" set
(iPhone 16 Pro Max, **1320 × 2868** pixels portrait) up-scales for the
6.7" / 6.5" classes automatically — capture this set first; everything
else is optional.

This plan is six screenshots. App Store Connect accepts up to ten.
Six is the right number for a v1 launch: the listing carousel shows
the first three above-the-fold; conversion drops sharply after #6.

## Capture environment

You're on Windows. To capture App-Store-grade screenshots you need
either:

- **The iOS Simulator on the macOS runner.** Add a `screenshots`
  Fastlane lane (uses `snapshot`) and run it via `bundle exec fastlane
  ios screenshots` from CI. Outputs land in `fastlane/screenshots/`
  ready to upload.
- **A real iPhone 16 Pro Max** (or borrow one). Take the screenshots
  with the standard side-button + volume-up combo; AirDrop them to
  yourself.

For the framing copy ("headline" and "subheadline" overlays below):
the easiest path is **Apple's free Screenshot Framing app
(deprecated 2023)** — replaced by **Rotato**, **Appstrings**, or
**Figma** with the iPhone 16 device frame from the Apple Marketing
Resources kit. Or use the App Store Connect-built-in basic frame
(no overlay) and skip the copy — screenshots without overlay copy
underperform but are valid for v1.

---

## Screenshot 1 — Hero: Live Recording mid-conversation

**Slot priority: 1st (most important; first frame in the carousel).**

| Field | Value |
|-------|-------|
| Screen | `LiveRecordingView` (dark theme) |
| State | Recording in progress (state == .recording), pulse mid-cycle, timer reading 02:14, contact name "With Neera," waveform bars at varying heights, live transcript reading "I think the IBM offer is solid but I want to talk through the timing before I commit—" (truncated mid-sentence to imply real-time capture) |
| Headline (above device) | **Just talk.** |
| Subheadline | **Murmur transcribes you live, on your device.** |
| Background | Warm cream gradient (#F6F2EA → #EFE9DD), 5° tilted device |
| Why it converts | Establishes the product in one frame: it's a recorder, it's transcribing, it's real-time. The pulse + waveform make it feel alive. |

**Capture trick:** start a recording on a real device, speak the
target sentence, let it transcribe for ~10 seconds, then take the
screenshot. The aggregated text and the timer will look authentic
rather than mocked.

---

## Screenshot 2 — Summary card on a finished call

**Slot priority: 2nd.**

| Field | Value |
|-------|-------|
| Screen | `CallDetailView` Summary segment (light theme) |
| State | A finished call, hero waveform stretched across the top, summary card reading 2-3 sentences, key-points card with 4 bullets, action-items card with one item checked and two unchecked |
| Headline | **What got said. What you agreed to.** |
| Subheadline | **Two-sentence summaries. Action items, ready to tick off.** |
| Background | Warm ivory (#F6F2EA), 5° tilt opposite to #1 |
| Why it converts | The "summary + action items" combo is the unique value prop. Showing it second after recording = "this is what you get for tapping that red button." |

**Capture trick:** the Bundled-MLX heuristic will produce a sterile
summary. For App Store screenshots, **manually edit one CallEntity**
in a debug build to have a hand-written summary, key points, and
action items that read like a real conversation. The screenshot
should reflect product *intent*, not the current placeholder
quality. (Apple does not require screenshots to be unedited.)

---

## Screenshot 3 — Mind Map view (the differentiator)

**Slot priority: 3rd. Last above-the-fold frame.**

| Field | Value |
|-------|-------|
| Screen | `MindMapView` (light theme) |
| State | ~12-15 nodes settled into a balanced layout. Mix of People (call) nodes and Topic nodes. Two visible accent-bordered "highlighted" nodes connected by a stronger edge. Filter pill "All" selected. A peek card visible in bottom-left for one of the topic nodes. |
| Headline | **Every conversation, connected.** |
| Subheadline | **The threads across your calls — visualised.** |
| Background | Same warm ivory gradient, no tilt (let the graph fill the frame) |
| Why it converts | This is the screenshot that distinguishes Murmur from "yet another voice memo app." If a viewer reaches frame 3 and sees the mind map, they understand we're not the same as Voice Memos.app. |

**Capture trick:** seed a debug build with 8-10 fake calls covering
themes "Job search," "Family," "Apartment hunt," "IBM interview,"
"Wedding planning." Let the mind map auto-connect produce the graph
naturally — the resulting layout is more believable than a hand-
arranged one.

---

## Screenshot 4 — Onboarding privacy promise

**Slot priority: 4th.**

| Field | Value |
|-------|-------|
| Screen | `OnboardingFlowView.WelcomeView` (light theme) |
| State | The Murmur radiating-arcs mark, the brand line "Murmur" / "Conversations, kept quietly." / "Every call stays on this device." / Continue button. |
| Headline | **Your voice, your phone.** |
| Subheadline | **No account. No cloud. No analytics. Ever.** |
| Background | Same warm gradient, no tilt |
| Why it converts | Privacy-first is Murmur's positioning. Showing the promise on the welcome screen — not as a footnote in the description — earns trust above the install button. |

**Capture trick:** delete-and-reinstall the TestFlight build to make
sure onboarding actually shows. Or temporarily flip
`@AppStorage("onboardingCompleted")` to `false` in a debug build.

---

## Screenshot 5 — Calls list with content

**Slot priority: 5th.**

| Field | Value |
|-------|-------|
| Screen | `CallsListView` populated with 5-7 calls (light theme) |
| State | Each row shows avatar, name, summary preview, mini waveform, duration. Variety of contacts ("Neera Patel," "Mom," "Sam — work," "Dr. Patel — therapy," "Apartment broker"). One row in "processing" state to show that affordance. |
| Headline | **Every call, easy to find.** |
| Subheadline | **Search across every transcript and summary.** |
| Background | Same warm gradient |
| Why it converts | "What does the app actually look like when you've used it for a month?" Fills in the picture for a viewer trying to imagine themselves as a regular user. |

**Capture trick:** seed 6-10 plausible CallEntity rows in a debug
build, including one in `.transcribing` state so the "· processing"
chip renders.

---

## Screenshot 6 — Settings showing privacy controls

**Slot priority: 6th. Reinforcement frame for security-conscious buyers.**

| Field | Value |
|-------|-------|
| Screen | `SettingsView` scrolled to show Privacy section (light theme) |
| State | "Privacy" header visible at top. Rows: Privacy = "On-device only," Export library, Delete all data (red). Below, the Recording section with "Consent reminder" toggle ON. |
| Headline | **Take it all. Or wipe it all.** |
| Subheadline | **Export anytime. Delete with Face ID, instantly.** |
| Background | Same warm gradient |
| Why it converts | Closes the loop on the privacy promise. Buyers who care about export and deletion (a real cohort for "private" apps) need to see this control surface before they tap install. |

---

## Capture order (= App Store Connect upload order)

The order above is the conversion-optimised order. Upload them in
this exact sequence — App Store Connect uses upload order as display
order.

1. Live recording (hero) →
2. Summary card →
3. Mind map →
4. Onboarding privacy promise →
5. Calls list →
6. Settings privacy controls

---

## Production checklist

- [ ] Set up the Fastlane `snapshot` lane (or capture on a real
      iPhone 16 Pro Max).
- [ ] Seed the simulator/device with realistic content for #2, #3, #5.
- [ ] Capture all 6 at the correct resolution (1320×2868).
- [ ] Frame the device + add headline/subheadline overlays in Figma /
      Rotato (or upload bare for v1; framing can be added in a
      metadata-only update without re-review).
- [ ] Verify each PNG is sRGB color profile (App Store Connect
      sometimes rejects display-P3).
- [ ] Upload to App Store Connect → Media → iPhone 6.9" Display.
- [ ] Spot-check on an actual phone via the App Store Connect "Preview
      App Store Page" feature before submission.

---

## Optional: 6.5" / 5.5" sizes

App Store Connect will accept the 6.9" set as the source-of-truth
for older device classes too. You only need to capture additional
sizes if the 6.9" screenshots crop awkwardly — which they don't for
Murmur's text-light, padding-generous layout.

If you want to be thorough: also capture at iPhone 8 Plus (5.5",
**1242 × 2208**). Anything between 6.9" and 5.5" is auto-derived.

## Optional: iPad screenshots

Murmur's `project.yml` is `TARGETED_DEVICE_FAMILY: "1"` (iPhone only)
so iPad isn't an issue at all for v1. Don't fill the iPad slots — App
Store Connect will skip them.
