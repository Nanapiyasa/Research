import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseConfig {
  static bool _initialized = false;
  static bool _initializationAttempted = false;

  static Future<void> initializeFirebase({FirebaseOptions? options, Function(dynamic)? catchError}) async {
    if (!_initializationAttempted) {
      _initializationAttempted = true;
      try {
        if (Firebase.apps.isEmpty) {
          if (options != null) {
            await Firebase.initializeApp(options: options);
          } else {
            await Firebase.initializeApp();
          }
        }
        _initialized = true;
        print('Firebase initialized successfully');
      } catch (e) {
        print('Firebase initialization failed: $e');
        if (catchError != null) {
          catchError(e);
        }
        // Don't rethrow - let app continue without Firebase
      }
    } else if (!_initialized && Firebase.apps.isNotEmpty) {
      _initialized = true;
    }
  }

  static bool get isInitialized {
    if (!_initialized && Firebase.apps.isNotEmpty) {
      _initialized = true;
    }
    return _initialized;
  }

  static FirebaseAuth get auth {
    if (isInitialized) {
      return FirebaseAuth.instance;
    }
    throw Exception('Firebase not initialized');
  }

  static FirebaseFirestore get firestore {
    if (isInitialized) {
      return FirebaseFirestore.instance;
    }
    throw Exception('Firebase not initialized');
  }

  static CollectionReference get studentsCollection {
    return firestore.collection('students');
  }

  static CollectionReference get activitiesCollection {
    return firestore.collection('activities');
  }
}
