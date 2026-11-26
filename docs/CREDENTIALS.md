# External credentials and setup you must complete yourself

Smart Guardian Egypt works out of the box with simulated data and local
storage. These are the only external services involved, what is already
done, and what needs your own account/console steps.

## 1. Firebase Authentication (REQUIRED for sign-in) - already wired

The app ships with the web Firebase config in `lib/services/firebase_options.dart`
(public client config, not a secret). Email/password sign-in, sign-up and
password reset are implemented.

You must do once, in the Firebase console (free Spark plan):
1. Open the project.
2. Authentication > Sign-in method > enable **Email/Password**.
3. Add your users, or let them create accounts from the app.

## 2. OpenStreetMap tiles (free, no key) - no setup needed

The Smart Map uses the public OpenStreetMap tile server with the app
package name as the user agent, plus on-map attribution. Heavy commercial
use would need a paid tile provider; for this demo app no action is needed.

## 3. NOT included (need your own Firebase console setup if you want them)

These were listed in the master prompt but are intentionally not active,
because they each need configuration in your own Firebase project:

- **Cloud Firestore** (cloud database): the app currently stores everything
  locally in SQLite (schema v2, indexed). To add Firestore later: create the
  database in the console, add `cloud_firestore`, move `AppDatabase` behind
  the existing repository boundary, and publish security rules so users can
  only read/write their own records.
- **Firebase Cloud Messaging** (push notifications): local high-priority
  notifications are implemented. Remote push needs `firebase_messaging` and
  console setup.
- **Crashlytics / Analytics**: need `firebase_crashlytics` /
  `firebase_analytics` and console setup.
- **Cloud Functions**: none needed yet.

## 4. Android release signing (only for Play Store)

The CI release APK is signed with the debug key (fine for demos and
sideloading, not accepted by Play Store). For Play distribution, create an
upload key and configure `key.properties` in `android/`.

## 5. ESP32 hardware (optional)

No credentials needed. Build the sketch in `docs/ESP32_PROTOCOL.md`, pair
the board (name `FireGuard_ESP32`) in Android Bluetooth settings, and pick
it in the app. The app accepts JSON (preferred) or legacy CSV lines.

## Security notes

- No API keys or secrets are stored in the source. The Firebase web config
  is a public client identifier, not a credential.
- The app never auto-calls or auto-messages emergency services; every
  emergency action requires explicit user confirmation.
