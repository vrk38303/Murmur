# Murmur — Support & Privacy site (GitHub Pages)

This folder is the source for the public site that App Store Connect points at for both Support URL and Privacy Policy URL.

## How to enable it (one-time, ~2 minutes, browser only)

1. Push this folder to GitHub on the `main` branch.
2. In the browser, open: `https://github.com/vrk38303/Murmur/settings/pages`
3. Under **Build and deployment**:
   - **Source**: `Deploy from a branch`
   - **Branch**: `main`
   - **Folder**: `/docs`
4. Click **Save**.
5. Wait ~60 seconds. The settings page will show: *"Your site is live at `https://vrk38303.github.io/Murmur/`"*.
6. Open that URL and confirm both `/` and `/privacy/` render.

## Where to use the URL

Paste it as **both** the Support URL and Privacy Policy URL in App Store Connect:

- App Store Connect → your app → **App Information** → **Privacy Policy URL**: `https://vrk38303.github.io/Murmur/privacy/`
- App Store Connect → your app → **iOS App** → **1.0 Prepare for Submission** → **Support URL**: `https://vrk38303.github.io/Murmur/`

Apple accepts the same domain for both.

## Editing the site

- `index.md` — landing page (FAQ + support email).
- `privacy.md` — privacy policy. **Update the "Last updated" date** any time the underlying app behaviour changes — Apple cross-checks the policy against the Privacy Manifest in your IPA.
- `_config.yml` — Jekyll config. Uses the built-in `minima` theme so no custom CSS or build step is needed; GitHub Pages compiles it on push.

## Why GitHub Pages

- Free.
- Version-controlled (every privacy-policy change shows up in `git log`).
- No third-party hosting account to maintain.
- Survives if the developer changes employer / loses access to a paid hosting provider.

## Custom domain (optional, later)

If you want `murmur.app` or `support.murmur.app` instead of `vrk38303.github.io/Murmur`:

1. Buy the domain (Cloudflare, Namecheap, etc.).
2. Add a `docs/CNAME` file containing the bare domain (`support.murmur.app`).
3. In your DNS provider, add a CNAME record pointing the subdomain at `vrk38303.github.io`.
4. In GitHub Pages settings, paste the custom domain and tick **Enforce HTTPS**.
5. Update both URLs in App Store Connect to the new domain.

Don't do this for v1. Ship with the `vrk38303.github.io/Murmur` URL; Apple accepts it.
