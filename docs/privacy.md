---
layout: page
title: Privacy Policy
permalink: /privacy/
---

# Privacy Policy — Murmur

**Last updated: 2026-05-04**

Murmur is a private on-device voice-note app. We do not collect any data from you.

## Data we do not collect

- We do not collect any personal information.
- We do not collect contact information.
- We do not collect device identifiers, IP addresses, or analytics.
- We do not run any third-party SDKs that collect data.
- We do not have a server that we send data to.

## Data we process locally on your device

- **Audio you record** — stored encrypted at rest with AES-256-GCM, keyed to your device's Secure Enclave. Decryptable only on the same device while it is unlocked.
- **Transcripts of that audio** — produced by Apple's on-device speech recogniser. The audio is not sent to Apple's servers when on-device recognition is enabled (which Murmur enforces).
- **Summaries** — produced by Apple Intelligence on supported devices, or a bundled fallback engine. No transcript leaves the device in either case unless you explicitly enable cloud summarisation in Settings (off by default; not yet implemented).

## Permissions

- **Microphone** — used only when you tap record.
- **Speech recognition** — used to transcribe your recordings.
- **Contacts** — optional; used to label calls with the right name.
- **Face ID / Touch ID** — used only to confirm the "delete all data" action. Biometric data never leaves the device's Secure Enclave.

## Export and deletion

- Tap **Settings → Privacy → Export library** to take all your data off the device as a `.zip`.
- Tap **Settings → Privacy → Delete all data** to wipe every recording, transcript, summary, topic, and the encryption key from the device. There is no recovery.

## Children

Murmur is rated 4+ but does not knowingly process data from children under 13.

## Contact

Email <a href="mailto:vrkalavapalli@gmail.com">vrkalavapalli@gmail.com</a>.
