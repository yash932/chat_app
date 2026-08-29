# Deploying PulseChat to Railway

The server keeps state on disk — SQLite (`chat_data.db`) plus uploaded files in
`uploads/`. Railway containers get a fresh filesystem on every deploy, so both
must live on a **Volume**. That's the one step you can't skip.

## 1. Create the service

Push this folder to GitHub, then in Railway: **New Project → Deploy from GitHub repo**.
Or from this folder with the CLI:

```bash
railway init
```

Nixpacks detects Node and runs `npm start`. No Dockerfile needed.

## 2. Attach a Volume  ← the important part

In your service: **Settings → Volumes → New Volume**, mount path:

```
/data
```

## 3. Set environment variables

| Variable | Value | Why |
|---|---|---|
| `DATA_DIR` | `/data` | Puts the DB and uploads on the volume |

`PORT` is injected by Railway automatically — don't set it.

Without `DATA_DIR`, the app still boots, but **every message and photo is wiped
on each redeploy**. Set it before you invite testers.

## 4. Generate a public domain

**Settings → Networking → Generate Domain**. You'll get something like
`https://pulsechat-production-a1b2.up.railway.app`.

Verify it's alive:

```bash
curl https://YOUR-APP.up.railway.app/health
```

Expect `{"status":"ok","uptime":...}`.

## 5. Web client — already done

The browser client is served by the same process at `/`, and it talks to the
backend over same-origin relative paths. Opening your Railway domain in a
browser gives you the full web app with nothing further to configure.

## 6. Build the APK against that domain

The Flutter app reads its default server from a build-time define, so you don't
have to edit source:

```bash
flutter build apk --split-per-abi --dart-define=PULSE_SERVER_URL=https://YOUR-APP.up.railway.app
```

`--split-per-abi` produces three APKs (~18 MB each) instead of one 53 MB fat
build. For most phones, ship `app-arm64-v8a-release.apk`.

Testers can also change the server in-app — login screen → the "Server:" line,
or Profile → Settings — and it persists across restarts.

## Testing web + APK together

Both hit the same backend and the same Socket.IO rooms, so a message sent from
the browser appears in the app instantly, and vice versa. Sign up two accounts,
open the web on one and the APK on the other.

## Before you invite anyone

- **Release APK is still signed with the Flutter debug key.** Create a real
  upload keystore *before* handing out builds — re-signing later forces every
  tester to uninstall and reinstall.
- **No auth on the API.** `GET /api/users` and `GET /api/channels/:id/messages`
  are open to anyone with the URL.
- **Passwords are stored in plaintext**, and a user row with an empty password
  accepts any password on first login (`database.js`).

Fine for a private week-long test with people you trust. Not fine for a public link.
