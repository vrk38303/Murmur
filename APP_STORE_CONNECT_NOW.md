# App Store Connect: Do This From the Screen You Are On

You are currently on **App Store Connect → Apps** and it says **No Apps**. This means Apple Developer enrollment is far enough along to access App Store Connect, but the Murmur app shell has not been created yet.

I cannot directly move your mouse from this terminal-only environment. Do the clicks below exactly; after the app shell exists and credentials/secrets are in place, I can continue with the repo/CI side.

## Step 1 — Before clicking Add Apps: make sure the Bundle ID exists

Open a new browser tab:

`https://developer.apple.com/account/resources/identifiers/list`

Create this identifier if it is not already there:

| Field | Value |
|---|---|
| Type | App IDs → App |
| Description | Murmur |
| Bundle ID type | Explicit |
| Bundle ID | `app.murmur.Murmur` |
| Capabilities | Background Modes, Speech Recognition |

The bundle ID must exactly match the repo's `PRODUCT_BUNDLE_IDENTIFIER`.

If Apple says the identifier already exists, do not create another one; continue to Step 2.

## Step 2 — Create the app shell from your current screen

On the screen in your screenshot:

1. Click the blue **Add Apps** button in the center of the page.
   - If a menu appears instead, choose **New App**.
2. In the modal, enter exactly:

| Field | Value |
|---|---|
| Platforms | iOS only |
| Name | `Murmur` |
| Primary Language | English (U.S.) |
| Bundle ID | `app.murmur.Murmur` |
| SKU | `MURMUR-IOS-001` |
| User Access | Full Access |

3. Click **Create**.

If `Murmur` is already taken, use `Murmur — Voice Notes`.

If the Bundle ID dropdown is empty, stop and complete Step 1 first. It can take a minute or two for the identifier to appear.

## Step 3 — Create the API key

After the app shell is created:

1. Click **Users and Access** in the top navigation.
2. Click **Integrations**.
3. Click **App Store Connect API** / **Keys**.
4. Click **+**.
5. Use:

| Field | Value |
|---|---|
| Name | Murmur CI |
| Access | App Manager |

6. Click **Generate**.
7. Download the `.p8` file immediately. Apple only shows this file once.
8. Copy these three values into a password manager:
   - Key ID
   - Issuer ID
   - full `.p8` file contents

## Step 4 — Send me only these non-password confirmations/values

Send me:

1. `App shell created: yes`
2. `Bundle ID: app.murmur.Murmur`
3. `App Store Connect Key ID: <10-character key id>`
4. `Issuer ID: <uuid>`
5. `GitHub owner/org: <your GitHub username or org>`
6. Confirm whether you want the app name to stay `Murmur` or use fallback `Murmur — Voice Notes`.

Do **not** paste private keys or passwords into chat unless you explicitly want me to handle secret text here. The safer path is for you to add secrets directly in GitHub using the exact names from `LAUNCH_MASTER_PLAN.md`.

## Step 5 — What I will do next

Once Step 4 is done, I will drive the next concrete actions:

1. Verify the repository's app identifier and metadata line up.
2. Prepare/confirm the GitHub Actions secret list.
3. Guide the one-time signing bootstrap (`fastlane match appstore`).
4. Trigger or instruct the first TestFlight tag.
5. Move you toward App Store metadata completion and Ready to Submit.
