import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart' if (dart.library.html) 'model_service_web.dart';

class VocationalModelService {
  static VocationalModelService? _instance;
  static VocationalModelService get instance => _instance ??= VocationalModelService._();
  
  VocationalModelService._();
  
  Interpreter? _interpreter;
  bool _isModelLoaded = false;
  
  // Module labels - adjust based on your model's output classes
  static const List<String> _modules = ['chef', 'retail', 'cleaning'];
  
  Future<void> loadModel() async {
    if (_isModelLoaded) return;
    
    try {
      if (kIsWeb) {
        // Web platform - use mock
        final mockBytes = Uint8List(0); // Empty bytes for mock
        _interpreter = Interpreter.fromBuffer(mockBytes);
        print('Vocational model (mock) loaded successfully for web');
      } else {
        // Desktop/mobile platform - load real model
        final modelData = await rootBundle.load('assets/models/vocational_model.tflite');
        final modelBytes = modelData.buffer.asUint8List();
        _interpreter = Interpreter.fromBuffer(modelBytes);
        print('Vocational model loaded successfully from file');
      }
      _isModelLoaded = true;
    } catch (e) {
      print('Error loading model: $e');
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> predictModuleWithScores(List<int> questionnaireScores) async {
    if (!_isModelLoaded) {
      await loadModel();
    }
    
    if (_interpreter == null) {
      throw Exception('Model not loaded');
    }
    
    try {
      // Prepare input - convert to double list
      var input = questionnaireScores.map((score) => score.toDouble()).toList();
      
      // Create input tensor - reshape to [1, input.length]
      var inputTensor = [input];
      
      // Create output tensor - assuming 3 output classes
      var outputTensor = List.filled(3, 0.0);
      var output = [outputTensor];
      
      // Run inference
      _interpreter!.run(inputTensor, output);
      
      // Get prediction and scores
      var predictions = output[0];
      var maxIndex = predictions.indexOf(predictions.reduce((a, b) => a > b ? a : b));
      
      // Create module scores map
      Map<String, double> moduleScores = {};
      for (int i = 0; i < _modules.length; i++) {
        moduleScores[_modules[i]] = predictions[i];
      }
      
      return {
        'predictedModule': _modules[maxIndex],
        'confidence': predictions[maxIndex],
        'allScores': moduleScores,
      };
    } catch (e) {
      print('Error during prediction: $e');
      rethrow;
    }
  }
  
  Future<String> predictModule(List<int> questionnaireScores) async {
    var result = await predictModuleWithScores(questionnaireScores);
    return result['predictedModule'] as String;
  }
  
  // Alternative method if your model expects different input format
  Future<String> predictModuleFromTotal(int totalScore) async {
    if (!_isModelLoaded) {
      await loadModel();
    }
    
    if (_interpreter == null) {
      throw Exception('Model not loaded');
    }
    
    try {
      // Prepare input - using total score
      var inputTensor = [[totalScore.toDouble()]];
      
      // Create output tensor - assuming 3 output classes
      var outputTensor = List.filled(3, 0.0);
      var output = [outputTensor];
      
      // Run inference
      _interpreter!.run(inputTensor, output);
      
      // Get prediction
      var predictions = output[0];
      var maxIndex = predictions.indexOf(predictions.reduce((a, b) => a > b ? a : b));
      
      return _modules[maxIndex];
    } catch (e) {
      print('Error during prediction: $e');
      rethrow;
    }
  }
  
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isModelLoaded = false;
  }
}
