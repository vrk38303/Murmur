# Murmur — App Store Metadata

Copy-paste source for the App Store Connect listing. Pick one option
in each section, paste it, and ship it. The "Recommendation" lines
under each section are what `LAUNCH_REPORT.md` uses for the final
package.

---

## App Name (max 30 characters)

App Name is the bold title under your icon and is the strongest
keyword signal Apple gives you. It must be globally unique on the
App Store — if "Murmur" is taken, you'll need a fallback.

| # | Name | Chars | Notes |
|---|------|-------|-------|
| 1 | **Murmur** | 6 | First choice. Clean, brandable, search-light. |
| 2 | **Murmur — Voice Notes** | 19 | Falls back to keyword if #1 is taken. |
| 3 | **Murmur: Private Voice AI** | 25 | Punches the AI angle for ASO. |
| 4 | **Murmur — Call Notes** | 20 | Anchors against "call recording" intent. |
| 5 | **Murmur Voice Memo Notes** | 24 | Pure-keyword fallback if Apple rejects "Voice Notes." |

**Recommendation: 1. Murmur** (with fallback 2 if taken).

---

## Subtitle (max 30 characters)

Shown directly below the App Name. Apple indexes subtitle keywords
heavily. Subtitle can change between releases.

| # | Subtitle | Chars |
|---|----------|-------|
| 1 | **Conversations, kept quietly.** | 29 |
| 2 | **Private voice notes & summaries** | 30 |
| 3 | **On-device call summaries** | 26 |
| 4 | **Record. Transcribe. Connect.** | 30 |
| 5 | **AI voice memos that stay local** | 30 |
| 6 | **Capture calls. Find the thread.** | 30 |
| 7 | **Your conversations, on device** | 30 |
| 8 | **Voice memos with a memory** | 27 |
| 9 | **Listen back. See the pattern.** | 30 |
| 10 | **Private voice memo intelligence** | 30 |

**Recommendation: 2. Private voice notes & summaries** — leads with
"Private" (Apple platform tailwind), uses two high-volume keywords
("voice notes," "summaries"). Subtitle 1 is the brand line and is
beautiful but doesn't help search.

---

## Promotional Text (max 170 characters, can change without re-review)

Appears at the very top of the description on the listing. Best place
to announce a new release, sale, or feature push without re-submitting.

### Version A — clean
```
Murmur turns your conversations into searchable, summarised notes —
on-device. No cloud. No account. Your voice, your phone, your data.
```
*(150 chars)*

### Version B — feature-led
```
On-device transcription, AI summaries, action items, and a mind map
that connects every conversation. All private. No account required.
```
*(150 chars)*

### Version C — launch-week
```
Just shipped: cleaner mind map layout, faster summaries, .zip export
of your full library, and a polished onboarding flow. Try it free.
```
*(149 chars)*

**Recommendation: B for launch week, swap to C after first update.**

---

## Description (max 4000 characters)

Three full versions to A/B test, plus a recommendation.

### Version A — Clean & professional

```
Murmur is a private voice-note recorder built for people who actually
listen back to their conversations.

Tap once to record. Murmur transcribes you in real time, on your
device. When you stop, it summarises what was said in two or three
sentences, pulls out the key points, lifts any action items into a
checklist, and weaves the topics into a personal mind map that grows
with every recording.

Nothing leaves your phone. There is no account to sign up for. There
is no cloud to opt out of. Apple's on-device speech models do the
transcription. Apple Intelligence (or a bundled fallback) does the
summarisation. Audio is encrypted at rest with AES-256-GCM, keyed to
your device.

CORE FEATURES

· One-tap recording with a live waveform and live transcript
· On-device transcription via Apple SpeechAnalyzer / SFSpeechRecognizer
· On-device summarisation via Apple Intelligence (iPhone 15 Pro/16+)
  or a bundled fallback engine
· Action items lifted automatically into a per-call checklist
· Topic mind map that connects related conversations across time
· Full-library .zip export (transcripts, summaries, optional audio)
· Per-recording consent reminders, with a one-time education on first use
· Face ID-gated "delete everything" for total local wipe

PRIVACY

· No account, no login, no cloud sync
· Privacy nutrition label: Data Not Collected
· Microphone access only while you are recording
· Speech recognition runs entirely on-device
· Recordings encrypted with AES-256-GCM, file-protected at rest
· Encryption key non-syncable, only available when device is unlocked

DESIGN

A warm, paper-feeling UI in light mode and a quiet charcoal palette
in dark mode. Designed for one-handed use. Dynamic Type and VoiceOver
supported throughout.

WHAT MURMUR DOES NOT DO

· Murmur cannot record cellular phone-call audio. iOS does not allow
  any app to do that. Use speakerphone if you want to capture a call.
· Murmur does not transcribe in languages your device's on-device
  speech model doesn't support; check Settings → General → Keyboard →
  Dictation Languages for what's available on your phone.

REQUIREMENTS

· iPhone running iOS 18 or later
· On-device speech model installed for your locale (Settings →
  General → Language & Region → On-Device Dictation)
· Apple Intelligence (optional) requires iPhone 15 Pro or newer

Privacy policy: https://vrk38303.github.io/Murmur/privacy/
Support: https://vrk38303.github.io/Murmur/
```

### Version B — Emotional & user-focused

```
You finish a call. You meant to write down the three things you'd
agreed to. You don't. The week passes and you're trying to remember
who said what.

Murmur is for that.

Tap one button. Talk. When you stop, Murmur has a summary of what was
said, the action items lifted into a checklist, and a mind map that
connects this conversation to everything else you've recorded.

Everything happens on your phone. Nothing is sent anywhere.

— Catch up after a call you almost missed.
— Find the conversation where someone mentioned that one idea.
— Watch your work, your relationships, your week build into a map you
  actually understand.

Murmur was built around a simple promise: that the most private things
in your life — what you say out loud — should stay private. That
means no account. No cloud. No analytics. No share-with-OpenAI
tickbox.

WHAT'S IN THE BOX

· Live transcription, on-device, as you talk
· A two- or three-sentence summary of every call
· Action items that read more like the way you'd actually write them
· A mind map of topics, people, and threads across every conversation
· One-tap export of your whole library
· Per-recording consent reminders so the people you talk to are never
  surprised

WHAT'S NOT IN THE BOX

· No sign-up. There's no email field anywhere.
· No cloud. There's no "send to server" code path.
· No analytics. We don't know how often you record, what you record,
  or whether you ever opened the app.
· No phone-call recording. iOS doesn't let any app do that. Use
  speakerphone.

A NOTE ON CONSENT

Recording someone without their knowledge is illegal in many places
and unkind everywhere. Murmur reminds you to ask, every time. It's
in your hands what you do with that.

Built quietly.

Privacy policy: https://vrk38303.github.io/Murmur/privacy/
Support: https://vrk38303.github.io/Murmur/
```

### Version C — Polished, App-Store-conversion-optimised

```
THE PRIVATE VOICE-NOTE APP THAT REMEMBERS EVERY CONVERSATION

Murmur records your voice notes, transcribes them on-device, and
turns them into searchable summaries with action items and a topic
map. Everything stays on your phone. No account. No cloud. No tracking.

★ ON-DEVICE TRANSCRIPTION
Tap record. Watch the words appear in real time using Apple's speech
engine. Audio never leaves the phone.

★ AI SUMMARIES THAT ACTUALLY HELP
Two or three sentences capture what was said. The bullet list is
short and useful. Action items become a checklist you can tick off.

★ A MIND MAP OF EVERY CONVERSATION
Topics from one call connect to topics from another. People connect
to people. Search across your entire history in one place — and find
the thread you were following last month.

★ TRUE PRIVACY, NOT MARKETING PRIVACY
· Privacy Manifest: Data Not Collected, top to bottom
· No account. No login. No "create profile."
· No cloud. No analytics. No telemetry.
· AES-256-GCM encryption at rest
· Apple Intelligence summaries on iPhone 15 Pro & 16-series
· On-device fallback summariser for older iPhones

★ ONE-HANDED, SLOW-WEB DESIGN
A warm paper-feel light mode. A quiet charcoal dark mode. Original
icon set. Dynamic Type, VoiceOver, Reduce Motion all supported.

★ EXPORT WHENEVER YOU WANT
Tap export → get a .zip of every transcript, summary, and topic
graph (audio optional). Goes to Files, AirDrop, anywhere you choose.

★ DELETE WHENEVER YOU WANT
Face ID confirmation, then everything is wiped: SwiftData store,
encrypted audio, encryption key. No "deleted but recoverable" — gone.

PRICING

Murmur is free for 3 recordings a month. Murmur Plus ($X.XX/mo)
unlocks unlimited recordings, the mind map, AI summaries, and export.
Murmur Pro adds advanced transcription engines and speaker labels
when those land. Lifetime Founder ($X.XX one-time) unlocks everything
forever.

REQUIREMENTS

· iPhone with iOS 18 or later
· On-device speech model for your locale
· Apple Intelligence (optional) requires iPhone 15 Pro or newer

WHAT MURMUR DOESN'T DO

· Cannot record cellular phone-call audio. iOS prohibits this for
  every app, not just Murmur. Use speakerphone.
· Doesn't sync between devices in v1. Local-only.
· Doesn't transcribe languages your device's on-device dictation
  doesn't already support.

Privacy policy: https://vrk38303.github.io/Murmur/privacy/
Support: https://vrk38303.github.io/Murmur/
Made with care. Built quietly.
```

**Recommendation: Version C for launch.** Heaviest keyword density,
clearest feature list, explicit pricing scaffolding, and the negative-
space "what it doesn't do" section disarms the App Review concern
about call recording before the reviewer even reads the notes.

After 4-6 weeks of data, A/B by swapping to Version B (the emotional
version) and watching conversion rate.

---

## Keyword bank (max 100 chars total, comma-separated, no spaces after commas)

Apple indexes the App Name + Subtitle + this Keywords field.
**Don't repeat words from the Name or Subtitle.** Don't include
plurals when the singular is already present. Don't use spaces after
commas — every char counts.

### Recommended keyword string (97 / 100 chars)

```
recorder,transcribe,memo,call,meeting,summary,journal,notes,interview,private,offline,ai,whisper
```

### Why each one

- `recorder` — primary intent for users searching "voice recorder."
  We're not in the App Name so this carries the search.
- `transcribe` — high-volume verb intent.
- `memo` — captures the "voice memo" Apple-native search term.
- `call` — captures users searching for "call recorder" / "call
  notes." We will appear; the description and review notes make
  clear we're not actually recording cellular calls.
- `meeting` — adjacent intent, lower competition than `recorder`.
- `summary` — captures "voice summary," "meeting summary."
- `journal` — adjacent app category (Apple Journal is also iOS 18-only
  on-device); cross-pollinates well.
- `notes` — broad, but worth the slot for the synonym tail.
- `interview` — high-intent, low-competition; journalists/students.
- `private` — high-conversion modifier; reinforces the brand.
- `offline` — captures "offline transcription" tail.
- `ai` — yes, even in 2026; users still search for it.
- `whisper` — hooks searches for "Whisper transcribe" looking for the
  Whisper model name.

### Alternative bank if Apple rejects `whisper` (it's a trademark fight that's been litigated both ways):

```
recorder,transcribe,memo,call,meeting,summary,journal,notes,interview,private,offline,ai,dictation
```

---

## Age Rating

**Recommendation: 4+** (lowest tier, no objectionable content).

App Store Connect → App Privacy → **Age Rating** wizard. Answer:

| Question | Answer |
|----------|--------|
| Cartoon or fantasy violence | None |
| Realistic violence | None |
| Sexual content / nudity | None |
| Profanity / crude humor | None |
| Drugs / alcohol references | None |
| Mature/suggestive themes | None |
| Horror/fear themes | None |
| Gambling | None |
| Unrestricted web access | No |
| Medical/treatment information | No |
| Contests | No |
| User-generated content (UGC) | **No** — Murmur generates content
                                  from the user's own audio but
                                  never displays content from other
                                  users. Apple's UGC checkbox is for
                                  apps like forums/social. |

Result: **4+**.

(Note: if you ever ship cloud sync with shared transcripts between
users, this becomes 12+ at minimum because of the UGC moderation
requirement. Stay on-device → stay 4+.)

---

## Category

| Tier | Pick | Why |
|------|------|-----|
| **Primary** | **Productivity** | Apple's Productivity charts feature
                                   note-taking and memo apps; that's
                                   our nearest neighbour and our
                                   highest-intent audience. |
| **Secondary** | **Utilities** | Captures the "voice recorder /
                                  utility" search lane. Murmur is also
                                  a defensible Lifestyle pick if you
                                  prefer brand-led discovery, but
                                  Utilities ranks better for `recorder`
                                  / `transcribe` searches. |

**Recommendation: Productivity (primary) + Utilities (secondary).**

---

## Support URL

**REQUIRED by Apple.** Easiest options for a solo dev who doesn't want
to maintain a website:

1. **GitHub Pages from this repo** (recommended): enable Pages in the
   repo settings (Source: `main /docs`), drop a `docs/index.md` with
   a short FAQ + `support@` mailto, and your URL is
   `https://<you>.github.io/Murmur`. Free, version-controlled.
2. **Notion / Carrd / Vercel** landing page: 5 minutes of work.
3. **Mailto-only** (`mailto:support@yourdomain.com`): Apple sometimes
   accepts this, sometimes rejects with "support URL must be a web
   page." Not worth the gamble.

**Recommendation: GitHub Pages.** Stick a privacy policy there too
and use the same URL for both fields in App Store Connect.

---

## Privacy Policy URL

Apple requires a privacy policy URL for any app that uses sensitive
permissions (microphone qualifies). Same URL is fine if your support
page hosts a `/privacy` section.

Minimum content for Murmur's privacy policy (you don't need a lawyer
for this; the wording reflects the actual code):

```
PRIVACY POLICY — MURMUR

Last updated: <date>

Murmur is a private on-device voice-note app. We do not collect any
data from you.

Data we do not collect:
  · We do not collect any personal information.
  · We do not collect contact information.
  · We do not collect device identifiers, IP addresses, or analytics.
  · We do not run any third-party SDKs that collect data.
  · We do not have a server that we send data to.

Data we process locally on your device:
  · Audio you record — stored encrypted at rest with AES-256-GCM,
    keyed to your device's Secure Enclave. Decryptable only on the
    same device while it is unlocked.
  · Transcripts of that audio — produced by Apple's on-device
    speech recogniser. The audio is not sent to Apple's servers
    when on-device recognition is enabled (which Murmur enforces).
  · Summaries — produced by Apple Intelligence on supported devices,
    or a bundled fallback engine. No transcript leaves the device
    in either case unless you explicitly enable cloud summarisation
    in Settings (off by default; not yet implemented).

Permissions:
  · Microphone — used only when you tap record.
  · Speech recognition — used to transcribe your recordings.
  · Contacts — optional; used to label calls with the right name.
  · Face ID / Touch ID — used only to confirm the "delete all data"
    action. Biometric data never leaves the device's Secure Enclave.

Export and deletion:
  · Tap Settings → Privacy → Export library to take all your data
    off the device as a .zip.
  · Tap Settings → Privacy → Delete all data to wipe every recording,
    transcript, summary, topic, and the encryption key from the
    device. There is no recovery.

Children:
  · Murmur is rated 4+ but does not knowingly process data from
    children under 13.

Contact: <support email>
```

---

## Localizations (v1)

Ship English only for v1. Plan localisations for the second release.

| Locale | Status | Reason |
|--------|--------|--------|
| en-US | ✅ ship | Strings live in `Localizable.strings` |
| en-GB | ⏳ next | Easy diff from en-US |
| es-ES, es-MX | ⏳ next | High App Store volume; Apple speech model is solid |
| fr, de | ⏳ later | Apple speech model varies |
| Japanese, Korean, Chinese | ⏳ much later | On-device speech quality varies a lot |

When you add a locale, also add the matching App Store Connect
listing copy in that locale or you'll show English on a Japanese
device which looks worse than not localising at all.
