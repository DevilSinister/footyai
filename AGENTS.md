# AGENTS.md — Footy AI

Instructions for AI coding agents (Codex, Antigravity, Claude Code, Cursor, Copilot).
Read this before touching any file in this repository.

---

## 1. Required languages (non-negotiable)

Every change must be written in the language that already owns that part of the tree.
Do **not** introduce a new language, framework, or state-management library to solve a
problem the existing stack can already solve.

| Area | Path | Required language / stack |
|---|---|---|
| Mobile app (all screens & UI) | `Footy_AI/footy_ai_app/` | **Dart / Flutter** (stable channel, Material `ThemeData`) |
| Video + AI processing API | FastAPI service (external, see §5) | **Python 3.10+ / FastAPI** |
| Legacy DB API (frozen) | `DataBase API/` | **C# / ASP.NET Web API** — do not extend, see §6 |
| Figma screen exports (read-only) | `Footy_AI/<screen_name>/code.html` | HTML/CSS — reference only, never the runtime |

Rules that follow from the table:

- New screens are Dart files in `lib/screens/`, registered in `lib/main.dart` routes.
- No TypeScript, no React, no Kotlin/Swift platform code unless a Flutter plugin
  genuinely cannot do the job — and say so before you write it.
- No new state-management package (no Riverpod/Bloc/GetX). This app uses plain
  `StatefulWidget` + `setState` and `static` service classes. Match that.
- Networking goes through `package:http` and the existing service classes. Do not add
  Dio, Chopper, Retrofit, or a codegen client.
- Persistence goes through `shared_preferences`. Do not add Hive/Isar/sqflite.
- **Communicate in the language the user writes to you in.** If the user writes in a
  language other than English, reply, explain, and write commit messages in that
  language. Code identifiers, API field names, and route paths stay English.

---

## 2. What changed in the latest commit

This commit rewires the Flutter app from the old **two-backend** setup (C# DB API plus
a separate Python processing API) onto a **single FastAPI service**, and adds a
human-in-the-loop team-naming step to the analysis flow.

### 2.1 Configuration — `lib/config/app_config.dart`

- One base URL now drives everything: `AppConfig.apiBaseUrl`.
- Resolution order: value saved in `SharedPreferences` → `--dart-define=API_BASE_URL`
  → default `http://10.0.2.2:8000` (Android emulator loopback to the host machine).
- `dbApiBaseUrl` and `processingApiBaseUrl` still exist as getters and still honour the
  legacy `DB_API_BASE_URL` / `PROCESSING_API_BASE_URL` defines, but with no override
  both fall through to `apiBaseUrl`. Keep them — old installs depend on them.
- New API: `load()`, `validateAndNormalizeApiBaseUrl()`, `saveApiBaseUrl()`,
  `resetApiBaseUrl()`. The validator rejects userinfo, query strings, fragments, and
  non-root paths, and defaults a missing port to `8000`.
- `main()` is now `async` and calls `WidgetsFlutterBinding.ensureInitialized()` and
  `await AppConfig.load()` **before** `runApp`. Anything that reads `apiBaseUrl` at
  startup must run after that await.

### 2.2 New screen — `lib/screens/settings_screen.dart`

- Lets the user type the server address at runtime, validate it, save it, or reset to
  the build-time default. No rebuild needed when the LAN IP changes.
- Reachable two ways: the **Settings** tab in `main_navigation_screen.dart`, and a
  "Server settings" button on the login screen (so the address can be fixed *before*
  the user is able to log in).
- Registered as route `/settings` in `lib/main.dart`.

### 2.3 Endpoints — `lib/services/api_client.dart`

Old PascalCase C# routes were replaced with the FastAPI snake_case routes:

| Old | New |
|---|---|
| `/Users/Register` | `/api/users/register` |
| `/Users/Login` | `/api/users/login` |
| `/Users/GetUserById` | `/api/users` (id appended as `/api/users/{id}`) |
| `/Processing/GetMatchesByUser` | `/api/matches?user_id={id}` |
| `/Processing/GetMatchSummary?matchId=` | `/api/matches/{matchId}` |

`ApiConstants.processingIngest` was removed; ingestion is handled by the processing
endpoints in `processing_service.dart`.

### 2.4 Auth — `lib/services/auth_service.dart`

- Every request has a 20-second timeout.
- Non-2xx responses are no longer treated as success: the body is parsed for
  `message` / `detail` and surfaced to the user.
- Connection failures now name the address that failed and point at Settings, e.g.
  *"Unable to reach http://192.168.1.50:8000. Check Server Settings and make sure the
  FastAPI server is running."*

### 2.5 Team confirmation flow — `ai_video_upload.dart` + `ai_processing_screen.dart`

This is the biggest behavioural change. The pipeline now pauses and asks the user to
name the two teams before it analyses the match.

1. `ai_video_upload.dart` uploads the video and pushes `/processing` with a `jobId`.
   The picker is wrapped in try/catch (an unavailable gallery used to crash), the
   real `userId` is passed instead of a hardcoded `1`, and the screen was rebuilt as a
   centred, max-width `ListView` with an `AppBar`.
2. `ai_processing_screen.dart` polls `GET /api/processing/status/{jobId}` **every 2s**
   (was 3s). The joke ticker and the client-side `_fallbackProgress` guesswork were
   deleted — progress now comes only from the server's `progress_percent`.
3. When status becomes `awaiting_team_confirmation`, polling **stops** and the screen
   renders the server's `team_candidates` (each with a `sample_image` of a detected
   player) with two text fields.
4. `ProcessingService.confirmTeams()` POSTs
   `/api/processing/confirm-teams/{jobId}` with `{team_1_name, team_2_name}`.
   Validation: both non-empty, and not equal case-insensitively.
5. Polling resumes; on `completed` the screen reads the result and navigates to
   `/summary` with `matchId` (falling back from `db_response.matchId` to
   `result.match_id`).
6. `202 Accepted` is now treated as success alongside `200` on upload and status.
7. Status `failed` stops polling and shows the server error.

### 2.6 Match summary — `lib/screens/ai_match_summary.dart`

- Goal events now name the scorer when the backend supplies one:
  `Team A — #9 John Doe scored`, degrading to `Team A — #9 scored` and then
  `Team A scored` as data is missing. Reads `jerseyNumber`/`detectedJerseyNo` and
  `playerName`/`detectedPlayerName`.
- `ApiService._buildHighlightsFromSummary` gained the same jersey/player fallbacks and
  emits `#<jersey>` or `Scorer unavailable` rather than a wrong name.

### 2.7 Housekeeping

- **`MyHttpOverrides` was deleted from `main.dart`.** It globally accepted every
  invalid TLS certificate. Do not reintroduce it. If HTTPS to a dev server is needed,
  fix the certificate or scope the exception to that one host.
- `splash_screen.dart` holds its 3s delay in a cancellable `Timer` and cancels it in
  `dispose()` (fixes a setState-after-dispose path).
- All `Color.withOpacity(x)` in touched files became `Color.withValues(alpha: x)`
  (`withOpacity` is deprecated). Untouched files still use the old call — see §4.
- Whole app reformatted with `dart format`; much of the diff is formatting only.
- `android/app/build.gradle.kts`: release still uses debug signing — fine for internal
  testing, **must** get a real upload key before any store release.

---

## 3. How to run it

```bash
cd Footy_AI/footy_ai_app && flutter pub get
```

Android emulator (host loopback default, nothing to pass):

```bash
flutter run
```

Physical device on the same Wi-Fi — use the computer's LAN IP:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8000
```

Release APK:

```bash
flutter build apk --release --dart-define=API_BASE_URL=http://192.168.1.50:8000
```

If the IP changes after install, the user does **not** need a rebuild — they change it
in the app's Settings tab.

---

## 4. Before you open a PR

```bash
cd Footy_AI/footy_ai_app && dart format . && flutter analyze --no-pub
```

Current baseline: **0 errors, 0 warnings, 51 infos.** The infos live in files this
change did not touch (`signup_screen.dart`, `analysis_card.dart`, parts of
`splash_screen.dart`) and are all `curly_braces_in_flow_control_structures` or
deprecated `withOpacity`. Do not let your change raise the error or warning count.
Clearing the leftover infos is welcome as its own separate commit.

There is no test suite yet. If you add logic worth protecting, add
`test/<name>_test.dart` and run `flutter test`.

---

## 5. Backend contract the app expects

The FastAPI service is **not stored in this repository** — it is run separately. The
app assumes these routes exist on `API_BASE_URL`:

```
POST /api/users/register                     {username, email, password}
POST /api/users/login                        {email, password}
GET  /api/users/{userId}
GET  /api/matches?user_id={id}
GET  /api/matches/{matchId}
POST /api/processing/upload                  (multipart video)
GET  /api/processing/status/{jobId}
POST /api/processing/confirm-teams/{jobId}   {team_1_name, team_2_name}
GET  /api/processing/result/{jobId}
GET  /api/processing/clips/{jobId}/{fileName}
```

Status values the app switches on: `queued`, `downloading`, `uploaded`, `processing`,
`awaiting_team_confirmation`, `completed`, `failed`.

Status payload fields the app reads: `status`, `stage`, `progress_percent`, `error`,
`team_candidates[].sample_image`.

If you change any route, payload shape, or status string, change it on both sides in
the same commit.

---

## 6. Localizing the Flutter screens

The screens are currently English-first. Before adding another language, adopt
Flutter's localization flow (`flutter_localizations`, `intl`, ARB files, and
generated localizations) rather than scattering translated literals through
widgets.

- Move every visible string into translations: screen titles, buttons, form
  labels, validation and network errors, snack bars, dialog copy, placeholders,
  semantics labels, and dynamic status/result messages.
- Keep API routes, JSON keys, enum/status values, Dart identifiers, and stored
  preferences stable and in English. Translate the labels presented to users,
  not the backend contract.
- Use parameterized complete messages for names, scores, numbers, and durations;
  never concatenate translated fragments. Format values with `intl` for the
  selected locale.
- Support right-to-left locales using Flutter directionality. Use directional
  layout APIs (`EdgeInsetsDirectional`, `AlignmentDirectional`, and
  `TextAlign.start/end`) instead of left/right-specific values in touched UI.
- Test every locale at phone and tablet widths. Let labels, team names, and error
  messages wrap or expand; do not clip critical actions, scores, or accessible
  labels.
- Record supported locale codes and the in-app language-selection path in this
  handoff whenever localization is added.

---

## 7. Do not touch without asking

- `DataBase API/` — the legacy C# ASP.NET API. The app no longer calls it. It is kept
  for reference. Do not extend it, and do not point the app back at it.
- `Footy_AI/<screen_name>/code.html` + `screen.png` — original Figma exports. They are
  design reference. Editing them changes nothing at runtime.
- `Footy_AI/server.js` + `node_modules/` — an old Node helper, not part of the app.
- Generated files: `*/flutter/generated_plugin_registrant.*`, `generated_plugins.cmake`,
  `GeneratedPluginRegistrant.swift`. Regenerated by `flutter pub get`; never hand-edit.
- Never commit the FastAPI service's `uploads/`, `static/`, model weights, `.env`, or
  any real database credentials.

---

## 8. Conventions

- Dart: `dart format` defaults (80 cols), `lowerCamelCase` members, `_private` prefix,
  `const` constructors wherever possible.
- Always `if (!mounted) return;` after an `await` before touching `context` or
  calling `setState`.
- Always cancel `Timer`s and dispose `TextEditingController`s and
  `VideoPlayerController`s in `dispose()`.
- Colors and text styles come from `lib/theme.dart` (`AppColors`) and the `Lexend`
  font family. Do not hardcode hex colors inside a screen.
- Network failures must reach the user as a readable `SnackBar` or inline error that
  names what to check. Never swallow an exception silently.
- Commit messages: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`), written
  in the user's language.
