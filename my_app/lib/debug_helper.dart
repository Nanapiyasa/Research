import 'package:flutter/material.dart';
import 'firebase_config.dart';

class DebugHelper {
  static Future<void> checkFirebaseInitialization() async {
    try {
      await FirebaseConfig.initializeFirebase();
      print('Firebase initialized successfully');
    } catch (e) {
      print('Firebase initialization failed: $e');
      // Don't show error dialog, just print the error
      // The app will continue but Firebase won't work
    }
  }
}
