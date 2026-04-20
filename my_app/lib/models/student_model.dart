import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String? id;
  final String firstName;
  final String lastName;
  final String age;
  final String username;
  final DateTime createdAt;
  final Map<String, dynamic> gameResults;
  final Map<String, dynamic> activityTimes;
  final Map<String, dynamic> moduleProgress;
  final String? recommendedJobRole;

  Student({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.username,
    required this.createdAt,
    this.gameResults = const {},
    this.activityTimes = const {},
    this.moduleProgress = const {},
    this.recommendedJobRole,
  });

  // Convert Student to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'username': username,
      'createdAt': createdAt,
      'gameResults': gameResults,
      'activityTimes': activityTimes,
      'moduleProgress': moduleProgress,
      'recommendedJobRole': recommendedJobRole,
    };
  }

  // Create Student from Firestore Document
  factory Student.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Student(
      id: doc.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      age: data['age'] ?? '',
      username: data['username'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      gameResults: data['gameResults'] ?? {},
      activityTimes: data['activityTimes'] ?? {},
      moduleProgress: data['moduleProgress'] ?? {},
      recommendedJobRole: data['recommendedJobRole'],
    );
  }

  // Create Student copy with updated fields
  Student copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? age,
    String? username,
    DateTime? createdAt,
    Map<String, dynamic>? gameResults,
    Map<String, dynamic>? activityTimes,
    Map<String, dynamic>? moduleProgress,
    String? recommendedJobRole,
  }) {
    return Student(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      age: age ?? this.age,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
      gameResults: gameResults ?? this.gameResults,
      activityTimes: activityTimes ?? this.activityTimes,
      moduleProgress: moduleProgress ?? this.moduleProgress,
      recommendedJobRole: recommendedJobRole ?? this.recommendedJobRole,
    );
  }
}

class GameResult {
  final String gameType; // chef, retail, cleaning
  final int score;
  final int timeSpent; // in seconds
  final DateTime timestamp;
  final Map<String, dynamic> additionalData;

  GameResult({
    required this.gameType,
    required this.score,
    required this.timeSpent,
    required this.timestamp,
    this.additionalData = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'gameType': gameType,
      'score': score,
      'timeSpent': timeSpent,
      'timestamp': timestamp,
      'additionalData': additionalData,
    };
  }

  factory GameResult.fromMap(Map<String, dynamic> data) {
    return GameResult(
      gameType: data['gameType'] ?? '',
      score: data['score'] ?? 0,
      timeSpent: data['timeSpent'] ?? 0,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      additionalData: data['additionalData'] ?? {},
    );
  }
}

class ActivityTime {
  final String activityName;
  final int duration; // in seconds
  final DateTime startTime;
  final DateTime endTime;

  ActivityTime({
    required this.activityName,
    required this.duration,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'activityName': activityName,
      'duration': duration,
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  factory ActivityTime.fromMap(Map<String, dynamic> data) {
    return ActivityTime(
      activityName: data['activityName'] ?? '',
      duration: data['duration'] ?? 0,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
    );
  }
}

class ModuleProgress {
  final String moduleId;
  final String moduleName;
  final double completionPercentage;
  final List<String> completedTasks;
  final DateTime lastUpdated;

  ModuleProgress({
    required this.moduleId,
    required this.moduleName,
    required this.completionPercentage,
    this.completedTasks = const [],
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'moduleId': moduleId,
      'moduleName': moduleName,
      'completionPercentage': completionPercentage,
      'completedTasks': completedTasks,
      'lastUpdated': lastUpdated,
    };
  }

  factory ModuleProgress.fromMap(Map<String, dynamic> data) {
    return ModuleProgress(
      moduleId: data['moduleId'] ?? '',
      moduleName: data['moduleName'] ?? '',
      completionPercentage: (data['completionPercentage'] ?? 0.0).toDouble(),
      completedTasks: List<String>.from(data['completedTasks'] ?? []),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }
}
