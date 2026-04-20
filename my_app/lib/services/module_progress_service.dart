import 'package:flutter/material.dart';
import 'firebase_service.dart';
import '../models/student_model.dart';

class ModuleProgressService {
  static final ModuleProgressService _instance = ModuleProgressService._internal();
  factory ModuleProgressService() => _instance;
  ModuleProgressService._internal();

  // Update module progress
  Future<void> updateModuleProgress({
    required String studentId,
    required String moduleId,
    required String moduleName,
    required String taskId,
    required int totalTasks,
    bool isCompleted = true,
  }) async {
    try {
      // Get current student data
      Student? student = await FirebaseService().getStudent(studentId);
      if (student == null) return;

      // Get current module progress
      Map<String, dynamic> moduleProgress = student.moduleProgress;
      ModuleProgress? currentProgress;

      if (moduleProgress.containsKey(moduleId)) {
        currentProgress = ModuleProgress.fromMap(moduleProgress[moduleId]);
      } else {
        currentProgress = ModuleProgress(
          moduleId: moduleId,
          moduleName: moduleName,
          completionPercentage: 0.0,
          completedTasks: [],
          lastUpdated: DateTime.now(),
        );
      }

      // Update completed tasks
      List<String> completedTasks = List.from(currentProgress.completedTasks);
      if (isCompleted && !completedTasks.contains(taskId)) {
        completedTasks.add(taskId);
      } else if (!isCompleted && completedTasks.contains(taskId)) {
        completedTasks.remove(taskId);
      }

      // Calculate new completion percentage
      double newPercentage = (completedTasks.length / totalTasks) * 100;

      // Create updated progress
      ModuleProgress updatedProgress = ModuleProgress(
        moduleId: moduleId,
        moduleName: moduleName,
        completionPercentage: newPercentage,
        completedTasks: completedTasks,
        lastUpdated: DateTime.now(),
      );

      // Save to Firebase
      await FirebaseService().updateModuleProgress(studentId, updatedProgress);
      
      print('Module progress updated: $moduleId - ${newPercentage.toStringAsFixed(1)}%');
    } catch (e) {
      print('Error updating module progress: $e');
      rethrow;
    }
  }

  // Get module progress for a student
  Future<ModuleProgress?> getModuleProgress(String studentId, String moduleId) async {
    try {
      Student? student = await FirebaseService().getStudent(studentId);
      if (student == null) return null;

      Map<String, dynamic> moduleProgress = student.moduleProgress;
      if (moduleProgress.containsKey(moduleId)) {
        return ModuleProgress.fromMap(moduleProgress[moduleId]);
      }
      return null;
    } catch (e) {
      print('Error getting module progress: $e');
      return null;
    }
  }

  // Get all module progress for a student
  Future<Map<String, ModuleProgress>> getAllModuleProgress(String studentId) async {
    try {
      Student? student = await FirebaseService().getStudent(studentId);
      if (student == null) return {};

      Map<String, ModuleProgress> allProgress = {};
      Map<String, dynamic> moduleProgress = student.moduleProgress;

      moduleProgress.forEach((moduleId, progressData) {
        allProgress[moduleId] = ModuleProgress.fromMap(progressData);
      });

      return allProgress;
    } catch (e) {
      print('Error getting all module progress: $e');
      return {};
    }
  }

  // Calculate overall completion percentage
  Future<double> getOverallCompletion(String studentId) async {
    try {
      Map<String, ModuleProgress> allProgress = await getAllModuleProgress(studentId);
      
      if (allProgress.isEmpty) return 0.0;

      double totalPercentage = 0.0;
      allProgress.forEach((moduleId, progress) {
        totalPercentage += progress.completionPercentage;
      });

      return totalPercentage / allProgress.length;
    } catch (e) {
      print('Error calculating overall completion: $e');
      return 0.0;
    }
  }

  // Get completed modules count
  Future<int> getCompletedModulesCount(String studentId) async {
    try {
      Map<String, ModuleProgress> allProgress = await getAllModuleProgress(studentId);
      
      int completedCount = 0;
      allProgress.forEach((moduleId, progress) {
        if (progress.completionPercentage >= 100.0) {
          completedCount++;
        }
      });

      return completedCount;
    } catch (e) {
      print('Error getting completed modules count: $e');
      return 0;
    }
  }

  // Get next incomplete task for a module
  Future<String?> getNextIncompleteTask(String studentId, String moduleId, List<String> allTasks) async {
    try {
      ModuleProgress? progress = await getModuleProgress(studentId, moduleId);
      if (progress == null) return allTasks.isNotEmpty ? allTasks.first : null;

      for (String task in allTasks) {
        if (!progress.completedTasks.contains(task)) {
          return task;
        }
      }

      return null; // All tasks completed
    } catch (e) {
      print('Error getting next incomplete task: $e');
      return null;
    }
  }

  // Reset module progress
  Future<void> resetModuleProgress(String studentId, String moduleId) async {
    try {
      ModuleProgress resetProgress = ModuleProgress(
        moduleId: moduleId,
        moduleName: '', // Will be updated separately
        completionPercentage: 0.0,
        completedTasks: [],
        lastUpdated: DateTime.now(),
      );

      await FirebaseService().updateModuleProgress(studentId, resetProgress);
      print('Module progress reset: $moduleId');
    } catch (e) {
      print('Error resetting module progress: $e');
      rethrow;
    }
  }

  // Get progress summary for dashboard
  Future<Map<String, dynamic>> getProgressSummary(String studentId) async {
    try {
      Map<String, ModuleProgress> allProgress = await getAllModuleProgress(studentId);
      
      int totalModules = allProgress.length;
      int completedModules = 0;
      int inProgressModules = 0;
      double overallCompletion = 0.0;

      allProgress.forEach((moduleId, progress) {
        if (progress.completionPercentage >= 100.0) {
          completedModules++;
        } else if (progress.completionPercentage > 0.0) {
          inProgressModules++;
        }
        overallCompletion += progress.completionPercentage;
      });

      if (totalModules > 0) {
        overallCompletion = overallCompletion / totalModules;
      }

      return {
        'totalModules': totalModules,
        'completedModules': completedModules,
        'inProgressModules': inProgressModules,
        'notStartedModules': totalModules - completedModules - inProgressModules,
        'overallCompletion': overallCompletion,
        'completionPercentage': (completedModules / totalModules * 100).clamp(0.0, 100.0),
      };
    } catch (e) {
      print('Error getting progress summary: $e');
      return {
        'totalModules': 0,
        'completedModules': 0,
        'inProgressModules': 0,
        'notStartedModules': 0,
        'overallCompletion': 0.0,
        'completionPercentage': 0.0,
      };
    }
  }
}

// Mixin for activities that need progress tracking
mixin ModuleProgressMixin<T extends StatefulWidget> on State<T> {
  final ModuleProgressService _progressService = ModuleProgressService();
  String? _currentStudentId;
  String? _currentModuleId;
  String? _currentModuleName;
  List<String> _allTasks = [];

  // Initialize progress tracking for a module
  void initializeModuleProgress({
    required String studentId,
    required String moduleId,
    required String moduleName,
    required List<String> allTasks,
  }) {
    _currentStudentId = studentId;
    _currentModuleId = moduleId;
    _currentModuleName = moduleName;
    _allTasks = allTasks;
  }

  // Mark task as completed
  Future<void> completeTask(String taskId, {int totalTasks = 1}) async {
    if (_currentStudentId != null && _currentModuleId != null && _currentModuleName != null) {
      await _progressService.updateModuleProgress(
        studentId: _currentStudentId!,
        moduleId: _currentModuleId!,
        moduleName: _currentModuleName!,
        taskId: taskId,
        totalTasks: totalTasks,
        isCompleted: true,
      );
    }
  }

  // Mark task as incomplete
  Future<void> uncompleteTask(String taskId, {int totalTasks = 1}) async {
    if (_currentStudentId != null && _currentModuleId != null && _currentModuleName != null) {
      await _progressService.updateModuleProgress(
        studentId: _currentStudentId!,
        moduleId: _currentModuleId!,
        moduleName: _currentModuleName!,
        taskId: taskId,
        totalTasks: totalTasks,
        isCompleted: false,
      );
    }
  }

  // Get current module progress
  Future<ModuleProgress?> getCurrentModuleProgress() async {
    if (_currentStudentId != null && _currentModuleId != null) {
      return await _progressService.getModuleProgress(_currentStudentId!, _currentModuleId!);
    }
    return null;
  }

  // Get completion percentage
  Future<double> getCompletionPercentage() async {
    ModuleProgress? progress = await getCurrentModuleProgress();
    return progress?.completionPercentage ?? 0.0;
  }

  // Check if module is completed
  Future<bool> isModuleCompleted() async {
    ModuleProgress? progress = await getCurrentModuleProgress();
    if (progress != null) {
      return progress.completionPercentage >= 100.0;
    }
    return false;
  }

  // Get next incomplete task
  Future<String?> getNextIncompleteTask() async {
    if (_currentStudentId != null && _currentModuleId != null) {
      return await _progressService.getNextIncompleteTask(_currentStudentId!, _currentModuleId!, _allTasks);
    }
    return null;
  }
}
