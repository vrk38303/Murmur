# Manual test plan

Walk this list before any TestFlight build. Everything here maps to PRD §14
self-review items plus the conversion moments from §15.5.

## Onboarding

- [ ] Welcome → Continue advances to Permissions
- [ ] Permissions: tap "Allow" on Mic, Speech, Contacts → all show "Allowed"
- [ ] Continue → Consent step shows the chat-bubble illustration
- [ ] "I understand" sets `onboardingCompleted=true` and lands on Calls
- [ ] Re-launch: skips straight to Calls

## Permissions

- [ ] If user denies microphone: hitting `+` surfaces an `AppError.microphoneDenied`
      with a "Open Settings" button (verify dialog)
- [ ] Denying speech recognition still allows recording but transcript shows
      `(transcription unavailable)`

## Recording — happy path

- [ ] Tap `+` → sheet animates in over the calls list
- [ ] Tap the red dot → Live Recording fullscreen cover, dark theme
- [ ] Pulse dot animates at 0.7s cadence
- [ ] Timer increments every second, monospace
- [ ] Live waveform reacts to ambient sound (clap test)
- [ ] Live transcript fills as you speak (on-device)
- [ ] Pause → engine pauses; Resume → engine resumes; timer freezes during
      pause
- [ ] Tap stop → Processing screen, three steps tick on in order
- [ ] Done returns to Calls list, the new call is at the top

## Recording — interruptions

- [ ] Receive a phone call mid-recording: Murmur pauses, shows audio
      interruption notice. After hangup, Murmur resumes if `.shouldResume`,
      else finalises gracefully.
- [ ] Lock the device for 30 minutes; recording continues (background mode
      = `audio`). Verify the file exists and the timer is correct.

## Calls list

- [ ] Search "neera" filters in real time
- [ ] Each row shows initial avatar, summary preview, mini waveform, duration
- [ ] Tap a row → CallDetailView with hero waveform + segmented control
- [ ] Pull-to-refresh triggers reload (if implemented)

## Call detail

- [ ] Summary segment shows summary, key points, action items, connections
- [ ] Tapping an action-item checkbox toggles its strikethrough
- [ ] Transcript segment shows speaker-labeled lines with timestamps
- [ ] Map segment shows the local subgraph
- [ ] PlayBar appears above the tab bar; play button is hit-target large

## Mind map

- [ ] First load builds layout; nodes settle in [0,1] coords
- [ ] Filter bar (All / People / Topics) recomputes the visible set
- [ ] Tap a node → peek card animates in
- [ ] Reduce Motion ON → no spring animations, snap transitions
- [ ] Performance: 200 nodes scrolled at 60 fps on iPhone 13

## Settings

- [ ] Privacy section: "Export library" produces a directory in temp,
      JSON files validate
- [ ] "Delete all data" prompts Face ID; on success wipes SwiftData,
      audio dir, and the keychain key
- [ ] Auto-connect threshold slider clamps at 0.7–0.95

## Encryption-at-rest

- [ ] Record a call. Use the `Files` app to navigate to the app's audio
      directory (only possible if you turn on `LSSupportsOpeningDocumentsInPlace`,
      which we **do not**). Verify the `.enc` blob is opaque.
- [ ] On a jailbroken/dev device, copy the blob off the device via
      `idevicebackup2` or Files transfer. Open it on macOS — it should be
      gibberish. Decrypting requires the keychain key, which is
      `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` and not exported.

## Subscription gating

- [ ] As Free user, record 3 calls; the 4th tap on `+` shows the paywall
- [ ] Mind Map tab on Free user shows greyed graph + paywall preview blur
- [ ] Cross-call search hit on Free user surfaces the "you have N
      conversations connected here" sheet
- [ ] Paid tiers (Plus/Pro/Lifetime) bypass all gates

## Accessibility

- [ ] VoiceOver reads the calls list rows in form "Name, duration, when ago"
- [ ] Dynamic Type at xSmall: text doesn't truncate
- [ ] Dynamic Type at accessibility5: layout doesn't crash, scrolls vertically
- [ ] Reduce Motion is honored everywhere with animations
- [ ] Color contrast: ink-on-bg passes 4.5:1 in both themes

## Privacy

- [ ] No network requests outside the bundled MLX/WhisperKit downloads.
      Run with Charles or `nettop` while recording — should be silent.
- [ ] Privacy nutrition label set to "Data Not Collected" everywhere when
      cloud features are off.
