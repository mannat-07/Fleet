import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase options generated from your project's web config.
/// Source: Firebase Console → Project Settings → Your apps → Web app
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    // Add android / ios options here when needed
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'AIzaSyD08LjWN7pxA3fmTBCN2eF75oJbPiyO12o',
    authDomain:        'hackindia-2dd25.firebaseapp.com',
    projectId:         'hackindia-2dd25',
    storageBucket:     'hackindia-2dd25.firebasestorage.app',
    messagingSenderId: '756694360930',
    appId:             '1:756694360930:web:518af63a4e9530cbe6823b',
    measurementId:     'G-0HDBVCVZ8T',
  );
}
