import 'package:flutter/material.dart';
import '../services/timer_service.dart';
import '../services/game_results_service.dart';
import '../services/module_progress_service.dart';
import '../services/firebase_service.dart';
import '../models/student_model.dart';
import '../../auth_service.dart';

/*
 * EXAMPLE: How to integrate Firebase services into your games
 * 
 * This file shows how to use the timer tracking, game results, and progress
 * tracking services in your game activities.
 */

// Example 1: Chef Game Integration
class ChefGameExample extends StatefulWidget {
  final String studentId;
  
  const ChefGameExample({Key? key, required this.studentId}) : super(key: key);

  @override
  State<ChefGameExample> createState() => _ChefGameExampleState();
}

class _ChefGameExampleState extends State<ChefGameExample> 
    with ActivityTimerMixin, ModuleProgressMixin {
  
  final GameResultsService _gameResultsService = GameResultsService();
  int _score = 0;
  int _maxScore = 100;
  bool _gameCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    // Initialize timer tracking
    initializeActivityTimer(widget.studentId, 'chef_game');
    
    // Initialize module progress tracking
    initializeModuleProgress(
      studentId: widget.studentId,
      moduleId: 'chef_level_01',
      moduleName: 'Chef Level 1',
      allTasks: [
        'task_1_vegetable_cutting',
        'task_2_food_preparation',
        'task_3_cooking',
        'task_4_plating',
        'task_5_cleaning',
      ],
    );
  }

  void _completeTask(String taskId) {
    // Mark task as completed
    completeTask(taskId, totalTasks: 5);
    
    // Update score based on task completion
    setState(() {
      _score += 20;
    });
    
    // Check if game is completed
    if (_score >= _maxScore) {
      _gameCompleted = true;
      _finalizeGame();
    }
  }

  Future<void> _finalizeGame() async {
    // Stop timer tracking
    await finalizeActivityTimer();
    
    // Save game result
    await _gameResultsService.saveGameResult(
      studentId: widget.studentId,
      gameType: 'chef',
      score: _score,
      maxScore: _maxScore,
      additionalData: {
        'level': 1,
        'tasksCompleted': _score ~/ 20,
        'timeBonus': getElapsedSeconds() < 300 ? 10 : 0, // Bonus for fast completion
      },
    );
    
    // Show completion message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Game completed! Score: $_score/$_maxScore, Time: ${getCurrentElapsedTime()}'),
        duration: Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chef Game Example'),
        actions: [
          ActivityTimerWidget(
            studentId: widget.studentId,
            activityName: 'chef_game',
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: _score / _maxScore,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          
          // Game content
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Score: $_score/$_maxScore'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _completeTask('task_1_vegetable_cutting'),
                    child: Text('Complete Vegetable Cutting'),
                  ),
                  ElevatedButton(
                    onPressed: () => _completeTask('task_2_food_preparation'),
                    child: Text('Complete Food Preparation'),
                  ),
                  ElevatedButton(
                    onPressed: () => _completeTask('task_3_cooking'),
                    child: Text('Complete Cooking'),
                  ),
                  ElevatedButton(
                    onPressed: () => _completeTask('task_4_plating'),
                    child: Text('Complete Plating'),
                  ),
                  ElevatedButton(
                    onPressed: () => _completeTask('task_5_cleaning'),
                    child: Text('Complete Cleaning'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Example 2: Retail Game Integration
class RetailGameExample extends StatefulWidget {
  final String studentId;
  
  const RetailGameExample({Key? key, required this.studentId}) : super(key: key);

  @override
  State<RetailGameExample> createState() => _RetailGameExampleState();
}

class _RetailGameExampleState extends State<RetailGameExample> 
    with ActivityTimerMixin, ModuleProgressMixin {
  
  final GameResultsService _gameResultsService = GameResultsService();
  int _score = 0;
  int _maxScore = 50;
  int _customersServed = 0;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    // Initialize timer tracking
    initializeActivityTimer(widget.studentId, 'retail_game');
    
    // Initialize module progress tracking
    initializeModuleProgress(
      studentId: widget.studentId,
      moduleId: 'retail_level_01',
      moduleName: 'Retail Level 1',
      allTasks: [
        'customer_service_1',
        'customer_service_2',
        'customer_service_3',
        'customer_service_4',
        'customer_service_5',
      ],
    );
  }

  void _serveCustomer() {
    setState(() {
      _score += 10;
      _customersServed++;
    });
    
    // Mark customer service task as completed
    completeTask('customer_service_$_customersServed', totalTasks: 5);
    
    if (_customersServed >= 5) {
      _finalizeGame();
    }
  }

  Future<void> _finalizeGame() async {
    await finalizeActivityTimer();
    
    await _gameResultsService.saveGameResult(
      studentId: widget.studentId,
      gameType: 'retail',
      score: _score,
      maxScore: _maxScore,
      additionalData: {
        'customersServed': _customersServed,
        'averageTimePerCustomer': getElapsedSeconds() / _customersServed,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Retail Game Example'),
        actions: [
          ActivityTimerWidget(
            studentId: widget.studentId,
            activityName: 'retail_game',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Customers Served: $_customersServed/5'),
            Text('Score: $_score/$_maxScore'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _serveCustomer,
              child: Text('Serve Customer'),
            ),
          ],
        ),
      ),
    );
  }
}

// Example 3: Student Dashboard with Analytics
class StudentDashboardExample extends StatefulWidget {
  final String studentId;
  
  const StudentDashboardExample({Key? key, required this.studentId}) : super(key: key);

  @override
  State<StudentDashboardExample> createState() => _StudentDashboardExampleState();
}

class _StudentDashboardExampleState extends State<StudentDashboardExample> {
  final FirebaseService _firebaseService = FirebaseService();
  final GameResultsService _gameResultsService = GameResultsService();
  final ModuleProgressService _progressService = ModuleProgressService();
  
  Student? _student;
  Map<String, dynamic>? _analytics;
  Map<String, dynamic>? _gameStatistics;
  Map<String, dynamic>? _progressSummary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      // Load student data
      Student? student = await _firebaseService.getStudent(widget.studentId);
      
      // Load analytics
      Map<String, dynamic> analytics = await _firebaseService.getStudentAnalytics(widget.studentId);
      
      // Load game statistics
      Map<String, dynamic> gameStats = await _gameResultsService.getGameStatistics(widget.studentId);
      
      // Load progress summary
      Map<String, dynamic> progressSummary = await _progressService.getProgressSummary(widget.studentId);
      
      setState(() {
        _student = student;
        _analytics = analytics;
        _gameStatistics = gameStats;
        _progressSummary = progressSummary;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading student data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Student Dashboard')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Info
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Student: ${_student?.firstName ?? ''} ${_student?.lastName ?? ''}'),
                    Text('Username: ${_student?.username ?? ''}'),
                    Text('Age: ${_student?.age ?? ''}'),
                    Text('Recommended Job: ${_student?.recommendedJobRole ?? 'Not determined'}'),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Analytics
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Total Time Spent: ${_formatDuration(_analytics?['totalTimeSpent'] ?? 0)}'),
                    Text('Overall Completion: ${(_analytics?['overallCompletion'] ?? 0.0).toStringAsFixed(1)}%'),
                    Text('Total Modules: ${_analytics?['totalModules'] ?? 0}'),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Game Statistics
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Game Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    if (_gameStatistics != null)
                      ..._gameStatistics!.entries.map((entry) {
                        return Text('${entry.key}: ${_formatGameStats(entry.value)}');
                      }).toList(),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Progress Summary
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Progress Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Total Modules: ${_progressSummary?['totalModules'] ?? 0}'),
                    Text('Completed: ${_progressSummary?['completedModules'] ?? 0}'),
                    Text('In Progress: ${_progressSummary?['inProgressModules'] ?? 0}'),
                    Text('Not Started: ${_progressSummary?['notStartedModules'] ?? 0}'),
                    Text('Overall Completion: ${(_progressSummary?['completionPercentage'] ?? 0.0).toStringAsFixed(1)}%'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  String _formatGameStats(dynamic stats) {
    if (stats is Map) {
      return 'Avg: ${stats['averageScore']?.toStringAsFixed(1) ?? 0} (${stats['averagePercentage']?.toStringAsFixed(1) ?? 0}%)';
    }
    return 'No data';
  }
}

// Example 4: How to get current student ID from AuthService
class AuthServiceIntegration {
  static String? getCurrentStudentId(AuthService authService) {
    // Use the generated Firestore student document ID from AuthService
    return authService.currentStudentId;
  }
  
  static Future<String?> getStudentIdFromUsername(String username) async {
    try {
      Student? student = await FirebaseService().getStudentByUsername(username);
      return student?.id;
    } catch (e) {
      print('Error getting student ID: $e');
      return null;
    }
  }
}
