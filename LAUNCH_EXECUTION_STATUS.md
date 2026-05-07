# Murmur Launch Execution Status

Last updated: 2026-05-07

## Completed in this session

- Read the available launch docs: `APP_STORE_CONNECT_CHECKLIST.md`, `PUBLISHING.md`, `WINDOWS_TO_APPSTORE.md`, `APP_STORE_METADATA.md`, `SCREENSHOT_PLAN.md`, `APP_REVIEW_DEMO_VIDEO.md`, `project.yml`, `codemagic.yaml`, GitHub workflows, `fastlane/*`, and `Gemfile`.
- Confirmed the iOS bundle identifier in `project.yml` is `app.murmur.Murmur`.
- Confirmed App Store export compliance is configured as `ITSAppUsesNonExemptEncryption: false`.
- Confirmed the GitHub account available through the connector is `vrk38303`.
- Repaired the local `.git` directory enough to fetch `origin/main` from `https://github.com/vrk38303/Murmur.git`.
- Verified remote `origin/main` currently does not contain the local app source directories, `.github/workflows`, `docs`, or `fastlane`.
- Pushed the local app source, tests, docs site, Fastlane config, and GitHub Actions workflows to PR #2.
- Fixed CI blockers in PR #2:
  - pinned workflows to installed Xcode 16.4 / iOS 18.5 simulator runtime,
  - generated Info.plists for test bundles,
  - avoided an unavailable `NLContextualEmbeddingResult.embedding` API,
  - simplified heuristic summary key point extraction,
  - scoped smoke builds to unit tests so screenshot UI tests run only through the screenshot lane.
- Confirmed GitHub Actions PR Tests run #7 passed on commit `905a6e3ae7f0d166a128a14240ab50673096c067`.

## Blocked

- Apple Developer/App Store Connect browser navigation is blocked in this Codex Desktop session by a Browser Use app-server path error: `failed to start codex app-server: The system cannot find the path specified. (os error 3)`.
- The earlier Node runtime blocker was cleared by updating the default Node runtime to v25.9.0.
- The requested files `APP_STORE_CONNECT_NOW.md` and `LAUNCH_MASTER_PLAN.md` are not present in this local checkout.
- `bash scripts_launch_preflight.sh` could not run through `bash` because `bash` is not on the default PowerShell path. The script file also was not present at repo root in the local file list.

## Notes for next session

- Fix or restart the Codex Desktop Browser Use app-server integration, then retry Browser Use against Apple Developer and App Store Connect.
- Merge PR #2 or tag its head commit before triggering TestFlight. The remote default branch still does not contain the app source until PR #2 is merged.
- Do not submit to App Review or perform account/legal actions without explicit confirmation.
