# Footy AI Quick Handoff

> Working with an AI coding agent (Codex, Antigravity, Claude Code, Cursor)?
> Read [AGENTS.md](AGENTS.md) first — it covers the required languages, the full
> list of what recently changed, and the backend contract.

Use this note before rebuilding the APK whenever the network changes.

## The network changed. What now?

Usually: **nothing to rebuild.** Open the app, go to the **Settings** tab, type the
new server address, and save it. It is stored on the device.

Only rebuild if the app cannot start at all:

```bash
cd Footy_AI/footy_ai_app
flutter run --dart-define=API_BASE_URL=http://<current-ip>:8000
```

- `10.0.2.2:8000` is the default and only works from an Android emulator.
- A physical device needs the computer's LAN IP on the same Wi-Fi.
- One FastAPI service now serves auth, matches, and video processing. The legacy
  `DB_API_BASE_URL` / `PROCESSING_API_BASE_URL` defines still work for older
  split-service installs, but you do not need them.

## What should still work after the change

- Login and register hit the FastAPI service and show a real error if it is unreachable
- Uploading a video returns a job, then the app asks you to name the two detected teams
- After confirmation, processing runs to completion and opens the match summary
- The highlights screen shows live match data, not mock/demo content

## Important files

- `Footy_AI/footy_ai_app/lib/config/app_config.dart` — base URL resolution and storage
- `Footy_AI/footy_ai_app/lib/screens/settings_screen.dart` — in-app server address editor
- `Footy_AI/footy_ai_app/lib/services/api_service.dart` — matches and summaries
- `Footy_AI/footy_ai_app/lib/services/auth_service.dart` — login and register
- `Footy_AI/footy_ai_app/lib/services/processing_service.dart` — upload, status, confirm-teams
- `Footy_AI/footy_ai_app/lib/screens/match_highlights_list.dart` — highlights feed

## If the app falls back to empty or demo-looking data

- Check the FastAPI service is running and reachable from the current network
- Check the address saved in the app's Settings tab matches the machine running it
- Check the phone and the computer are on the same Wi-Fi (not guest isolation)
- Check the login error message — it names the exact address that failed
