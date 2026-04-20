import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lib/firebase_config.dart';
import 'lib/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await FirebaseConfig.initializeFirebase();
  
  // Check Kasun's questionnaire completion status
  final authService = AuthService();
  final hasCompleted = await authService.hasCompletedQuestionnaire('kasun');
  
  print('=== Questionnaire Status Check ===');
  print('Username: kasun');
  print('Has completed questionnaire: $hasCompleted');
  
  if (hasCompleted) {
    print('Kasun can directly access vocational modules');
  } else {
    print('Kasun needs to complete questionnaire first');
  }
  
  // Also check directly in Firestore for debugging
  try {
    final firestore = FirebaseFirestore.instance;
    final querySnapshot = await firestore
        .collection('questionnaire_results')
        .where('studentId', isEqualTo: 'kasun')
        .limit(1)
        .get();
    
    print('Direct Firestore check - Documents found: ${querySnapshot.docs.length}');
    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      print('Document ID: ${doc.id}');
      print('Document data: ${doc.data()}');
    }
  } catch (e) {
    print('Error checking Firestore directly: $e');
  }
}
