# Murmur iOS App Store Launch Master Plan (Operator-Ready)

This runbook is designed so an operator (me) can execute almost everything end-to-end with minimal user interruption. Where Apple/GitHub require account ownership actions, those are explicitly marked **USER REQUIRED**.

## 0) Outcome definition

Success means all of the following are true:
1. App builds and uploads via CI to TestFlight from a version tag.
2. TestFlight build passes basic functional QA on real device.
3. App Store Connect metadata, privacy, screenshots, and review notes are complete.
4. Version is in **Ready to Submit** state.
5. User performs final legal/ownership button press: **Submit to App Review**.

---

## 1) Critical path overview

1. Verify repo launch readiness and CI integrity.
2. Provision Apple/GitHub credentials and signing materials.
3. Seed signing repo with Match.
4. Run smoke upload to TestFlight.
5. Complete App Store Connect listing and compliance.
6. Bind build and submit.

Estimated wall-clock:
- ~2–4 hours active work after Apple enrollment approval.
- +24–48 hours if Apple Developer enrollment pending.

---

## 2) What I can execute now (no user interaction)

- Validate repository structure and docs.
- Validate workflow files and fastlane config consistency.
- Produce exact secret matrix and one-shot command set.
- Prepare release checklist and go/no-go gates.

---

## 3) Minimal information I must request from user

These are mandatory blockers:
1. Apple ID email used for Developer Program.
2. GitHub username/org that owns this repo.
3. Confirmation whether app name should remain "Murmur" or fallback variant.
4. Legal display name for copyright string.
5. Support contact email + phone for App Review Information.

Optional but strongly recommended:
- Dedicated launch date window (UTC + local timezone).
- Preferred release mode (manual vs phased).

---

## 4) Security/secrets matrix (authoritative)

Required GitHub Actions secrets:
- APP_STORE_CONNECT_KEY_ID
- APP_STORE_CONNECT_ISSUER_ID
- APP_STORE_CONNECT_KEY_P8
- MATCH_PASSWORD
- MATCH_GIT_URL
- MATCH_GIT_BASIC_AUTH
- KEYCHAIN_PASSWORD
- APPLE_ID
- APPLE_APP_SPECIFIC_PASSWORD (only if using non-interactive match init workflow)

Hard requirements:
- `MATCH_GIT_URL` must point to a private repo.
- `MATCH_PASSWORD` must be recoverable by owner (password manager).
- `APP_STORE_CONNECT_KEY_P8` must be exact multi-line key text.

---

## 5) Execution plan (step-by-step)

### Phase A — Preflight audit

A1. Confirm app identifier consistency across project config and fastlane.
A2. Confirm testflight workflow triggers on `v*.*.*` tag.
A3. Confirm signing type is appstore, not development/ad-hoc.
A4. Confirm Info.plist/privacy manifest align with declared privacy answers.

Exit gate: all A checks pass.

### Phase B — Apple account provisioning (**USER REQUIRED where noted**)

B1. **USER REQUIRED** enroll in Apple Developer Program.
B2. **USER REQUIRED** create App ID `app.murmur.Murmur` with required capabilities.
B3. **USER REQUIRED** create App Store Connect app shell.
B4. **USER REQUIRED** create App Store Connect API key and provide key material for secret entry.

Exit gate: App ID and app shell exist, API key created.

### Phase C — Signing bootstrap

C1. Create private certs repo (`murmur-certs`).
C2. Create fine-grained PAT with contents read/write only to cert repo.
C3. Add all GitHub secrets.
C4. Run one-time Match init via cloud macOS or one-shot workflow.
C5. Validate cert/profile committed to certs repo.

Exit gate: `fastlane match appstore` succeeds.

### Phase D — Build and distribution smoke test

D1. Create and push tag `v0.0.1` (or agreed starting version).
D2. Monitor CI until green.
D3. Verify build appears in TestFlight and processing completes.
D4. Resolve export compliance questionnaire.
D5. Add internal testers and install on device.

Exit gate: internal tester can install and launch app.

### Phase E — App Store metadata and policy completion

E1. App information (subtitle/category/content rights).
E2. Pricing and availability.
E3. Version metadata (promo text, description, keywords, URLs, copyright).
E4. Screenshot upload (6.9" set in required order).
E5. App Review Information + demo video attachment.
E6. App Privacy questionnaire publish.

Exit gate: version page indicates all required sections complete.

### Phase F — Submission

F1. Bind latest approved TestFlight build to version.
F2. Run final readiness checklist.
F3. **USER REQUIRED** click `Add for Review` → `Submit to App Review`.
F4. Monitor status + respond to review feedback quickly.

Exit gate: status Approved / Pending Developer Release.

---

## 6) RACI (who does what)

- Agent (me): all local validation, command execution, checklist orchestration, issue triage guidance.
- User: account-owner-only actions (Apple legal confirmations, key generation/download, final submission).

---

## 7) Failure handling playbook

1. Signing errors: verify `MATCH_PASSWORD` + PAT auth first.
2. Build number collisions: bump build number and re-tag.
3. App Review 2.5.9 concerns: provide demo video + explicit reviewer notes.
4. Lost match password: revoke certs and recreate signing chain.

---

## 8) Immediate next actions

1. User provides blocker inputs listed in section 3.
2. I then execute preflight + exact secret population instructions tailored to their account values.
3. Once secrets are populated, I run smoke tag flow and drive to Ready-to-Submit state.

