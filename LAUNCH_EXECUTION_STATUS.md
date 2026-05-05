# Murmur Launch Execution Status

Last updated: 2026-05-05

## Completed in this session

- Read the available launch docs: `APP_STORE_CONNECT_CHECKLIST.md`, `PUBLISHING.md`, `WINDOWS_TO_APPSTORE.md`, `APP_STORE_METADATA.md`, `SCREENSHOT_PLAN.md`, `APP_REVIEW_DEMO_VIDEO.md`, `project.yml`, `codemagic.yaml`, GitHub workflows, `fastlane/*`, and `Gemfile`.
- Confirmed the iOS bundle identifier in `project.yml` is `app.murmur.Murmur`.
- Confirmed App Store export compliance is configured as `ITSAppUsesNonExemptEncryption: false`.
- Confirmed the GitHub account available through the connector is `vrk38303`.
- Repaired the local `.git` directory enough to fetch `origin/main` from `https://github.com/vrk38303/Murmur.git`.
- Verified remote `origin/main` currently does not contain the local app source directories, `.github/workflows`, `docs`, or `fastlane`.

## Blocked

- Apple Developer/App Store Connect browser work is blocked in this Codex Desktop session because the Browser Use Node runtime is resolving to `C:\Program Files\nodejs\node.exe` version `22.14.0`, while the browser plugin requires Node `>=22.22.0`.
- A newer Node exists at `C:\Program Files\WindowsApps\OpenAI.Codex_26.429.8261.0_x64__2p2nqsd0c76g0\app\resources\node.exe` and `NODE_REPL_NODE_PATH` was set for future sessions, but the already-running Node REPL service did not pick it up.
- The requested files `APP_STORE_CONNECT_NOW.md` and `LAUNCH_MASTER_PLAN.md` are not present in this local checkout.
- `bash scripts_launch_preflight.sh` could not run through `bash` because `bash` is not on the default PowerShell path. The script file also was not present at repo root in the local file list.

## Notes for next session

- Restart Codex Desktop so the Node REPL service can pick up `NODE_REPL_NODE_PATH`, then retry Browser Use against Apple Developer and App Store Connect.
- Before tagging a TestFlight build, commit and push the local app source/workflow/Fastlane/docs directories to `vrk38303/Murmur`, or reconcile them with the intended remote branch.
- Do not submit to App Review or perform account/legal actions without explicit confirmation.
