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
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _questionScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _questionAnimationController,
      curve: Curves.linear,
    ));

    _generateNewRound();
    _startQuestionAnimation();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _questionAnimationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _initializeFruits() {
    fruits = [
      Fruit(name: 'Ripe Papaya', assetPath: 'assets/Ripe Papaya.png'),
      Fruit(name: 'Ripe Yellow Mango', assetPath: 'assets/Ripe Mango.png'),
      Fruit(name: 'Ripe Banana', assetPath: 'assets/Ripe Banana.png'),
      Fruit(name: 'Half ripe Papaya', assetPath: 'assets/Half ripe.png'),
      Fruit(name: 'Unripe Papaya dark', assetPath: 'assets/Unripe papaya dark.png'),
      Fruit(name: 'Unripe Mango', assetPath: 'assets/Unripe Mango .png'),
      Fruit(name: 'Unripe Banana', assetPath: 'assets/Unripe Banana.png'),
    ];
  }

  void _startQuestionAnimation() {
    _questionAnimationController.repeat(reverse: true);
  }

  void _generateNewRound() {
    final correctRipeFruits = fruits.where((f) => 
        f.name == 'Ripe Papaya' || 
        f.name == 'Ripe Yellow Mango' || 
        f.name == 'Ripe Banana'
    ).toList();
    
    targetFruit = correctRipeFruits[(DateTime.now().millisecondsSinceEpoch ~/ 1000) % correctRipeFruits.length];
    
    options = [];
    options.add(targetFruit);
    
    // Add 2-3 random incorrect options
    final incorrectFruits = fruits.where((f) => 
        f.name != 'Ripe Papaya' && 
        f.name != 'Ripe Yellow Mango' && 
        f.name != 'Ripe Banana'
    ).toList();
    
    incorrectFruits.shuffle();
    for (int i = 0; i < 2 && i < incorrectFruits.length; i++) {
      options.add(incorrectFruits[i]);
    }
    
    options.shuffle();
    isAnswered = false;
    selectedFruitName = null;
    isCorrect = false;
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
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Match the Ripe Fruits',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 30),
                              _buildQuestionCard(),
                              const SizedBox(height: 40),
                              _buildOptionsGrid(isSmallScreen: true),
                            ],
                          ),
                        ),
                      ],
                    );
                  } else {
                    // Large screen - horizontal layout
                    return Row(
                      children: [
                        // Left side - stats and question
                        Expanded(
                          flex: 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Match the Ripe Fruits',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 40),
                              Row(
                                children: [
                                  _buildStatItem('Score', score.toString()),
                                  const SizedBox(width: 16),
                                  _buildStatItem('Lives', lives.toString()),
                                ],
                              ),
                              const SizedBox(height: 40),
                              _buildQuestionCard(),
                            ],
                          ),
                        ),
                        // Right side - options
                        Expanded(
                          flex: 1,
                          child: _buildOptionsGrid(isSmallScreen: false),
                        ),
                      ],
                    );
                  }
                },
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

  Widget _buildQuestionCard() {
    return ScaleTransition(
      scale: _questionScaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Find the ripe fruit:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange, width: 3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  targetFruit.assetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.image, size: 50, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              targetFruit.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsGrid({required bool isSmallScreen}) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isSmallScreen ? 2 : 3,
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          childAspectRatio: 0.8,
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
              onTap: () => _handleFruitSelection(fruit),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isCorrect
                          ? Colors.green
                          : Colors.red)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : Colors.black12,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            fruit.assetPath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(Icons.image, size: 30, color: Colors.grey),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          fruit.name,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class Fruit {
  final String name;
  final String assetPath;

  Fruit({required this.name, required this.assetPath});
}
