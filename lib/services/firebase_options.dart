import 'package:firebase_core/firebase_core.dart';

/// Firebase client configuration for the Smart Guardian Egypt project
/// (project id: smart-guardian-egypt).
///
/// These values come from the Firebase app config. They identify the
/// project; they are not secrets (access is controlled by Firebase Auth
/// rules and by restricting the API key in Google Cloud console).
/// Only Firebase Authentication is used. No other Firebase data is stored.
///
/// This is the Android app registration (package
/// com.smartguardian.smart_guardian_ai). The project also has a web app
/// registration (appId 1:128600707815:web:d2631c93ae30a0c45f0842) if a web
/// build is ever added.
const FirebaseOptions smartGuardianFirebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyBbR_Pwgy6XDMauZTWGtsIMTeghYLDBD1U',
  appId: '1:128600707815:android:6174a21fae0a0a085f0842',
  messagingSenderId: '128600707815',
  projectId: 'smart-guardian-egypt',
  authDomain: 'smart-guardian-egypt.firebaseapp.com',
  storageBucket: 'smart-guardian-egypt.firebasestorage.app',
);
