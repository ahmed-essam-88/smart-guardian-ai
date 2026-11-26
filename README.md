# SMART GUARDIAN AI

Intelligent Fire Risk Monitoring & Early Warning System. Flutter / Dart, Android.

This is a supplementary monitoring tool. It is not a replacement for certified smoke alarms, fire detection systems or professional emergency services.

## What it does
- Dashboard: circular risk gauge (0-100%), 4 risk levels, six sensor cards, ESP32 connection panel, emergency section.
- Rule-based risk engine (temperature > 50 C, smoke > 100, gas > 100, flame, +25 each). Thresholds are configurable in Settings. They are demonstration values, not certified fire-safety thresholds, and the score is not a validated probability of fire. Sensors must be calibrated and validated before real use.
- Flame detection raises an immediate alert regardless of the score. Alerts fire on risk-level changes with a 60 s duplicate-prevention cooldown.
- Analytics (today / 7 / 30 days): totals, average and highest risk, temperature, smoke and risk charts, sensor comparison, empty states.
- History: SQLite storage, search, risk filter, newest/oldest, details, delete with confirmation, CSV export.
- Bluetooth Classic (SPP) with safe CSV parsing. See docs/ESP32_PROTOCOL.md.
- Demo Mode: simulated readings (Normal / Elevated / Fire), clearly marked DEMO, stored with source=demo so they never mix with real hardware data.
- Emergency: opens the dialer (never auto-calls), WhatsApp SOS draft you review and send yourself, location only with explicit permission, safety instructions.
- No trained AI model exists. `FutureAiEngine` in `lib/services/risk_engine.dart` is an empty boundary for a future model. The app shows no AI predictions.

## Structure
    lib/core        theme and design system
    lib/data        models, sqflite database, settings
    lib/services    risk engine, Bluetooth, demo generator, notifications
    lib/state       MonitorController (ties input, engine, storage, alerts)
    lib/ui          screens and reusable widgets
    android/        native Bluetooth + notification code (MainActivity.kt)
    tools/make_icon.py  regenerates the icon set

## Build
    flutter pub get
    flutter test
    flutter build apk --release
Needs Flutter 3.35+, JDK 17, Android SDK 34. Output: build/app/outputs/flutter-apk/app-release.apk.
The release APK is signed with the debug key (fine for demos and sideloading, not for Play Store).

## Testing
Unit tests: `flutter test` (risk engine levels and boundaries, parser, demo tagging).
Manual: Settings > Demo Mode > pick Normal / Elevated / Fire emergency and watch the gauge, alerts, History and Analytics. For hardware, pair FireGuard_ESP32 and connect from the dashboard.

## Cloud sync
Not implemented. The database schema is versioned and records have ids and timestamps so a sync layer can be added later.

## Reset and emergency numbers
- Settings > Reset app: confirmation dialog, then restores all settings to defaults, disconnects Bluetooth, stops Demo Mode and deletes stored readings and alerts.
- Emergency screen: quick buttons for Fire 180, Ambulance 123 and Police 122 (Egypt). They open the dialer with the number filled in; the call is never started automatically.

## Languages, safety guide, SOS location
- Arabic (RTL) and English. Settings > Language; defaults to English. Translations live in lib/core/l10n.dart.
- Safety guide (Emergency screen > Open safety guide): fire, gas leak, electrical and kitchen fires, extinguisher use, home prevention. Arabic and English.
- WhatsApp SOS can attach a Google Maps link built from the phone's own GPS/network location (Android LocationManager, no API key, no Google services). Permission is requested first; WhatsApp opens with the text prefilled and the user presses send.

## Login (Firebase Auth)
Email/password sign-in, sign-up and password reset through Firebase Authentication only (no Firestore/Storage/Analytics). Config: lib/services/firebase_options.dart (public client config, not a secret). Login is required to use the app. In the Firebase console: Authentication > Sign-in method > enable Email/Password.
