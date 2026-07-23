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

- `DB_API_BASE_URL`: C# API base URL (example: `http://192.168.18.14/Footy_AI/api`)
- `PROCESSING_API_BASE_URL`: Python FastAPI base URL (example: `http://192.168.18.14:8000`)

Example:

```bash
flutter run ^
  --dart-define=DB_API_BASE_URL=http://192.168.18.14/Footy_AI/api ^
  --dart-define=PROCESSING_API_BASE_URL=http://192.168.18.14:8000
```
