# Footy AI Quick Handoff

Use this note before rebuilding the APK whenever the network changes.

What to update:

- Edit `Footy_AI/footy_ai_app/lib/config/app_config.dart`
- Set the API base URLs with `--dart-define`
- Do not rely on hardcoded defaults

Build-time example:

- `DB_API_BASE_URL=http://<current-ip>/Footy_AI/api`
- `PROCESSING_API_BASE_URL=http://<current-ip>:8000`

What should still work after the change:

- Flutter should fetch recent matches and match summaries from the DB API
- Flutter should upload videos and poll the processing API
- The highlights screen should show live match data instead of mock/demo content

Important files:

- `Footy_AI/footy_ai_app/lib/config/app_config.dart`
- `Footy_AI/footy_ai_app/lib/services/api_service.dart`
- `Footy_AI/footy_ai_app/lib/screens/match_highlights_list.dart`

If the app ever falls back to empty or demo-looking data again, check:

- The DB API is reachable from the current network
- The processing API is reachable from the current network
- The values passed through `--dart-define` match the machine running the services
