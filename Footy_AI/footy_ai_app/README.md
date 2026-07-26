# footy_ai_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Runtime API Configuration

This app supports runtime endpoint configuration via `--dart-define`.

You should pass these values at build time:
- `DB_API_BASE_URL`
- `PROCESSING_API_BASE_URL`

- `DB_API_BASE_URL`: C# API base URL
- `PROCESSING_API_BASE_URL`: Python FastAPI base URL

Example:

```bash
flutter run ^
  --dart-define=DB_API_BASE_URL=http://<current-ip>/Footy_AI/api ^
  --dart-define=PROCESSING_API_BASE_URL=http://<current-ip>:8000
```

APK build example:

```bash
flutter build apk ^
  --dart-define=DB_API_BASE_URL=http://<current-ip>/Footy_AI/api ^
  --dart-define=PROCESSING_API_BASE_URL=http://<current-ip>:8000
```
