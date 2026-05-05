# Cowork pass — handoff (2026-05-04)

A Windows-only second pass that ran after the initial Claude Code launch report. Picked up the items the first pass flagged but didn't finish.

This is the document to read in 5 minutes if you're trying to figure out **what to do next**. The single source of truth for "what's the state of the launch" is still `LAUNCH_REPORT.md`; this file is a delta.

---

## What changed in this pass

### Tier 1 — Hosted URLs (App Store submission blocker)

- Created `docs/index.md`, `docs/privacy.md`, `docs/_config.yml`, `docs/README.md`. The site uses Jekyll's built-in `minima` theme so GitHub Pages compiles it on push with no custom build step.
- Replaced every `<support URL>` placeholder in `APP_STORE_METADATA.md` with `https://vrk38303.github.io/Murmur/` (literal `vrk38303` placeholder; you'll find-and-replace once you know your GitHub username).
- The dev-only README at `docs/README.md` walks the developer through enabling Pages from the GitHub UI.

**Status**: docs/ ready to ship. **Pages enable is a manual UI click — see action #2 below.**

### Tier 2 — Repo polish

- **Tier 2.1 — Paywall gated.** Wrapped `paywallVisible = true` in `Murmur/Features/Calls/CallsListViewModel.swift` `tapAdd()` behind `#if MURMUR_PAYWALL_ENABLED`. Added a Release-only `SWIFT_ACTIVE_COMPILATION_CONDITIONS` slot in `project.yml` configs, blank by default. To turn the paywall on once StoreKit products land, append `MURMUR_PAYWALL_ENABLED` to that string and re-`xcodegen generate`. **Default behaviour: free users see the recording sheet even past the cap, no dead-end paywall.**
- **Tier 2.2 — Real share sheet for export.** Added `shareItem: URL?` to `SettingsViewModel`. `exportLibrary` sets it from `bundle.archiveURL` on success. `SettingsView` replaces the old "Saved to filename" alert with a `.sheet` containing a `ShareSheet: UIViewControllerRepresentable` wrapping `UIActivityViewController`.
- **Tier 2.3 — Settings hint for dictation.** `Localizable.strings` `error.transcription.unavailable` now names the exact iOS path: Settings → General → Keyboard → Dictation, then Settings → General → Language & Region → On-Device Dictation. `TranscriptionService.swift` `startSFRecognizer()` surfaces the same string via `AppError.transcriptionUnavailable.errorDescription` instead of the silent `(transcription unavailable)` fallback.
- **Tier 2.4 — Apple Intelligence hidden until SDK lands.** `SummarizationService.bestAvailableEngine()` and `availableEngines()` both gate `.appleIntelligence` behind `#if canImport(FoundationModels)`. `SettingsView` picker now reads `vm.availableSummarizationEngines` (populated from the service on appear) instead of `SummarizationEngine.allCases`. The default engine flipped from `.appleIntelligence` to `.bundledMLX` so a fresh install doesn't land on a broken engine.
- **Tier 2.5 — ConsentReminderService unit test.** New `MurmurTests/ViewModelTests/SettingsViewModelTests.swift`. Single test mutates `vm.consentAlwaysRemind`, asserts `UserDefaults.standard.bool(forKey: "consent.alwaysRemind")` flipped, and confirms `services.consent.alwaysRemind` matches. Restores prior state in defer to avoid contaminating the global suite.

### Tier 3 — Mac-in-the-loop prep

- **Tier 3.1 — Screenshots lane.** `fastlane/Fastfile` now has a `screenshots` lane that calls `capture_ios_screenshots`. New `fastlane/Snapfile` targets iPhone 16 Pro Max, en-US, status-bar override, with `-MurmurSeedScreenshots` as a launch arg. New `MurmurUITests/MurmurSnapshots.swift` is a 6-method UI test driving the SCREENSHOT_PLAN.md states (`01-Hero` through `06-SettingsPrivacy`). New `MurmurUITests/SnapshotHelper.swift` vendors the standard Fastlane helper (MIT-licensed). The `MurmurUITests` target is wired into `project.yml` and added to the Murmur scheme's test step.
- **Tier 3.2 — Seed factory.** New `Murmur/App/MurmurDebugSeed.swift`, `#if DEBUG`-gated. Activates only when launched with `-MurmurSeedScreenshots`. Inserts 8 hand-written CallEntities ("With Neera", "Mom", "Sam — work", "Dr. Patel — therapy", "Apartment broker", "Priya — IBM", "Maya — Lisbon", "Standup") plus 8 TopicEntities, each call linked to 1-2 topics so the mind map produces a believable graph. Skips if any CallEntity already exists (idempotent on re-launch). Wired into `MurmurApp.swift` `.task` block. Real launches do not see the flag and skip seeding.
- **Tier 3.3 — Match init workflow.** New `.github/workflows/match-init.yml`. `workflow_dispatch`-only. Runs `bundle exec fastlane run match type:appstore app_identifier:app.murmur.Murmur`. The header comment says: **delete this file after one successful run** — leaving it in the repo means any collaborator who clicks Run workflow can overwrite the distribution cert.

### Tier 4 — App Store Connect readiness

- **Tier 4.1 — Click-by-click checklist.** New `APP_STORE_CONNECT_CHECKLIST.md`. 30 numbered steps covering enroll → API key → app record → bundle id → metadata → screenshots upload → privacy questionnaire → build selection → submit. Each step has a URL, the exact button to click, and the value to paste with a citation back to `APP_STORE_METADATA.md`, `WINDOWS_TO_APPSTORE.md`, or `docs/`.
- **Tier 4.2 — Demo video shot list.** New `APP_REVIEW_DEMO_VIDEO.md`. Second-by-second timed shot list for the 30-s demo video Apple needs to clear Guideline 2.5.9. Includes the voiceover script as one paste-able block, a pre-flight checklist, and a list of common mistakes. Built so the developer can record a single take with QuickTime + iPhone, no editing.

---

## READ ME — actions only you can do

Ordered by priority. Don't reorder; some are blocked by earlier ones.

### 1. Find-and-replace `vrk38303` (5 minutes)

Once you know your GitHub username (the one you'll push the repo from), run a find-and-replace across the repo:

- Find: `vrk38303`
- Replace: your-actual-github-username

Files affected:
- `docs/README.md`
- `APP_STORE_METADATA.md`
- `APP_STORE_CONNECT_CHECKLIST.md`
- `LAUNCH_REPORT.md`
- `COWORK_HANDOFF.md` (this file)
- `WINDOWS_TO_APPSTORE.md` (already had this placeholder before the Cowork pass)
- `PUBLISHING.md` (same)

PowerShell one-liner if you don't want to use VS Code's Find in Files:
```powershell
Get-ChildItem -Recurse -Include *.md,*.yml |
  ForEach-Object { (Get-Content $_.FullName) -replace 'vrk38303', 'your-actual-username' | Set-Content $_.FullName }
```

### 2. Enable GitHub Pages (2 minutes; required for App Store Connect submission)

After your first push to GitHub:

- Open: `https://github.com/vrk38303/Murmur/settings/pages`
- Source: **Deploy from a branch**
- Branch: **main**
- Folder: **/docs**
- Click: **Save**
- Wait ~60 s. The page will say *"Your site is live at `https://vrk38303.github.io/Murmur/`"*.
- Open `/` and `/privacy/` and confirm both render.

This produces the URL you'll paste into the Support URL and Privacy Policy URL fields in App Store Connect.

### 3. Enroll in Apple Developer Program (24-48 h wait)

`APP_STORE_CONNECT_CHECKLIST.md` step 1. $99 USD. Use vrkalavapalli@gmail.com. Pick **Individual**, not Organization. Apple emails approval; nothing else moves until that email lands.

### 4. Once enrolled — wire CI secrets (~15 minutes)

`APP_STORE_CONNECT_CHECKLIST.md` steps 4-10. Generates the App ID, the App Store Connect API key, the murmur-certs repo, and the GitHub Secrets that CI reads.

### 5. Run the one-shot Match init (~5 minutes, then delete)

`APP_STORE_CONNECT_CHECKLIST.md` step 11. Visit `https://github.com/vrk38303/Murmur/actions/workflows/match-init.yml`, click **Run workflow**, wait for green. Then `git rm .github/workflows/match-init.yml && git commit -m "Remove one-shot match init" && git push`.

### 6. First TestFlight build (~12 minutes elapsed; ~5 min of attention)

```powershell
git tag v0.0.1
git push origin v0.0.1
```

Watch `https://github.com/vrk38303/Murmur/actions`. When green, watch `https://appstoreconnect.apple.com/apps` → Murmur → TestFlight. The build appears in 5-15 min after the workflow finishes.

### 7. Capture screenshots (~10 minutes; needs CI macOS runner)

The `screenshots` Fastlane lane is wired but won't auto-run. Trigger it from CI manually (you'll need to add a `screenshots.yml` workflow file or add it as a job to your existing testflight workflow — I left this unwired because it's a one-shot per release and a single CI button is simpler than auto-running on every tag).

A minimal `.github/workflows/screenshots.yml` would be:
```yaml
name: Screenshots
on: { workflow_dispatch: }
jobs:
  shots:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with: { ruby-version: "3.2", bundler-cache: true }
      - run: brew install xcodegen && xcodegen generate
      - run: bundle exec fastlane ios screenshots
      - uses: actions/upload-artifact@v4
        with:
          name: screenshots
          path: fastlane/screenshots/en-US/
```
Add it whenever you want the run; download the artifact zip from the run page.

### 8. Record the demo video (~10 minutes)

`APP_REVIEW_DEMO_VIDEO.md` has the second-by-second shot list and the voiceover script. Use QuickTime + USB-tethered iPhone with a TestFlight build installed. One take, save as `MurmurDemo.mov`.

### 9. Fill App Store Connect metadata (~30 minutes)

Walk `APP_STORE_CONNECT_CHECKLIST.md` from step 16 to step 28. Every value cites its source line in `APP_STORE_METADATA.md`. Stop at step 29 — that's the Submit button, which is yours to click after a final eyeball pass.

### 10. App Review (24-48 h wait + maybe 1 round of back-and-forth)

The most likely rejection is Guideline 2.5.9 ("are you recording phone calls?"). Reply with the demo video from step 8 + the App Review Notes wording in `WINDOWS_TO_APPSTORE.md` § "Required App Review Notes". Apple typically clears within one round.

---

## Things this pass deliberately did NOT do

- **Did not enable GitHub Pages.** That's a Settings UI click only you can make.
- **Did not enroll in Apple Developer Program.** Requires your Apple ID, payment, and identity verification.
- **Did not generate App Store Connect API keys.** Tied to your Apple ID.
- **Did not register the App ID `app.murmur.Murmur`.** Tied to your Apple ID.
- **Did not push any tags.** No CI triggered.
- **Did not click "Submit for Review."** Yours.
- **Did not run `xcodegen generate`.** Windows can't run XcodeGen reliably; CI does this on the macOS runner.
- **Did not build or test any Swift on a Mac.** Source changes are static-verified by re-reading. Expect minor compiler nags on the first CI build (typical pattern for Windows-authored Swift).
- **Did not update the AppIcon placeholder.** Designer task, called out in `LAUNCH_REPORT.md` § 2 #4.

---

## Things to verify on the first Mac build

The Cowork pass touched these surfaces; eyeball them in the Xcode build phases / first simulator run:

- [ ] `MurmurUITests` target appears in the scheme picker. Test action runs both unit + UI tests.
- [ ] `MurmurDebugSeed.swift` only compiles into Debug builds (the `#if DEBUG` gate is at file scope).
- [ ] Launching with `-MurmurSeedScreenshots` from Xcode (Edit Scheme → Run → Arguments → Arguments Passed On Launch) inserts the 8 seed calls without duplicates on second launch.
- [ ] Settings → Privacy → Export library opens the iOS share sheet with the .zip selected (not an alert).
- [ ] Settings → Summarization → Engine picker does NOT show "Apple Intelligence" on the iOS 18 SDK build.
- [ ] Settings → Reset map positions still works (regression check; not changed in this pass).
- [ ] `consent.alwaysRemind` UserDefaults round-trip test passes.
- [ ] Recording on a locale without an on-device speech model surfaces the new Settings-path string instead of "(transcription unavailable)".

If any of these regress, the diff to bisect is small — every change in this pass is in the files listed in `LAUNCH_REPORT.md` § 9.

---

*Cowork pass complete. The launch is now blocked on Apple-account-side actions only — every Windows-doable item from the original `LAUNCH_REPORT.md` § 2 has been progressed or queued for the developer above.*
