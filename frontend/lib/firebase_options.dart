// Run `flutterfire configure` to replace placeholders with your Firebase project.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError('DefaultFirebaseOptions is not supported for this platform.');
    }
  }

  /// Google OAuth Web Client ID (Firebase Console → Authentication → Google).
  static const String webClientId =
      '1021927325395-367j2rf0cpssct9votp9agi5trs2fblp.apps.googleusercontent.com';

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCq4V1v_vnMAhxAdgAPoM8lTv8v_VMkOn8',
    appId: '1:1021927325395:web:833ff6acc06aa5e14f5e26',
    messagingSenderId: '1021927325395',
    projectId: 'pagepace-cb8fb',
    authDomain: 'pagepace-cb8fb.firebaseapp.com',
    storageBucket: 'pagepace-cb8fb.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBE-G5Ig9PyczSmnsa_MsYOnP75qoX562k',
    appId: '1:1021927325395:android:b3c0d5ec6aab35884f5e26',
    messagingSenderId: '1021927325395',
    projectId: 'pagepace-cb8fb',
    storageBucket: 'pagepace-cb8fb.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC9gl0B8uLdxCQKfPn740Gs66ioxJYMzEU',
    appId: '1:1021927325395:ios:871f1b4f18817f4c4f5e26',
    messagingSenderId: '1021927325395',
    projectId: 'pagepace-cb8fb',
    storageBucket: 'pagepace-cb8fb.firebasestorage.app',
    iosClientId: '1021927325395-fmifj9tkqg5rqbirtameovbqa7ahcoiv.apps.googleusercontent.com',
    iosBundleId: 'com.pagepace.pagepace',
  );

  static const FirebaseOptions macos = ios;

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'YOUR_WINDOWS_API_KEY',
    appId: 'YOUR_WINDOWS_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );
}