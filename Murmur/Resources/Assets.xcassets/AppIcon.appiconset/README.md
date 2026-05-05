# AppIcon — what's here, what's missing

## Status

`Contents.json` declares the asset catalog wants a single
**1024 × 1024 PNG** named `AppIcon-1024.png` in this folder.

That PNG **is not yet committed** because the design package ships an
SVG-style vector mark (the radiating-arcs glyph from
`OnboardingFlowView.WelcomeView`) and not a finished raster icon.

## Why the single-size set works for iOS 18+

Apple deprecated the per-size icon array in Xcode 14. As of Xcode 15+
the asset catalog accepts a single 1024×1024 source image (the
"single-size" / "Any Appearance" set declared in our Contents.json) and
auto-generates every smaller size at build time. This Contents.json is
correct as shipped — no edits needed once the PNG is present.

If you want light/dark/tinted variants (iOS 18 Tinted icon support),
add two more entries to Contents.json:

```json
{
  "appearances" : [{ "appearance" : "luminosity", "value" : "dark" }],
  "filename" : "AppIcon-1024-dark.png",
  "idiom" : "universal", "platform" : "ios", "size" : "1024x1024"
},
{
  "appearances" : [{ "appearance" : "luminosity", "value" : "tinted" }],
  "filename" : "AppIcon-1024-tinted.png",
  "idiom" : "universal", "platform" : "ios", "size" : "1024x1024"
}
```

Apple recommends but does NOT require dark/tinted variants. Shipping
just the light variant is fine for v1.

## Producing the PNG

You have three options, in increasing order of "actually looks like a
shipping app":

### Option 1 — Generate a minimal placeholder on the Codemagic / cloud Mac

Add a one-time script step to your CI (or run locally if you ever get
on a Mac) that uses macOS's built-in `sips` to render a flat-colour
PNG with the Murmur ink hex. Use this only to clear App Review's
"missing app icon" check while you wait for real artwork:

```bash
# Run from the repo root on a Mac:
python3 - <<'PY'
import struct, zlib

W = H = 1024
# Murmur ink (#15110A). RGB.
R, G, B = 0x15, 0x11, 0x0A

def chunk(tag, data):
    return (struct.pack('>I', len(data)) + tag + data
            + struct.pack('>I', zlib.crc32(tag + data) & 0xffffffff))

sig    = b'\x89PNG\r\n\x1a\n'
ihdr   = struct.pack('>IIBBBBB', W, H, 8, 2, 0, 0, 0)  # 8-bit RGB
raw    = b''
for _ in range(H):
    raw += b'\x00' + bytes([R, G, B]) * W
idat   = zlib.compress(raw, 9)
png    = sig + chunk(b'IHDR', ihdr) + chunk(b'IDAT', idat) + chunk(b'IEND', b'')
open('Murmur/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png', 'wb').write(png)
print('wrote AppIcon-1024.png (', len(png), 'bytes )')
PY
```

This produces a solid #15110A square. App Review accepts it as a valid
icon. It looks awful. **Replace it before public launch.**

### Option 2 — Render the radiating-arcs mark from the design system

The mark already lives in code at
`Murmur/Features/Onboarding/OnboardingFlowView.swift:62-78` (the
`WelcomeView` ZStack). Port that drawing to a one-shot Swift script
that writes a 1024×1024 PNG via `UIGraphicsImageRenderer`. Run it once
in an Xcode Playground on a cloud Mac. Commit the resulting PNG.

### Option 3 — Designer hand-off (recommended for App Store launch)

Hand the designer a 1024×1024 canvas brief:
- Background: `#15110A` (ink) or `#F6F2EA` (ivory paper)
- Mark: the four concentric-arc "murmur radiating outward" glyph,
  centered, ~48% of canvas
- No text on the icon (Apple HIG)
- No alpha channel (Apple rejects transparent app icons)
- Export as 24-bit PNG, sRGB color profile

Drop the file in this folder named `AppIcon-1024.png`. Done.

## How to verify

After dropping the PNG in:

```bash
xcodegen generate
xcodebuild -scheme Murmur -destination 'platform=iOS Simulator,name=iPhone 16' build
# Look for "AppIcon" in the build log; should show no warnings.
```

Then on a real install: long-press the app on the home screen — the
icon should render at every size from 60×60 (notification badge) to
180×180 (home screen on 6.7" devices).
