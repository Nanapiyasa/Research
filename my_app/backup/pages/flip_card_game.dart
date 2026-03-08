import 'dart:async';
import 'package:flutter/material.dart';

// Game difficulty levels
enum GameLevel {
  easy,
  medium,
  hard,
  expert,
}

extension GameLevelExtension on GameLevel {
  String get displayName {
    switch (this) {
      case GameLevel.easy:
        return 'Easy';
      case GameLevel.medium:
        return 'Medium';
      case GameLevel.hard:
        return 'Hard';
      case GameLevel.expert:
        return 'Expert';
    }
  }

  Color get color {
    switch (this) {
      case GameLevel.easy:
        return Colors.green;
      case GameLevel.medium:
        return Colors.orange;
      case GameLevel.hard:
        return Colors.red;
      case GameLevel.expert:
        return Colors.purple;
    }
  }

  int get cardCount {
    switch (this) {
      case GameLevel.easy:
        return 8; // 4 pairs
      case GameLevel.medium:
        return 12; // 6 pairs
      case GameLevel.hard:
        return 16; // 8 pairs
      case GameLevel.expert:
        return 20; // 10 pairs
    }
  }

  int get timeBonus {
    switch (this) {
      case GameLevel.easy:
        return 10;
      case GameLevel.medium:
        return 20;
      case GameLevel.hard:
        return 30;
      case GameLevel.expert:
        return 50;
    }
  }
}

class CardItem {
  final int id;
  final String emoji;
  bool isFlipped;
  bool isMatched;
  int pairId;

  CardItem({
    required this.id,
    required this.emoji,
    required this.pairId,
    this.isFlipped = false,
    this.isMatched = false,
  });
}

class GameStats {
  int memoryScore;
  int reactionTimeMs;
  int moves;
  int matches;
  Duration totalTime;
  DateTime startTime;
  List<Duration> reactionTimes;
  GameLevel level;
  int levelBonus;

  GameStats({
    this.memoryScore = 0,
    this.reactionTimeMs = 0,
    this.moves = 0,
    this.matches = 0,
    this.totalTime = Duration.zero,
    required this.startTime,
    List<Duration>? reactionTimes,
    this.level = GameLevel.easy,
    this.levelBonus = 0,
  }) : reactionTimes = reactionTimes ?? [];

  // Calculate average reaction time
  int get averageReactionTime {
    if (reactionTimes.isEmpty) return 0;
    final total = reactionTimes.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds);
    return total ~/ reactionTimes.length;
  }

  // Memory score based on matches, moves efficiency, and level
  int calculateMemoryScore() {
    if (matches == 0) return 0;

    // Base score from matches
    double baseScore = matches * 10;

    // Efficiency bonus/penalty
    int expectedMoves = matches * 2; // Minimum moves needed
    int extraMoves = (moves - expectedMoves).clamp(0, 100);
    double efficiencyPenalty = extraMoves * 1.5;

    // Time bonus/penalty (faster completion = higher score)
    int timeSeconds = totalTime.inSeconds;
    double timeFactor = 1.0;
    if (timeSeconds < 30) {
      timeFactor = 1.5; // Bonus for fast completion
    } else if (timeSeconds > 60) {
      timeFactor = 0.8; // Penalty for slow completion
    }

    // Level bonus
    double levelMultiplier = 1.0 + (level.index * 0.2); // 1.0, 1.2, 1.4, 1.6

    // Calculate final score
    double finalScore = (baseScore - efficiencyPenalty) * timeFactor * levelMultiplier;

    return finalScore.round().clamp(0, 200);
  }

  Map<String, dynamic> toJson() {
    return {
      'memory_score': calculateMemoryScore(),
      'reaction_time': averageReactionTime,
      'moves': moves,
      'matches': matches,
      'total_time_seconds': totalTime.inSeconds,
      'level': level.index,
      'level_name': level.displayName,
      'level_bonus': levelBonus,
    };
  }
}