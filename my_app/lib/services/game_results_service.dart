import 'package:flutter/material.dart';
import 'firebase_service.dart';
import '../models/student_model.dart';
import 'timer_service.dart';

class GameResultsService {
  static final GameResultsService _instance = GameResultsService._internal();
  factory GameResultsService() => _instance;
  GameResultsService._internal();

  // Save game result with timer data
  Future<void> saveGameResult({
    required String studentId,
    required String gameType,
    required int score,
    required int maxScore,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Get current timer data
      TimerService timerService = TimerService();
      int timeSpent = timerService.elapsedSeconds;
      
      // Create game result
      GameResult gameResult = GameResult(
        gameType: gameType,
        score: score,
        timeSpent: timeSpent,
        timestamp: DateTime.now(),
        additionalData: {
          'maxScore': maxScore,
          'percentage': (score / maxScore * 100).round(),
          ...?additionalData,
        },
      );

      // Save to Firebase
      await FirebaseService().addGameResult(studentId, gameResult);
      
      // Update job recommendation based on performance
      await _updateJobRecommendation(studentId, gameType, score, maxScore);
      
      print('Game result saved: $gameType - Score: $score/$maxScore, Time: ${timeSpent}s');
    } catch (e) {
      print('Error saving game result: $e');
      rethrow;
    }
  }

  // Update job recommendation based on game performance
  Future<void> _updateJobRecommendation(String studentId, String gameType, int score, int maxScore) async {
    try {
      // Get student's current data
      Student? student = await FirebaseService().getStudent(studentId);
      if (student == null) return;

      // Calculate performance percentage
      double percentage = score / maxScore;
      
      // Job role recommendations based on game performance
      Map<String, List<String>> jobRecommendations = {
        'chef': ['Chef', 'Cook', 'Kitchen Assistant', 'Food Service Worker'],
        'retail': ['Sales Associate', 'Cashier', 'Customer Service Representative', 'Retail Manager'],
        'cleaning': ['Housekeeping', 'Janitor', 'Cleaning Technician', 'Facility Maintenance'],
        'fruit_matching': ['Food Processor', 'Quality Control', 'Agricultural Worker', 'Food Inspector'],
        'life_skills': ['Personal Care Assistant', 'Community Worker', 'Social Services Assistant'],
        'job_simulation': ['General Worker', 'Multi-role Employee', 'Warehouse Worker'],
      };

      // Get current game results
      Map<String, dynamic> gameResults = student.gameResults;
      Map<String, double> averageScores = {};

      // Calculate average scores
      student.gameResults.forEach((gameType, results) {
        if (results is List) {
          int totalScore = 0;
          int count = 0;
          for (var result in results) {
            if (result is Map && result['score'] != null) {
              totalScore += (result['score'] as num).toInt();
              count++;
            }
          }
          if (count > 0) {
            averageScores[gameType] = totalScore / count;
          }
        }
      });

      // Update average scores with current game
      if (averageScores.containsKey(gameType)) {
        double currentAvg = averageScores[gameType]!;
        int count = gameResults[gameType].length;
        averageScores[gameType] = (currentAvg * (count - 1) + percentage) / count;
      } else {
        averageScores[gameType] = percentage;
      }

      // Determine best performing area
      String bestGameType = '';
      double bestScore = 0.0;
      
      averageScores.forEach((game, score) {
        if (score > bestScore) {
          bestScore = score;
          bestGameType = game;
        }
      });

      // Get recommended job based on best performance
      String? recommendedJob = student.recommendedJobRole;
      if (bestScore > 0.7 && jobRecommendations.containsKey(bestGameType)) {
        List<String> jobs = jobRecommendations[bestGameType]!;
        // Select job based on score level
        if (bestScore > 0.9) {
          recommendedJob = jobs[0]; // Best job
        } else if (bestScore > 0.8) {
          recommendedJob = jobs[1]; // Good job
        } else {
          recommendedJob = jobs[2]; // Entry level job
        }
      }

      // Update recommendation if changed
      if (recommendedJob != null && recommendedJob != student.recommendedJobRole) {
        await FirebaseService().updateJobRecommendation(studentId, recommendedJob);
      }
    } catch (e) {
      print('Error updating job recommendation: $e');
    }
  }

  // Get student's game statistics
  Future<Map<String, dynamic>> getGameStatistics(String studentId) async {
    try {
      Student? student = await FirebaseService().getStudent(studentId);
      if (student == null) return {};

      Map<String, dynamic> gameResults = student.gameResults;
      Map<String, dynamic> statistics = {};

      gameResults.forEach((gameType, results) {
        if (results is List) {
          List<int> scores = [];
          List<int> times = [];
          int totalScore = 0;
          int totalTime = 0;
          int maxScore = 0;

          for (var result in results) {
            if (result is Map) {
              int score = result['score'] ?? 0;
              int time = result['timeSpent'] ?? 0;
              int max = result['additionalData']['maxScore'] ?? 0;
              
              scores.add(score);
              times.add(time);
              totalScore += score;
              totalTime += time;
              maxScore = max;
            }
          }

          if (scores.isNotEmpty) {
            statistics[gameType] = {
              'totalGames': scores.length,
              'averageScore': totalScore / scores.length,
              'bestScore': scores.reduce((a, b) => a > b ? a : b),
              'worstScore': scores.reduce((a, b) => a < b ? a : b),
              'averageTime': totalTime / times.length,
              'bestTime': times.reduce((a, b) => a < b ? a : b),
              'totalTime': totalTime,
              'maxScore': maxScore,
              'averagePercentage': (totalScore / (maxScore * scores.length)) * 100,
            };
          }
        }
      });

      return statistics;
    } catch (e) {
      print('Error getting game statistics: $e');
      return {};
    }
  }

  // Get leaderboard for a specific game
  Future<List<Map<String, dynamic>>> getLeaderboard(String gameType, {int limit = 10}) async {
    try {
      List<Student> allStudents = await FirebaseService().getAllStudents();
      List<Map<String, dynamic>> leaderboard = [];

      for (Student student in allStudents) {
        Map<String, dynamic> gameResults = student.gameResults;
        if (gameResults.containsKey(gameType) && gameResults[gameType] is List) {
          List results = gameResults[gameType];
          if (results.isNotEmpty) {
            // Get best score for this student in this game
            int bestScore = 0;
            int bestTime = 0;
            int maxScore = 0;

            for (var result in results) {
              if (result is Map) {
                int score = result['score'] ?? 0;
                int time = result['timeSpent'] ?? 0;
                int max = result['additionalData']['maxScore'] ?? 0;
                
                if (score > bestScore || (score == bestScore && time < bestTime)) {
                  bestScore = score;
                  bestTime = time;
                  maxScore = max;
                }
              }
            }

            leaderboard.add({
              'studentId': student.id,
              'username': student.username,
              'firstName': student.firstName,
              'lastName': student.lastName,
              'bestScore': bestScore,
              'bestTime': bestTime,
              'maxScore': maxScore,
              'percentage': (bestScore / maxScore) * 100,
            });
          }
        }
      }

      // Sort by percentage (descending), then by time (ascending)
      leaderboard.sort((a, b) {
        int percentageCompare = (b['percentage'] as double).compareTo(a['percentage'] as double);
        if (percentageCompare != 0) return percentageCompare;
        return (a['bestTime'] as int).compareTo(b['bestTime'] as int);
      });

      return leaderboard.take(limit).toList();
    } catch (e) {
      print('Error getting leaderboard: $e');
      return [];
    }
  }
}
