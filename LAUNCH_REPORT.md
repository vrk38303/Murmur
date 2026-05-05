# Murmur — Launch Report

**Date**: 2026-05-04
**Audit + fix pass**: senior iOS launch engineer, QA lead, App Store
strategist, release manager (combined role)
**Environment**: Windows 11. No Xcode, no simulator, no device. All
findings static + all fixes verified against the source by re-reading
the changed files.

---

## 1. Build status

### What's fixed in this pass

| # | Item | Why it mattered | Evidence |
|---|------|-----------------|----------|
| F1 | Added `Murmur/Resources/PrivacyInfo.xcprivacy` | **Mandatory** for App Store submissions since May 2024. Apple auto-rejects without it. | new file; wired into `project.yml` `resources:` |
| F2 | Generated `AppIcon-1024.png` placeholder | Asset catalog declared the icon but no PNG existed → "missing app icon" rejection at upload time | new 1024×1024 PNG in `AppIcon.appiconset/`; renderable proven |
| F3 | Documented full multi-size icon strategy | Avoids developer confusion about pre-Xcode-14 per-size sets | `AppIcon.appiconset/README.md` |
| F4 | Wired Settings "Reset map positions" to actually call `MindMapService.resetLayoutCache()` | Dead button is an App Review red flag and a real UX bug | `SettingsView.swift`, `SettingsViewModel.swift`, `MindMapService.swift` (added to protocol) |
| F5 | Hardened `RecordingService.stop()` against in-flight buffer Tasks | Race could truncate the trailing audio of a recording | `RecordingService.swift:179-188` |
| F6 | Renamed Bundled MLX engine to "Bundled (MLX) — preview" | LIMITATIONS.md called this out: "fix that label before TestFlight ship if MLX isn't wired up." Honest labelling matters for paid-app trust + App Review | `TranscriptUpdate.swift` `SummarizationEngine.displayName` |
| F7 | Settings pickers now use `displayName` instead of raw enum strings | The "preview" label and other human-readable engine names weren't actually visible to the user | `SettingsView.swift` `pickerRow(... displayLabel:)` |
| F8 | `codemagic.yaml` shipped — true zero-Mac CI path | Developer is on Windows, doesn't want to learn Fastlane Match | new file |
| F9 | Fixed build-number bump in both CI lanes (PlistBuddy, not agvtool) | XcodeGen bakes literal `CFBundleVersion` into Info.plist; agvtool's $(CURRENT_PROJECT_VERSION) target wouldn't update it. Would have caused "build number must be greater than previously uploaded" rejections on every release after the first. | `codemagic.yaml`, `fastlane/Fastfile` |

### What was already fixed (verified during audit, listed in QA_REPORT.md as "open" — that report was stale)

| Item | Status | Where it lives |
|------|--------|----------------|
| H3 — MindMap layout cache returns empty positions on first load | ✅ already fixed | `MindMapService.swift:225-235` (`allCached` + `lastNodeCount > 0` guards) |
| H4 — `transcribeFile` continuation leak | ✅ already fixed | `TranscriptionService.swift:145-172` (ContinuationBox + 120s timeout) |
| H5 — `@AppStorage` inside `@Observable` skips observation | ✅ already fixed | `ConsentReminderService.swift:22-61` (UserDefaults-backed stored properties) |
| M1 — `AVAudioConverter` allocated per buffer | ✅ already fixed | `RecordingService.swift:39, 113-122, 234-254` (session-scoped converter) |
| M3 — `extractJSONObject` brace counter doesn't escape strings | ✅ already fixed | `SummarizationService.swift:209-243` (`inString`/`escapeNext` tracking) |
| M4 — Settings consent toggle bypassing VM | ✅ already fixed | `SettingsViewModel.swift:104-107` (`consentAlwaysRemind` computed property) |
| M5 — Unused Combine import in RecordingService | ✅ already fixed | `RecordingService.swift:1-2` (only Foundation + AVFoundation) |
| Export → directory not .zip | ✅ already fixed | `ExportService.swift:86-119` (NSFileCoordinator `.forUploading` zip) |

### What still needs a Mac

These cannot be done from Windows. Each is a one-shot session, not
ongoing work:

1. **Initialise Fastlane Match** *(only if you choose the GitHub
   Actions lane; skipped entirely if you use Codemagic)*. ~10
   minutes on $1 of MacInCloud, or zero-Mac via the workflow_dispatch
   one-shot in `PUBLISHING.md` step 8 option D.
2. **Capture App Store screenshots**. 6 screens, plan in
   `SCREENSHOT_PLAN.md`. Easiest via Fastlane `snapshot` lane on the
   macOS runner.
3. **Smoke-test the actual built IPA on a real iPhone** before App
   Review submission. If you don't own one, install on a friend's
   device via TestFlight invite (works fully).
4. **Verify encryption-at-rest** by extracting the `.enc` blob from a
   sealed device with `idevicebackup2`. NEXT.md item #2; nice-to-have,
   not a launch blocker.

---

## 2. Launch blockers remaining

Listed in priority order. Items 1-3 must be addressed before App Store
submission. Items 4-6 are TestFlight-ready as-is but should be
addressed before public launch.

| # | Blocker | Severity | Where to fix |
|---|---------|----------|--------------|
| 1 | **App Store Connect listing doesn't exist yet** | Hard blocker | One-time setup, ~10 min in browser. See `WINDOWS_TO_APPSTORE.md` step 2. |
| 2 | **Apple Developer Program not enrolled** | Hard blocker, 24-48h wait | $99/year, browser-only. `WINDOWS_TO_APPSTORE.md` step 1. |
| 3 | **StoreKit subscription products not configured in App Store Connect** | Hard blocker IF the paywall is reachable | Two paths: (A) wire products in App Store Connect (5 product IDs are already declared in `SubscriptionService.swift:52-66`); (B) hide paywall trigger for v1 by short-circuiting `CallsListViewModel.tapAdd()`. **Pick (A) if you want to monetize in v1; (B) if you want a free-only launch.** |
| 4 | **AppIcon is a placeholder** (clean ripple mark, not finished art) | App-Store-launch blocker. TestFlight-OK | Hand to a designer; drop the result at `Murmur/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`. README in that folder has the brief. |
| 5 | **Real summarization not yet implemented** (MLX heuristic only) | Public-launch quality blocker; TestFlight-OK because UI labels it "preview" | NEXT.md item #1. Wire `SummarizationService.runFoundationModels` (Apple Intelligence) or `runBundledMLX` (mlx-swift-examples Gemma 2 2B). |
| 6 | **Support URL + Privacy Policy URL not yet hosted** | Hard blocker for App Store submission | 5 minutes of work — GitHub Pages or Carrd. Privacy policy text is provided in `APP_STORE_METADATA.md`. |
| 7 | **30-minute background-recording smoke test never run** | Public-launch quality risk | NEXT.md item #3. Lock device 30 min, verify file. |

The Windows audit found **zero remaining static-analysis launch
blockers** in the source code itself. Everything above is process /
configuration / content work.

---

## 3. Files changed in this pass

### Created

| File | Purpose |
|------|---------|
| `codemagic.yaml` | Zero-Mac CI/CD pipeline (alternative to GitHub Actions) |
| `Murmur/Resources/PrivacyInfo.xcprivacy` | Mandatory Apple Privacy Manifest |
| `Murmur/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png` | Placeholder ripple-mark app icon |
| `Murmur/Resources/Assets.xcassets/AppIcon.appiconset/README.md` | Icon brief + multi-size strategy notes |
| `WINDOWS_TO_APPSTORE.md` | End-to-end launch playbook from Windows |
| `TESTFLIGHT_NOTES.md` | Hand to internal testers |
| `APP_STORE_METADATA.md` | All copy options for App Store Connect |
| `SCREENSHOT_PLAN.md` | 6-screenshot conversion plan |
| `LAUNCH_REPORT.md` | This document |

### Modified

| File | Change | Reason |
|------|--------|--------|
| `project.yml` | Added `Murmur/Resources/PrivacyInfo.xcprivacy` to `resources:` | Bundle the manifest into the IPA |
| `Murmur/Services/MindMapService.swift` | Added `resetLayoutCache() async` to protocol | Expose existing actor method to the VM layer |
| `Murmur/Features/Settings/SettingsViewModel.swift` | Added `resetMapPositions()` method | VM surface for the new Settings row |
| `Murmur/Features/Settings/SettingsView.swift` | Wired "Reset map positions" row; pickers now use `displayName` | Dead button removal; correct labels in UI |
| `Murmur/Services/RecordingService.swift` | Added `await Task.yield()` after `engine.stop()` | Drain in-flight buffer Tasks before fileWriter teardown |
| `Murmur/Services/TranscriptUpdate.swift` | `SummarizationEngine.bundledMLX.displayName` → `"Bundled (MLX) — preview"` | Honest engine labelling |
| `codemagic.yaml` | (already created above) Build-number bump now uses PlistBuddy | XcodeGen bakes literal CFBundleVersion; agvtool wouldn't update it |
| `fastlane/Fastfile` | Build-number bump now uses PlistBuddy on Info.plist | Same reason |

---

## 4. Windows-to-App-Store path (the recommended route)

**For a solo developer on Windows shipping their first iOS app:**

1. **Pick Codemagic over GitHub Actions** — it's the true zero-Mac
   path; no Fastlane Match init required.
2. **Enroll in Apple Developer Program** ($99, 24-48h wait).
3. **Create the App Store Connect listing** (~10 min, browser).
4. **Generate App Store Connect API key** (~5 min, browser).
5. **Connect API key in Codemagic dashboard** as integration
   `Murmur App Store Connect`.
6. **Push a tag**: `git tag v0.0.1 && git push origin v0.0.1`.
7. **TestFlight build appears in ~12 min**, processed by Apple in
   ~5-15 min, then shows up under TestFlight in App Store Connect.
8. **Add yourself + test users to the Internal group** in App Store
   Connect → TestFlight.
9. **Iterate** by tagging new versions.
10. **For App Store**: fill metadata from `APP_STORE_METADATA.md`,
    capture screenshots per `SCREENSHOT_PLAN.md`, fill privacy
    questionnaire (Data Not Collected, top to bottom), paste the App
    Review notes from `WINDOWS_TO_APPSTORE.md` step 8, click Submit.
11. **Expected review timing**: 24-48 hours first round; expect 1-2
    rounds total because of the "is this a phone-call recorder"
    Guideline 2.5.9 conversation.

Total elapsed time from "today" to "v1.0 live in App Store":
**~5-10 days**, gated mostly on the 24-48h Apple Developer Program
verification + 24-48h initial App Review + your own
metadata/screenshot prep time.

---

## 5. App Store Package — final, ready-to-paste

Picked from the options in `APP_STORE_METADATA.md`. This is what to
paste into App Store Connect at submission time.

### App Name
```
Murmur
```
*(fallback if taken: `Murmur — Voice Notes`)*

### Subtitle
```
Private voice notes & summaries
```

### Promotional Text
```
On-device transcription, AI summaries, action items, and a mind map
that connects every conversation. All private. No account required.
```

### Description (Version C — conversion-optimised)
*(see `APP_STORE_METADATA.md` § "Version C" for the full 4000-char
text; paste verbatim. Replace `<support URL>` placeholders with your
actual URL once hosted.)*

### Keywords (97 / 100 chars)
```
recorder,transcribe,memo,call,meeting,summary,journal,notes,interview,private,offline,ai,whisper
```

### Category
- Primary: **Productivity**
- Secondary: **Utilities**

### Age Rating
**4+**

### Support URL
*Not yet hosted.* Recommended: enable GitHub Pages on the Murmur repo,
add `docs/index.md` with the privacy policy from `APP_STORE_METADATA.md`
+ a `mailto:` link, point Apple at
`https://<your-gh-username>.github.io/Murmur`.

### Privacy Policy URL
Same URL as Support URL (use a `#privacy` anchor or `/privacy`
sub-page).

### App Review Notes
*(see `WINDOWS_TO_APPSTORE.md` step 8 — paste verbatim. Includes the
critical "Murmur is NOT a phone-call recorder" framing.)*

### TestFlight notes (per build, in App Store Connect → TestFlight →
build → "What to Test")
```
Internal smoke test. Please verify:
1. Onboarding completes; Microphone + Speech Recognition both grant.
2. Tap +, tap red dot, speak 30s, tap stop. New call appears in list
   with a transcript.
3. Open call detail. Toggle an action item; leave the screen and
   come back; the toggle persists.
4. Mind Map tab loads without jitter.
5. Settings → Privacy → Export library produces a .zip.
6. Lock device with recording active; unlock 5 min later; recording
   continues, transcript still growing.

Known limitations in this build are documented in TESTFLIGHT_NOTES.md
in the repo root.
```

### Privacy nutrition checklist (App Store Connect → App Privacy)

✅ **Data Not Collected** for every category. The Privacy Manifest
(`Murmur/Resources/PrivacyInfo.xcprivacy`) backs this with declared
zero `NSPrivacyCollectedDataTypes`. If you ever add Sentry / Firebase
/ analytics, this answer changes — update both the questionnaire
*and* the manifest in lockstep or Apple will flag the mismatch.

### Screenshots (6, in this exact order)

1. Live recording mid-conversation (hero)
2. Summary card on a finished call
3. Mind map view (the differentiator)
4. Onboarding privacy promise screen
5. Calls list with content
6. Settings showing privacy controls

Plan + headline copy in `SCREENSHOT_PLAN.md`.

---

## 6. Risks I'm flagging that the developer should know

1. **The bundle id `app.murmur.Murmur` assumes the developer owns the
   `app.murmur` reverse domain.** Apple lets you register any prefix,
   so this works for an Individual account — but if you want to
   eventually transfer ownership to a company, register the domain
   `murmur.app` first and switch to `app.murmur.Murmur` knowing the
   match. If someone else has registered `app.murmur.Murmur` already
   in Apple's namespace (unlikely but possible), change
   `PRODUCT_BUNDLE_IDENTIFIER` in `project.yml`.
2. **`ConsentReminderService` consent toggle binding is technically
   observation-correct now but the unit test coverage for it is
   absent.** Worth a 30-line XCTest before public launch.
3. **The export "Saved to" alert just shows the file name** — the
   user has to know to look in tmp. We should hand the URL to
   `UIActivityViewController` (the share sheet) so they can save it
   to Files / AirDrop directly. Not a launch blocker; small UX miss.
4. **`TranscriptionService` falls back to "(transcription unavailable)"
   silently when `SFSpeechRecognizer.isAvailable` is false.** This is
   correct behavior, but doesn't tell the user *why*. On first launch
   on a non-English locale where the on-device model isn't installed,
   this will look like a bug. Worth a one-line fix to surface the
   "open Settings → General → Language & Region → On-Device Dictation"
   instruction.
5. **The Apple Intelligence engine code path
   (`runFoundationModels`) currently always throws
   `summarizationUnavailable`** because the SDK isn't wired. On
   iPhone 15 Pro / 16 with iOS 26, the picker will show "Apple
   Intelligence" as selected by default and produce no summary. Two
   options: (a) wire the SDK; (b) gate the picker option behind a
   `canImport(FoundationModels)` check so it only appears when the
   call site is real. Pick (b) for v1; do (a) before public launch.

---

## 7. Verification checklist for first Mac build

When the developer (or CI) runs the first `xcodegen generate +
xcodebuild` on a Mac:

- [ ] `PrivacyInfo.xcprivacy` shows up under "Copy Bundle Resources" in
      the build phases (XcodeGen wires it from `project.yml`).
- [ ] `AppIcon-1024.png` is referenced from the asset catalog without
      "missing image" warning.
- [ ] Strict-concurrency build succeeds (the codebase is
      `SWIFT_STRICT_CONCURRENCY: complete`; the `@unchecked Sendable`
      extensions on `AVAudioPCMBuffer` and `AVAudioFormat` may need to
      live in a separate file if the module-import order trips the
      compiler).
- [ ] All five test files pass:
      `xcodebuild test -scheme Murmur -destination 'platform=iOS
      Simulator,name=iPhone 16'`.
- [ ] On simulator: complete onboarding, tap +, tap red dot, tap stop,
      see Processing screen tick through, see new call in list. Tap a
      row, see CallDetailView; tap action-item box, leave screen, come
      back, box still checked.
- [ ] On simulator: Settings → Reset map positions does not crash.
      (Can't visually verify the layout reset without map data; pair
      with #3 below for a real check.)
- [ ] On simulator: Settings shows "Bundled (MLX) — preview" in the
      Summarization picker, not just "bundledMLX."

---

## 8. What the next pass should focus on

In priority order:

1. **Hosted support / privacy URLs** (5 min in GitHub Pages).
2. **Real designer-produced AppIcon** (placeholder is functional but
   not market-ready).
3. **Wire StoreKit products in App Store Connect** OR remove paywall
   trigger from `CallsListViewModel.tapAdd()` for the free-only v1.
4. **Real summarization** — Apple Intelligence on iOS 26 (NEXT.md #1).
5. **30-minute background recording smoke test on a real device**
   (NEXT.md #3).
6. **Encryption verification round-trip** (NEXT.md #2).
7. **Replace `decryptToTempFile` for export's audio path with a
   directly-streaming variant** so we don't write decrypted audio
   to tmp before zipping (avoids a brief unencrypted-on-disk window).

After all seven, Murmur is shippable to the public App Store.

---

*Audit + fix pass complete. The repo is now in a state where every
launch blocker that doesn't require a Mac, a designer, or an Apple
account has been addressed. The remaining blockers are accurately
named and each has an explicit next step.*

---

## 9. Cowork pass — 2026-05-04

A second round, also from Windows, picking up the items the first pass
flagged but didn't finish. The full action-by-action handoff lives in
`COWORK_HANDOFF.md`; this section is a one-page summary for future
reviewers.

### Created in this pass

| File | Purpose |
|------|---------|
| `docs/index.md` | GitHub Pages landing — "What is Murmur?" + FAQ + support mailto. Maps to App Store Connect Support URL. |
| `docs/privacy.md` | GitHub Pages privacy policy verbatim from `APP_STORE_METADATA.md`. Maps to App Store Connect Privacy Policy URL. |
| `docs/_config.yml` | Minimal Jekyll config using the built-in `minima` theme (no custom CSS, no build step). |
| `docs/README.md` | Step-by-step for the developer to enable Pages from the GitHub Settings UI. |
| `Murmur/App/MurmurDebugSeed.swift` | `#if DEBUG`-gated factory that inserts 8 hand-written calls + 8 topics behind the `-MurmurSeedScreenshots` launch arg. Drives believable App Store screenshots. |
| `MurmurUITests/MurmurSnapshots.swift` | 6-method UI test that drives the app through the SCREENSHOT_PLAN.md states and calls `snapshot("01-Hero")` etc. |
| `MurmurUITests/SnapshotHelper.swift` | Vendored Fastlane snapshot helper (MIT-licensed). |
| `MurmurTests/ViewModelTests/SettingsViewModelTests.swift` | Unit test confirming `consentAlwaysRemind` round-trips to `UserDefaults` via the VM. |
| `fastlane/Snapfile` | iPhone 16 Pro Max, en-US, status-bar override, `-MurmurSeedScreenshots`. |
| `.github/workflows/match-init.yml` | One-shot `workflow_dispatch` Match init per PUBLISHING.md option D. **Delete after one successful run.** |
| `APP_STORE_CONNECT_CHECKLIST.md` | 30-step click-by-click runbook for the developer's first App Store Connect session. |
| `APP_REVIEW_DEMO_VIDEO.md` | Second-by-second 30-s shot list for the Guideline 2.5.9 demo video. |
| `COWORK_HANDOFF.md` | Sibling to this report; lists every change + every action only the developer can do. |

### Modified in this pass

| File | Change | Reason |
|------|--------|--------|
| `APP_STORE_METADATA.md` | Replaced 6 `<support URL>` placeholders with `https://vrk38303.github.io/Murmur/` and `…/privacy/` | Tier 1.2 — paste-ready copy once GitHub username is known |
| `Murmur/Features/Calls/CallsListViewModel.swift` | Wrapped `paywallVisible = true` in `#if MURMUR_PAYWALL_ENABLED` | Free-only v1 — paywall is unreachable until StoreKit products are configured |
| `project.yml` | Added `configs:` block with `SWIFT_ACTIVE_COMPILATION_CONDITIONS` (Debug = `DEBUG`, Release = blank). Added `MurmurUITests` target. Added `MurmurUITests` to test scheme. | Paywall flag landing pad + UI test target wiring |
| `Murmur/Features/Settings/SettingsViewModel.swift` | Added `shareItem: URL?`, set on export success. Added `availableSummarizationEngines` populated from `SummarizationService.availableEngines()` on appear. Default summarization engine flipped from `.appleIntelligence` to `.bundledMLX`. | Real share-sheet hand-off; honest engine picker |
| `Murmur/Features/Settings/SettingsView.swift` | Replaced "Export ready" alert with `.sheet` containing `UIActivityViewController` representable. Picker now reads `vm.availableSummarizationEngines`. Added `loadAvailableEngines()` call in `.task`. Imported UIKit. | Tier 2.2 + 2.4 |
| `Murmur/Services/TranscriptionService.swift` | Replaced inline `(transcription unavailable)` fallback with `AppError.transcriptionUnavailable.errorDescription` so the streaming path surfaces the same Settings-path hint as the file path | Tier 2.3 |
| `Murmur/Resources/Localizable.strings` | `error.transcription.unavailable` now names the exact iOS Settings → General → Keyboard → Dictation path | Tier 2.3 |
| `Murmur/Services/SummarizationService.swift` | Gated `.appleIntelligence` in both `bestAvailableEngine()` and `availableEngines()` behind `#if canImport(FoundationModels)` | Tier 2.4 — picker won't expose Apple Intelligence on iOS 18 SDK builds |
| `Murmur/App/MurmurApp.swift` | Calls `MurmurDebugSeed.seedIfRequested(...)` from `.task` (DEBUG only). Honors `-MurmurUITestSkipOnboarding` and `-MurmurUITestForceOnboarding` via a derived `effectiveOnboardingCompleted`. | Tier 3.2 — screenshot tests can request seeded state without polluting real launches |
| `fastlane/Fastfile` | Added `screenshots` lane | Tier 3.1 |

### What's still left for the developer

See `COWORK_HANDOFF.md` § "READ ME — actions only you can do" for the
ordered list. Top three:

1. Enroll in the Apple Developer Program (24-48 h wait).
2. Enable GitHub Pages for `docs/` from the repo Settings → Pages UI.
3. Fill in the developer's GitHub username (find/replace `vrk38303`)
   in `APP_STORE_METADATA.md` and `APP_STORE_CONNECT_CHECKLIST.md`.

The remaining blockers from § 2 ("Launch blockers remaining") are
unchanged — none of them could be progressed without the developer's
Apple ID, payment method, or an actual Mac in the loop.
