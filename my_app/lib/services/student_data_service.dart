import 'package:cloud_firestore/cloud_firestore.dart';

class StudentDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Store individual level data for a student
  static Future<void> storeLevelData({
    required String studentId,
    required int level,
    required int score,
    required int attempts,
    required int timeSpent,
    required String difficultyLevel,
    String? activityId, // Foreign key to activities collection
  }) async {
    try {
      final levelData = {
        'studentId': studentId, // Foreign key to students collection
        'level': level, // Level number (1, 2, 3)
        'score': score, // Score achieved in this level
        'attempts': attempts, // Number of attempts
        'timeSpent': timeSpent, // Time spent in seconds
        'difficultyLevel': difficultyLevel, // e.g., 'Easy', 'Medium', 'Hard'
        'activityId': activityId, // Foreign key to activities collection
        'completedAt': FieldValue.serverTimestamp(), // When the level was completed
      };

      await _firestore.collection('student_data').add(levelData);
      print('Level data stored successfully for student: $studentId, level: $level');
    } catch (e) {
      print('Error storing level data: $e');
      throw Exception('Failed to store level data: $e');
    }
  }

  /// Get all level data for a specific student
  static Future<List<Map<String, dynamic>>> getStudentLevelData(String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('student_data')
          .where('studentId', isEqualTo: studentId)
          .orderBy('completedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error fetching student level data: $e');
      return [];
    }
  }

  /// Get level data for a specific module and level
  static Future<Map<String, dynamic>?> getSpecificLevelData({
    required String studentId,
    required String moduleName,
    required int level,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('student_data')
          .where('studentId', isEqualTo: studentId)
          .where('moduleName', isEqualTo: moduleName)
          .where('level', isEqualTo: level)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      print('Error fetching specific level data: $e');
      return null;
    }
  }

  /// Get module summary for a student
  static Future<Map<String, dynamic>> getModuleSummary({
    required String studentId,
    required String moduleName,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('student_data')
          .where('studentId', isEqualTo: studentId)
          .where('moduleName', isEqualTo: moduleName)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'totalScore': 0,
          'totalTime': 0,
          'totalAttempts': 0,
          'levelsCompleted': 0,
        };
      }

      final docs = querySnapshot.docs.map((doc) => doc.data()).toList();
      
      int totalScore = 0;
      int totalTime = 0;
      int totalAttempts = 0;
      int levelsCompleted = docs.length;

      for (final doc in docs) {
        totalScore += (doc['score'] ?? 0) as int;
        totalTime += (doc['timeSpent'] ?? 0) as int;
        totalAttempts += (doc['attempts'] ?? 0) as int;
      }

      return {
        'totalScore': totalScore,
        'totalTime': totalTime,
        'totalAttempts': totalAttempts,
        'levelsCompleted': levelsCompleted,
        'averageScore': levelsCompleted > 0 ? (totalScore / levelsCompleted).round() : 0,
      };
    } catch (e) {
      print('Error fetching module summary: $e');
      return {
        'totalScore': 0,
        'totalTime': 0,
        'totalAttempts': 0,
        'levelsCompleted': 0,
      };
    }
  }

  /// Update existing level data
  static Future<void> updateLevelData({
    required String documentId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _firestore.collection('student_data').doc(documentId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Level data updated successfully for document: $documentId');
    } catch (e) {
      print('Error updating level data: $e');
      throw Exception('Failed to update level data: $e');
    }
  }
}
