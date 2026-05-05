# App Review demo video — second-by-second shot list

A 30-second demo video for the App Store Connect → App Review → Notes attachment field. Apple's Guideline 2.5.9 ("does this app record phone calls?") is the most likely rejection for Murmur. This video disarms it before the reviewer even reads the notes.

## How to record it

You record this on your iPhone with QuickTime, no editing. The flow is designed so a single take through the device works.

1. Plug your iPhone into a Mac (the only Mac step in the whole launch — borrow one for 5 minutes from anyone, or use a $1 MacInCloud session).
2. Open **QuickTime Player** → **File → New Movie Recording**.
3. Click the dropdown next to the red record button and pick your iPhone for **Camera** and **Microphone**.
4. On the iPhone, install Murmur via TestFlight. **Open Settings → General → Date & Time → Set Automatically → OFF → set the clock to 9:41 AM** for App Store-grade output.
5. Force-quit Murmur so the take starts at the Calls list.
6. Click record in QuickTime. Speak the voiceover into the Mac mic while you tap through the iPhone. Keep going even if you fumble — the timestamps below have buffer for re-attempts.
7. Click stop. **File → Save** as `MurmurDemo.mov`. Export at 1080p, no editing.

If you fumble: record a second take. Apple accepts up to 500 MB. A re-record is faster than learning a video editor.

## What Apple needs to see

Three points, in this order:
1. The user explicitly taps record. There is no automatic recording, no phone-call hook.
2. Transcription is on-device. The audio never leaves the phone.
3. Murmur cannot record cellular phone calls. iOS doesn't allow it.

The shot list is built around those three points. Each point gets ~10 seconds.

## Shot list (timed; total 30 s)

| Time | What's on screen | On-screen text overlay (optional, skip for v1) | Voiceover |
|------|------------------|-----------------------------------------------|-----------|
| 0-2 s  | Calls list, populated. Finger lifts off the screen so it's clear you're not tapping yet. | none | "Murmur is a private voice-note app." |
| 2-4 s  | Tap the blue **+** button. The "Ask first, then tap" sheet slides up. | none | "I tap plus to start a recording." |
| 4-7 s  | Camera lingers on the consent sheet for two beats. Then tap the red dot. | none | "Murmur reminds me to ask the other person for consent. Then I tap the red dot to start." |
| 7-13 s | Live recording screen takes over. Pulsing red dot, timer ticking up. Speak a sentence aloud — "I'm walking through the demo, the transcript should appear below in real time." Watch the transcript stream in. | none | "Audio is captured from this phone's microphone only. Transcription runs on-device, in real time. Nothing goes to a server." |
| 13-15 s | Tap the red square stop. Brief Processing screen. | none | "I stop. Murmur summarises what I said, on the same device." |
| 15-19 s | Cut to the Call Detail page. Camera slowly pans down the summary, key points, and action items. | none | "Here's the summary. The action items I mentioned, lifted out into a checklist." |
| 19-23 s | Tap the **Mind Map** tab. The graph settles. Tap one node; the peek card slides up. | none | "Topics across all my conversations get connected on a personal mind map." |
| 23-27 s | Cut to a slow camera angle showing the **iPhone Phone app** open with the Phone icon highlighted, NOT in Murmur. Make it visually unambiguous: this is the iOS Phone app. | none | "Important: Murmur cannot record cellular phone calls. iOS doesn't allow any app to do that. To capture a call I'd put it on speakerphone, then start a Murmur recording." |
| 27-30 s | Cut back to the Murmur Calls list. Hold for two beats. | none | "Everything stays on the device. No account. No cloud. Murmur." |

## Voiceover script — copy-paste, pre-rehearsed

Read this aloud into the Mac mic. Total speaking time: ~28 seconds at a natural pace. Practice it once before recording.

> Murmur is a private voice-note app. I tap plus to start a recording. Murmur reminds me to ask the other person for consent. Then I tap the red dot to start. Audio is captured from this phone's microphone only. Transcription runs on-device, in real time. Nothing goes to a server. I stop. Murmur summarises what I said, on the same device. Here's the summary. The action items I mentioned, lifted out into a checklist. Topics across all my conversations get connected on a personal mind map. Important: Murmur cannot record cellular phone calls. iOS doesn't allow any app to do that. To capture a call I'd put it on speakerphone, then start a Murmur recording. Everything stays on the device. No account. No cloud. Murmur.

## Pre-flight checklist before you hit record

- [ ] iPhone clock set to 9:41 AM (App Store convention).
- [ ] Murmur is force-quit so the take opens fresh on the Calls list.
- [ ] Calls list has 5+ seeded calls so the screen looks real (the seeded build from `MurmurDebugSeed.swift` does this).
- [ ] Notification banners are silenced (Settings → Focus → Do Not Disturb → ON).
- [ ] Wi-Fi indicator is full bars (visual cleanliness, not technical reason).
- [ ] Battery is above 50% (so the indicator is green, not red).
- [ ] Brightness is high so the screen reads clearly in the recording.
- [ ] Voiceover is rehearsed once aloud.

## Common mistakes to avoid

- **Recording in Murmur the whole time.** The reviewer needs to see the iOS Phone app at 23-27 s to understand "this is what we don't do." If you skip that shot, Guideline 2.5.9 will come up regardless.
- **Filming the iPhone with another phone.** Use QuickTime + USB. Phone-on-phone clips look jittery and Apple sometimes rejects on quality.
- **Skipping the consent reminder.** That sheet is a key part of the "we're not a sketchy stalkerware app" story. Don't tap through it too fast at 4-7 s.
- **Editing.** Don't. Apple does not require edited video. A clean single take wins.

## What to do with the file

- Save it as `MurmurDemo.mov` (or .mp4) at 1080p.
- File size: should be ~15-40 MB at 30 s / 1080p / H.264. App Store Connect cap is 500 MB.
- Upload via App Store Connect → your app → **App Store** → **1.0 Prepare for Submission** → **App Review Information** → **Attachment** → **Choose File**.
- Re-link if you re-record between submission rounds — Apple does not retain attachments across rejections.
