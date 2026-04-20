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
        
        // Print model information for debugging
        print('Model input tensors: ${_interpreter!.getInputTensors()}');
        print('Model output tensors: ${_interpreter!.getOutputTensors()}');
        
        // Get input and output shapes
        var inputTensors = _interpreter!.getInputTensors();
        var outputTensors = _interpreter!.getOutputTensors();
        
        if (inputTensors.isNotEmpty) {
          print('Input shape: ${inputTensors[0].shape}');
          print('Input type: ${inputTensors[0].type}');
        }
        
        if (outputTensors.isNotEmpty) {
          print('Output shape: ${outputTensors[0].shape}');
          print('Output type: ${outputTensors[0].type}');
        }
        
        print('Vocational model loaded successfully from file');
      }
      _isModelLoaded = true;
    } catch (e) {
      print('Error loading model: $e');
      _isModelLoaded = false;
      // Don't rethrow, allow fallback to handle it
    }
  }
  
  Future<Map<String, dynamic>> predictModuleWithScores(List<int> questionnaireScores) async {
    print('=== PREDICTION START ===');
    print('Input scores: $questionnaireScores');
    
    try {
      if (!_isModelLoaded) {
        print('Model not loaded, attempting to load...');
        await loadModel();
      }
      
      if (_interpreter == null) {
        print('ERROR: Interpreter is null after loading');
        throw Exception('Model not loaded');
      }
      
      print('Model loaded successfully, proceeding with prediction...');
      
      // Get input and output shapes from the model
      var inputTensors = _interpreter!.getInputTensors();
      var outputTensors = _interpreter!.getOutputTensors();
      
      if (inputTensors.isEmpty || outputTensors.isEmpty) {
        print('ERROR: Model has no input or output tensors');
        throw Exception('Model has no input or output tensors');
      }
      
      var inputShape = inputTensors[0].shape;
      var outputShape = outputTensors[0].shape;
      
      print('Model input shape: $inputShape');
      print('Model output shape: $outputShape');
      print('Input tensor type: ${inputTensors[0].type}');
      print('Output tensor type: ${outputTensors[0].type}');
      
      // Prepare input based on model's expected input shape
      var input = questionnaireScores.map((score) => score.toDouble()).toList();
      print('Converted input: $input');
      
      // Reshape input according to model requirements
      var inputTensor;
      if (inputShape.length == 2) {
        // Model expects [batch_size, features]
        inputTensor = [input];
        print('Using 2D input shape: [batch_size, features]');
      } else if (inputShape.length == 1) {
        // Model expects [features] only
        inputTensor = input;
        print('Using 1D input shape: [features]');
      } else {
        // Handle other shapes
        inputTensor = [input];
        print('Using default 2D input shape');
      }
      
      // Prepare output based on model's expected output shape
      var output;
      if (outputShape.length == 2) {
        // Model expects [batch_size, num_classes]
        var numClasses = outputShape[1];
        var outputTensor = List.filled(numClasses, 0.0);
        output = [outputTensor];
        print('Using 2D output shape with $numClasses classes');
      } else if (outputShape.length == 1) {
        // Model expects [num_classes] only
        var numClasses = outputShape[0];
        var outputTensor = List.filled(numClasses, 0.0);
        output = outputTensor;
        print('Using 1D output shape with $numClasses classes');
      } else {
        // Default to 3 classes
        var outputTensor = List.filled(3, 0.0);
        output = [outputTensor];
        print('Using default 3 classes output');
      }
      
      print('Running inference...');
      // Run inference
      _interpreter!.run(inputTensor, output);
      
      // Extract predictions based on output format
      List<double> predictions;
      if (output is List && output.isNotEmpty && output[0] is List) {
        predictions = List<double>.from(output[0]);
        print('Extracted predictions from 2D output: $predictions');
      } else {
        predictions = List<double>.from(output);
        print('Extracted predictions from 1D output: $predictions');
      }
      
      // Get prediction and scores
      var maxIndex = predictions.indexOf(predictions.reduce((a, b) => a > b ? a : b));
      print('Max prediction index: $maxIndex, value: ${predictions[maxIndex]}');
      
      // Create module scores map
      Map<String, double> moduleScores = {};
      for (int i = 0; i < _modules.length && i < predictions.length; i++) {
        moduleScores[_modules[i]] = predictions[i];
        print('${_modules[i]}: ${(predictions[i] * 100).toStringAsFixed(1)}%');
      }
      
      var result = {
        'predictedModule': _modules[maxIndex],
        'confidence': predictions[maxIndex],
        'allScores': moduleScores,
      };
      
      print('=== TENSORFLOW LITE PREDICTION SUCCESS ===');
      print('Predicted module: ${result['predictedModule']}');
      print('Confidence: ${((result['confidence'] as double) * 100).toStringAsFixed(1)}%');
      print('All scores: ${result['allScores']}');
      print('=== PREDICTION END ===');
      
      return result;
    } catch (e) {
      print('=== TENSORFLOW LITE FAILED ===');
      print('Error: $e');
      print('Stack trace: ${StackTrace.current}');
      print('Using fallback prediction method...');
      return _fallbackPrediction(questionnaireScores);
    }
  }
  
  // Fallback prediction method based on score ranges
  Map<String, dynamic> _fallbackPrediction(List<int> questionnaireScores) {
    print('=== FALLBACK PREDICTION START ===');
    print('Input scores: $questionnaireScores');
    
    // Calculate total score
    int totalScore = questionnaireScores.reduce((a, b) => a + b);
    print('Total score: $totalScore');
    
    // More sophisticated scoring based on individual answers
    Map<String, double> moduleScores = {
      'chef': 0.0,
      'retail': 0.0,
      'cleaning': 0.0,
    };
    
    // Analyze each question answer
    // Q1: Helping people (helpful for retail, moderate for chef)
    if (questionnaireScores.isNotEmpty) {
      int q1 = questionnaireScores[0];
      moduleScores['retail'] = moduleScores['retail']! + (q1 * 0.15);
      moduleScores['chef'] = moduleScores['chef']! + (q1 * 0.08);
    }
    
    // Q2: Organizing things (helpful for retail, moderate for chef)
    if (questionnaireScores.length > 1) {
      int q2 = questionnaireScores[1];
      moduleScores['retail'] = moduleScores['retail']! + (q2 * 0.12);
      moduleScores['chef'] = moduleScores['chef']! + (q2 * 0.10);
    }
    
    // Q3: Talking to people (very helpful for retail)
    if (questionnaireScores.length > 2) {
      int q3 = questionnaireScores[2];
      moduleScores['retail'] = moduleScores['retail']! + (q3 * 0.18);
    }
    
    // Q4: Making/preparing things (very helpful for chef)
    if (questionnaireScores.length > 3) {
      int q4 = questionnaireScores[3];
      moduleScores['chef'] = moduleScores['chef']! + (q4 * 0.20);
    }
    
    // Q5-9: Yes/Sometimes/Needs help questions (convert to 5-3-1 scale)
    for (int i = 4; i < questionnaireScores.length; i++) {
      int answer = questionnaireScores[i];
      int convertedScore;
      if (answer == 5) convertedScore = 5; // Yes
      else if (answer == 3) convertedScore = 3; // Sometimes
      else if (answer == 1) convertedScore = 1; // Needs help
      else convertedScore = 3; // Default to sometimes
      
      // Different weights for different questions
      double weight = 0.08;
      if (i == 4) weight = 0.10; // Following instructions (chef)
      else if (i == 5) weight = 0.08; // Remember routines (all)
      else if (i == 6) weight = 0.12; // Working with others (retail)
      else if (i == 7) weight = 0.15; // Staying focused (chef)
      else if (i == 8) weight = 0.10; // Working in groups (retail)
      
      moduleScores['chef'] = moduleScores['chef']! + (convertedScore * weight * 0.6);
      moduleScores['retail'] = moduleScores['retail']! + (convertedScore * weight * 0.8);
      moduleScores['cleaning'] = moduleScores['cleaning']! + (convertedScore * weight * 0.4);
    }
    
    // Normalize scores to 0-1 range
    double maxScore = moduleScores.values.reduce((a, b) => a > b ? a : b);
    if (maxScore > 0) {
      moduleScores = moduleScores.map((key, value) => MapEntry(key, value / maxScore));
    }
    
    // Add some base confidence to avoid zero values
    moduleScores = moduleScores.map((key, value) => MapEntry(key, value * 0.7 + 0.1));
    
    // Find the module with highest score
    String predictedModule = moduleScores.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    double confidence = moduleScores[predictedModule]!;
    
    print('Detailed module scores:');
    moduleScores.forEach((module, score) {
      print('  $module: ${(score * 100).toStringAsFixed(1)}%');
    });
    print('Fallback prediction: $predictedModule (confidence: ${(confidence * 100).toStringAsFixed(1)}%)');
    print('=== FALLBACK PREDICTION END ===');
    
    return {
      'predictedModule': predictedModule,
      'confidence': confidence,
      'allScores': moduleScores,
    };
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
