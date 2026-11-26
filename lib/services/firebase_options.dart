import 'package:firebase_core/firebase_core.dart';

/// Firebase client configuration for the Smart Guardian AI project.
///
/// These values come from the Firebase web app config. They identify the
/// project; they are not secrets (access is controlled by Firebase Auth
/// rules and by restricting the API key in Google Cloud console).
/// Only Firebase Authentication is used. No other Firebase data is stored.
const FirebaseOptions smartGuardianFirebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyA5BOfXDpaT8Vl5L8tHfVSIYENK0Rl3-dQ',
  appId: '1:1021309416608:web:48996e05ff6eb95a6985c5',
  messagingSenderId: '1021309416608',
  projectId: 'smart-guradian-ai',
  authDomain: 'smart-guradian-ai.firebaseapp.com',
  storageBucket: 'smart-guradian-ai.firebasestorage.app',
);
