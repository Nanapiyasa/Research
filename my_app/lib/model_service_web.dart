// Web compatibility stub for tflite_flutter
import 'dart:typed_data';

class Interpreter {
  static Interpreter fromBuffer(Uint8List buffer) {
    return Interpreter._();
  }
  
  Interpreter._() {
    print('Mock Interpreter created for web platform');
  }
  
  void run(List input, List output) {
    // Mock prediction - generate more realistic scores
    final random = DateTime.now().millisecond % 100;
    double chefScore = 0.3 + (random % 40) / 100.0;
    double retailScore = 0.2 + ((random + 20) % 35) / 100.0;
    double cleaningScore = 0.1 + ((random + 40) % 30) / 100.0;
    
    // Normalize to ensure they sum to 1.0
    double total = chefScore + retailScore + cleaningScore;
    chefScore /= total;
    retailScore /= total;
    cleaningScore /= total;
    
    output[0] = [chefScore, retailScore, cleaningScore];
    
    print('Mock prediction - Chef: ${(chefScore * 100).toStringAsFixed(1)}%, Retail: ${(retailScore * 100).toStringAsFixed(1)}%, Cleaning: ${(cleaningScore * 100).toStringAsFixed(1)}%');
  }
  
  void close() {
    // No-op for mock
  }
}
