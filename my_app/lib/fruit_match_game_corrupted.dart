import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:confetti/confetti.dart';

class FruitMatchGame extends StatelessWidget {
  const FruitMatchGame({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Match the Ripe Fruits',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      home: const LandscapeGame(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LandscapeGame extends StatelessWidget {
  const LandscapeGame({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Force landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    return const GameScreen();
  }
}

class Fruit {
  final String name;
  final Color color;
  final String emoji;
  final String imagePath;

  Fruit({
    required this.name,
    required this.color,
    required this.emoji,
    required this.imagePath,
  });
}

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late List<Fruit> fruits;
  late Fruit targetFruit;
  late List<Fruit> options;
  int score = 0;
  int lives = 3;
  int levelScoreLimit = 100;
  bool isAnswered = false;
  String? selectedFruitName;
  bool isCorrect = false;
  late AnimationController _scaleController;
  late AnimationController _questionAnimationController;
  late Animation<double> _questionScaleAnimation;
  
  // Confetti controller
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _initializeFruits();
    
    // Initialize confetti controller
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _questionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200), // Slower animation for better performance
      vsync: this,
    );

    _questionScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15, // Reduced scale range for better performance
    ).animate(CurvedAnimation(
      parent: _questionAnimationController,
      curve: Curves.linear, // Use linear curve for better performance
    ));
    
    // Start animation after initialization
    _questionAnimationController.repeat(reverse: true);
    
    _generateNewRound();
  }

  void _initializeFruits() {
    fruits = [
      // Papaya stages
      Fruit(
        name: 'Unripe Papaya',
        color: const Color(0xFF2E7D32), // Dark Green
        emoji: '🟢',
        imagePath: 'assets/Unripe papaya dark.png',
      ),
      Fruit(
        name: 'Half-Ripe Papaya',
        color: const Color(0xFF9CCC65), // Green + Yellow mix
        emoji: '🟡',
        imagePath: 'assets/Half ripe.png',
      ),
      Fruit(
        name: 'Ripe Papaya',
        color: const Color(0xFFFFB74D), // Yellow-Orange
        emoji: '🟠',
        imagePath: 'assets/Ripe Papaya.png',
      ),
      // Mango stages
      Fruit(
        name: 'Unripe Mango',
        color: const Color(0xFF2E7D32), // Dark Green
        emoji: '🟢',
        imagePath: 'assets/Unripe Mango .png',
      ),
      Fruit(
        name: 'Ripe Yellow Mango',
        color: const Color(0xFFFFB74D), // Yellow-Orange
        emoji: '�',
        imagePath: 'assets/Ripe Mango.png',
      ),
      // Banana stages
      Fruit(
        name: 'Unripe Banana',
        color: const Color(0xFF2E7D32), // Dark Green
        emoji: '🟢',
        imagePath: 'assets/Unripe Banana.png',
      ),
      Fruit(
        name: 'Overripe Banana',
        color: const Color(0xFF8D6E63), // Brown
        emoji: '�',
        imagePath: 'assets/Over ripe banana.png',
      ),
      Fruit(
        name: 'Ripe Banana',
        color: const Color(0xFFFFB74D), // Yellow-Orange
        emoji: '�',
        imagePath: 'assets/Ripe Banana.png',
      ),
    ];
  }

  void _generateNewRound() {
    // Only target the correct ripe fruits
    final correctRipeFruits = fruits.where((f) => 
        f.name == 'Ripe Papaya' || 
        f.name == 'Ripe Yellow Mango' || 
        f.name == 'Ripe Banana'
    ).toList();
    
    targetFruit = correctRipeFruits[(DateTime.now().millisecondsSinceEpoch ~/ 1000) % correctRipeFruits.length];
    
    options = [];
    options.add(targetFruit);
    
    // Add 2 wrong options from the remaining fruits
    final availableFruits = fruits.where((f) => f.name != targetFruit.name).toList();
    availableFruits.shuffle();
    options.addAll(availableFruits.take(2));
    
    options.shuffle();
    isAnswered = false;
    selectedFruitName = null;
    isCorrect = false;
    
    // Start continuous pop in and out animation for new question
    // Animation is already running from initState
  }

  void _handleFruitSelection(Fruit selectedFruit) {
    if (isAnswered) return;
    
    setState(() {
      isAnswered = true;
      selectedFruitName = selectedFruit.name;
      isCorrect = selectedFruit.name == targetFruit.name;
    });

    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });

    if (isCorrect) {
      setState(() => score += 10);
      
      // Trigger confetti for correct answer
      _confettiController.play();
      
      // Check if level score limit reached
      if (score >= levelScoreLimit) {
        _showLevelCompleteDialog();
      } else {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() => _generateNewRound());
          }
        });
      }
    } else {
      setState(() => lives--);
      if (lives <= 0) {
        _showGameOverDialog();
      } else {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() => _generateNewRound());
          }
        });
      }
    }
  }

  void _showLevelCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Level 1 Complete!'),
        content: Text('Congratulations! You completed Level 1 with a score of $score!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                score = 0;
                lives = 3;
                _generateNewRound();
              });
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Game Over!'),
        content: Text('Final Score: $score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                score = 0;
                lives = 3;
                _generateNewRound();
              });
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _questionAnimationController.dispose();
    _confettiController.dispose();
    super.dispose();
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 600) {
                    // Small screen - vertical layout
                    return Column(
                      children: [
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildCompactStatItem('Score', score.toString()),
                            const SizedBox(width: 16),
                            _buildCompactStatItem('Lives', lives.toString()),
                          ],
                color: Colors.orange,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 400) {
                      // Small screen - vertical layout
                      return Column(
                        children: [
                          const Text(
                            'Match the Ripe Fruits',
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
                              _buildCompactStatItem('Lives', lives.toString()),
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
                            'Match the Ripe Fruits',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              _buildStatItem('Score', score.toString()),
                              const SizedBox(width: 16),
                              _buildStatItem('Lives', lives.toString()),
                            ],
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
              // Main game area - Horizontal split
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Left side - Target fruit display
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Find this ripe fruit:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: targetFruit.color,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.black26,
                                      width: 2,
                                    ),
                                  ),
                                  child: AnimatedBuilder(
                                    animation: _questionScaleAnimation,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _questionScaleAnimation.value,
                                        child: Image.asset(
                                          targetFruit.imagePath,
                                          fit: BoxFit.contain,
                                          alignment: Alignment.center,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.image_not_supported,
                                              size: 80,
                                              color: Colors.white,
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                targetFruit.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Right side - Answer options
                      Expanded(
                        flex: 1,
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.0, // Makes tiles square
                          ),
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final fruit = options[index];
                            final isSelected = selectedFruitName == fruit.name;
                            
                            return ScaleTransition(
                              scale: isSelected
                                  ? Tween(begin: 1.0, end: 1.05).animate(
                                      _scaleController,
                                    )
                                  : AlwaysStoppedAnimation(1.0),
                              child: GestureDetector(
                                onTap: () =>
                                    _handleFruitSelection(fruit),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (isCorrect
                                            ? Colors.green
                                            : Colors.red)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.transparent
                                          : Colors.black12,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                        spreadRadius: 2,
                                      ),
                                      BoxShadow(
                                        color: fruit.color.withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    gradient: isSelected
                                        ? null
                                        : LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.white,
                                              Colors.grey.shade50,
                                            ],
                                          ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Image.asset(
                                      fruit.imagePath,
                                      fit: BoxFit.contain,
                                      alignment: Alignment.center,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.image_not_supported,
                                          size: 60,
                                          color: Colors.grey,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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

  Widget _buildStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
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

  Widget _buildCompactStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
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
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
