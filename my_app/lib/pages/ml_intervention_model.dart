// lib/pages/ml_intervention_model.dart
import 'package:flutter/material.dart';

// Cosmic Codebreaker - Difficulty Levels
enum CosmicLevel {
  recruit,
  cadet,
  officer,
  commander,
  admiral,
}

extension CosmicLevelExtension on CosmicLevel {
  String get displayName {
    switch (this) {
      case CosmicLevel.recruit:
        return 'Recruit';
      case CosmicLevel.cadet:
        return 'Cadet';
      case CosmicLevel.officer:
        return 'Officer';
      case CosmicLevel.commander:
        return 'Commander';
      case CosmicLevel.admiral:
        return 'Admiral';
    }
  }

  int get encoded {
    switch (this) {
      case CosmicLevel.recruit:
        return 0;
      case CosmicLevel.cadet:
        return 1;
      case CosmicLevel.officer:
        return 2;
      case CosmicLevel.commander:
        return 3;
      case CosmicLevel.admiral:
        return 4;
    }
  }

  Color get color {
    switch (this) {
      case CosmicLevel.recruit:
        return Color(0xFF4CAF50); // Green
      case CosmicLevel.cadet:
        return Color(0xFF2196F3); // Blue
      case CosmicLevel.officer:
        return Color(0xFFFF9800); // Orange
      case CosmicLevel.commander:
        return Color(0xFFF44336); // Red
      case CosmicLevel.admiral:
        return Color(0xFF9C27B0); // Purple
    }
  }

  IconData get icon {
    switch (this) {
      case CosmicLevel.recruit:
        return Icons.rocket_launch;
      case CosmicLevel.cadet:
        return Icons.rocket;
      case CosmicLevel.officer:
        return Icons.satellite_alt;
      case CosmicLevel.commander:
        return Icons.military_tech; // Changed from astronaut
      case CosmicLevel.admiral:
        return Icons.stars;
    }
  }

  String get imagePath {
    switch (this) {
      case CosmicLevel.recruit:
        return 'assets/images/recruit.png';
      case CosmicLevel.cadet:
        return 'assets/images/cadet.png';
      case CosmicLevel.officer:
        return 'assets/images/officer.png';
      case CosmicLevel.commander:
        return 'assets/images/commander.png';
      case CosmicLevel.admiral:
        return 'assets/images/admiral.png';
    }
  }

  int get baseScore {
    switch (this) {
      case CosmicLevel.recruit:
        return 100;
      case CosmicLevel.cadet:
        return 250;
      case CosmicLevel.officer:
        return 500;
      case CosmicLevel.commander:
        return 1000;
      case CosmicLevel.admiral:
        return 2000;
    }
  }

  int get sequenceLength {
    switch (this) {
      case CosmicLevel.recruit:
        return 3;
      case CosmicLevel.cadet:
        return 4;
      case CosmicLevel.officer:
        return 5;
      case CosmicLevel.commander:
        return 6;
      case CosmicLevel.admiral:
        return 7;
    }
  }

  int get timeLimit {
    switch (this) {
      case CosmicLevel.recruit:
        return 60;
      case CosmicLevel.cadet:
        return 50;
      case CosmicLevel.officer:
        return 40;
      case CosmicLevel.commander:
        return 30;
      case CosmicLevel.admiral:
        return 20;
    }
  }

  double get speedMultiplier {
    switch (this) {
      case CosmicLevel.recruit:
        return 1.0;
      case CosmicLevel.cadet:
        return 1.3;
      case CosmicLevel.officer:
        return 1.6;
      case CosmicLevel.commander:
        return 2.0;
      case CosmicLevel.admiral:
        return 2.5;
    }
  }
}

// Cosmic Symbols
enum CosmicSymbol {
  star('⭐', 'Star', Color(0xFFFFD700)),
  planet('🪐', 'Planet', Color(0xFFFFA500)),
  comet('☄️', 'Comet', Color(0xFF00FFFF)),
  galaxy('🌌', 'Galaxy', Color(0xFF800080)),
  astronaut('👨‍🚀', 'Astronaut', Color(0xFF4169E1)),
  ufo('🛸', 'UFO', Color(0xFF32CD32)),
  moon('🌙', 'Moon', Color(0xFF808080)),
  sun('☀️', 'Sun', Color(0xFFFF4500));

  final String emoji;
  final String name;
  final Color color;

  const CosmicSymbol(this.emoji, this.name, this.color);
}

// Session Data for ML Prediction
class GameSessionData {
  final int timeSec;
  final int numberOfTimesPlayed;
  final int score;
  final int difficultyLevelEncoded;
  final DateTime timestamp;
  final int correctSequences;
  final int totalSequences;
  final double accuracy;

  GameSessionData({
    required this.timeSec,
    required this.numberOfTimesPlayed,
    required this.score,
    required this.difficultyLevelEncoded,
    required this.timestamp,
    required this.correctSequences,
    required this.totalSequences,
    required this.accuracy,
  });

  Map<String, dynamic> toJson() {
    return {
      'time_sec': timeSec,
      'number_of_times_played': numberOfTimesPlayed,
      'score': score,
      'difficulty_level_encoded': difficultyLevelEncoded,
      'correct_sequences': correctSequences,
      'total_sequences': totalSequences,
      'accuracy': accuracy,
    };
  }
}

// ML Prediction Result
class MLPredictionResult {
  final String recommendation;
  final double probability;
  final bool needsIntervention;
  final Map<String, dynamic> similarPattern;
  final String interventionType;

  MLPredictionResult({
    required this.recommendation,
    required this.probability,
    required this.needsIntervention,
    required this.similarPattern,
    required this.interventionType,
  });

  factory MLPredictionResult.fromJson(Map<String, dynamic> json) {
    return MLPredictionResult(
      recommendation: json['recommendation'] ?? 'Keep up the great work, space cadet!',
      probability: (json['probability'] ?? 0.0).toDouble(),
      needsIntervention: json['needs_intervention'] ?? false,
      similarPattern: json['similar_pattern'] ?? {},
      interventionType: json['intervention_type'] ?? 'none',
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
  int correctSequences;
  int totalSequences;
  Map<CosmicLevel, int> levelAttempts;
  List<GameSessionData> sessionHistory;
  DateTime firstPlayed;
  DateTime lastPlayed;

  GameStatistics({
    this.totalSessions = 0,
    this.totalScore = 0,
    this.totalTimeSpent = 0,
    this.correctSequences = 0,
    this.totalSequences = 0,
    Map<CosmicLevel, int>? levelAttempts,
    List<GameSessionData>? sessionHistory,
    required this.firstPlayed,
    required this.lastPlayed,
  })  : levelAttempts = levelAttempts ?? {},
        sessionHistory = sessionHistory ?? [];

  double get accuracy {
    if (totalSequences == 0) return 0;
    return (correctSequences / totalSequences) * 100;
  }

  double get averageScore {
    if (totalSessions == 0) return 0;
    return totalScore / totalSessions;
  }

  CosmicLevel? get favoriteLevel {
    if (levelAttempts.isEmpty) return null;
    return levelAttempts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  GameSessionData getCurrentSessionData(
      int timeSec,
      int score,
      CosmicLevel level,
      int correct,
      int total,
      ) {
    return GameSessionData(
      timeSec: timeSec,
      numberOfTimesPlayed: totalSessions + 1,
      score: score,
      difficultyLevelEncoded: level.encoded,
      timestamp: DateTime.now(),
      correctSequences: correct,
      totalSequences: total,
      accuracy: total > 0 ? (correct / total) * 100 : 0,
    );
  }
}