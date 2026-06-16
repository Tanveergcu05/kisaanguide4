# Kisaan Guide 4

Flutter app for farmers: **Phone auth**, **Weather (online + offline cache)**, **Crops guide (Urdu/English)**, **Orchard tips**, and **Expense tracker**.

## Requirements

- Flutter: `3.32.5` (current workspace)  
- Dart: `3.8.1`

## Run (local)

Install deps:

```bash
flutter pub get
```

Optional (recommended) OpenWeather API key override:

```bash
flutter run --dart-define=OPENWEATHER_API_KEY=YOUR_KEY
```

## Firebase

- App is configured via FlutterFire (`lib/firebase_options.dart`).
- Firestore security rules live in `firestore.rules`.
- Storage rules live in `storage.rules`.

## Notes

- The OpenWeather key is centralized in `lib/core/config/app_config.dart`. If a real key is committed, treat it as leaked and rotate it.
