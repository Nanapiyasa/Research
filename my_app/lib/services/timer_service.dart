import 'dart:async';
import 'package:flutter/material.dart';
import 'firebase_service.dart';
import '../models/student_model.dart';

class TimerService {
  static final TimerService _instance = TimerService._internal();
  factory TimerService() => _instance;
  TimerService._internal();

  String? _currentStudentId;
  String? _currentActivity;
  DateTime? _startTime;
  Timer? _timer;
  int _elapsedSeconds = 0;

  // Start tracking an activity for a student
  void startActivityTracking(String studentId, String activityName) {
    _currentStudentId = studentId;
    _currentActivity = activityName;
    _startTime = DateTime.now();
    _elapsedSeconds = 0;

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
    });

    print('Started tracking activity: $activityName for student: $studentId');
  }

  // Stop tracking current activity and save to Firebase
  Future<void> stopActivityTracking() async {
    if (_currentStudentId == null || _currentActivity == null || _startTime == null) {
      print('No active activity to stop');
      return;
    }

    _timer?.cancel();
    DateTime endTime = DateTime.now();

    ActivityTime activityTime = ActivityTime(
      activityName: _currentActivity!,
      duration: _elapsedSeconds,
      startTime: _startTime!,
      endTime: endTime,
    );

    try {
      await FirebaseService().addActivityTime(_currentStudentId!, activityTime);
      print('Activity time saved: ${activityTime.activityName} - ${activityTime.duration} seconds');
    } catch (e) {
      print('Error saving activity time: $e');
    }

    // Reset tracking
    _currentStudentId = null;
    _currentActivity = null;
    _startTime = null;
    _elapsedSeconds = 0;
  }

  // Get current tracking info
  Map<String, dynamic>? getCurrentTrackingInfo() {
    if (_currentStudentId == null || _currentActivity == null) {
      return null;
    }

    return {
      'studentId': _currentStudentId,
      'activityName': _currentActivity,
      'startTime': _startTime,
      'elapsedSeconds': _elapsedSeconds,
    };
  }

  // Get formatted elapsed time
  String getFormattedElapsedTime() {
    int hours = _elapsedSeconds ~/ 3600;
    int minutes = (_elapsedSeconds % 3600) ~/ 60;
    int seconds = _elapsedSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  // Check if currently tracking
  bool get isTracking => _currentStudentId != null && _currentActivity != null;

  // Get current activity name
  String? get currentActivity => _currentActivity;

  // Get elapsed seconds
  int get elapsedSeconds => _elapsedSeconds;
}

// Widget to display timer during activities
class ActivityTimerWidget extends StatefulWidget {
  final String studentId;
  final String activityName;

  const ActivityTimerWidget({
    Key? key,
    required this.studentId,
    required this.activityName,
  }) : super(key: key);

  @override
  State<ActivityTimerWidget> createState() => _ActivityTimerWidgetState();
}

class _ActivityTimerWidgetState extends State<ActivityTimerWidget> {
  final TimerService _timerService = TimerService();
  Timer? _updateTimer;
  String _elapsedTime = '0s';

  @override
  void initState() {
    super.initState();
    _startActivityTracking();
    _startTimerUpdate();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _timerService.stopActivityTracking();
    super.dispose();
  }

  void _startActivityTracking() {
    _timerService.startActivityTracking(widget.studentId, widget.activityName);
  }

  void _startTimerUpdate() {
    _updateTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime = _timerService.getFormattedElapsedTime();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, color: Colors.white, size: 16),
          SizedBox(width: 4),
          Text(
            'Time: $_elapsedTime',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Mixin for activities that need timer tracking
mixin ActivityTimerMixin<T extends StatefulWidget> on State<T> {
  final TimerService _timerService = TimerService();
  String? _currentStudentId;
  String? _currentActivityName;

  // Initialize timer tracking for an activity
  void initializeActivityTimer(String studentId, String activityName) {
    _currentStudentId = studentId;
    _currentActivityName = activityName;
    _timerService.startActivityTracking(studentId, activityName);
  }

  // Stop timer tracking when activity ends
  Future<void> finalizeActivityTimer() async {
    await _timerService.stopActivityTracking();
  }

  // Get current elapsed time
  String getCurrentElapsedTime() {
    return _timerService.getFormattedElapsedTime();
  }

  // Get elapsed seconds
  int getElapsedSeconds() {
    return _timerService.elapsedSeconds;
  }

  @override
  void dispose() {
    _timerService.stopActivityTracking();
    super.dispose();
  }
}
