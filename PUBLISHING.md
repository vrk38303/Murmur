# Publishing Murmur from Windows

## The honest answer up front

There is no way around the fact that an iOS `.ipa` must be built on macOS,
signed with an Apple-issued certificate, and uploaded through Apple's
Transporter pipeline. Apple does not ship Windows tooling. Anyone telling
you otherwise is selling you a sideloading hack that will not pass App
Review.

**But** you do not need to *own* a Mac. You do not need to *touch* a Mac.
The macOS build runs in CI on a hosted runner, triggered by `git push`
from your Windows machine. Total elapsed time from "code committed" to
"build appears in TestFlight" is ~12 minutes.

This repo is already wired for that flow. You just need to do the
one-time Apple account setup. ~90 minutes total, mostly waiting on Apple.

---

## What's already in this repo

- `.github/workflows/testflight.yml` — GitHub Actions workflow that, on a
  `v*.*.*` tag push, runs `xcodegen → xcodebuild test → fastlane match →
  fastlane beta → upload to TestFlight`. All on Apple's hosted macOS-15
  runner. You provide secrets; CI does the rest.
- `.github/workflows/pr-tests.yml` — runs unit tests on every PR.
- `Gemfile` — Ruby deps (Fastlane + xcpretty).
- `fastlane/Fastfile` — the actual `certificates` and `beta` lanes.
- `fastlane/Appfile` — bundle id and team config.
- `fastlane/Matchfile` — points Match at your private signing-certs repo.

---

## One-time setup checklist

You do steps 1–7 from your Windows browser. Step 8 is a single 10-minute
session on a *cloud* Mac (free options listed). Step 9 is GitHub config.
After that, every future build is `git tag v1.0.x && git push --tags`.

### 1. Apple Developer Program — $99/year

- Browser: <https://developer.apple.com/programs/enroll/>
- Sign up with your Apple ID. Individual ($99) is fine for v1; the
  Organization tier needs a D-U-N-S number and is slower to approve.
- Wait 24–48 hours for Apple to verify your identity.

### 2. Create the App ID

- Browser: <https://developer.apple.com/account/resources/identifiers/list>
- Click `+` → App IDs → App
- **Bundle ID**: `app.murmur.Murmur` (must match `project.yml`)
- **Capabilities**: Background Modes, Speech Recognition (no others for v1)
- Save

### 3. Create the App Store Connect listing

- Browser: <https://appstoreconnect.apple.com/apps>
- My Apps → `+` → New App
- Pick the bundle id you just made. Fill in the basics; you can edit
  everything later. The listing must exist before TestFlight will accept
  uploads.

### 4. Create an App Store Connect API key

This replaces username/password auth and is what Fastlane uses from CI.

- Browser: <https://appstoreconnect.apple.com/access/integrations/api>
- Keys tab → `+` → name it "GitHub Actions Murmur"
- Access: **Admin** (or App Manager — needs to upload builds)
- Click Generate. **Download the .p8 file immediately** — Apple shows it
  exactly once.
- Note these three values; you'll paste them into GitHub Secrets:
  - **Issuer ID** (UUID at the top of the page)
  - **Key ID** (10-char alphanumeric)
  - **.p8 contents** (open the file in Notepad, copy everything)

### 5. Create a private GitHub repo for your signing certs

Match stores your certs and provisioning profiles, encrypted, in a
separate git repo. Don't put them in the main app repo.

- Browser: <https://github.com/new>
- Name: `murmur-certs`
- Visibility: **Private** (critical)
- Do NOT initialize with a README
- Note the URL: `https://github.com/<you>/murmur-certs.git`

### 6. Generate a GitHub Personal Access Token for CI to read that repo

- Browser: <https://github.com/settings/tokens?type=beta>
- Generate new token (fine-grained)
- Repository access: only `<you>/murmur-certs`
- Permissions: Contents → Read & Write
- Copy the token. Then base64-encode `<your-gh-username>:<the-token>`:
  - On Windows PowerShell:
    `[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("yourname:ghp_xxxxx"))`
  - That's the value for `MATCH_GIT_BASIC_AUTH`.

### 7. Pick a Match passphrase

Any string. 24+ chars random is good. Save it in your password manager.
This encrypts the certs at rest in the certs repo.

### 8. The one Mac step you cannot skip — initialize Match

This runs **once**, ever. It generates your distribution cert and
provisioning profile and stores them encrypted in the certs repo.

You have three free or cheap ways to do this:

**Option A — GitHub Codespaces with macOS (currently waitlisted, free if available)**
Skip; not yet GA.

**Option B — MacInCloud "Pay-As-You-Go" — ~$1**
- <https://www.macincloud.com/pay-as-you-go-plans>
- Sign up, launch a session. You get a Mac desktop in your browser.
- In the cloud Mac's Terminal:
  ```bash
  brew install xcodegen rbenv git
  git clone https://github.com/<you>/Murmur.git
  cd Murmur
  bundle install
  export MATCH_PASSWORD="<the-passphrase-from-step-7>"
  export MATCH_GIT_URL="https://github.com/<you>/murmur-certs.git"
  export MATCH_GIT_BASIC_AUTH="<base64-from-step-6>"
  bundle exec fastlane match appstore
  ```
- Match will:
  1. Ask you to log into Apple (paste your Apple ID + 2FA code)
  2. Create your distribution certificate
  3. Create the App Store provisioning profile
  4. Encrypt both with your passphrase
  5. Push them to the `murmur-certs` repo
- Log out of MacInCloud. You're done with macOS forever (unless certs
  expire, which is yearly — same drill, ~10 minutes).

**Option C — Borrow a friend's Mac**
- Free if you have one. Same commands as Option B.

**Option D — Ask Anthropic-Claude-on-a-Mac-runner via GitHub Actions one-shot**
You can also do the `match init` from a manually-triggered GitHub Actions
workflow. Add this temporary file at `.github/workflows/match-init.yml`,
push, run it once via "Actions → Run workflow", then **delete the file**:

```yaml
name: One-time Match init
on: { workflow_dispatch: }
jobs:
  init:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
      - run: gem install bundler && bundle install
      - env:
          MATCH_PASSWORD:        ${{ secrets.MATCH_PASSWORD }}
          MATCH_GIT_URL:         ${{ secrets.MATCH_GIT_URL }}
          MATCH_GIT_BASIC_AUTH:  ${{ secrets.MATCH_GIT_BASIC_AUTH }}
          FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD: ${{ secrets.APPLE_APP_SPECIFIC_PASSWORD }}
          APPLE_ID:              ${{ secrets.APPLE_ID }}
        run: bundle exec fastlane match appstore --shallow_clone
```

The catch: this needs interactive 2FA the first run, which CI cannot do.
Use an **app-specific password** from <https://account.apple.com/account/manage>
→ App-Specific Passwords. Set it as `APPLE_APP_SPECIFIC_PASSWORD`. Then
this workflow runs unattended.

This is the truly zero-Mac path. The downside: harder to debug if Apple
returns an error mid-flow.

### 9. Add GitHub Actions secrets

Browser: `https://github.com/<you>/Murmur/settings/secrets/actions` →
**New repository secret** for each:

| Secret name                     | Value |
|---------------------------------|-------|
| `APP_STORE_CONNECT_KEY_ID`      | from step 4 |
| `APP_STORE_CONNECT_ISSUER_ID`   | from step 4 |
| `APP_STORE_CONNECT_KEY_P8`      | the entire .p8 file contents from step 4 |
| `MATCH_PASSWORD`                | from step 7 |
| `MATCH_GIT_URL`                 | from step 5 |
| `MATCH_GIT_BASIC_AUTH`          | from step 6 |
| `KEYCHAIN_PASSWORD`             | any random string, e.g. `openssl rand -hex 32` |
| `APPLE_ID`                      | your Apple ID email |
| `APPLE_APP_SPECIFIC_PASSWORD`   | from step 8 option D, only if used |

### 10. Smoke-test from Windows

```powershell
# Just to prove the round trip works, push a tag.
git tag v0.0.1
git push origin v0.0.1
```

Watch the run at `https://github.com/<you>/Murmur/actions`.

If it goes green, open <https://appstoreconnect.apple.com/apps> →
your app → TestFlight. The build appears in ~5 min after the workflow
finishes (Apple needs time to "process" the IPA, which is opaque).

Add yourself as an internal tester to install on your phone via the
TestFlight app.

---

## What "publishing" actually looks like day-to-day

```powershell
# Edit Swift in VS Code or Cursor on Windows.
git add .
git commit -m "fix: paywall trigger on cross-call search"
git push

# When you want a build:
git tag v1.0.5
git push origin v1.0.5
# 12 min later it's in TestFlight.
```

To promote a TestFlight build to the public App Store, that's a *single
human button click* in App Store Connect ("Add for Review" → submit). No
re-build, no re-upload — TestFlight builds are App Store builds.

---

## Troubleshooting (the real-world list)

**"No code signing identity found" in CI**
Match passphrase wrong, or `MATCH_GIT_BASIC_AUTH` wrong. The error
message is bad; check both.

**"Provisioning profile doesn't include this device" in TestFlight**
You're trying to use a Development profile, not App Store. Check the
`type:` in `Matchfile` is `appstore`.

**Build number conflict ("This bundle is invalid… build number must be
greater than the previously uploaded version")**
Fastlane's `latest_testflight_build_number` should handle this. If it
breaks, manually bump `CFBundleVersion` in `project.yml` and re-tag.

**"Invalid provisioning profile signature" after a Match cert renewal**
Your cert was rotated by Match. Re-run `fastlane match appstore` from
Option B/D once to refresh the profile, then re-tag.

**App Review rejects with "your app records phone calls"**
Read PRD §15.6 + NEXT.md #5. Submit the demo video, use the exact
language from the PRD reviewer notes. They'll let you through within
a round or two.

**You forgot the Match passphrase**
You'll need to revoke certs in the Apple Developer portal, delete the
`murmur-certs` repo, and re-run step 8 from scratch. Don't lose this
passphrase.

---

## Annual maintenance

- **$99/yr Apple Developer renewal** — Apple emails you, you click
  Renew.
- **Cert expiry** — Apple Developer certs are valid for 1 year. Match
  handles renewal *if* you re-run `fastlane match appstore --force`
  on a Mac (Option B or D). Calendar this annually.
- **Xcode major versions** — when Xcode 17 ships, bump
  `Xcode_16.app` → `Xcode_17.app` in both workflow files. Test in a PR
  branch first.

---

## What this setup does NOT cover

- **Local development**. You can't run the app on a simulator from
  Windows. If you need to iterate on UI fast, use a cloud Mac
  (MacInCloud hourly, ~$1/hour) or buy a used M1 Mac mini ($400ish).
  Worth it once you're shipping weekly.
- **Local testing of Apple Intelligence / SpeechAnalyzer / on-device
  models**. These only run on real iPhones. The TestFlight build is
  your iteration loop until you have hardware.
- **App Store Screenshots**. Apple wants 6.7" and 6.1" screenshots.
  Generate them in CI with the iOS simulator + `snapshot` (Fastlane
  lane), or take them on a real device. Either way, all on the macOS
  runner — never on Windows.

---

## Cost summary

| Item                              | Cost          | Frequency     |
|-----------------------------------|---------------|---------------|
| Apple Developer Program           | $99           | yearly        |
| GitHub private repo CI minutes    | $0–$5         | per build     |
| Match init via MacInCloud (Opt B) | ~$1           | once + yearly |
| Murmur-certs private repo         | free          | always        |
| Total first-year                  | ~$110         |               |
| Total each year after             | ~$105         |               |

If you go public-repo route on GitHub Actions, the macOS minutes are
free, and total first year drops to ~$100.
