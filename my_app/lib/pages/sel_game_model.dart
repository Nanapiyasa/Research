// lib/pages/sel_game_model.dart
import 'package:flutter/material.dart';

// Game Levels
enum SELGameLevel {
  beginner,
  intermediate,
  advanced,
  expert,
}

extension SELGameLevelExtension on SELGameLevel {
  String get displayName {
    switch (this) {
      case SELGameLevel.beginner:
        return 'Beginner';
      case SELGameLevel.intermediate:
        return 'Intermediate';
      case SELGameLevel.advanced:
        return 'Advanced';
      case SELGameLevel.expert:
        return 'Expert';
    }
  }

  Color get color {
    switch (this) {
      case SELGameLevel.beginner:
        return Colors.green;
      case SELGameLevel.intermediate:
        return Colors.blue;
      case SELGameLevel.advanced:
        return Colors.orange;
      case SELGameLevel.expert:
        return Colors.purple;
    }
  }

  IconData get icon {
    switch (this) {
      case SELGameLevel.beginner:
        return Icons.egg;
      case SELGameLevel.intermediate:
        return Icons.forest;
      case SELGameLevel.advanced:
        return Icons.whatshot;
      case SELGameLevel.expert:
        return Icons.emoji_events;
    }
  }

  int get scenariosCount {
    switch (this) {
      case SELGameLevel.beginner:
        return 5;
      case SELGameLevel.intermediate:
        return 8;
      case SELGameLevel.advanced:
        return 12;
      case SELGameLevel.expert:
        return 15;
    }
  }

  int get timeBonus {
    switch (this) {
      case SELGameLevel.beginner:
        return 10;
      case SELGameLevel.intermediate:
        return 20;
      case SELGameLevel.advanced:
        return 30;
      case SELGameLevel.expert:
        return 50;
    }
  }
}

// SEL Skills
enum SELSkill {
  empathy,
  selfAwareness,
  emotionalRegulation,
  socialSkills,
  problemSolving,
}

extension SELSkillExtension on SELSkill {
  String get displayName {
    switch (this) {
      case SELSkill.empathy:
        return 'Empathy';
      case SELSkill.selfAwareness:
        return 'Self-Awareness';
      case SELSkill.emotionalRegulation:
        return 'Emotional Control';
      case SELSkill.socialSkills:
        return 'Social Skills';
      case SELSkill.problemSolving:
        return 'Problem Solving';
    }
  }

  String get description {
    switch (this) {
      case SELSkill.empathy:
        return 'Understanding feelings of others';
      case SELSkill.selfAwareness:
        return 'Knowing your own emotions';
      case SELSkill.emotionalRegulation:
        return 'Managing feelings wisely';
      case SELSkill.socialSkills:
        return 'Building friendships';
      case SELSkill.problemSolving:
        return 'Finding smart solutions';
    }
  }

  Color get color {
    switch (this) {
      case SELSkill.empathy:
        return Color(0xFFFF6B6B); // Coral
      case SELSkill.selfAwareness:
        return Color(0xFF4ECDC4); // Turquoise
      case SELSkill.emotionalRegulation:
        return Color(0xFFFFB347); // Orange
      case SELSkill.socialSkills:
        return Color(0xFFA06CD5); // Purple
      case SELSkill.problemSolving:
        return Color(0xFF6C8EB2); // Blue
    }
  }

  IconData get icon {
    switch (this) {
      case SELSkill.empathy:
        return Icons.favorite;
      case SELSkill.selfAwareness:
        return Icons.self_improvement;
      case SELSkill.emotionalRegulation:
        return Icons.psychology;
      case SELSkill.socialSkills:
        return Icons.groups;
      case SELSkill.problemSolving:
        return Icons.lightbulb;
    }
  }

  String get emoji {
    switch (this) {
      case SELSkill.empathy:
        return '💝';
      case SELSkill.selfAwareness:
        return '🧘';
      case SELSkill.emotionalRegulation:
        return '🧠';
      case SELSkill.socialSkills:
        return '🤝';
      case SELSkill.problemSolving:
        return '💡';
    }
  }
}

class SELScenario {
  final String id;
  final SELSkill skill;
  final SELGameLevel level;
  final String title;
  final String description;
  final String imageAsset;
  final List<SELOption> options;
  final String feedback;
  final int xpReward;

  SELScenario({
    required this.id,
    required this.skill,
    required this.level,
    required this.title,
    required this.description,
    required this.imageAsset,
    required this.options,
    required this.feedback,
    this.xpReward = 10,
  });
}

class SELOption {
  final String text;
  final bool isCorrect;
  final String explanation;
  final IconData? icon;

  SELOption({
    required this.text,
    required this.isCorrect,
    required this.explanation,
    this.icon,
  });
}

class SELGameStats {
  int score;
  int totalXP;
  int currentLevel;
  int scenariosCompleted;
  int correctAnswers;
  int totalScenarios;
  Map<SELSkill, int> skillScores;
  Map<SELSkill, int> skillAttempts;
  List<Duration> responseTimes;
  DateTime startTime;
  DateTime? endTime;
  SELGameLevel gameLevel;

  SELGameStats({
    this.score = 0,
    this.totalXP = 0,
    this.currentLevel = 1,
    this.scenariosCompleted = 0,
    this.correctAnswers = 0,
    this.totalScenarios = 0,
    Map<SELSkill, int>? skillScores,
    Map<SELSkill, int>? skillAttempts,
    List<Duration>? responseTimes,
    required this.startTime,
    this.endTime,
    required this.gameLevel,
  })  : skillScores = skillScores ?? {},
        skillAttempts = skillAttempts ?? {},
        responseTimes = responseTimes ?? [];

  // Calculate average response time
  double get averageResponseTime {
    if (responseTimes.isEmpty) return 0;
    final total = responseTimes.fold<double>(
        0, (sum, d) => sum + d.inMilliseconds);
    return (total / responseTimes.length) / 1000;
  }

  // Calculate completion percentage
  double get completionPercentage {
    if (totalScenarios == 0) return 0;
    return (scenariosCompleted / totalScenarios) * 100;
  }

  // Calculate accuracy
  double get accuracy {
    if (scenariosCompleted == 0) return 0;
    return (correctAnswers / scenariosCompleted) * 100;
  }

  // Get skill mastery
  double getSkillMastery(SELSkill skill) {
    int attempts = skillAttempts[skill] ?? 0;
    int correct = skillScores[skill] ?? 0;
    if (attempts == 0) return 0;
    return (correct / attempts) * 100;
  }

  // Prepare data for API
  Map<String, dynamic> toPredictionData() {
    return {
      '_score': totalXP,
      'timePerScenario': averageResponseTime,
      'attemptsPerScenario': scenariosCompleted > 0
          ? (skillAttempts.values.fold(0, (a, b) => a + b) / scenariosCompleted)
          : 1.0,
      'correctAnswers': correctAnswers,
      'completionStatus': completionPercentage,
      'gameLevel': gameLevel.index,
    };
  }

  // Get level up requirements
  int get xpForNextLevel {
    return currentLevel * 100;
  }

  int get xpProgress {
    return totalXP % 100;
  }
}