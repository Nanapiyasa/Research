import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../firebase_config.dart';
import '../models/student_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Student Operations
  Future<String> createStudent(Student student) async {
    try {
      DocumentReference docRef = await FirebaseConfig.studentsCollection.add(student.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating student: $e');
      rethrow;
    }
  }

  Future<Student?> getStudent(String studentId) async {
    try {
      DocumentSnapshot doc = await FirebaseConfig.studentsCollection.doc(studentId).get();
      if (doc.exists) {
        return Student.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting student: $e');
      rethrow;
    }
  }

  Future<Student?> getStudentByUsername(String username) async {
    try {
      QuerySnapshot query = await FirebaseConfig.studentsCollection
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        return Student.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting student by username: $e');
      rethrow;
    }
  }

  Future<void> updateStudent(String studentId, Map<String, dynamic> data) async {
    try {
      await FirebaseConfig.studentsCollection.doc(studentId).update(data);
    } catch (e) {
      print('Error updating student: $e');
      rethrow;
    }
  }

  // Game Results Operations
  Future<void> addGameResult(String studentId, GameResult gameResult) async {
    try {
      await FirebaseConfig.studentsCollection.doc(studentId).update({
        'gameResults.${gameResult.gameType}': FieldValue.arrayUnion([gameResult.toMap()])
      });
    } catch (e) {
      print('Error adding game result: $e');
      rethrow;
    }
  }

  // Activity Time Operations
  Future<void> addActivityTime(String studentId, ActivityTime activityTime) async {
    try {
      await FirebaseConfig.studentsCollection.doc(studentId).update({
        'activityTimes.${activityTime.activityName}': FieldValue.arrayUnion([activityTime.toMap()])
      });
    } catch (e) {
      print('Error adding activity time: $e');
      rethrow;
    }
  }

  // Module Progress Operations
  Future<void> updateModuleProgress(String studentId, ModuleProgress moduleProgress) async {
    try {
      await FirebaseConfig.studentsCollection.doc(studentId).update({
        'moduleProgress.${moduleProgress.moduleId}': moduleProgress.toMap()
      });
    } catch (e) {
      print('Error updating module progress: $e');
      rethrow;
    }
  }

  // Job Role Recommendation
  Future<void> updateJobRecommendation(String studentId, String jobRole) async {
    try {
      await FirebaseConfig.studentsCollection.doc(studentId).update({
        'recommendedJobRole': jobRole
      });
    } catch (e) {
      print('Error updating job recommendation: $e');
      rethrow;
    }
  }

  // Get all students (for admin purposes)
  Future<List<Student>> getAllStudents() async {
    try {
      QuerySnapshot query = await FirebaseConfig.studentsCollection.get();
      return query.docs.map((doc) => Student.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting all students: $e');
      rethrow;
    }
  }

  // Delete student
  Future<void> deleteStudent(String studentId) async {
    try {
      await FirebaseConfig.studentsCollection.doc(studentId).delete();
    } catch (e) {
      print('Error deleting student: $e');
      rethrow;
    }
  }

  // Analytics Methods
  Future<Map<String, dynamic>> getStudentAnalytics(String studentId) async {
    try {
      DocumentSnapshot doc = await FirebaseConfig.studentsCollection.doc(studentId).get();
      if (doc.exists) {
        Student student = Student.fromFirestore(doc);
        
        // Calculate total time spent
        int totalTime = 0;
        student.activityTimes.forEach((key, value) {
          if (value is List) {
            for (var activity in value) {
              if (activity is Map && activity['duration'] != null) {
                totalTime += activity['duration'] as int;
              }
            }
          }
        });

        // Calculate average game scores
        Map<String, double> averageScores = {};
        student.gameResults.forEach((gameType, results) {
          if (results is List) {
            int totalScore = 0;
            int count = 0;
            for (var result in results) {
              if (result is Map && result['score'] != null) {
                totalScore += result['score'] as int;
                count++;
              }
            }
            if (count > 0) {
              averageScores[gameType] = totalScore / count;
            }
          }
        });

        // Calculate overall completion percentage
        double overallCompletion = 0.0;
        int moduleCount = student.moduleProgress.length;
        if (moduleCount > 0) {
          double totalCompletion = 0.0;
          student.moduleProgress.forEach((key, value) {
            if (value is Map && value['completionPercentage'] != null) {
              totalCompletion += (value['completionPercentage'] as num).toDouble();
            }
          });
          overallCompletion = totalCompletion / moduleCount;
        }

        return {
          'totalTimeSpent': totalTime,
          'averageGameScores': averageScores,
          'overallCompletion': overallCompletion,
          'totalModules': moduleCount,
          'recommendedJobRole': student.recommendedJobRole,
        };
      }
      return {};
    } catch (e) {
      print('Error getting student analytics: $e');
      rethrow;
    }
  }
}
