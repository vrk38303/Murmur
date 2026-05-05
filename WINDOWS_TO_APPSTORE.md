# Murmur — Windows → TestFlight → App Store

The exact step-by-step launch path for a developer working on Windows
with no local Mac. Everything in this document is doable from a Windows
browser + VS Code; the one mandatory Mac step (initialising Fastlane
Match) takes ~10 minutes on a $1 cloud Mac, or zero minutes if you
choose the Codemagic path that automates it.

> Already covered in detail in `PUBLISHING.md` — this file is the
> consolidated launch checklist that pulls Apple Developer enrollment,
> CI choice, signing, App Store Connect setup, and review submission
> into a single linear playbook. Read both.

---

## Cost summary

| Item                                | Cost      | Frequency |
|-------------------------------------|-----------|-----------|
| Apple Developer Program             | $99       | yearly    |
| GitHub Actions macOS minutes (private) | $0–$5  | per build |
| **OR** Codemagic free tier          | $0        | up to 500 build-min/mo |
| Match init via cloud Mac (one-shot) | ~$1       | once + yearly cert renewal |
| **First-year total**                | **~$110** |           |

You do NOT need to buy a Mac. You do NOT need to install Xcode.

---

## Pick your CI lane (do this once, before step 2)

Both pipelines are committed to this repo. Pick one and disable the
other so you don't double-upload to TestFlight:

| Lane | File | Free? | Mac required? | Best when… |
|------|------|-------|---------------|------------|
| **GitHub Actions + Fastlane Match** | `.github/workflows/testflight.yml` | Free for public repos; ~$0.16/min for private | Yes — one ~10-min cloud-Mac session to init Match (or use the workflow_dispatch one-shot in PUBLISHING.md option D for a true zero-Mac path) | You already use GitHub Actions, want full control over signing, are OK with Fastlane's learning curve |
| **Codemagic** | `codemagic.yaml` | 500 build-min/month free | **No** — Codemagic's `app-store-connect fetch-signing-files --create` mints the cert + profile from your API key on the runner | You want the smoothest first-time setup, don't want to learn Fastlane Match, are OK with a vendor-specific dashboard |

**Recommendation for a solo Windows dev shipping their first iOS app:
Codemagic.** Less ceremony, less to debug, no cert-management baggage.
Switch to Actions later if you outgrow the free tier or want fully
open-source CI config.

To disable the lane you're not using: comment out the trigger block in
the file you're not picking. Example for the Actions lane:

```yaml
# on:
#   push:
#     tags:
#       - 'v*.*.*'
on:
  workflow_dispatch:
```

---

## Step 1 — Apple Developer Program ($99, ~24-48 h wait)

**From Windows browser.** This is the only step with a hard wait.

1. Go to <https://developer.apple.com/programs/enroll/>
2. Sign in with an Apple ID (or create one). **Use the email
   `vrkalavapalli@gmail.com`** so we can wire it through Fastlane.
3. Choose **Individual** ($99/year). Skip Organization unless you
   already have a D-U-N-S number — the verification adds 1-2 weeks.
4. Pay. Apple emails approval within 24-48 hours.
5. Enable two-factor auth on the Apple ID. **Save backup recovery
   codes in your password manager.** You will need 2FA for at least one
   step (Match init); CI uses an API key after that and never needs 2FA
   again.

Outputs: an Apple Developer account; an Apple Team ID (10-char
alphanumeric, visible at <https://developer.apple.com/account>).

---

## Step 2 — App Store Connect listing (~10 min, before any build upload)

**From Windows browser.** Apple won't accept TestFlight uploads until
the App Store Connect record exists.

1. Go to <https://appstoreconnect.apple.com/apps>
2. Click **`+` → New App**
3. Fill:
   - Platform: **iOS**
   - Name: **Murmur** *(must be globally unique on the App Store; if
     taken, prepend "Murmur — ", "Murmur Notes", "Murmur Voice", etc.;
     see `APP_STORE_METADATA.md` for fallbacks)*
   - Primary language: **English (U.S.)**
   - Bundle ID: pick **`app.murmur.Murmur`** if you've already created
     it in step 3 of `PUBLISHING.md`. If not: do that first, then
     come back here.
   - SKU: `MURMUR-IOS-001` (any unique string; never visible to users)
   - User access: **Full Access**
4. Save. The shell record is created. You can fill metadata, screenshots,
   pricing, etc. later — only the shell needs to exist before TestFlight.

---

## Step 3 — App Store Connect API key (~5 min)

**From Windows browser.** This key is what CI uses to sign in to App
Store Connect; it replaces your username + 2FA. Treat it like a
password.

1. <https://appstoreconnect.apple.com/access/integrations/api>
2. **Keys** tab → **`+`**
3. Name: `Murmur CI`
4. Access: **App Manager** (minimum to upload TestFlight builds; use
   **Admin** if you want CI to also manage app metadata).
5. **Generate**. Apple shows the .p8 file ONCE. Download immediately
   into your password manager / 1Password vault. Note also:
   - **Issuer ID** (UUID at top of page)
   - **Key ID** (10 chars next to the key name)

Outputs: 3 secrets you'll paste into GitHub Secrets (or Codemagic env
vars) in step 5.

---

## Step 4 — Signing material

This is the step Codemagic vs GitHub Actions diverges. Pick whichever
matches your CI choice in step 0.

### Step 4a (Codemagic path) — connect your API key, done

1. Codemagic dashboard → **Teams → Personal Account → Integrations →
   Developer Portal**
2. **App Store Connect** → Add API key → paste Issuer ID + Key ID +
   .p8 contents from step 3.
3. Name the integration `Murmur App Store Connect` (must match the
   `integrations:` line in `codemagic.yaml`).
4. The first time the workflow runs, Codemagic's
   `app-store-connect fetch-signing-files --create` command will:
   - Mint a new iOS distribution certificate against your API key
   - Create the App Store provisioning profile for `app.murmur.Murmur`
   - Cache both for the next build

**No Mac required.** Skip to step 5.

### Step 4b (GitHub Actions path) — initialise Fastlane Match (one Mac session, ~$1)

Match stores certs and profiles, encrypted, in a separate private GitHub
repo. CI fetches and decrypts on demand.

1. **From Windows browser**: create a new private GitHub repo named
   `murmur-certs` — DO NOT initialise with a README.
2. **From Windows PowerShell**: generate a fine-grained PAT at
   <https://github.com/settings/tokens?type=beta> with Read & Write on
   `murmur-certs` only. Then base64-encode `gh-username:token`:
   ```powershell
   [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("yourname:ghp_xxxxx"))
   ```
   Save the output as `MATCH_GIT_BASIC_AUTH`.
3. Pick a **Match passphrase** (24+ random chars). Save in password
   manager as `MATCH_PASSWORD`. **If you lose this, you start over.**
4. **Initialise Match** — pick one of:
   - **MacInCloud Pay-As-You-Go** ($1, ~10 min). Browser-based macOS
     desktop. See PUBLISHING.md step 8 Option B for the exact terminal
     commands.
   - **GitHub Actions one-shot workflow** (zero Mac, true zero-Mac
     path). See PUBLISHING.md step 8 Option D. Requires an
     app-specific Apple ID password from
     <https://account.apple.com/account/manage>.
   - **Borrow a Mac** for 10 minutes if a friend has one.

Output: an encrypted certificate + profile sitting in `murmur-certs`,
ready for CI to decrypt.

---

## Step 5 — CI secrets

### Codemagic

Settings → Environment variables → variable group **`appstore`** (mark
Secret):

| Variable | Source |
|----------|--------|
| `APP_STORE_CONNECT_ISSUER_ID` | Step 3 |
| `APP_STORE_CONNECT_KEY_IDENTIFIER` | Step 3 |
| `APP_STORE_CONNECT_PRIVATE_KEY` | Paste full .p8 file from step 3 |

That's it for Codemagic — manual signing variables are unused on the
zero-Mac automatic path.

### GitHub Actions

Repo → Settings → Secrets and variables → Actions → New repository
secret:

| Secret | Source |
|--------|--------|
| `APP_STORE_CONNECT_KEY_ID` | Step 3 (10 chars) |
| `APP_STORE_CONNECT_ISSUER_ID` | Step 3 (UUID) |
| `APP_STORE_CONNECT_KEY_P8` | Paste full .p8 contents |
| `MATCH_PASSWORD` | Step 4b passphrase |
| `MATCH_GIT_URL` | `https://github.com/<you>/murmur-certs.git` |
| `MATCH_GIT_BASIC_AUTH` | base64 from step 4b |
| `KEYCHAIN_PASSWORD` | Any random string (`openssl rand -hex 32`) |
| `APPLE_ID` | `vrkalavapalli@gmail.com` |
| `APPLE_APP_SPECIFIC_PASSWORD` | Only needed if you used the
                                 PUBLISHING.md option D zero-Mac path |

---

## Step 6 — First build smoke test

```powershell
# from Windows PowerShell, in the repo root
git tag v0.0.1
git push origin v0.0.1
```

- **GitHub Actions**: watch <https://github.com/{you}/Murmur/actions>
- **Codemagic**: watch the Codemagic dashboard

Expected timing: ~12 min total (most of it is `xcodebuild`).

If it fails, the most likely causes (in decreasing order):
1. Bundle ID mismatch — `app.murmur.Murmur` in `project.yml` doesn't
   match what you registered. Fix project.yml, re-tag.
2. Missing/wrong secret — re-check step 5 against the exact spelling
   above. Codemagic prints the variables it's reading; Actions does
   not (security feature) but the failing step name will tell you which
   API was rejected.
3. Code signing identity not found — usually means your Match passphrase
   or git auth is wrong. Re-run the Match init step.
4. Compile error — fix in your editor, push, re-tag.

When green, Apple processes the IPA over ~5-15 min. Check
<https://appstoreconnect.apple.com/apps> → your app → **TestFlight**.

---

## Step 7 — TestFlight internal testing

**From Windows browser.** Internal testing requires zero App Review.

1. App Store Connect → your app → **TestFlight** → Internal Testing →
   `+` → name the group "Internal" (matches `codemagic.yaml`).
2. Add testers by Apple ID email. They get a TestFlight invite within
   ~5 min.
3. Each tester downloads the **TestFlight** app from the App Store on
   their iPhone, accepts the invite, and installs Murmur.
4. Iterate: every `git tag v0.0.x && git push --tags` produces a new
   TestFlight build automatically.

Hand testers `TESTFLIGHT_NOTES.md` so they know what to test and what's
intentionally not done yet.

---

## Step 8 — App Store Connect listing — fill metadata

**From Windows browser.** Use `APP_STORE_METADATA.md` and
`SCREENSHOT_PLAN.md` from this repo as your copy-paste source.

App Store Connect → your app → **App Information**:
- Name (max 30 chars)
- Subtitle (max 30 chars)
- Category: Primary **Productivity** / Secondary **Utilities**
- Content Rights: confirm you own all content
- Age Rating: **4+** (no objectionable content; clean utility)

App Store Connect → your app → **iOS App** → **1.0 Prepare for
Submission**:
- Promotional Text (170 chars; can be edited without re-submitting)
- Description (4000 chars)
- Keywords (100 chars; comma-separated)
- Support URL: **REQUIRED**. Easiest options:
  - GitHub Pages from this repo: enable Pages, set up `docs/index.md`,
    your URL becomes `https://<you>.github.io/Murmur`
  - A simple Notion / Carrd / Vercel landing page
- Marketing URL: optional
- Copyright: `2026 <Your Name>` *(year you first submit)*
- Sign-In Information: not required (Murmur has no accounts)
- App Review Notes: paste the exact disclaimer below
- Demo Account: not required
- Contact Information: your name + the email Apple should reach you at
- Screenshots: at least one set for iPhone 6.9" (iPhone 16 Pro Max).
  See `SCREENSHOT_PLAN.md` for the 6-screenshot plan. Capture them via
  the iOS Simulator on the macOS runner (Codemagic's `xcode-project
  build-ipa` output includes a build artifact you can use), or
  manually on a real device.
- App Store Icon: app already includes the 1024×1024 marketing icon
  from the asset catalog. App Store Connect pulls it automatically
  from the IPA.

### Required App Review Notes (paste verbatim)

```
Murmur is a private on-device voice-note recorder and conversation
summariser. Important context for App Review:

1. Murmur does NOT and CANNOT record cellular phone call audio. iOS
   provides no entitlement for that. Murmur records the device
   microphone only — what the user speaks aloud, plus what they choose
   to play through speakerphone. The user must explicitly tap the red
   record button to begin every recording.

2. All transcription is on-device using Apple's SFSpeechRecognizer
   (and SpeechAnalyzer where iOS 26 is available). No audio leaves the
   phone.

3. All summarisation is on-device using Apple Intelligence
   (FoundationModels) on supported hardware, or a bundled fallback.
   No audio or transcript leaves the phone.

4. There is no account system. There is no cloud sync (off by
   default; not yet implemented). The Privacy Manifest declares
   "Data Not Collected" for everything.

5. The app prompts the user to ask the other party for consent at the
   start of every recording. This is shown as a one-time education
   sheet on first use and a per-call reminder banner that the user
   can dismiss but cannot disable below the law's floor.

To reproduce a recording:
  • Launch the app, complete the 3-step onboarding (allow Microphone
    and Speech Recognition; Contacts is optional).
  • Tap the blue + button on the Calls list.
  • Tap the red dot on the sheet that appears.
  • Speak for a few seconds, then tap the red square stop button.
  • The Processing screen runs transcription → summarisation →
    mind-map linking on-device.
  • The Calls list now shows the new conversation; tap to view summary,
    transcript, and mind-map links.

Thank you for the review.
```

---

## Step 9 — Privacy questionnaire (required before submission)

App Store Connect → your app → **App Privacy** → **Get Started**.

Answer each section as below — these mirror the Privacy Manifest we
ship in the bundle (`Murmur/Resources/PrivacyInfo.xcprivacy`):

- **Data collection**: select **No, we do not collect data from this
  app**. (Murmur is fully on-device; no analytics, no crash reports
  with PII, no account system.)
- That's the entire questionnaire. Click **Publish**.

If you later add Sentry, Firebase, etc., you must come back and
update this. Apple's automated checks compare the questionnaire
against the privacy manifests bundled in your IPA and reject on
mismatches.

---

## Step 10 — Submit for Review

App Store Connect → your app → **iOS App** → 1.0 → **Add for Review**.

- **Build**: pick the most recent TestFlight build that you've actually
  exercised on a device.
- **Export Compliance**: `ITSAppUsesNonExemptEncryption = false` is set
  in our Info.plist; App Store Connect won't ask you the question.
- Click **Submit for Review**.

Expected wait: 24-48 hours for first review. Status moves
**Waiting → In Review → Pending Developer Release / Approved**.

### Common rejections + how to respond

1. **"Your app records phone calls" / Guideline 2.5.9**: This is the
   most likely rejection. Reply with a video reproducing the consent
   flow + recording, and the **App Review Notes** wording from step 8.
   Apple typically clears it within one round.
2. **"Missing demo content" / Guideline 2.1**: include a 30-second
   screen recording in App Review Notes showing onboarding → record →
   summary → mind map. Use QuickTime Player on a cloud Mac, or
   AltStore/Reflector on Windows to mirror a real device.
3. **"Missing required information" / Privacy Manifest**: shouldn't
   happen — we ship `PrivacyInfo.xcprivacy`. If it does, Apple will
   tell you which key is missing; add it to the manifest and re-submit.
4. **"Subscriptions not configured"**: if you haven't yet wired
   StoreKit 2 products in App Store Connect, REMOVE the paywall code
   path (`paywallVisible` in `CallsListViewModel`) before review — or
   configure the products. Don't ship a paywall that leads to nothing.

---

## Step 11 — Post-launch

After approval:

- **Phased release** (recommended for v1): App Store Connect →
  Version Release → "Automatically release this version with phased
  release for automatic updates". Apple ramps the update over 7 days.
- **Crash monitoring**: Xcode Organizer (only on a Mac) or
  App Store Connect → Analytics → **Crashes**. The latter works from
  Windows browser but is slower to update than the Xcode Organizer.
- **Reviews**: App Store Connect → your app → **Ratings and Reviews**.
  Reply to every 1-2 star review within 48 hours.
- **Update cadence**: aim for one release every 2-4 weeks while iterating.
  Each release is a new tag push; same flow as step 6.

### Annual maintenance

- **$99/yr Apple Developer renewal** — Apple emails 30 days out.
- **Cert expiry** — Apple distribution certs are 1-year. Match handles
  renewal if you re-run `fastlane match appstore --force` from a Mac.
  Calendar this annually. (Codemagic's automatic-signing path
  refreshes certs without intervention.)
- **Xcode major versions** — when Xcode 17 GA's, bump `xcode: 16.0` →
  `xcode: 17.0` in `codemagic.yaml` and `Xcode_16.app` → `Xcode_17.app`
  in the GitHub Actions workflow. Test in a PR branch first.
- **iOS deployment target** — currently 18.0. When iOS 26 ships GA,
  bump to 26.0 to light up `SpeechAnalyzer` and `FoundationModels` end-
  to-end.

---

## What this setup does NOT cover

- **Local development on Windows.** You can't run the iOS Simulator on
  Windows. Iterate via TestFlight builds (~12 min cycle). If you need
  faster iteration, MacInCloud hourly is ~$1/hour, or buy a used M1
  Mac mini ($400ish) once you ship weekly.
- **Apple Intelligence + SpeechAnalyzer real testing.** These only
  run on real iPhones (iPhone 15 Pro / 16 family for AI;
  any iPhone running iOS 26 for SpeechAnalyzer). TestFlight on a
  borrowed device is your iteration loop until you own one.
- **Push notifications.** Not used by Murmur v1. If you add them,
  enable Push Notifications capability in App ID and add the
  notification service entitlement.
- **In-app purchase pricing.** StoreKit 2 product IDs are referenced
  in `SubscriptionService` but the products themselves must be
  configured in App Store Connect → Monetization → Subscriptions
  before the paywall actually leads anywhere. **Do this before you
  submit for review or hide the paywall trigger.**
