import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:confetti/confetti.dart';

class TeaLevel1Game extends StatefulWidget {
  const TeaLevel1Game({super.key});

  @override
  State<TeaLevel1Game> createState() => _TeaLevel1GameState();
}

class _TeaLevel1GameState extends State<TeaLevel1Game> {
  List<String> ingredients = ['Ginger', 'Milk', 'Sugar', 'Cup leaves'];
  List<String> correctIngredients = ['Ginger', 'Milk', 'Sugar', 'Cup leaves'];
  String? draggedItem;
  String? droppedInCup;
  bool isGameComplete = false;
  int score = 0;
  int attempts = 0;
  int _seconds = 0;
  Timer? _timer;
  
  // Confetti controller
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    // Initialize confetti controller
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    
    // Force landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Start timer
    _startTimer();
  }

  @override
  void dispose() {
    // Reset orientation when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Cancel timer
    _timer?.cancel();
    // Dispose confetti controller
    _confettiController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++; // Count up instead of down
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Kitchen background
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/kitchen1.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
              // Top bar with title
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 400) {
                      // Small screen - vertical layout
                      return Column(
                        children: [
                          const Text(
                            'Tea Making - Level 1',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildCompactStatItem('Score', score.toString()),
                              const SizedBox(width: 16),
                              _buildTimer(),
                              const SizedBox(width: 16),
                              _buildCompactStatItem('Attempts', attempts.toString()),
                            ],
                          ),
                        ],
                      );
                    } else {
                      // Large screen - horizontal layout
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tea Making - Level 1',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _buildTimer(),
                          Row(
                            children: [
                              _buildStatItem('Score', score.toString()),
                              const SizedBox(width: 16),
                              _buildStatItem('Attempts', attempts.toString()),
                            ],
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
              // Main game area - Cup centered with ingredients on sides
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Left side - Vertical ingredients
                      Expanded(
                        flex: 1,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (ingredients.isNotEmpty) _buildIngredientCard(ingredients[0]),
                            if (ingredients.length > 1) _buildIngredientCard(ingredients[1]),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Center - Cup drop zone
                      Container(
                        width: 250,
                        height: 250,
                        child: DragTarget<String>(
                          onAccept: (data) {
                            setState(() {
                              droppedInCup = data;
                              attempts++;
                              
                              if (correctIngredients.contains(data)) {
                                score += 10;
                                ingredients.remove(data);
                                
                                // Trigger confetti for correct answer
                                _confettiController.play();
                                
                                if (ingredients.isEmpty) {
                                  isGameComplete = true;
                                  _showCompletionDialog();
                                }
                              } else {
                                _showWrongIngredientDialog();
                              }
                            });
                          },
                          builder: (context, candidateData, rejectedData) {
                            return Container(
                              width: 250,
                              height: 250,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: candidateData != null ? Colors.green.withOpacity(0.3) : Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: candidateData != null ? Colors.green : Colors.white.withOpacity(0.5),
                                  width: candidateData != null ? 4 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Drop here:',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.grey.shade100,
                                        ),
                                        child: Image.asset(
                                          'assets/Cup.jpeg',
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) {
                                            print('Error loading assets/Cup.jpeg: $error');
                                            return Icon(Icons.local_cafe, size: 60, color: Color(0xFF8B4513));
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      if (droppedInCup != null)
                                        Text(
                                          'Added: $droppedInCup',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Right side - Vertical ingredients
                      Expanded(
                        flex: 1,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (ingredients.length > 2) _buildIngredientCard(ingredients[2]),
                            if (ingredients.length > 3) _buildIngredientCard(ingredients[3]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            ),
          ),
          ),
          
          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: math.pi / 2, // downward direction
              blastDirectionality: BlastDirectionality.directional,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              shouldLoop: false,
              colors: [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientCard(String ingredient) {
    bool isUsed = draggedItem == ingredient;
    
    // Map ingredient names to actual asset files
    String assetPath;
    switch (ingredient) {
      case 'Ginger':
        assetPath = 'assets/Ginger.jpeg';
        break;
      case 'Milk':
        assetPath = 'assets/Milk.jpeg';
        break;
      case 'Sugar':
        assetPath = 'assets/Sugar.jpeg';
        break;
      case 'Cup leaves':
        assetPath = 'assets/cup leaves.jpeg';
        break;
      default:
        assetPath = 'assets/Cup.jpeg';
    }
    
    return Draggable<String>(
      data: ingredient,
      feedback: Container(
        width: 120,
        height: 120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading $assetPath: $error');
                  return Icon(Icons.error, size: 40, color: Colors.red);
                },
              ),
            ),
            SizedBox(height: 8),
            Text(
              ingredient,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 2,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      childWhenDragging: Container(
        width: 120,
        height: 120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.withOpacity(0.3),
              ),
              child: Center(
                child: Text(
                  ingredient,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      child: Container(
        width: 120,
        height: 120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading $assetPath: $error');
                  return Icon(Icons.error, size: 40, color: Colors.red);
                },
              ),
            ),
            SizedBox(height: 8),
            Text(
              ingredient,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 2,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showWrongIngredientDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Wrong Ingredient!'),
        content: Text('This is not the right ingredient for tea. Try again!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    _timer?.cancel(); // Stop timer when game completes
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Level Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Congratulations!'),
            Text('Final Score: $score'),
            Text('Total Attempts: $attempts'),
            Text('Time Spent: $_seconds seconds'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to next level or back to menu
              Navigator.pop(context);
            },
            child: Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '${_seconds}s',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
