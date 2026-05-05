# Building Murmur

This repo contains the Swift sources, asset catalog, and project spec for the
Murmur iOS app. It was scaffolded on a non-Apple machine, so the Xcode project
file is generated rather than checked in. Generation takes one command on a
Mac and you only need to do it once.

## Prerequisites

- macOS 14.5 or later
- Xcode 16 with the iOS 18 SDK (Xcode 16.1+ recommended; iOS 26 SDK once
  Apple ships it lets you light up SpeechAnalyzer + Foundation Models)
- An Apple Developer account (paid tier for TestFlight)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

## First-time setup

```bash
cd /path/to/Murmur
xcodegen generate           # produces Murmur.xcodeproj from project.yml
open Murmur.xcodeproj
```

In Xcode:

1. Select the **Murmur** target → **Signing & Capabilities**
2. Pick your **Team** so automatic provisioning kicks in
3. Confirm the bundle id (`app.murmur.Murmur`) is unique to your account.
   If someone else owns it, change `PRODUCT_BUNDLE_IDENTIFIER` in
   `project.yml` and re-run `xcodegen generate`.
4. Capabilities to enable:
   - Background Modes → **Audio**
   - Speech Recognition (auto-added via Info.plist usage string)

## Running on a device

The microphone APIs only work on real hardware. Plug in an iPhone running
iOS 18+ (use 17.5 for visual smoke tests but transcription will be broken),
trust the device, then `Cmd+R`.

The simulator is fine for everything except:

- Live transcription (`SFSpeechRecognizer` requires a device / on-device model)
- Apple Intelligence summarization (iPhone 15 Pro / iPhone 16 family only)
- Microphone capture (the simulator routes the Mac's mic; AVAudioSession
  category negotiation is unreliable)

## Tests

```bash
xcodebuild test \
  -scheme Murmur \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

The test target covers `MindMapService`, `SummarizationService` (heuristic
path), `SubscriptionService` gating, `EncryptedFileStore`, and
`CallsListViewModel`.

## TestFlight

1. Bump `CFBundleShortVersionString` and `CFBundleVersion` in `project.yml`.
2. `xcodegen generate` and re-archive (Product → Archive).
3. App Store Connect → upload archive → invite testers.

Read PRD §15 for App Review messaging — the explanation that we **do not
record cellular call audio** has to be in the reviewer notes.
