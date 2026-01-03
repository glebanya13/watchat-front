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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB6ywxrmSQa9hRywiCLV_lPdkONthNdZjo',
    appId: '1:875145628698:web:1ea10564facaf556f915a3',
    messagingSenderId: '875145628698',
    projectId: 'chatzy-web-app-115df',
    authDomain: 'chatzy-web-app-115df.firebaseapp.com',
    storageBucket: 'chatzy-web-app-115df.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDLPPYB9AW72_OiqlS_hFuUTZgnjrCzdWM',
    appId: '1:875145628698:android:085b89c3b3c6bb98f915a3',
    messagingSenderId: '875145628698',
    projectId: 'chatzy-web-app-115df',
    storageBucket: 'chatzy-web-app-115df.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBDNksBqxhniWzb10HkV58Bgihu4fKD_5k',
    appId: '1:875145628698:ios:408a594b86ff85c8f915a3',
    messagingSenderId: '875145628698',
    projectId: 'chatzy-web-app-115df',
    storageBucket: 'chatzy-web-app-115df.firebasestorage.app',
    iosClientId: '875145628698-23ai8h9hc8sb5giq7k0p9uqb6jfgcfj9.apps.googleusercontent.com',
    iosBundleId: 'com.example.gochat',
  );

}