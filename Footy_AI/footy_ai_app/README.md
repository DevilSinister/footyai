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

This app supports runtime endpoint configuration via `--dart-define` or from
the in-app **Settings** screen. For a physical device, use the computer's LAN
IP; `10.0.2.2` only reaches the host from an Android emulator.

Pass `API_BASE_URL` for the unified FastAPI service. The legacy
`DB_API_BASE_URL` and `PROCESSING_API_BASE_URL` values remain supported for
older split-service installations.

Example:

```bash
flutter run --dart-define=API_BASE_URL=http://<current-ip>:8000
```

APK build example:

```bash
flutter build apk --release --dart-define=API_BASE_URL=http://<current-ip>:8000
```
