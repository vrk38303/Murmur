# App Store Connect — first-session click-by-click runbook

A literal step-by-step for the first time you touch App Store Connect for Murmur. Each item is one URL, one button, and one value to paste. Every "value to paste" cites the source line in `APP_STORE_METADATA.md` or `WINDOWS_TO_APPSTORE.md` so you don't have to retype anything.

Estimated time: ~70 minutes if Apple's enrollment is already approved; otherwise add the 24-48 hour enrollment wait.

Replace `vrk38303` everywhere with your actual GitHub username before pasting. Replace `<your-apple-id>` with the Apple ID email used for enrollment.

---

## Phase 1 — Enrollment & API key

1. **Enroll in Apple Developer Program**
   - URL: https://developer.apple.com/programs/enroll/
   - Click: **Start Your Enrollment**
   - Sign in with `<your-apple-id>` (use vrkalavapalli@gmail.com so the rest of this runbook lines up).
   - Pick: **Individual** ($99). Skip Organization.
   - If unfamiliar: Apple validates ID via a video selfie + driver's license upload. Approval takes 24-48 h.

2. **Enable two-factor on the Apple ID**
   - URL: https://account.apple.com/account/manage
   - Click: **Sign-In and Security → Two-Factor Authentication → Turn On**
   - Save the recovery code in a password manager.
   - If unfamiliar: needed for Match init only; CI uses the API key after that.

3. **Generate an app-specific password (only if you'll use the zero-Mac Match init)**
   - URL: https://account.apple.com/account/manage
   - Click: **App-Specific Passwords → Generate Password**
   - Label: `Murmur Match init`
   - Copy the 19-char password into your password manager.
   - Stash the value as the `APPLE_APP_SPECIFIC_PASSWORD` secret in step 8.

4. **Create the App ID**
   - URL: https://developer.apple.com/account/resources/identifiers/list
   - Click: `+` → **App IDs** → **App** → **Continue**
   - Description: `Murmur`
   - Bundle ID: **Explicit** → `app.murmur.Murmur`
   - Capabilities tick: **Background Modes**, **Speech Recognition**. Leave the rest unticked.
   - Click: **Continue → Register**.
   - If unfamiliar: this MUST exactly match `PRODUCT_BUNDLE_IDENTIFIER` in `project.yml`.

5. **Generate the App Store Connect API key**
   - URL: https://appstoreconnect.apple.com/access/integrations/api
   - Click: **Keys** tab → `+`
   - Name: `Murmur CI`. Access: **App Manager**.
   - Click: **Generate**.
   - Click: **Download API Key** (Apple shows the .p8 file ONCE — save to password manager immediately).
   - Note: **Issuer ID** (UUID at top of page) and **Key ID** (10 chars).
   - Stash for step 8.

---

## Phase 2 — Create the app record

6. **Create the app shell**
   - URL: https://appstoreconnect.apple.com/apps
   - Click: `+` → **New App**
   - Platforms: tick **iOS** only.
   - Name: `Murmur` (see `APP_STORE_METADATA.md` § App Name. If taken, fall back to `Murmur — Voice Notes`.)
   - Primary language: **English (U.S.)**
   - Bundle ID: pick **`app.murmur.Murmur`** from the dropdown (created in step 4).
   - SKU: `MURMUR-IOS-001`.
   - User Access: **Full Access**.
   - Click: **Create**.

7. **Confirm the App ID linkage**
   - URL: stays on App Store Connect → Murmur → **App Information**.
   - Confirm: **Bundle ID** reads `app.murmur.Murmur`.
   - If unfamiliar: if it shows anything else, you picked the wrong identifier — delete the app record and redo step 6.

---

## Phase 3 — Wire CI secrets

8. **Add GitHub Actions secrets**
   - URL: https://github.com/`vrk38303`/Murmur/settings/secrets/actions
   - Click: **New repository secret** for each row below. Names are case-sensitive:

       | Secret | Value |
       |---|---|
       | `APP_STORE_CONNECT_KEY_ID` | from step 5 (10 chars) |
       | `APP_STORE_CONNECT_ISSUER_ID` | from step 5 (UUID) |
       | `APP_STORE_CONNECT_KEY_P8` | full .p8 contents from step 5 |
       | `APPLE_ID` | `<your-apple-id>` |
       | `APPLE_APP_SPECIFIC_PASSWORD` | from step 3 (only if using `match-init.yml`) |
       | `MATCH_PASSWORD` | a 24+ char passphrase you generate |
       | `MATCH_GIT_URL` | `https://github.com/vrk38303/murmur-certs.git` |
       | `MATCH_GIT_BASIC_AUTH` | base64(`vrk38303:<fine-grained-PAT>`) |
       | `KEYCHAIN_PASSWORD` | output of `openssl rand -hex 32` |

   - If unfamiliar: see `WINDOWS_TO_APPSTORE.md` § Step 5 for the long-form recipe.

9. **Create the murmur-certs private repo**
   - URL: https://github.com/new
   - Name: `murmur-certs`
   - Visibility: **Private**.
   - Tick: **Initialize with a README** = OFF.
   - Click: **Create repository**.

10. **Generate the fine-grained PAT for Match**
    - URL: https://github.com/settings/personal-access-tokens/new
    - Token name: `Murmur Match cert repo`. Expiration: 1 year.
    - Repository access: **Only select repositories** → `murmur-certs`.
    - Permissions → Repository → **Contents**: Read and write.
    - Click: **Generate token**. Copy and stash for step 8 row `MATCH_GIT_BASIC_AUTH`.

11. **Run the one-shot Match init**
    - URL: https://github.com/`vrk38303`/Murmur/actions/workflows/match-init.yml
    - Click: **Run workflow** → **Run workflow**.
    - Wait ~5 minutes. Green checkmark = cert + profile sitting in `murmur-certs`.
    - **DELETE `.github/workflows/match-init.yml` after this completes** (`git rm`, commit, push).

---

## Phase 4 — Smoke build → TestFlight

12. **Push the first build tag**
    - From PowerShell in the repo root:
      ```
      git tag v0.0.1
      git push origin v0.0.1
      ```
    - URL to watch: https://github.com/`vrk38303`/Murmur/actions
    - Expected: ~12 min run, green status.

13. **Wait for Apple to process the IPA**
    - URL: https://appstoreconnect.apple.com/apps → Murmur → **TestFlight**.
    - Build appears under **iOS Builds** within 5-15 min after the workflow finishes.
    - State moves: **Processing → Missing Compliance → Ready to Submit**.

14. **Answer Export Compliance**
    - On the build row, click the **Manage** link in the Compliance column.
    - Tick: **No** (we set `ITSAppUsesNonExemptEncryption = false` in Info.plist; Apple may still ask).
    - Click: **Save**.

15. **Set up Internal Testing**
    - URL: https://appstoreconnect.apple.com/apps → Murmur → **TestFlight** → **Internal Testing**.
    - Click: `+` → name the group `Internal`.
    - Click: **Add Testers** → add yourself by Apple ID email.
    - Click: **Builds** tab in the group → `+` → pick the v0.0.1 build.
    - On your iPhone: install the **TestFlight** app from the App Store, accept the invite email, install Murmur.

---

## Phase 5 — Fill App Store metadata

16. **App Information**
    - URL: https://appstoreconnect.apple.com/apps → Murmur → **App Information**.
    - **Subtitle**: `Private voice notes & summaries` (`APP_STORE_METADATA.md` § Subtitle, option 2).
    - **Category**: Primary `Productivity`, Secondary `Utilities` (`APP_STORE_METADATA.md` § Category).
    - **Content Rights**: tick **does not contain, show, or access third-party content**.
    - Click: **Save**.

17. **Privacy Policy URL**
    - Same screen, scroll to **General Information**.
    - **Privacy Policy URL**: `https://vrk38303.github.io/Murmur/privacy/`
    - Click: **Save**.
    - If unfamiliar: see `docs/README.md` for how to enable GitHub Pages first.

18. **Age Rating**
    - Same screen → **Age Rating** → **Edit**.
    - Click: **None** for every row in the questionnaire (`APP_STORE_METADATA.md` § Age Rating has the per-row answers).
    - Result should display: **4+**.
    - Click: **Done**.

19. **Pricing and Availability**
    - URL: https://appstoreconnect.apple.com/apps → Murmur → **Pricing and Availability**.
    - **Price Schedule**: USD 0.00 (Free).
    - **App Distribution**: tick **Available in all countries and regions**.
    - Click: **Save**.

20. **iOS App → 1.0 Prepare for Submission**
    - URL: https://appstoreconnect.apple.com/apps → Murmur → **App Store** tab → click **1.0** in the sidebar.
    - **Promotional Text**: paste from `APP_STORE_METADATA.md` § Promotional Text, version B.
    - **Description**: paste verbatim from `APP_STORE_METADATA.md` § Description, **Version C** (the conversion-optimised one).
    - **Keywords**: paste `recorder,transcribe,memo,call,meeting,summary,journal,notes,interview,private,offline,ai,whisper` (97/100 chars).
    - **Support URL**: `https://vrk38303.github.io/Murmur/`
    - **Marketing URL**: leave blank.
    - **Copyright**: `2026 <Your Name>`.
    - Click: **Save** (do not click Submit yet).

21. **Upload screenshots — iPhone 6.9"**
    - Same page → scroll to **App Previews and Screenshots** → **iPhone 6.9" Display**.
    - Drag in the 6 PNGs from `fastlane/screenshots/en-US/` in this exact order: `01-Hero.png`, `02-Summary.png`, `03-MindMap.png`, `04-OnboardingPrivacy.png`, `05-CallsList.png`, `06-SettingsPrivacy.png`.
    - If unfamiliar: see `SCREENSHOT_PLAN.md` for what each frame should contain.
    - You only need 6.9" — Apple auto-derives 6.7"/6.5" classes.

22. **App Review Information**
    - Same page → scroll to **App Review Information**.
    - **Sign-In Required**: OFF.
    - **Contact Information**: your name, your phone, your email.
    - **Notes**: paste verbatim from `WINDOWS_TO_APPSTORE.md` § "Required App Review Notes".
    - **Attachment**: upload the 30-second demo video (`APP_REVIEW_DEMO_VIDEO.md` for the shot list).
    - Click: **Save**.

23. **Version Release**
    - Same page → scroll to **Version Release**.
    - Pick: **Manually release this version** for v1 (so you can sanity-check the live listing before it propagates). Switch to phased release on v1.0.1.
    - Click: **Save**.

---

## Phase 6 — Privacy questionnaire

24. **Open the App Privacy questionnaire**
    - URL: https://appstoreconnect.apple.com/apps → Murmur → **App Privacy** → **Get Started**.

25. **Data Collection: No**
    - Question: **Do you or your third-party partners collect data from this app?**
    - Click: **No, we do not collect data from this app**.
    - Click: **Save**.
    - If unfamiliar: Murmur is on-device only. The Privacy Manifest (`Murmur/Resources/PrivacyInfo.xcprivacy`) backs this answer. If you ever add Sentry/Firebase/analytics you must come back and update this OR Apple will reject the build.

26. **Publish the privacy section**
    - Click: **Publish**.

---

## Phase 7 — Bind a build & submit

27. **Bind the TestFlight build to the App Store version**
    - URL: https://appstoreconnect.apple.com/apps → Murmur → **App Store** tab → **1.0**.
    - Scroll to **Build** → click `+` → pick the v0.0.1 (or latest) TestFlight build.
    - Click: **Done**.

28. **Re-verify everything one last time**
    - Top of the version page should show: **Ready to Submit** (green).
    - If anything is yellow, click into it. The most common misses are: missing screenshot for one device class, blank Support URL, no demo video uploaded.

29. **Add for Review**
    - Top right of the version page: click **Add for Review**.
    - Apple shows a final summary modal. Click: **Submit to App Review**.
    - **STOP — Vick will click this final button. Do not have CI or any automation submit on his behalf.**

30. **Wait + watch the inbox**
    - Status: **Waiting → In Review → Pending Developer Release / Approved**.
    - First review: typically 24-48 hours.
    - Most likely rejection: Guideline 2.5.9 ("are you recording phone calls?"). Reply with the demo video + the App Review Notes wording from step 22; Apple typically clears within one round.
    - On approval, since you picked Manual Release in step 23, click **Release This Version** when ready.

---

## What's next after the first approval

- v1.0.1 onwards: same flow, but skip steps 1-11 and 16-19 (one-time setup). Just push a new tag, bind the new build, click Submit.
- Renew Apple Developer membership annually (Apple emails 30 days out).
- Re-run Match for cert renewal yearly: re-upload `match-init.yml`, run it, delete it again.

---

## Where each value comes from

| Value | Source line |
|---|---|
| App Name `Murmur` | `APP_STORE_METADATA.md` § App Name, option 1 |
| Subtitle | `APP_STORE_METADATA.md` § Subtitle, option 2 |
| Promotional Text | `APP_STORE_METADATA.md` § Promotional Text, version B |
| Description | `APP_STORE_METADATA.md` § Description, version C |
| Keywords | `APP_STORE_METADATA.md` § Keyword bank |
| Category | `APP_STORE_METADATA.md` § Category |
| Age Rating answers | `APP_STORE_METADATA.md` § Age Rating |
| Privacy Policy text | `docs/privacy.md` (rendered via Pages) |
| App Review Notes | `WINDOWS_TO_APPSTORE.md` § "Required App Review Notes" |
| Demo Video shot list | `APP_REVIEW_DEMO_VIDEO.md` |
| Bundle ID | `project.yml` `PRODUCT_BUNDLE_IDENTIFIER` |
| Screenshots (6) | `fastlane/screenshots/en-US/` after running the screenshots lane |
| Match secrets | `WINDOWS_TO_APPSTORE.md` § Step 5 + `PUBLISHING.md` § Step 9 |
