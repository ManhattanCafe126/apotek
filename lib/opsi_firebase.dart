import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class OpsiFirebaseDefault {
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
      case TargetPlatform.linux:
        throw UnsupportedError(
          'OpsiFirebaseDefault have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'OpsiFirebaseDefault are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBW9GmAcoyIRFT5SdL7ewDcPNH-PbVnFpE',
    appId: '1:672892715660:web:292111c5ddb7995474f1a9',
    messagingSenderId: '672892715660',
    projectId: 'flutter-ocr-1716d',
    authDomain: 'flutter-ocr-1716d.firebaseapp.com',
    storageBucket: 'flutter-ocr-1716d.firebasestorage.app',
    measurementId: 'G-959ZD9LXRC',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBFiD1-Ob4oLYLcsS41jvGwBRP1JrH53Hc',
    appId: '1:672892715660:android:4bd7ae5eef89d93974f1a9',
    messagingSenderId: '672892715660',
    projectId: 'flutter-ocr-1716d',
    storageBucket: 'flutter-ocr-1716d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCkRVDQWePEwtbWETxFKoyHPzUoICaoV3A',
    appId: '1:672892715660:ios:f9078bbd357a11fe74f1a9',
    messagingSenderId: '672892715660',
    projectId: 'flutter-ocr-1716d',
    storageBucket: 'flutter-ocr-1716d.firebasestorage.app',
    iosBundleId: 'com.example.apotekOcr',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCkRVDQWePEwtbWETxFKoyHPzUoICaoV3A',
    appId: '1:672892715660:ios:f9078bbd357a11fe74f1a9',
    messagingSenderId: '672892715660',
    projectId: 'flutter-ocr-1716d',
    storageBucket: 'flutter-ocr-1716d.firebasestorage.app',
    iosBundleId: 'com.example.apotekOcr',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBW9GmAcoyIRFT5SdL7ewDcPNH-PbVnFpE',
    appId: '1:672892715660:web:7afb4b979dbbfece74f1a9',
    messagingSenderId: '672892715660',
    projectId: 'flutter-ocr-1716d',
    authDomain: 'flutter-ocr-1716d.firebaseapp.com',
    storageBucket: 'flutter-ocr-1716d.firebasestorage.app',
    measurementId: 'G-9PJ6CC9VN3',
  );
}
