// lib/pages/ml_intervention_model.dart
import 'package:flutter/material.dart';

// Game Difficulty Levels
enum DifficultyLevel {
  veryEasy,
  easy,
  medium,
  hard,
  veryHard,
}

extension DifficultyLevelExtension on DifficultyLevel {
  String get displayName {
    switch (this) {
      case DifficultyLevel.veryEasy:
        return 'Very Easy';
      case DifficultyLevel.easy:
        return 'Easy';
      case DifficultyLevel.medium:
        return 'Medium';
      case DifficultyLevel.hard:
        return 'Hard';
      case DifficultyLevel.veryHard:
        return 'Very Hard';
    }
  }

  int get encoded {
    switch (this) {
      case DifficultyLevel.veryEasy:
        return 0;
      case DifficultyLevel.easy:
        return 1;
      case DifficultyLevel.medium:
        return 2;
      case DifficultyLevel.hard:
        return 3;
      case DifficultyLevel.veryHard:
        return 4;
    }
  }

  Color get color {
    switch (this) {
      case DifficultyLevel.veryEasy:
        return Colors.green;
      case DifficultyLevel.easy:
        return Colors.lightGreen;
      case DifficultyLevel.medium:
        return Colors.orange;
      case DifficultyLevel.hard:
        return Colors.deepOrange;
      case DifficultyLevel.veryHard:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case DifficultyLevel.veryEasy:
        return Icons.sentiment_very_satisfied;
      case DifficultyLevel.easy:
        return Icons.sentiment_satisfied;
      case DifficultyLevel.medium:
        return Icons.sentiment_neutral;
      case DifficultyLevel.hard:
        return Icons.sentiment_dissatisfied;
      case DifficultyLevel.veryHard:
        return Icons.sentiment_very_dissatisfied;
    }
  }
}

// Game Types
enum GameType {
  memoryMatch,
  patternRecognition,
  sequenceMemory,
  reactionTime,
  problemSolving,
}

extension GameTypeExtension on GameType {
  String get displayName {
    switch (this) {
      case GameType.memoryMatch:
        return 'Memory Match';
      case GameType.patternRecognition:
        return 'Pattern Recognition';
      case GameType.sequenceMemory:
        return 'Sequence Memory';
      case GameType.reactionTime:
        return 'Reaction Time';
      case GameType.problemSolving:
        return 'Problem Solving';
    }
  }

  IconData get icon {
    switch (this) {
      case GameType.memoryMatch:
        return Icons.psychology;
      case GameType.patternRecognition:
        return Icons.grid_on;
      case GameType.sequenceMemory:
        return Icons.timeline;
      case GameType.reactionTime:
        return Icons.speed;
      case GameType.problemSolving:
        return Icons.lightbulb;
    }
  }

  Color get color {
    switch (this) {
      case GameType.memoryMatch:
        return Colors.purple;
      case GameType.patternRecognition:
        return Colors.blue;
      case GameType.sequenceMemory:
        return Colors.teal;
      case GameType.reactionTime:
        return Colors.orange;
      case GameType.problemSolving:
        return Colors.green;
    }
  }
}

// Session Data for ML Prediction
class GameSessionData {
  final int timeSec; // Time spent in seconds
  final int numberOfTimesPlayed; // Number of sessions played
  final int score; // User score
  final DifficultyLevel difficultyLevel; // Difficulty level
  final GameType gameType; // Type of game played
  final DateTime timestamp;

  GameSessionData({
    required this.timeSec,
    required this.numberOfTimesPlayed,
    required this.score,
    required this.difficultyLevel,
    required this.gameType,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'time_sec': timeSec,
      'number_of_times_played': numberOfTimesPlayed,
      'score': score,
      'difficulty_level_encoded': difficultyLevel.encoded,
      'game_type': gameType.index,
    };
  }
}

// ML Prediction Result
class MLPredictionResult {
  final String recommendation;
  final double probability;
  final bool needsIntervention;
  final Map<String, dynamic> similarPattern;

  MLPredictionResult({
    required this.recommendation,
    required this.probability,
    required this.needsIntervention,
    required this.similarPattern,
  });

  factory MLPredictionResult.fromJson(Map<String, dynamic> json) {
    return MLPredictionResult(
      recommendation: json['recommendation'] ?? 'Keep up the good work!',
      probability: (json['probability'] ?? 0.0).toDouble(),
      needsIntervention: json['needs_intervention'] ?? false,
      similarPattern: json['similar_pattern'] ?? {},
    );
  }

  String get probabilityText {
    return '${(probability * 100).toStringAsFixed(1)}%';
  }

  Color get probabilityColor {
    if (probability < 0.3) return Colors.green;
    if (probability < 0.6) return Colors.orange;
    return Colors.red;
  }

  String get interventionMessage {
    if (needsIntervention) {
      return '⚠️ Intervention Recommended';
    } else {
      return '✅ On Track';
    }
  }
}

// Game Statistics
class GameStatistics {
  int totalSessions;
  int totalScore;
  int totalTimeSpent;
  Map<GameType, int> gamesPlayed;
  Map<DifficultyLevel, int> difficultyAttempts;
  List<GameSessionData> sessionHistory;
  DateTime firstPlayed;
  DateTime lastPlayed;

  GameStatistics({
    this.totalSessions = 0,
    this.totalScore = 0,
    this.totalTimeSpent = 0,
    Map<GameType, int>? gamesPlayed,
    Map<DifficultyLevel, int>? difficultyAttempts,
    List<GameSessionData>? sessionHistory,
    required this.firstPlayed,
    required this.lastPlayed,
  })  : gamesPlayed = gamesPlayed ?? {},
        difficultyAttempts = difficultyAttempts ?? {},
        sessionHistory = sessionHistory ?? [];

  // Calculate average score
  double get averageScore {
    if (totalSessions == 0) return 0;
    return totalScore / totalSessions;
  }

  // Calculate average time per session
  double get averageTimePerSession {
    if (totalSessions == 0) return 0;
    return totalTimeSpent / totalSessions;
  }

  // Get most played game
  GameType? get mostPlayedGame {
    if (gamesPlayed.isEmpty) return null;
    return gamesPlayed.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  // Get preferred difficulty
  DifficultyLevel? get preferredDifficulty {
    if (difficultyAttempts.isEmpty) return null;
    return difficultyAttempts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // Prepare data for ML prediction
  GameSessionData get currentSessionData {
    return GameSessionData(
      timeSec: totalTimeSpent,
      numberOfTimesPlayed: totalSessions,
      score: totalScore,
      difficultyLevel: preferredDifficulty ?? DifficultyLevel.medium,
      gameType: mostPlayedGame ?? GameType.memoryMatch,
      timestamp: DateTime.now(),
    );
  }
}